import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/home_widget_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/server_config_dialog.dart';
import '../../grades/providers/grades_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../schedule/providers/schedule_provider.dart';

/// Modal riêng biệt quản lý Cài đặt ứng dụng
class AppSettingsModal extends ConsumerStatefulWidget {
  const AppSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AppSettingsModal(),
    );
  }

  @override
  ConsumerState<AppSettingsModal> createState() => _AppSettingsModalState();
}

class _AppSettingsModalState extends ConsumerState<AppSettingsModal> {
  bool _scheduleReminder = true;

  @override
  Widget build(BuildContext context) {
    final activeUrl = ref.watch(serverUrlProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.settings_outlined, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Cài đặt ứng dụng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textForeground,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 22, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Placeholder
          _buildSettingsList(context, activeUrl),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, String activeUrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          _buildReminderRow(),
          const Divider(height: 1, color: AppColors.cardBorder),
          _buildTestNotifRow(),
          const Divider(height: 1, color: AppColors.cardBorder),
          _buildWidgetRow(),
          const Divider(height: 1, color: AppColors.cardBorder),
          _buildServerRow(activeUrl),
        ],
      ),
    );
  }

  Widget _buildReminderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.alarm_on_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nhắc nhở lịch học', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textForeground)),
                  SizedBox(height: 2),
                  Text('Thông báo trước khi bắt đầu 1 tiếng', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
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
                  const SnackBar(content: Text('Đã bật tính năng nhắc nhở lịch học trước 1 tiếng!'), duration: Duration(seconds: 2), backgroundColor: AppColors.primary),
                );
              } else {
                NotificationService.instance.cancelAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã tắt toàn bộ thông báo nhắc nhở lịch học.'), duration: Duration(seconds: 2)),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotifRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kiểm tra thông báo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textForeground)),
                  SizedBox(height: 2),
                  Text('Gửi thông báo mẫu lên thiết bị', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
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
                  const SnackBar(content: Text('Đã gửi thông báo thử nghiệm thành công!'), backgroundColor: AppColors.primary, duration: Duration(seconds: 2)),
                );
              }
            },
            icon: const Icon(Icons.send_outlined, size: 14),
            label: const Text('Thử gửi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.widgets_outlined, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Widget màn hình chính', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textForeground)),
                  SizedBox(height: 2),
                  Text('Đồng bộ ra màn hình điện thoại', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
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
                  const SnackBar(content: Text('Đã đồng bộ dữ liệu ra Widget Launcher!'), backgroundColor: Color(0xFF16A34A), duration: Duration(seconds: 2)),
                );
              }
            },
            icon: const Icon(Icons.sync_outlined, size: 14),
            label: const Text('Đồng bộ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerRow(String activeUrl) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ServerConfigDialog.show(context);
      },
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dns_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Máy chủ kết nối (API Server)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textForeground)),
                        const SizedBox(height: 2),
                        Text(activeUrl, style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w600, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
