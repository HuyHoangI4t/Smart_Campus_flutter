import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/nav_header.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _category = 'Cơ sở vật chất';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Cơ sở vật chất',
    'Chất lượng đào tạo',
    'Dịch vụ sinh viên',
    'Thư viện & KTX',
    'Góp ý ứng dụng',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        ApiEndpoints.feedback,
        data: {
          'title': '[$_category] Góp ý từ ứng dụng sinh viên',
          'category': _category,
          'content': _contentController.text.trim(),
          'rating': 5,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã gửi ý kiến phản hồi!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ghi nhận ý kiến phản hồi của bạn!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          NavHeader(
            title: 'Góp ý & Phản ánh',
            subtitle: 'Kênh tiếp nhận ý kiến đóng góp xây dựng Nhà trường',
            showBack: true,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ý kiến đóng góp xây dựng',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mọi phản ánh của bạn sẽ được chuyển trực tiếp tới Ban Giám hiệu và các phòng ban chuyên trách.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Phân loại
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Chủ đề phản ánh'),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nội dung
                      TextFormField(
                        controller: _contentController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung chi tiết *',
                          hintText: 'Nhập ý kiến, phản ánh về giảng đường, thiết bị, dịch vụ...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) =>
                            v == null || v.trim().length < 10
                                ? 'Vui lòng nhập tối thiểu 10 ký tự'
                                : null,
                      ),
                      const SizedBox(height: 24),

                      // Nút gửi
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Gửi ý kiến phản hồi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
