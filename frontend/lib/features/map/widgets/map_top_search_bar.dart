import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Thanh tìm kiếm và bộ lọc danh mục nổi trên đầu bản đồ (Chuẩn 09_map_campus_overview.jpg)
class MapTopSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onClearSearch;

  static const List<Map<String, dynamic>> categories = [
    {'label': 'Tất cả', 'icon': Icons.grid_view},
    {'label': 'Giảng đường', 'icon': Icons.menu_book},
    {'label': 'WC', 'icon': Icons.water_drop_outlined},
    {'label': 'Hành chính', 'icon': Icons.business_center_outlined},
    {'label': 'Ký túc xá', 'icon': Icons.home_outlined},
    {'label': 'Học tập', 'icon': Icons.book_outlined},
    {'label': 'Y tế', 'icon': Icons.local_hospital_outlined},
    {'label': 'Thể thao', 'icon': Icons.fitness_center},
    {'label': 'Tiện ích', 'icon': Icons.coffee},
  ];

  const MapTopSearchBar({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thanh tìm kiếm hình Pill
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textForeground),
                  decoration: const InputDecoration(
                    hintText: 'Tìm tòa nhà, phòng học (vd: 2.20, 8.3.4)...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: onClearSearch,
                  child: const Icon(Icons.cancel, color: AppColors.textSubtle, size: 18),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$totalCount điểm',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Danh sách Category dạng viên thuốc cuộn ngang
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final label = cat['label'] as String;
              final icon = cat['icon'] as IconData;
              final isSelected = selectedCategory == label;

              return GestureDetector(
                onTap: () => onCategorySelected(label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

