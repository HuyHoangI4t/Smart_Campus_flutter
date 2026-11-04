import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/server_discovery_service.dart';

class ServerConfigDialog extends ConsumerStatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ServerConfigDialog(),
    );
  }

  @override
  ConsumerState<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends ConsumerState<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  bool _isScanning = false;
  String? _scanStatus;
  double _scanProgress = 0.0;
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

  Future<void> _autoDetectServer() async {
    setState(() {
      _isScanning = true;
      _scanProgress = 0.05;
      _scanStatus = 'Bắt đầu quét mạng tìm máy chủ...';
      _testResult = null;
    });

    try {
      final foundUrl = await ServerDiscoveryService.discoverServer(
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              _scanStatus = status;
              _scanProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      if (foundUrl != null) {
        setState(() {
          _urlController.text = foundUrl;
          _isScanning = false;
          _testSuccess = true;
          _testResult = 'Đã tìm thấy máy chủ: $foundUrl (Sẵn sàng kết nối)';
        });
      } else {
        setState(() {
          _isScanning = false;
          _testSuccess = false;
          _testResult = 'Không tìm thấy máy chủ trong mạng Wi-Fi hiện tại. Hãy kiểm tra máy tính đã bật backend và kết nối cùng Wi-Fi.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _testSuccess = false;
          _testResult = 'Lỗi trong quá trình quét: $e';
        });
      }
    }
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
        _testResult = 'Không thể kết nối tới máy chủ. Vui lòng bấm "Tự động dò IP" hoặc kiểm tra lại địa chỉ.';
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Đã cập nhật máy chủ: $finalUrl')),
          ],
        ),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
              const SizedBox(height: 14),

              // Auto-Detect Button Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tự động nhận diện IP máy chủ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hệ thống sẽ tự động quét mạng Wi-Fi và phát hiện máy chủ backend mà không cần nhập IP thủ công.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _autoDetectServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: _isScanning
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.radar_rounded, size: 17),
                      label: Text(
                        _isScanning ? 'Đang tìm kiếm...' : '⚡ Tự động tìm máy chủ',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_isScanning) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _scanProgress > 0 ? _scanProgress : null,
                        backgroundColor: const Color(0xFFDBEAFE),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      if (_scanStatus != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _scanStatus!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Hoặc chọn nhanh cấu hình sẵn có:',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Presets
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip(
                    label: 'Cắm dây USB (127.0.0.1 - Mặc định)',
                    url: ApiEndpoints.localhostBaseUrl,
                  ),
                  _buildPresetChip(
                    label: 'Giả lập Android (10.0.2.2)',
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
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
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
                      onPressed: (_isTesting || _isScanning) ? null : () => _testConnection(_urlController.text),
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
                      onPressed: _isScanning ? null : _saveUrl,
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
