import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/wireframe_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/grade_model.dart';
import '../providers/grades_provider.dart';

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  final List<String> _semesters = [
    'Tất cả',
    'HK1 (2026)',
    'HK2 (2025)',
    'HK1 (2025)',
    'HK2 (2024)',
  ];

  @override
  Widget build(BuildContext context) {
    final gradesState = ref.watch(gradesProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = (user?.fullName.isNotEmpty == true)
        ? user!.fullName
        : (user?.isGuest == true ? 'Khách tham quan' : 'Sinh viên');
    final items = gradesState.filteredItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── 1. NAVHEADER (Navy #132F73) ───
          NavHeader(
            title: 'Kết quả học tập',
            subtitle: 'Bảng điểm của $userName',
            rightElement: GestureDetector(
              onTap: () => _showDetailModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Chi tiết',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── 2. SCROLLABLE BODY ───
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(gradesProvider.notifier).fetchGrades(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // 3. OVERVIEW CARD (NAVY BLUE)
                  _buildOverviewCard(context, gradesState),
                  const SizedBox(height: 18),

                  // 4. SEMESTER FILTER PILLS
                  _buildSemesterFilter(gradesState),
                  const SizedBox(height: 18),

                  // 5. LIST HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Học phần đã có điểm (${items.length})',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textForeground,
                        ),
                      ),
                      const Text(
                        'Kéo xuống để cập nhật',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 6. GRADE ITEMS (WIREFRAME SKELETON / EMPTY STATE)
                  if (gradesState.isLoading) ...[
                    const WireframeScheduleCard(),
                    const WireframeScheduleCard(),
                    const WireframeScheduleCard(),
                  ] else if (items.isEmpty) ...[
                    const WireframeEmptyState(
                      icon: Icons.school_outlined,
                      title: 'Chưa có dữ liệu điểm học phần',
                      subtitle: 'Không tìm thấy dữ liệu điểm nào trong cơ sở dữ liệu cho kỳ học này.',
                    ),
                  ] else
                    for (final item in items) ...[
                      _buildRealGradeCard(context, item),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── OVERVIEW CARD (Navy #132F73) ───
  Widget _buildOverviewCard(BuildContext context, GradesState gradesState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top Row: Title + Rank Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TỔNG KẾT ĐIỂM TÍCH LŨY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.military_tech, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      gradesState.academicRank.isNotEmpty ? gradesState.academicRank : 'Khá',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Columns: 7.21, 2.63, 106
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Thang 10
              Column(
                children: [
                  Text(
                    gradesState.averageScore10 > 0
                        ? gradesState.averageScore10.toStringAsFixed(2)
                        : '--',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thang điểm 10',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Thang 4
              Column(
                children: [
                  Text(
                    gradesState.gpa4 > 0
                        ? gradesState.gpa4.toStringAsFixed(2)
                        : '--',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thang điểm 4',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Tín chỉ
              Column(
                children: [
                  Text(
                    gradesState.accumulatedCredits > 0
                        ? '${gradesState.accumulatedCredits}'
                        : '0',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFCD34D), // Amber yellow
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tín chỉ tích lũy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Strip: Tín chỉ đã tích lũy vs Tín chỉ chưa học / đang học
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Đã tích lũy: ${gradesState.accumulatedCredits} TC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.pending_outlined, color: Color(0xFFFCD34D), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Đang học: ${gradesState.inProgressCredits} TC',
                      style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Button: "Xem bảng điểm chi tiết thành phần >"
          GestureDetector(
            onTap: () => _showDetailModal(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem bảng điểm chi tiết thành phần',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEMESTER FILTER PILLS ───
  Widget _buildSemesterFilter(GradesState gradesState) {
    final semesters = gradesState.availableSemesters.isNotEmpty
        ? gradesState.availableSemesters
        : _semesters;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(semesters.length, (index) {
          final title = semesters[index];
          final isSelected = title == gradesState.selectedSemester;

          return GestureDetector(
            onTap: () {
              ref.read(gradesProvider.notifier).selectSemester(title);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.text,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── SAMPLE GRADE ITEM (Matching 11_grades_overview.jpg) ───
  Widget _buildSampleGradeItem({
    required String credits,
    required String subject,
    required String semester,
    required String status,
    required String score,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Credits & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                credits,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2), // Light pink/red
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subject Title
          Text(
            subject,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textForeground,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: Semester & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                semester,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                score,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealGradeCard(BuildContext context, GradeItem item) {
    return _buildSampleGradeItem(
      credits: '${item.credits} tín chỉ',
      subject: item.subjectName,
      semester: item.semester,
      status: item.status,
      score: '${item.score10.toStringAsFixed(1)} (${item.conversion.letterGrade})',
    );
  }

  void _showDetailModal(BuildContext context) {
    context.push('/grades/detail');
  }
}
