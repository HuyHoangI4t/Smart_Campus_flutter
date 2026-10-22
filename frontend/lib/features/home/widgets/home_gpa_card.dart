import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/wireframe_widgets.dart';
import '../../grades/providers/grades_provider.dart';

/// Thẻ Tổng kết GPA (HomeGpaCard) - Chuẩn thiết kế Hybrid Android 16 & iOS HIG
/// Khi đang tải hoặc không có dữ liệu từ DB/cache, hiển thị Wireframe skeleton.
class HomeGpaCard extends ConsumerWidget {
  const HomeGpaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesState = ref.watch(gradesProvider);

    // 1. Trạng thái đang tải từ DB/mạng -> Hiển thị Wireframe Shimmer
    if (gradesState.isLoading) {
      return const WireframeGpaCard();
    }

    const rankColor = Color(0xFFF59E0B); // Amber accent
    final hasData = gradesState.items.isNotEmpty ||
        gradesState.summary.totalCredits > 0 ||
        gradesState.summary.gpa4 > 0;

    final gpa4Display = hasData ? gradesState.gpa4.toStringAsFixed(2) : '--';
    final gpa10Display = hasData ? gradesState.averageScore10.toStringAsFixed(2) : '--';
    final creditsDisplay = hasData ? gradesState.accumulatedCredits.toString() : '0';
    final rankDisplay = hasData && gradesState.summary.academicRank.isNotEmpty
        ? gradesState.summary.academicRank
        : 'Chưa có';

    return GestureDetector(
      onTap: () => context.push('/grades'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            // ── HEADER: BIỂU TƯỢNG + TIÊU ĐỀ + PILL XẾP LOẠI + CHEVRON ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.military_tech_outlined,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết quả học tập',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Tích lũy toàn khóa đào tạo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasData
                            ? rankColor.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: hasData
                              ? rankColor.withValues(alpha: 0.25)
                              : const Color(0xFFCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: hasData ? rankColor : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            rankDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: hasData ? rankColor : const Color(0xFF64748B),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textSubtle,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── BẢNG THỐNG KÊ TONAL SURFACE (TONAL CONTAINER) ──
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // GPA Hệ 4
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'GPA HỆ 4',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              gpa4Display,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: hasData ? AppColors.info : const Color(0xFF94A3B8),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              '/4.0',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 26,
                    color: AppColors.cardBorder,
                  ),

                  // GPA Hệ 10
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'GPA HỆ 10',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              gpa10Display,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: hasData ? AppColors.accent : const Color(0xFF94A3B8),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              '/10',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 26,
                    color: AppColors.cardBorder,
                  ),

                  // Tín chỉ tích luỹ
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'TÍN CHỈ',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              creditsDisplay,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: hasData ? AppColors.success : const Color(0xFF94A3B8),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'TC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
