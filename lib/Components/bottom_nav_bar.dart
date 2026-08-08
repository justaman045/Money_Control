import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Components/nav_item.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Services/performance_controller.dart';
import 'package:money_control/Utils/responsive.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  const BottomNavBar({super.key, required this.currentIndex, this.onTap});

  /// Height of the floating nav bar from the screen bottom (bottom margin +
  /// vertical padding + item height). Embedded screens lift their FABs by
  /// this amount so they render above the pill.
  static double get extendedHeight => 24.h + 42.h + 20.h;

  @override
  Widget build(BuildContext context) {
    // Obx: the blur is toggled reactively when lite mode changes in Settings.
    return Obx(() => _build(context));
  }

  Widget _build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = Responsive.isTablet(context);

    final containerColor = isDark
        ? const Color(0xFF161622).withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.95);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.lightBorder;

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.12);

    final glowColor = isDark ? const Color(0xFF00E5FF) : AppColors.primary;

    final lite = PerformanceController.to.liteMode.value;

    final navRow = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(index: 0, icon: Icons.grid_view_rounded, label: 'Home'),
          _navItem(
            index: 1,
            icon: Icons.pie_chart_outline_rounded,
            label: 'Analytics',
          ),
          _navItem(
            index: 2,
            icon: Icons.auto_awesome_outlined,
            label: 'Insights',
          ),
          _navItem(
            index: 3,
            icon: Icons.monetization_on_outlined,
            label: 'Wealth',
          ),
          _navItem(index: 4, icon: Icons.tune_rounded, label: 'Settings'),
        ],
      ),
    );

    return Container(
      margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20.w,
            offset: Offset(0.w, 10.w),
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.05),
            blurRadius: 15.w,
            spreadRadius: 2.w,
          ),
        ],
      ),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40.r),
          child: isTablet || lite
              ? navRow
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: navRow,
                ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    return NavItem(
      active: currentIndex == index,
      icon: icon,
      label: label,
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!(index);
        } else {
          gotoScreen(index, currentIndex);
        }
      },
    );
  }
}
