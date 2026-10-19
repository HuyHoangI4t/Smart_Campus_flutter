import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class ServerConfigDialog extends ConsumerStatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ServerConfigDialog(),
    );
  }

  @override
  ConsumerState<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends ConsumerState<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(serverUrlProvider);
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(String url) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final healthEndpoint = cleanUrl.endsWith('/api') ? '$cleanUrl/health' : '$cleanUrl/api/health';

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await dio.get(healthEndpoint);
      if (res.statusCode == 200) {
        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _testResult = 'Kết nối máy chủ thành công (200 OK)';
        });
      } else {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Máy chủ phản hồi mã lỗi: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra lại IP hoặc chạy "adb reverse tcp:5000 tcp:5000"';
      });
    }
  }

  Future<void> _saveUrl() async {
    final cleanUrl = _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    final finalUrl = cleanUrl.endsWith('/api') ? cleanUrl : '$cleanUrl/api';

    final storage = ref.read(storageServiceProvider);
    await storage.saveServerUrl(finalUrl);
    ref.read(serverUrlProvider.notifier).setUrl(finalUrl);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật máy chủ: $finalUrl'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_ethernet_rounded,
                    color: Color(0xFF132F73),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cấu hình IP Máy chủ',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn kết nối phù hợp với điện thoại của bạn:',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),

            // Presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  label: 'Wi-Fi (${ApiEndpoints.lanHost})',
                  url: ApiEndpoints.lanBaseUrl,
                ),
                _buildPresetChip(
                  label: 'USB Cáp (adb reverse)',
                  url: ApiEndpoints.localhostBaseUrl,
                ),
                _buildPresetChip(
                  label: 'Giả lập Android',
                  url: ApiEndpoints.emulatorBaseUrl,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Input URL
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Base URL API',
                hintText: 'http://192.168.x.x:5000/api',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 13.5, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),

            // Test Result Banner
            if (_testResult != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: _testSuccess ? const Color(0xFF16A34A) : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess ? const Color(0xFF15803D) : AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : () => _testConnection(_urlController.text),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    child: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Kiểm tra kết nối',
                            style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF132F73),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lưu cấu hình',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({required String label, required String url}) {
    final isSelected = _urlController.text.trim() == url.trim();
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? const Color(0xFF132F73) : const Color(0xFF475569),
        ),
      ),
      backgroundColor: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
      side: BorderSide(
        color: isSelected ? const Color(0xFF818CF8) : Colors.transparent,
      ),
      onPressed: () {
        setState(() {
          _urlController.text = url;
          _testResult = null;
        });
      },
    );
  }
}
