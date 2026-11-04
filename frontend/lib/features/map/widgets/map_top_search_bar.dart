import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/campus_constants.dart';

/// Thanh tìm kiếm và bộ lọc danh mục nổi trên đầu bản đồ
class MapTopSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final int totalCount;
  final List<CampusLocationItem> filteredLocations;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<CampusLocationItem> onLocationSelected;
  final VoidCallback onClearSearch;

  static const List<Map<String, dynamic>> categories = [
    {'label': 'Tất cả', 'icon': Icons.grid_view},
    {'label': 'Giảng đường', 'icon': Icons.menu_book},
    {'label': 'Học tập', 'icon': Icons.book_outlined},
    {'label': 'Phòng máy', 'icon': Icons.computer_outlined},
    {'label': 'Dịch vụ', 'icon': Icons.restaurant_outlined},
    {'label': 'WC', 'icon': Icons.water_drop_outlined},
    {'label': 'Hành chính', 'icon': Icons.business_center_outlined},
    {'label': 'Ký túc xá', 'icon': Icons.home_outlined},
    {'label': 'Y tế', 'icon': Icons.local_hospital_outlined},
    {'label': 'Thể thao', 'icon': Icons.fitness_center},
    {'label': 'Tiện ích', 'icon': Icons.coffee},
  ];

  const MapTopSearchBar({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.totalCount,
    required this.filteredLocations,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onLocationSelected,
    required this.onClearSearch,
  });

  @override
  State<MapTopSearchBar> createState() => _MapTopSearchBarState();
}

class _MapTopSearchBarState extends State<MapTopSearchBar> {
  bool _isExpanded = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isExpanded) {
        setState(() => _isExpanded = true);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _isExpanded && widget.filteredLocations.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchInput(showSuggestions),
        if (showSuggestions) _buildSuggestions(),
        const SizedBox(height: 8),
        if (!showSuggestions) _buildCategoryChips(),
      ],
    );
  }

  Widget _buildSearchInput(bool showSuggestions) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isExpanded && showSuggestions ? 16 : 999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              controller: widget.searchController,
              focusNode: _focusNode,
              onChanged: (val) {
                widget.onSearchChanged(val);
                if (!_isExpanded) setState(() => _isExpanded = true);
              },
              onTap: () => setState(() => _isExpanded = true),
              style: const TextStyle(fontSize: 13.5, color: AppColors.textForeground),
              decoration: const InputDecoration(
                hintText: 'Tìm tòa nhà, phòng học (vd: 2.20, Nhà 7, Thư viện)...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (widget.searchController.text.isNotEmpty || _isExpanded)
            GestureDetector(
              onTap: () {
                widget.onClearSearch();
                _focusNode.unfocus();
                setState(() => _isExpanded = false);
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.cancel, color: AppColors.textSubtle, size: 18),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${widget.totalCount} điểm',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          shrinkWrap: true,
          itemCount: widget.filteredLocations.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 50, color: Color(0xFFF1F5F9)),
          itemBuilder: (context, index) {
            final loc = widget.filteredLocations[index];
            return InkWell(
              onTap: () {
                _focusNode.unfocus();
                setState(() => _isExpanded = false);
                widget.onLocationSelected(loc);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: loc.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(loc.icon, color: loc.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.name,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textForeground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loc.building.isNotEmpty ? loc.building : loc.description,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loc.category,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MapTopSearchBar.categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = MapTopSearchBar.categories[index];
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = widget.selectedCategory == label;

          return GestureDetector(
            onTap: () => widget.onCategorySelected(label),
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
                  Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.primary),
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
    );
  }
}

