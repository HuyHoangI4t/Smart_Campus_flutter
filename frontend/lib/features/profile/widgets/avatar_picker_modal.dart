import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

const List<Map<String, String>> _presetAvatars = [
  // 1. Sinh viên phong cách 3D hiện đại
  {
    'id': '3d_male',
    'label': 'Nam sinh 3D',
    'uri': 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
  },
  {
    'id': '3d_female',
    'label': 'Nữ sinh 3D',
    'uri': 'https://cdn-icons-png.flaticon.com/512/3135/3135789.png',
  },
  {
    'id': '3d_grad',
    'label': 'Tốt nghiệp',
    'uri': 'https://cdn-icons-png.flaticon.com/512/3135/3135810.png',
  },
  {
    'id': '3d_tech',
    'label': 'Công nghệ TT',
    'uri': 'https://cdn-icons-png.flaticon.com/512/3135/3135768.png',
  },
  // 2. Avatar sinh viên thực tế (Unsplash CDN)
  {
    'id': 'real_male_1',
    'label': 'Nam sinh 1',
    'uri': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=250&q=80',
  },
  {
    'id': 'real_female_1',
    'label': 'Nữ sinh 1',
    'uri': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=250&q=80',
  },
  {
    'id': 'real_male_2',
    'label': 'Nam sinh 2',
    'uri': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=250&q=80',
  },
  {
    'id': 'real_female_2',
    'label': 'Nữ sinh 2',
    'uri': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=250&q=80',
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
  bool _isSaving = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _updateAvatar(String url) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final targetUser = ref.read(authProvider).user ?? widget.currentUser ?? UserModel.guest();
    final updated = targetUser.copyWith(avatarUrl: url);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final success = await ref.read(authProvider.notifier).updateUser(updated);

      if (navigator.canPop()) {
        navigator.pop();
      }

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  success
                      ? 'Đã cập nhật ảnh đại diện thành công!'
                      : 'Đã lưu ảnh đại diện vào thiết bị.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onReturnToEdit?.call();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật ảnh đại diện: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  onTap: _isSaving ? null : () => _updateAvatar(item['uri']!),
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
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 70,
                          height: 70,
                          color: const Color(0xFFEFF6FF),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
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
                onPressed: _isSaving
                    ? null
                    : () {
                        final url = _urlController.text.trim();
                        if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:image'))) {
                          _updateAvatar(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập đường dẫn ảnh hợp lệ (http:// hoặc https://)'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
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

