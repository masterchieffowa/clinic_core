// import 'package:clinic_core/core/database/hive/models/hive_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // Initialize Hive
//   await HiveService.init();
//   // Set preferred orientations
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.landscapeLeft,
//     DeviceOrientation.landscapeRight,
//     DeviceOrientation.portraitUp,
//   ]);
//   runApp(const ProviderScope(child: MyApp()));
// }
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'One Minute Clinic',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF009688), // Teal
//           brightness: Brightness.light,
//         ),
//         useMaterial3: true,
//       ),
//       darkTheme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF26A69A), // Lighter Teal
//           brightness: Brightness.dark,
//         ),
//         useMaterial3: true,
//       ),
//       themeMode: ThemeMode.system,
//       home: const TestHomePage(),
//     );
//   }
// }
// class TestHomePage extends StatelessWidget {
//   const TestHomePage({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('One Minute Clinic - Setup Test'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.check_circle_outline,
//                 size: 100,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Setup Successful! ✅',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                       color: Theme.of(context).colorScheme.primary,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Your clinic management system is ready to build!',
//                 style: Theme.of(context).textTheme.bodyLarge,
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 48),
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Next Steps:',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildStepItem('1', 'Run build_runner to generate code'),
//                       _buildStepItem('2', 'Initialize database'),
//                       _buildStepItem('3', 'Create authentication system'),
//                       _buildStepItem('4', 'Build dashboard'),
//                       _buildStepItem('5', 'Add features'),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Ready to start building features!'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//         },
//         icon: const Icon(Icons.play_arrow),
//         label: const Text('Start Building'),
//       ),
//     );
//   }
//   Widget _buildStepItem(String number, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 12,
//             child: Text(number, style: const TextStyle(fontSize: 12)),
//           ),
//           const SizedBox(width: 12),
//           Expanded(child: Text(text)),
//         ],
//       ),
//     );
//   }
// }

import 'package:clinic_core/core/database/local_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart';
import 'core/utils/logger_util.dart';
import 'features/auth/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Logger
  LoggerUtil.init();
  LoggerUtil.info('🚀 Starting One Minute Clinic...');

  try {
    // Initialize Dependency Injection
    await configureDependencies();
    LoggerUtil.info('✅ Dependencies configured');

    // Initialize Local Database (Hive + SQLite)
    await LocalDatabase.init();
    LoggerUtil.info('✅ Local database initialized');

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    LoggerUtil.error('❌ Error during initialization', e, stackTrace);
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One Minute Clinic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688), // Teal
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Dark Blue
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashPage(),
    );
  }
}

// Error App - shown if initialization fails
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 100, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Initialize App',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Please check the console logs for details',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
