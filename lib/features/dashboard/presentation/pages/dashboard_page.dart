import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../widgets/dashboard_home.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;

  final List<String> _menuTitles = [
    'Home',
    'Calendar',
    'Waiting List',
    'Patients',
    'Medical Records',
    'QMRA Tests',
    'Reports',
    'Settings',
  ];

  final List<IconData> _menuIcons = [
    Icons.home_rounded,
    Icons.calendar_month_rounded,
    Icons.hourglass_empty_rounded,
    Icons.people_rounded,
    Icons.folder_rounded,
    Icons.science_rounded,
    Icons.assessment_rounded,
    Icons.settings_rounded,
  ];

  Future<void> _handleLogout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: true,
            backgroundColor: colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.medical_services_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'One Minute\nClinic',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          currentUser?.name.substring(0, 1).toUpperCase() ??
                              'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentUser?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentUser?.displayRole ?? 'Role',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        // width: double.maxFinite,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: List.generate(
              _menuTitles.length,
              (index) => NavigationRailDestination(
                icon: Icon(_menuIcons[index]),
                selectedIcon: Icon(_menuIcons[index]),
                label: Text(_menuTitles[index]),
              ),
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardHome();
      case 1:
        return _buildPlaceholder('Calendar', Icons.calendar_month_rounded);
      case 2:
        return _buildPlaceholder('Waiting List', Icons.hourglass_empty_rounded);
      case 3:
        return _buildPlaceholder('Patients', Icons.people_rounded);
      case 4:
        return _buildPlaceholder('Medical Records', Icons.folder_rounded);
      case 5:
        return _buildPlaceholder('QMRA Tests', Icons.science_rounded);
      case 6:
        return _buildPlaceholder('Reports', Icons.assessment_rounded);
      case 7:
        return _buildPlaceholder('Settings', Icons.settings_rounded);
      default:
        return const DashboardHome();
    }
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
