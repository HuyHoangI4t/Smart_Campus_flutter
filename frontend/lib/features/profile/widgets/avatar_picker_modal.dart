import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

const List<Map<String, String>> _presetAvatars = [
  {
    'id': '1',
    'label': 'Sinh viên Nam 1',
    'uri': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=250&q=80',
  },
  {
    'id': '2',
    'label': 'Sinh viên Nữ 1',
    'uri': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=250&q=80',
  },
  {
    'id': '3',
    'label': 'Sinh viên Nam 2',
    'uri': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=250&q=80',
  },
  {
    'id': '4',
    'label': 'Sinh viên Nữ 2',
    'uri': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=250&q=80',
  },
  {
    'id': '5',
    'label': 'Avatar 3D Nam',
    'uri': 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
  },
  {
    'id': '6',
    'label': 'Avatar 3D Nữ',
    'uri': 'https://cdn-icons-png.flaticon.com/512/3135/3135789.png',
  },
];

/// Modal chọn ảnh đại diện từ preset hoặc URL tùy chỉnh
class AvatarPickerModal extends ConsumerStatefulWidget {
  final UserModel? currentUser;
  final VoidCallback? onReturnToEdit;

  const AvatarPickerModal({
    super.key,
    this.currentUser,
    this.onReturnToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    UserModel? currentUser,
    VoidCallback? onReturnToEdit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarPickerModal(
        currentUser: currentUser,
        onReturnToEdit: onReturnToEdit,
      ),
    );
  }

  @override
  ConsumerState<AvatarPickerModal> createState() => _AvatarPickerModalState();
}

class _AvatarPickerModalState extends ConsumerState<AvatarPickerModal> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _updateAvatar(String url) async {
    final updated = (widget.currentUser ?? UserModel.guest()).copyWith(
      avatarUrl: url,
    );
    await ref.read(authProvider.notifier).updateUser(updated);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onReturnToEdit?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn ảnh đại diện',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textForeground,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22, color: AppColors.textSecondary),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onReturnToEdit?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danh sách preset
          const Text(
            'Hình đại diện có sẵn',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presetAvatars.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final item = _presetAvatars[i];
                return GestureDetector(
                  onTap: () => _updateAvatar(item['uri']!),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        item['uri']!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.person),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Nhập URL tùy chỉnh
          const Text(
            'Hoặc nhập liên kết ảnh (URL)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _urlController,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'https://...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  final url = _urlController.text.trim();
                  if (url.isNotEmpty) {
                    _updateAvatar(url);
                  }
                },
                child: const Text(
                  'Áp dụng',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

