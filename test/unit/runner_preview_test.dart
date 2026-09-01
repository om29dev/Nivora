import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/app/theme/app_colors.dart';
import 'package:nivora/app/theme/app_theme.dart';
import 'package:nivora/core/models/project.dart';
import 'package:nivora/core/providers/app_providers.dart';
import 'package:nivora/features/runner_preview/runner_preview_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProject = Project(
    id: 'test-app',
    name: 'Weather Demo',
    path: '/path/to/test-app',
    remoteUrl: 'https://github.com/user/weather-demo',
    lastOpened: DateTime.now(),
    runCommand: 'npm run dev',
  );

  Widget createTestWidget({required ThemeData theme, Project? project}) {
    return ProviderScope(
      overrides: [
        activeProjectProvider.overrideWith((ref) => project ?? testProject),
      ],
      child: MaterialApp(
        theme: theme,
        home: const RunnerPreviewScreen(projectId: 'test-app'),
      ),
    );
  }

  group('RunnerPreviewScreen Theme & Dynamic Styling Tests', () {
    testWidgets('Adapts to Dark Theme properly', (tester) async {
      await tester.pumpWidget(createTestWidget(theme: AppTheme.darkTheme));
      await tester.pumpAndSettle();

      // Verify Screen Title & Main Elements
      expect(find.text('Run & Live Preview'), findsOneWidget);
      expect(find.text('npm run dev'), findsOneWidget);
      expect(find.text('Live Website'), findsOneWidget);
      expect(find.text('Server Logs'), findsOneWidget);

      // Verify Scaffold background matches darkBackground
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.darkBackground));

      // Verify WeatherPulse rendered in dark mode
      expect(find.text('WeatherPulse'), findsOneWidget);
      expect(find.byIcon(Icons.nightlight_round), findsOneWidget);

      // Verify theme toggle button works
      await tester.tap(find.byIcon(Icons.nightlight_round));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.wb_sunny_rounded), findsWidgets);
    });

    testWidgets('Adapts to Light Theme properly', (tester) async {
      await tester.pumpWidget(createTestWidget(theme: AppTheme.lightTheme));
      await tester.pumpAndSettle();

      // Verify Screen Title & Main Elements
      expect(find.text('Run & Live Preview'), findsOneWidget);
      expect(find.text('npm run dev'), findsOneWidget);

      // Verify Scaffold background matches lightBackground
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.lightBackground));

      // In light theme, site defaults to sun icon
      expect(find.byIcon(Icons.wb_sunny_rounded), findsWidgets);
    });

    testWidgets('Switching to Server Logs tab renders themed logs view', (tester) async {
      await tester.pumpWidget(createTestWidget(theme: AppTheme.darkTheme));
      await tester.pumpAndSettle();

      // Tap 'Server Logs'
      await tester.tap(find.text('Server Logs'));
      await tester.pumpAndSettle();

      // Verify empty state logs message
      expect(find.textContaining('No server logs yet'), findsOneWidget);
    });
  });
}
