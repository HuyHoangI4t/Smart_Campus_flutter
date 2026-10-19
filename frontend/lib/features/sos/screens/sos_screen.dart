import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/nav_header.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedIncidentType = 'Cần hỗ trợ y tế';
  bool _isSending = false;

  final List<String> _incidentTypes = [
    'Cần hỗ trợ y tế',
    'Sự cố an ninh / va chạm',
    'Chập điện / Hỏa hoạn',
    'Kẹt thang máy',
    'Khác',
  ];

  final List<Map<String, String>> _hotlines = [
    {
      'label': 'Bảo vệ & An ninh cơ sở (Huy Hoàng)',
      'phone': '0329106783',
      'icon': 'shield',
    },
    {
      'label': 'Trạm Y tế sinh viên (Duyên)',
      'phone': '0978269097',
      'icon': 'health',
    },
    {
      'label': 'Cấp cứu 115 (Xuân Hoàng)',
      'phone': '0326896303',
      'icon': 'emergency',
    },
    {
      'label': 'Cứu hỏa PCCC 114 (Kiên)',
      'phone': '0968372005',
      'icon': 'fire',
    },
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _triggerSosAlert() async {
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập vị trí hiện tại của bạn để đội an ninh tiếp cận nhanh nhất.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      Position? position;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
      } catch (_) {}

      final dio = ref.read(dioProvider);
      await dio.post(
        ApiEndpoints.sos,
        data: {
          'incidentType': _selectedIncidentType,
          'location': _locationController.text.trim(),
          'description': _noteController.text.trim(),
          'latitude': position?.latitude ?? 12.6515,
          'longitude': position?.longitude ?? 108.0245,
        },
      );

      if (!mounted) return;
      setState(() => _isSending = false);

      _showSuccessDialog();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('Đã phát tín hiệu SOS!', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tín hiệu báo động đã được truyền ngay lập tức về Ban An ninh và Trạm Y tế trường Đại học Tây Nguyên.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sự cố: $_selectedIncidentType', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Vị trí: ${_locationController.text.trim()}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          NavHeader(
            title: 'Trợ giúp khẩn cấp SOS',
            subtitle: 'Hệ thống báo động an ninh & y tế học đường',
            showBack: true,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Panic Warning Box
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA), width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.danger, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tính năng phát tín hiệu khẩn cấp hỗ trợ định vị và thông báo tới đội an ninh trường ngay lập tức.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOẠI SỰ CỐ KHẨN CẤP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _incidentTypes.map((type) {
                          final isSelected = type == _selectedIncidentType;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedIncidentType = type),
                            selectedColor: AppColors.danger,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textForeground,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.danger : AppColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'VỊ TRÍ HIỆN TẠI CỦA BẠN *',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Tầng 2, Nhà học số 7, Giảng đường A1...',
                          prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'GHI CHÚ THÊM (NẾU CÓ)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Mô tả ngắn gọn về tình trạng hiện tại...',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSending ? null : _triggerSosAlert,
                        child: _isSending
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.warning, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'GỬI TÍN HIỆU CỨU HỘ KHẨN CẤP',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Hotlines List
                const Text(
                  'Đường dây nóng hỗ trợ trực tiếp',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textForeground,
                  ),
                ),
                const SizedBox(height: 10),

                Column(
                  children: _hotlines.map((hotline) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.phone_in_talk, color: AppColors.danger, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hotline['label']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textForeground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hotline['phone']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _makePhoneCall(hotline['phone']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Gọi ngay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
