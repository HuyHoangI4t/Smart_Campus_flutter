import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'avatar_picker_modal.dart';

/// Modal Cập nhật hồ sơ sinh viên (Chuẩn 15_profile_edit.jpg)
/// Tuân thủ quy tắc Flutter: Form validation, TextFormField tối ưu không lồng viền, dispose controller sạch sẽ.
class EditProfileModal extends ConsumerStatefulWidget {
  final UserModel? currentUser;

  const EditProfileModal({super.key, this.currentUser});

  static Future<void> show(BuildContext context, {UserModel? currentUser}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileModal(currentUser: currentUser),
    );
  }

  @override
  ConsumerState<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<EditProfileModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _classController;
  late TextEditingController _facultyController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.currentUser;
    _nameController = TextEditingController(text: u?.fullName ?? 'Nguyễn Huy Hoàng');
    _emailController = TextEditingController(text: u?.email ?? '${u?.studentId ?? "23103023"}@sv.ttn.edu.vn');
    _phoneController = TextEditingController(text: u?.phone ?? '0329106783');
    _classController = TextEditingController(text: u?.studentClass ?? 'K23');
    _facultyController = TextEditingController(text: u?.faculty ?? 'KHTN &CN');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _classController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Họ tên không được để trống.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final u = widget.currentUser ?? UserModel.guest();
    final updated = u.copyWith(
      fullName: name,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      studentClass: _classController.text.trim(),
      faculty: _facultyController.text.trim(),
    );

    try {
      await ref.read(authProvider.notifier).updateUser(updated);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin cá nhân lên hệ thống.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openAvatarPicker() {
    Navigator.pop(context);
    AvatarPickerModal.show(
      context,
      currentUser: widget.currentUser,
      onReturnToEdit: () => EditProfileModal.show(context, currentUser: ref.read(authProvider).user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.currentUser?.avatarUrl ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cập nhật hồ sơ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textForeground,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!_saving) Navigator.pop(context);
                    },
                    child: const Icon(Icons.close, size: 22, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Avatar preview & Thay đổi ảnh đại diện
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _openAvatarPicker,
                      child: Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE2E8F0),
                              border: Border.all(color: const Color(0xFFEEF2FF), width: 2),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: AppColors.primary,
                                  child: const Icon(Icons.person, size: 36, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.camera_alt, size: 11, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openAvatarPicker,
                      child: const Text(
                        'Thay đổi ảnh đại diện',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5 ô input thiết kế chuẩn
              _buildField(
                label: 'Họ và tên',
                controller: _nameController,
              ),
              const SizedBox(height: 12),

              _buildField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              _buildField(
                label: 'Số điện thoại',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              _buildField(
                label: 'Lớp sinh hoạt',
                controller: _classController,
              ),
              const SizedBox(height: 12),

              _buildField(
                label: 'Khoa',
                controller: _facultyController,
              ),
              const SizedBox(height: 20),

              // Nút Lưu thay đổi
              InkWell(
                onTap: _saving ? null : _handleSave,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textForeground,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

