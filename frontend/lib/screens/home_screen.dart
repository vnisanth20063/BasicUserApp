import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/app_version_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/backend_settings_sheet.dart';

/// Main screen featuring User Registration form and Registered Users list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _apiService = ApiService();

  // Form Controllers & Key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Registration Form State
  bool _isRegistering = false;
  String? _registrationSuccessMessage;
  String? _registrationErrorMessage;

  // Registered Users State
  bool _isLoadingUsers = false;
  String? _usersErrorMessage;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch users and check whether a newer app release is available.
    _fetchUsers();
    _checkForAppUpdate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Backend Operations
  // ---------------------------------------------------------------------------

  /// Fetches registered users from backend GET /api/users
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _usersErrorMessage = null;
    });

    try {
      final users = await _apiService.fetchUsers();
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _usersErrorMessage = e.message;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _usersErrorMessage = 'Unexpected error: $e';
        _isLoadingUsers = false;
      });
    }
  }

  /// Checks the backend's /api/version endpoint and offers the latest APK.
  /// Direct APK distribution requires the user to approve/install the update;
  /// Android does not allow an app to silently replace itself.
  Future<void> _checkForAppUpdate() async {
    try {
      final AppVersionModel? latest = await _apiService.checkAppVersion();
      if (!mounted || latest == null) return;

      final hasUpdate = latest.isUpdateAvailable(
        ApiConfig.appVersion,
        ApiConfig.appBuildNumber,
      );
      if (!hasUpdate || latest.releaseUrl.trim().isEmpty) return;

      final releaseUri = Uri.tryParse(latest.releaseUrl);
      if (releaseUri == null ||
          (releaseUri.scheme != 'https' && releaseUri.scheme != 'http')) {
        return;
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: !latest.forceUpdate,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Update available'),
          content: Text(
            latest.releaseNotes.isEmpty
                ? 'A newer version of BasicUserApp is available.'
                : 'A newer version of BasicUserApp is available.\\n\\n${latest.releaseNotes}',
          ),
          actions: [
            if (!latest.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Later'),
              ),
            FilledButton(
              onPressed: () async {
                final opened = await launchUrl(
                  releaseUri,
                  mode: LaunchMode.externalApplication,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (!opened && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open the update download link.'),
                    ),
                  );
                }
              },
              child: const Text('Download update'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Update checks must never prevent the registration screen from opening.
    }
  }

  /// Submits new user to backend POST /api/users
  Future<void> _submitRegistration() async {
    // Clear previous banners
    setState(() {
      _registrationSuccessMessage = null;
      _registrationErrorMessage = null;
    });

    // Run client-side validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final newUser = await _apiService.registerUser(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );

      setState(() {
        _isRegistering = false;
        _registrationSuccessMessage =
            'User "${newUser.name}" registered successfully!';
        // Reset form inputs
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
      });

      // Refresh users list in background
      _fetchUsers();
    } on ApiException catch (e) {
      setState(() {
        _isRegistering = false;
        _registrationErrorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isRegistering = false;
        _registrationErrorMessage =
            'An unexpected error occurred while communicating with the server: $e';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Validation Methods
  // ---------------------------------------------------------------------------

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address (e.g., name@example.com).';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number.';
    }
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number (at least 7 digits).';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.emeraldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.how_to_reg_rounded,
                color: AppTheme.emeraldPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('User Registration'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configure Backend API URL',
            icon: const Icon(Icons.settings_ethernet_rounded),
            color: AppTheme.emeraldPrimary,
            onPressed: () {
              BackendSettingsSheet.show(
                context,
                onConfigSaved: () => _fetchUsers(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.emeraldPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.emeraldPrimary,
          indicatorWeight: 3,
          tabs: [
            const Tab(
              icon: Icon(Icons.person_add_outlined),
              text: 'Register',
            ),
            Tab(
              icon: Badge(
                label: Text('${_users.length}'),
                isLabelVisible: _users.isNotEmpty,
                backgroundColor: AppTheme.emeraldPrimary,
                child: const Icon(Icons.people_outline_rounded),
              ),
              text: 'Users List',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegistrationTab(),
          _buildUsersListTab(),
        ],
      ),
    );
  }

  /// Tab 1: User Registration Form
  Widget _buildRegistrationTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Subtitle & API Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter your details to register with the REST API.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        BackendSettingsSheet.show(
                          context,
                          onConfigSaved: () => _fetchUsers(),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.emeraldPrimary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.emeraldPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'API Config',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.emeraldDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Success Feedback Banner
                if (_registrationSuccessMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.emeraldPrimary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.emeraldPrimary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _registrationSuccessMessage!,
                                style: const TextStyle(
                                  color: AppTheme.emeraldDeep,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _tabController.animateTo(1),
                                child: const Text(
                                  'View registered users in Users List →',
                                  style: TextStyle(
                                    color: AppTheme.emeraldDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Error Feedback Banner
                if (_registrationErrorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppTheme.errorRed,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _registrationErrorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.errorRed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Input Field 1: Full Name
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isRegistering,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g., John Doe',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 18),

                // Input Field 2: Email Address
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isRegistering,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'e.g., john.doe@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 18),

                // Input Field 3: Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isRegistering,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., +1 (555) 234-5678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 28),

                // Register User Button with Loading Indicator
                ElevatedButton(
                  onPressed: _isRegistering ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isRegistering
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Registering User...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Register User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),

                // Helpful Beginner Tip Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current backend target: ${ApiConfig.baseUrl}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tab 2: Registered Users List with Pull-to-Refresh & States
  Widget _buildUsersListTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Column(
          children: [
            // Sub-header with Title, Counter and Refresh Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Registered Users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_users.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.emeraldDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Refresh User List',
                    icon: _isLoadingUsers
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.emeraldPrimary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    color: AppTheme.emeraldPrimary,
                    onPressed: _isLoadingUsers ? null : _fetchUsers,
                  ),
                ],
              ),
            ),

            // Content Body with Dynamic States
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.emeraldPrimary,
                onRefresh: _fetchUsers,
                child: _buildUsersContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds appropriate widget based on current data state
  Widget _buildUsersContent() {
    // State 1: Initial Loading
    if (_isLoadingUsers && _users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.emeraldPrimary),
            SizedBox(height: 16),
            Text(
              'Retrieving users from server...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // State 2: Error State
    if (_usersErrorMessage != null && _users.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppTheme.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppTheme.errorRed,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to Load Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _usersErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  BackendSettingsSheet.show(
                    context,
                    onConfigSaved: () => _fetchUsers(),
                  );
                },
                icon: const Icon(Icons.settings_ethernet, size: 16),
                label: const Text('Change API Target URL'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.emeraldDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // State 3: Empty List State
    if (_users.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Icon(
                  Icons.group_off_rounded,
                  color: AppTheme.textMuted,
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Users Registered Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The users list on the server is currently empty.\nFill out the registration form to add your first user.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Go to Registration'),
              ),
            ],
          ),
        ),
      );
    }

    // State 4: Populated User List
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Initials
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.emeraldLight,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppTheme.emeraldDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // User Information Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (user.createdAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Registered: ${user.createdAt!.toLocal().toString().split('.')[0]}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

