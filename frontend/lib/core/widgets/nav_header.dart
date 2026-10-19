import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

/// Header thanh điều hướng chuẩn Navy Blue (#132F73)
/// Đồng bộ 1:1 với NavHeader.tsx của Expo
class NavHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? preTitle;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? rightElement;
  final IconData? rightIcon;
  final VoidCallback? onRight;
  final Color backgroundColor;

  const NavHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.preTitle,
    this.onBack,
    this.showBack = false,
    this.rightElement,
    this.rightIcon,
    this.onRight,
    this.backgroundColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 16),
      child: Row(
        children: [
          if (showBack || onBack != null) ...[
            GestureDetector(
              onTap: onBack ?? () => context.pop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preTitle != null) ...[
                  Text(
                    preTitle!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.72),
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (rightElement != null) ...[
            const SizedBox(width: 8),
            rightElement!,
          ] else if (rightIcon != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRight,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  rightIcon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

