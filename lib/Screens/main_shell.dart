import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/adaptive_scaffold.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/offline_banner.dart';
import 'package:money_control/Screens/analysis.dart';
import 'package:money_control/Screens/analytics.dart';
import 'package:money_control/Screens/edit_profile.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'package:money_control/Screens/settings.dart';
import 'package:money_control/Screens/wealth_builder.dart';
import 'package:money_control/Services/performance_controller.dart';
import 'package:money_control/Utils/responsive.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _wealthIndex = 3;

  late int _index = widget.initialIndex;
  late int _visited = widget.initialIndex + 1;
  final List<Widget?> _pages = List.filled(5, null);

  Future<void> _select(int i) async {
    if (i == _index) return;
    // The Wealth Builder computes financial targets from the user's age, so
    // users without an age must set one first (was enforced in gotoScreen
    // before the switch was collapsed into this shell).
    if (i == _wealthIndex) {
      final hasAge = await _checkAgeGate();
      if (!mounted) return;
      if (!hasAge) return;
    }
    setState(() {
      _index = i;
      if (i + 1 > _visited) _visited = i + 1;
    });
  }

  /// Returns true when the user may open the Wealth Builder. When age is
  /// missing (or invalid) it shows the "Setup Required" dialog and returns
  /// false. Fails open on read errors so a transient Firestore failure never
  /// strands the user on the tab bar.
  Future<bool> _checkAgeGate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();
      final data = doc.data();
      int? age = data?['age'] is num ? (data!['age'] as num).toInt() : null;
      if (age == null && data?['dob'] != null) {
        final dobTs = data!['dob'];
        final dob = dobTs is Timestamp ? dobTs.toDate() : null;
        if (dob != null) {
          final now = DateTime.now();
          age = now.year - dob.year;
          if (now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day)) {
            age--;
          }
        }
      }
      if (age != null && age > 0) return true;
    } catch (e) {
      debugPrint("Error checking age: $e");
      return true;
    }

    final overlayCtx = Get.overlayContext;
    if (overlayCtx == null) return false;
    // Get.overlayContext always resolves a fresh context — false positive.
    // ignore: use_build_context_synchronously
    await showGeneralDialog(
      context: overlayCtx, // ignore: use_build_context_synchronously
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: () {
                final sw = MediaQuery.sizeOf(ctx).width;
                final raw = sw * 0.85;
                return raw > 340
                    ? 340.0
                    : raw < 260
                    ? 260.0
                    : raw;
              }(),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Get.isDarkMode
                      ? AppColors.darkGradient
                      : AppColors.lightGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: Get.isDarkMode
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppColors.lightBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30.w,
                    offset: Offset(0.w, 10.w),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: const Color(0xFF00E5FF),
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Setup Required",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Get.isDarkMode
                          ? Colors.white
                          : AppColors.lightTextPrimary,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "To use the Wealth Builder, we need your age to calculate financial targets.",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Get.isDarkMode
                          ? Colors.white70
                          : AppColors.lightTextSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                                color: Get.isDarkMode
                                    ? Colors.white54
                                    : AppColors.lightTextTertiary),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Get.to(() => const EditProfileScreen());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Set Age",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: child,
        );
      },
    );
    return false;
  }

  Widget _buildPage(int i) {
    switch (i) {
      case 0:
        return const BankingHomeScreen(showNavigation: false);
      case 1:
        return const AnalyticsScreen(showNavigation: false);
      case 2:
        return const AIInsightsScreen(showNavigation: false);
      case 3:
        return const WealthBuilderScreen(showNavigation: false);
      default:
        return const SettingsScreen(showNavigation: false);
    }
  }

  Widget _page(int i) => _pages[i] ??= _buildPage(i);

  @override
  Widget build(BuildContext context) {
    final isWide =
        Responsive.isTablet(context) && Responsive.isLandscape(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stack = Column(
      children: [
        const OfflineBanner(),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: List.generate(_visited, (i) {
              final active = i == _index;
              return IgnorePointer(
                ignoring: !active,
                child: ExcludeSemantics(
                  excluding: !active,
                  child: AnimatedSlide(
                    offset: Offset(active ? 0 : (i < _index ? -1 : 1), 0),
                    duration: PerformanceController.to.liteMode.value
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    child: _page(i),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );

    if (isWide) {
      return Row(
        children: [
          AdaptiveNavigationRail(
            currentIndex: _index,
            isDark: isDark,
            onNavChanged: _select,
          ),
          Expanded(child: stack),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: stack,
      bottomNavigationBar: BottomNavBar(currentIndex: _index, onTap: _select),
    );
  }
}
