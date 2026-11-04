import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/home_widget_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/server_config_dialog.dart';
import '../../grades/providers/grades_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../schedule/providers/schedule_provider.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _scheduleReminder = true;
  bool _isAutoDetecting = false;

  @override
  Widget build(BuildContext context) {
    final activeUrl = ref.watch(serverUrlProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // NavHeader
          NavHeader(
            title: 'Cài đặt ứng dụng',
            subtitle: 'Tùy chỉnh thông báo, tiện ích & kết nối',
            showBack: true,
            onBack: () => context.pop(),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. NHÓM THÔNG BÁO & NHẮC NHỞ
                  _buildSectionHeader(
                    icon: Icons.notifications_active_outlined,
                    title: 'Thông báo & Nhắc nhở',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildCardContainer([
                    _buildReminderTile(),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _buildTestNotifTile(),
                  ]),

                  const SizedBox(height: 22),

                  // 2. NHÓM TIỆN ÍCH WIDGET
                  _buildSectionHeader(
                    icon: Icons.widgets_outlined,
                    title: 'Tiện ích màn hình (Widget)',
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 8),
                  _buildCardContainer([
                    _buildWidgetTile(),
                  ]),

                  const SizedBox(height: 22),

                  // 3. NHÓM MÁY CHỦ & KẾT NỐI
                  _buildSectionHeader(
                    icon: Icons.dns_outlined,
                    title: 'Kết nối mạng & Máy chủ',
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 8),
                  _buildCardContainer([
                    _buildServerTile(activeUrl),
                    const Divider(height: 1, color: AppColors.cardBorder),
                    _buildAutoScanTile(),
                  ]),

                  const SizedBox(height: 22),

                  // 4. NHÓM HỆ THỐNG & BỘ NHỚ
                  _buildSectionHeader(
                    icon: Icons.info_outline,
                    title: 'Hệ thống & Thông tin',
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 8),
                  _buildCardContainer([
                    _buildAppInfoTile(),
                  ]),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildReminderTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.alarm_on_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhắc nhở lịch học',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textForeground,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thông báo trước khi ca học bắt đầu 1 tiếng',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _scheduleReminder,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _scheduleReminder = val);
              if (val) {
                final scheduleItems = ref.read(scheduleProvider).items;
                NotificationService.instance.syncAllScheduleReminders(scheduleItems);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã bật tính năng nhắc nhở lịch học trước 1 tiếng!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } else {
                NotificationService.instance.cancelAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã tắt toàn bộ thông báo nhắc nhở lịch học.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotifTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kiểm tra thông báo đẩy',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textForeground,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gửi ngay 1 thông báo mẫu lên màn hình khóa',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final nextClass = ref.read(nextClassProvider);
              final subject = nextClass.subject.isNotEmpty ? nextClass.subject : 'Lập trình di động';
              final time = nextClass.time.isNotEmpty ? nextClass.time : 'Tiết 1-4';
              final room = nextClass.room.isNotEmpty ? nextClass.room : '2.21 (CLC)';

              await NotificationService.instance.sendTestNotification(
                title: '🔔 Nhắc nhở ca học: $subject',
                body: 'Ca học bắt đầu lúc $time tại phòng $room. Hãy chuẩn bị trước 1 tiếng!',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi thông báo thử nghiệm thành công!'),
                    backgroundColor: AppColors.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.send_outlined, size: 14),
            label: const Text('Thử gửi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.widgets_outlined, color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Widget màn hình chính',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textForeground,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Đồng bộ môn học & GPA ra widget launcher',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final nextClass = ref.read(nextClassProvider);
              final gradesState = ref.read(gradesProvider);

              await HomeWidgetService.instance.updateWidgetData(
                subject: nextClass.subject.isNotEmpty ? nextClass.subject : '--',
                time: nextClass.time.isNotEmpty ? nextClass.time : '--',
                room: nextClass.room.isNotEmpty ? nextClass.room : '--',
                status: nextClass.capsuleLabel.isNotEmpty ? nextClass.capsuleLabel : 'LỊCH HỌC',
                countdown: nextClass.countdownText,
                gpa: gradesState.gpa4.toStringAsFixed(2),
                credits: '${gradesState.accumulatedCredits} TC',
                rank: gradesState.summary.academicRank.isNotEmpty ? gradesState.summary.academicRank : '--',
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đồng bộ dữ liệu ra Widget màn hình chính!'),
                    backgroundColor: Color(0xFF16A34A),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.sync_outlined, size: 14),
            label: const Text('Đồng bộ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerTile(String activeUrl) {
    return InkWell(
      onTap: () => ServerConfigDialog.show(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dns_outlined, color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Máy chủ kết nối (API Server)',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeUrl,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoScanTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.wifi_find_outlined, color: Color(0xFF475569), size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tự động quét mạng Wi-Fi',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textForeground,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quét UDP tìm backend trên mạng nội bộ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _isAutoDetecting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              : OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => _isAutoDetecting = true);
                    final found = await ref.read(serverUrlProvider.notifier).autoDetectWifiServer();
                    if (mounted) {
                      setState(() => _isAutoDetecting = false);
                      if (found != null && found.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã tìm thấy máy chủ: $found'),
                            backgroundColor: const Color(0xFF16A34A),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không tìm thấy máy chủ Wi-Fi. Đang dùng cấu hình hiện hành.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.search, size: 14),
                  label: const Text('Quét', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAppInfoTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Campus TTN',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textForeground,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Phiên bản 2.1.0 • Đại học Tây Nguyên',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'v2.1',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
