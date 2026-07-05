// ====================================
// App Shell — Bottom Navigation Tab Bar
// ====================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/presensi')) return 0;
    if (location.startsWith('/riwayat')) return 1;
    if (location.startsWith('/rekap')) return 2;
    if (location.startsWith('/absen')) return 3;
    if (location.startsWith('/profil')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/presensi');
      case 1:
        context.go('/riwayat');
      case 2:
        context.go('/rekap');
      case 3:
        context.go('/absen');
      case 4:
        context.go('/profil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: 68 + MediaQuery.of(context).padding.bottom,
        color: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The Navigation Bar Background and non-center items
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 58 + MediaQuery.of(context).padding.bottom,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                  left: 12,
                  right: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Index 1: Riwayat
                    _buildBoxItem(
                      context: context,
                      isSelected: currentIndex == 1,
                      activeIcon: Icons.history,
                      inactiveIcon: Icons.history_outlined,
                      onTap: () => _onTap(context, 1),
                      isDark: isDark,
                    ),
                    // Index 2: Rekap
                    _buildBoxItem(
                      context: context,
                      isSelected: currentIndex == 2,
                      activeIcon: Icons.calendar_month,
                      inactiveIcon: Icons.calendar_month_outlined,
                      onTap: () => _onTap(context, 2),
                      isDark: isDark,
                    ),
                    // Placeholder for Center Button (Presensi)
                    const Expanded(
                      child: SizedBox(height: 56),
                    ),
                    // Index 3: Absen
                    _buildBoxItem(
                      context: context,
                      isSelected: currentIndex == 3,
                      activeIcon: Icons.event_busy,
                      inactiveIcon: Icons.event_busy_outlined,
                      onTap: () => _onTap(context, 3),
                      isDark: isDark,
                    ),
                    // Index 4: Profil
                    _buildBoxItem(
                      context: context,
                      isSelected: currentIndex == 4,
                      activeIcon: Icons.person,
                      inactiveIcon: Icons.person_outline,
                      onTap: () => _onTap(context, 4),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            // Center Elevated Circular Button (Index 0: Presensi)
            Positioned(
              top: -16, // Elevate it slightly above the bar
              left: MediaQuery.of(context).size.width / 2 - 30, // Centered (width of button is 60)
              child: _buildCenterCircularItem(
                context: context,
                isSelected: currentIndex == 0,
                activeIcon: Icons.fingerprint,
                inactiveIcon: Icons.fingerprint_outlined,
                onTap: () => _onTap(context, 0),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxItem({
    required BuildContext context,
    required bool isSelected,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              size: 24,
              shadows: isSelected
                  ? [
                      Shadow(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCircularItem({
    required BuildContext context,
    required bool isSelected,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBackgroundElement : AppColors.lightBackgroundElement),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isSelected ? activeIcon : inactiveIcon,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkText : AppColors.lightText),
            size: 32,
            shadows: isSelected
                ? [
                    const Shadow(
                      color: Colors.white,
                      blurRadius: 10,
                    ),
                  ]
                : (isDark
                    ? null
                    : [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ]),
          ),
        ),
      ),
    );
  }
}
