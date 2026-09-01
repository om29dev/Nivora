import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivora/app/theme/app_theme.dart';
import 'package:nivora/core/models/project.dart';
import 'package:nivora/core/providers/app_providers.dart';
import 'package:nivora/core/widgets/nivora_bottom_nav_bar.dart';
import 'package:nivora/core/widgets/nivora_floating_ai_button.dart';
import 'package:nivora/features/more/more_screen.dart';
import 'package:nivora/features/projects/projects_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Nivora Bottom Navigation & AI Button Tests', () {
    testWidgets('NivoraBottomNavBar renders 4 tabs and center AI button', (tester) async {
      int selectedIndex = 0;
      bool aiTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: NivoraBottomNavBar(
              currentIndex: selectedIndex,
              onItemSelected: (idx) => selectedIndex = idx,
              onAITapped: () => aiTapped = true,
            ),
          ),
        ),
      );

      // Verify all 4 tab labels exist
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Verify AI button exists
      expect(find.byType(NivoraFloatingAIButton), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      // Test tapping tab 1 (Projects)
      await tester.tap(find.text('Projects'));
      await tester.pump();
      expect(selectedIndex, equals(1));

      // Test tapping tab 2 (Terminal)
      await tester.tap(find.text('Terminal'));
      await tester.pump();
      expect(selectedIndex, equals(2));

      // Test tapping AI button
      await tester.tap(find.byType(NivoraFloatingAIButton));
      await tester.pump();
      expect(aiTapped, isTrue);
    });

    testWidgets('NivoraFloatingAIButton has semantic label and scales on press', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NivoraFloatingAIButton(
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Open AI Agent'), findsOneWidget);

      // Tap down triggers animation
      final gesture = await tester.startGesture(tester.getCenter(find.byType(NivoraFloatingAIButton)));
      await tester.pump(const Duration(milliseconds: 60));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('NivoraBottomNavBar renders seamlessly in Light Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: NivoraBottomNavBar(
              currentIndex: 0,
              onItemSelected: (_) {},
              onAITapped: () {},
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byType(NivoraFloatingAIButton), findsOneWidget);
    });

    testWidgets('ProjectsScreen renders project search and empty or project list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProjectsScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Repositories'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('MoreScreen renders developer workstation tools', (tester) async {
      final container = ProviderContainer(
        overrides: [
          activeProjectProvider.overrideWith((ref) => Project(
                id: 'test-repo',
                name: 'test-repo',
                path: '/dummy/test',
                remoteUrl: 'https://github.com/user/test-repo',
                currentBranch: 'main',
                language: 'TypeScript',
                runtime: 'Node.js',
                lastOpened: DateTime.now(),
              )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MoreScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('More & Tools'), findsOneWidget);
      expect(find.text('Runner & Live Preview'), findsOneWidget);
      expect(find.text('Git Source Control'), findsOneWidget);
      expect(find.text('Camera Error Debugger'), findsOneWidget);
      expect(find.text('Voice Coding Studio'), findsOneWidget);
      expect(find.text('Office Kit Wireless Companion'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      expect(find.text('Global Settings'), findsOneWidget);
    });
  });
}
