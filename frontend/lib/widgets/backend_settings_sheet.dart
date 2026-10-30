import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Modal bottom sheet allowing beginners to view or adjust the backend API base URL
/// and test the connection using the /api/health endpoint.
class BackendSettingsSheet extends StatefulWidget {
  final VoidCallback onConfigSaved;

  const BackendSettingsSheet({super.key, required this.onConfigSaved});

  static Future<void> show(BuildContext context, {required VoidCallback onConfigSaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackendSettingsSheet(onConfigSaved: onConfigSaved),
    );
  }

  @override
  State<BackendSettingsSheet> createState() => _BackendSettingsSheetState();
}

class _BackendSettingsSheetState extends State<BackendSettingsSheet> {
  late final TextEditingController _urlController;
  final ApiService _apiService = ApiService();
  bool _isTesting = false;
  String? _testMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    final previousUrl = ApiConfig.baseUrl;
    ApiConfig.baseUrl = _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');

    final isHealthy = await _apiService.checkHealth();

    setState(() {
      _isTesting = false;
      _testSuccess = isHealthy;
      _testMessage = isHealthy
          ? 'Backend connected! Health check succeeded.'
          : 'Could not connect to ${ApiConfig.baseUrl}. Verify that the Node server is running and accessible.';
    });

    if (!isHealthy) {
      ApiConfig.baseUrl = previousUrl;
    }
  }

  void _saveUrl() {
    final newUrl = _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    if (newUrl.isNotEmpty) {
      ApiConfig.baseUrl = newUrl;
      widget.onConfigSaved();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API URL updated to: ${ApiConfig.baseUrl}'),
          backgroundColor: AppTheme.emeraldPrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Backend API Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a preset or enter your host computer\'s Wi-Fi IP address if running on a physical Android phone.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Quick Preset Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Android Emulator (10.0.2.2)'),
                  backgroundColor: AppTheme.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  onPressed: () {
                    setState(() {
                      _urlController.text = 'http://10.0.2.2:5000';
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Reset to Default'),
                  backgroundColor: AppTheme.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.cardBorder),
                  ),
                  onPressed: () {
                    setState(() {
                      _urlController.text = ApiConfig.defaultEmulatorUrl;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text input for base URL
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://10.0.2.2:5000 or http://192.168.1.X:5000',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),

            // Test Feedback Banner
            if (_testMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess ? AppTheme.successLight : AppTheme.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _testSuccess ? AppTheme.successGreen : AppTheme.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess ? AppTheme.emeraldDeep : AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Buttons: Test & Save
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check, size: 18),
                    label: Text(_isTesting ? 'Testing...' : 'Test Health'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.emeraldPrimary,
                      side: const BorderSide(color: AppTheme.emeraldPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save & Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

