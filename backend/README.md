# BasicUserApp Backend REST API

A beginner-friendly Node.js Express REST API built for user registration and retrieval with JSON file persistence.

> **Note on Storage:** JSON file storage (`data/users.json`) is designed for educational demonstrations, local testing, and rapid prototyping. For production deployments, migrate to a database such as PostgreSQL or MongoDB.

---

## Features
- **ES Modules**: Modern JavaScript syntax.
- **Data Safety**: Concurrency locking and atomic file writes to protect against JSON corruption.
- **Input Validation**: Strict checks for name, email format, and phone number.
- **Duplicate Prevention**: Prevents duplicate email registrations.
- **Error Protection**: Safe error handling without leaking stack traces or internal secrets.
- **CORS Enabled**: Ready to serve requests from web, emulators, and mobile devices.

---

## API Endpoints

### 1. Health Check
- **Method**: `GET`
- **Path**: `/api/health`
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "BasicUserApp API is running smoothly.",
    "data": {
      "status": "healthy",
      "timestamp": "2026-10-29T14:00:00.000Z"
    }
  }
  ```

### 2. Register User
- **Method**: `POST`
- **Path**: `/api/users`
- **Request Body**:
  ```json
  {
    "name": "Jane Doe",
    "email": "jane.doe@example.com",
    "phone": "+1234567890"
  }
  ```
- **Success Response (201 Created)**:
  ```json
  {
    "success": true,
    "message": "User registered successfully.",
    "data": {
      "id": "usr_1730210000000_abc123",
      "name": "Jane Doe",
      "email": "jane.doe@example.com",
      "phone": "+1234567890",
      "createdAt": "2026-10-29T14:00:00.000Z"
    }
  }
  ```
- **Validation Failure / Duplicate Email (400 Bad Request)**:
  ```json
  {
    "success": false,
    "message": "A user with this email address is already registered.",
    "data": null
  }
  ```

### 3. List All Users
- **Method**: `GET`
- **Path**: `/api/users`
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Users retrieved successfully.",
    "data": [
      {
        "id": "usr_1730210000000_abc123",
        "name": "Jane Doe",
        "email": "jane.doe@example.com",
        "phone": "+1234567890",
        "createdAt": "2026-10-29T14:00:00.000Z"
      }
    ]
  }
  ```

---

## Setup & Running

```bash
# 1. Navigate to backend directory
cd backend

# 2. Install dependencies
npm install

# 3. Start the server
npm start
```
The server will start at `http://localhost:5000` (or `PORT` defined in your environment).

