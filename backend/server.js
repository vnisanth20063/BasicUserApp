import express from 'express';
import cors from 'cors';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

// -----------------------------------------------------------------------------
// Server Configuration
// -----------------------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 5000;
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'users.json');

// Middleware
app.use(cors()); // Allow cross-origin requests from Flutter apps & web clients
app.use(express.json()); // Parse incoming JSON request bodies

// Handle malformed JSON body syntax gracefully with 400 Bad Request
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({
      success: false,
      message: 'Invalid JSON format in request body.',
      data: null
    });
  }
  next(err);
});

// -----------------------------------------------------------------------------
// Safe File Storage Helper (with Concurrency Protection & Atomic Writes)
// NOTE: File-based JSON storage is intended for learning and small demonstrations.
// For production deployments, migrate to a relational or document database (e.g., PostgreSQL or MongoDB).
// -----------------------------------------------------------------------------

// Sequential queue/mutex to prevent race conditions during concurrent write requests
let fileLockPromise = Promise.resolve();

function withFileLock(operation) {
  const next = fileLockPromise.then(() => operation(), () => operation());
  fileLockPromise = next;
  return next;
}

/**
 * Ensures data/ directory and users.json exist.
 * Initializes with an empty JSON array if missing.
 */
async function initializeDataStorage() {
  try {
    await fs.mkdir(DATA_DIR, { recursive: true });
    try {
      await fs.access(DATA_FILE);
    } catch {
      // File does not exist, initialize with empty array
      await fs.writeFile(DATA_FILE, '[]\n', 'utf-8');
      console.log('Created fresh data storage file at:', DATA_FILE);
    }
  } catch (error) {
    console.error('Error during data storage initialization:', error.message);
  }
}

/**
 * Reads all users from users.json safely.
 */
async function readUsers() {
  try {
    const raw = await fs.readFile(DATA_FILE, 'utf-8');
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    if (error.code === 'ENOENT') {
      return [];
    }
    console.error('Failed to parse users.json, falling back to empty list:', error.message);
    return [];
  }
}

/**
 * Writes users atomically by saving to a temporary file first, then renaming.
 */
async function writeUsers(users) {
  const tempFile = `${DATA_FILE}.tmp.${Date.now()}`;
  const serialized = JSON.stringify(users, null, 2);
  await fs.writeFile(tempFile, serialized, 'utf-8');
  await fs.rename(tempFile, DATA_FILE);
}

// -----------------------------------------------------------------------------
// Validation Helpers
// -----------------------------------------------------------------------------
function validateUserData({ name, email, phone }) {
  const errors = [];

  // Validate Name
  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    errors.push('Full name is required.');
  } else if (name.trim().length < 2) {
    errors.push('Full name must be at least 2 characters long.');
  }

  // Validate Email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email || typeof email !== 'string' || email.trim().length === 0) {
    errors.push('Email address is required.');
  } else if (!emailRegex.test(email.trim())) {
    errors.push('Please provide a valid email address.');
  }

  // Validate Phone
  const phoneRegex = /^\+?[0-9\s\-()]{7,20}$/;
  if (!phone || typeof phone !== 'string' || phone.trim().length === 0) {
    errors.push('Phone number is required.');
  } else if (!phoneRegex.test(phone.trim())) {
    errors.push('Please provide a valid phone number (at least 7 digits).');
  }

  return errors;
}

// -----------------------------------------------------------------------------
// REST API Endpoints
// -----------------------------------------------------------------------------

/**
 * GET /api/health
 * Health check endpoint confirming that the REST API is operational.
 */
app.get('/api/health', (req, res) => {
  return res.status(200).json({
    success: true,
    message: 'BasicUserApp API is running smoothly.',
    data: {
      status: 'healthy',
      timestamp: new Date().toISOString()
    }
  });
});

/**
 * GET /api/version
 * Returns latest available mobile app version, download URL, and changelog.
 * Used by the mobile app's in-app updater to notify users of new releases.
 */
app.get('/api/version', (req, res) => {
  const latestVersion = process.env.LATEST_APP_VERSION || '1.0.1';
  const buildNumber = parseInt(process.env.LATEST_BUILD_NUMBER || '2', 10);
  const releaseUrl = process.env.APP_DOWNLOAD_URL || 'https://github.com/vnisanth20063/BasicUserApp/releases/latest/download/app-release.apk';
  const releaseNotes = process.env.RELEASE_NOTES || 'New release with automated updates, UI enhancements, and performance fixes.';

  return res.status(200).json({
    success: true,
    message: 'App version retrieved successfully.',
    data: {
      latestVersion,
      buildNumber,
      releaseUrl,
      releaseNotes,
      forceUpdate: false
    }
  });
});

/**
 * GET /api/users
 * Returns list of all registered users.
 */
app.get('/api/users', async (req, res, next) => {
  try {
    const users = await withFileLock(() => readUsers());
    return res.status(200).json({
      success: true,
      message: 'Users retrieved successfully.',
      data: users
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/users
 * Registers a new user with name, email, and phone validation.
 * Rejects duplicate email addresses.
 */
app.post('/api/users', async (req, res, next) => {
  try {
    const { name, email, phone } = req.body || {};

    // Validate inputs
    const errors = validateUserData({ name, email, phone });
    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: errors.join(' '),
        data: null
      });
    }

    const trimmedName = name.trim();
    const trimmedEmail = email.trim();
    const trimmedPhone = phone.trim();

    // Use lock for safe read-modify-write operation
    const result = await withFileLock(async () => {
      const users = await readUsers();

      // Check duplicate email (case-insensitive)
      const emailExists = users.some(
        (u) => u.email.toLowerCase() === trimmedEmail.toLowerCase()
      );

      if (emailExists) {
        return { duplicate: true };
      }

      const newUser = {
        id: `usr_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`,
        name: trimmedName,
        email: trimmedEmail,
        phone: trimmedPhone,
        createdAt: new Date().toISOString()
      };

      users.push(newUser);
      await writeUsers(users);

      return { duplicate: false, user: newUser };
    });

    if (result.duplicate) {
      return res.status(400).json({
        success: false,
        message: 'A user with this email address is already registered.',
        data: null
      });
    }

    return res.status(201).json({
      success: true,
      message: 'User registered successfully.',
      data: result.user
    });
  } catch (error) {
    next(error);
  }
});

// -----------------------------------------------------------------------------
// Error Handlers
// -----------------------------------------------------------------------------

// 404 Handler for undefined routes
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Cannot ${req.method} ${req.originalUrl}`,
    data: null
  });
});

// Centralized 500 Internal Server Error Handler (does not leak stack traces)
app.use((err, req, res, _next) => {
  console.error('Unhandled server error:', err.message);
  res.status(500).json({
    success: false,
    message: 'An unexpected internal server error occurred. Please try again later.',
    data: null
  });
});

// -----------------------------------------------------------------------------
// Server Initialization
// -----------------------------------------------------------------------------
await initializeDataStorage();

app.listen(PORT, '0.0.0.0', () => {
  console.log(`===============================================`);
  console.log(` BasicUserApp Backend Server running on port ${PORT}`);
  console.log(` Local:   http://localhost:${PORT}`);
  console.log(` Network: http://0.0.0.0:${PORT}`);
  console.log(` Storage: ${DATA_FILE}`);
  console.log(`===============================================`);
});

