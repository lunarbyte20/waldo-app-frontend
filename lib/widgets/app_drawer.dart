import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/clock/clock_screen.dart';
import '../screens/dtr/dtr_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../services/api_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute; // 'clock' | 'attendance' | 'dtr'

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of WALDO Guard App?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await ApiService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateTo(BuildContext context, Widget targetScreen) {
    Navigator.pop(context); // Close drawer
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProviderScope.of(context);
    const navyBackground = Color(0xFF1E293B);
    const navyHeader = Color(0xFF0F172A);
    const activePillColor = Color(0xFF2563EB);
    const textMuted = Color(0xFF94A3B8);

    return Drawer(
      child: Container(
        color: navyBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Logo & Branding
            Container(
              color: navyHeader,
              padding: const EdgeInsets.only(top: 48, bottom: 20, left: 20, right: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      AppConstants.logoAssetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WALDO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'SECURITY AGENCY INC.',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF334155), height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                children: [
                  // Category Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'MY WORK',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 1. Clock Station
                  _buildNavItem(
                    context: context,
                    icon: Icons.access_time_rounded,
                    label: 'Clock Station',
                    isSelected: currentRoute == 'clock',
                    onTap: () {
                      if (currentRoute != 'clock') {
                        _navigateTo(context, const ClockScreen());
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    activeColor: activePillColor,
                    mutedColor: textMuted,
                  ),

                  const SizedBox(height: 8),

                  // 2. My Attendance
                  _buildNavItem(
                    context: context,
                    icon: Icons.assignment_outlined,
                    label: 'My Attendance',
                    isSelected: currentRoute == 'attendance',
                    onTap: () {
                      if (currentRoute != 'attendance') {
                        _navigateTo(context, const HistoryScreen());
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    activeColor: activePillColor,
                    mutedColor: textMuted,
                  ),

                  const SizedBox(height: 8),

                  // 3. My DTR
                  _buildNavItem(
                    context: context,
                    icon: Icons.article_outlined,
                    label: 'My DTR',
                    isSelected: currentRoute == 'dtr',
                    onTap: () {
                      if (currentRoute != 'dtr') {
                        _navigateTo(context, const DtrScreen());
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    activeColor: activePillColor,
                    mutedColor: textMuted,
                  ),

                  const SizedBox(height: 8),

                  // 4. My Profile
                  _buildNavItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    isSelected: currentRoute == 'profile',
                    onTap: () {
                      if (currentRoute != 'profile') {
                        _navigateTo(context, const ProfileScreen());
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    activeColor: activePillColor,
                    mutedColor: textMuted,
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF334155), height: 1),

            // Footer: Sign Out
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: _buildNavItem(
                context: context,
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                isSelected: false,
                onTap: () => _handleLogout(context),
                activeColor: activePillColor,
                mutedColor: Colors.red.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required Color mutedColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withAlpha(60) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: activeColor, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : mutedColor,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : mutedColor,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
