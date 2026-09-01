import 'package:go_router/go_router.dart';
import '../features/ai_assistant/ai_assistant_screen.dart';
import '../features/ai_setup/ai_setup_screen.dart';
import '../features/camera_debug/camera_debug_screen.dart';
import '../features/clone/clone_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/file_explorer/file_explorer_screen.dart';
import '../features/git/git_screen.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/office_kit/office_kit_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/project_overview/project_overview_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/runner_preview/runner_preview_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/terminal/global_terminal_screen.dart';
import '../features/terminal/terminal_screen.dart';
import '../features/voice/voice_coding_modal.dart';
import 'nivora_nav_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Pre-navigation onboarding routes
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/ai-setup',
      builder: (context, state) => const AISetupScreen(),
    ),
    GoRoute(
      path: '/clone',
      builder: (context, state) {
        final initialUrl = state.extra as String? ?? '';
        return CloneScreen(initialUrl: initialUrl);
      },
    ),

    // Global Bottom Navigation Shell (StatefulShellRoute)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return NivoraNavShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Dashboard (Home)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 1: Projects (Repository Explorer)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/projects',
              builder: (context, state) => const ProjectsScreen(),
            ),
          ],
        ),

        // Tab 2: Terminal (Global Workstation Console)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/terminal',
              builder: (context, state) => const GlobalTerminalScreen(),
            ),
          ],
        ),

        // Tab 3: More (Secondary Tools & Settings Hub)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              builder: (context, state) => const MoreScreen(),
            ),
          ],
        ),
      ],
    ),

    // Project Workspace Deep Routes
    GoRoute(
      path: '/project/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProjectOverviewScreen(projectId: id);
      },
      routes: [
        GoRoute(
          path: 'files',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return FileExplorerScreen(projectId: id);
          },
        ),
        GoRoute(
          path: 'editor',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EditorScreen(projectId: id);
          },
        ),
        GoRoute(
          path: 'ai',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final prompt = state.extra as String?;
            return AIAssistantScreen(projectId: id, initialPrompt: prompt);
          },
        ),
        GoRoute(
          path: 'run',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return RunnerPreviewScreen(projectId: id);
          },
        ),
        GoRoute(
          path: 'terminal',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TerminalScreen(projectId: id);
          },
        ),
        GoRoute(
          path: 'git',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return GitScreen(projectId: id);
          },
        ),
      ],
    ),

    // Standalone Auxiliary Tool Routes
    GoRoute(
      path: '/camera-debug',
      builder: (context, state) => const CameraDebugScreen(),
    ),
    GoRoute(
      path: '/voice-coding',
      builder: (context, state) => const VoiceCodingScreen(),
    ),
    GoRoute(
      path: '/office-kit',
      builder: (context, state) => const OfficeKitScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
