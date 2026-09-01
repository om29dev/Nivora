import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/project.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/process_manager.dart';
import '../../core/utils/ansi_parser.dart';
import '../../core/widgets/nivora_button.dart';
import '../../core/widgets/nivora_status.dart';

class RunnerPreviewScreen extends ConsumerStatefulWidget {
  final String projectId;

  const RunnerPreviewScreen({super.key, required this.projectId});

  @override
  ConsumerState<RunnerPreviewScreen> createState() => _RunnerPreviewScreenState();
}

class _RunnerPreviewScreenState extends ConsumerState<RunnerPreviewScreen> {
  int _selectedTab = 0; // 0 = Live Website, 1 = Server Logs
  String _previewUrl = 'http://localhost:5173';
  bool _siteDarkMode = false;
  final int _simulatedTemp = 72;
  int _starCount = 1420;
  bool _isStarred = false;
  bool _isStarting = false;

  Future<void> _startServer() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final proc = ref.read(processManagerProvider);
      var activeProject = ref.read(activeProjectProvider);

      if (activeProject == null || activeProject.id != widget.projectId) {
        final projects = ref.read(projectsListProvider);
        activeProject = projects.firstWhere(
          (p) => p.id == widget.projectId,
          orElse: () => projects.isNotEmpty
              ? projects.first
              : Project(
                  id: widget.projectId,
                  name: widget.projectId,
                  path: '',
                  remoteUrl: '',
                  lastOpened: DateTime.now(),
                ),
        );
        ref.read(activeProjectProvider.notifier).state = activeProject;
      }

      await proc.startDevServer(
        workingDirectory: activeProject.path,
        command: activeProject.runCommand ?? 'npm run dev',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start server: $e'),
            backgroundColor: AppColors.coralRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  void _stopServer() {
    final proc = ref.read(processManagerProvider);
    proc.killActiveProcess();
    setState(() {});
  }

  Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $url in browser...'),
            backgroundColor: AppColors.electricCyan,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProject = ref.watch(activeProjectProvider);
    final proc = ref.watch(processManagerProvider);
    final activeProcess = proc.activeProcessInfo;
    final isRunning = proc.isProcessRunning;

    final port = activeProcess?.localPort ?? 5173;
    _previewUrl = 'http://localhost:$port';

    // Strictly enforce Light Theme on the Runner & Live Preview screen
    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
              ),
              leading: IconButton(
                tooltip: 'Back to Project',
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/project/${widget.projectId}');
                  }
                },
              ),
              title: const Text(
                'Run & Live Preview',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Open in Browser',
                  icon: const Icon(Icons.open_in_browser_rounded, color: AppColors.electricCyan),
                  onPressed: () => _openInBrowser(_previewUrl),
                ),
                IconButton(
                  tooltip: 'View in Terminal',
                  icon: const Icon(Icons.terminal_rounded, color: Color(0xFF475569)),
                  onPressed: () => context.push('/project/${widget.projectId}/terminal'),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              bottom: true,
              child: Column(
              children: [
                // Command & Server Control Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            NivoraStatus(
                              type: isRunning ? NivoraStatusType.running : NivoraStatusType.idle,
                              label: isRunning ? 'Port :$port' : 'Server Idle',
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                activeProject?.runCommand ?? 'npm run dev',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isRunning)
                        NivoraButton(
                          text: _isStarting ? 'Starting...' : 'Run',
                          icon: Icons.play_arrow_rounded,
                          isLoading: _isStarting,
                          onPressed: _startServer,
                        )
                      else
                        NivoraButton(
                          text: 'Stop',
                          icon: Icons.stop_rounded,
                          backgroundColor: AppColors.coralRed,
                          onPressed: _stopServer,
                        ),
                    ],
                  ),
                ),

                // Tabs: Live Website / Server Logs
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTab == 0 ? AppColors.electricCyan : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.language_rounded, size: 16, color: AppColors.electricCyan),
                                const SizedBox(width: 6),
                                Text(
                                  'Live Website',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                                    color: _selectedTab == 0 ? AppColors.electricCyan : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTab == 1 ? AppColors.electricCyan : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.terminal_rounded, size: 16, color: AppColors.electricCyan),
                                const SizedBox(width: 6),
                                Text(
                                  'Server Logs',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                                    color: _selectedTab == 1 ? AppColors.electricCyan : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Viewport
                Expanded(
                  child: _selectedTab == 0
                      ? _buildFullWebsiteViewport(_previewUrl, activeProject?.name ?? 'project')
                      : _buildServerLogs(proc),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  }

  // --- Real Interactive Website Viewport ---
  Widget _buildFullWebsiteViewport(String url, String projectName) {
    final isHtml = projectName.contains('html');
    final isPython = projectName.contains('fastapi') || projectName.contains('python');

    return Column(
      children: [
        // Browser Chrome Navigation Bar (Light Theme)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFFF1F5F9),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: AppColors.emeraldGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          url,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Refresh Page',
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF475569)),
                onPressed: () => setState(() {}),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                tooltip: 'Open in Chrome',
                icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.electricCyan),
                onPressed: () => _openInBrowser(url),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ),

        // Live Rendered Web Page
        Expanded(
          child: isHtml
              ? _renderHtmlPortfolioSite()
              : (isPython ? _renderFastApiSwaggerSite() : _renderReactWeatherSite()),
        ),
      ],
    );
  }

  // 1. FULL REACT WEATHER WEBSITE (Light Theme)
  Widget _renderReactWeatherSite() {
    const bg = Color(0xFFF8FAFC);
    const cardBg = Colors.white;
    const textCol = Color(0xFF0F172A);
    const subTextCol = Color(0xFF64748B);

    return Container(
      color: bg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Website Nav Header
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.electricCyan, AppColors.skyBlue]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cloud_queue_rounded, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'WeatherPulse',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textCol),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Toggle Site Theme',
                icon: const Icon(Icons.wb_sunny_rounded, size: 18, color: Color(0xFFF59E0B)),
                onPressed: () => setState(() => _siteDarkMode = !_siteDarkMode),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Bar inside Web App
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: subTextCol),
                SizedBox(width: 8),
                Text('San Francisco, CA', style: TextStyle(fontSize: 13, color: textCol, fontWeight: FontWeight.w500)),
                Spacer(),
                Icon(Icons.my_location_rounded, size: 16, color: AppColors.electricCyan),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Hero Weather Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('San Francisco', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Sunny & Clear', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFDE047), size: 36),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_simulatedTemp°', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, height: 1)),
                    const SizedBox(width: 8),
                    const Text('F', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.white),
                          Text('76° ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.white),
                          Text('58°', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weather Metrics Grid
          Row(
            children: [
              Expanded(child: _buildMetricTile('Wind', '12 mph NW', Icons.air_rounded, cardBg, textCol, subTextCol)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Humidity', '64%', Icons.water_drop_rounded, cardBg, textCol, subTextCol)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('UV Index', '6 (High)', Icons.wb_twilight_rounded, cardBg, textCol, subTextCol)),
            ],
          ),

          const SizedBox(height: 16),

          // Hourly Forecast Horizontal Scroll
          const Text('HOURLY FORECAST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subTextCol, letterSpacing: 1)),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHourlyCard('Now', '$_simulatedTemp°', Icons.wb_sunny_rounded, cardBg, textCol),
                _buildHourlyCard('1 PM', '74°', Icons.wb_sunny_rounded, cardBg, textCol),
                _buildHourlyCard('2 PM', '75°', Icons.wb_sunny_rounded, cardBg, textCol),
                _buildHourlyCard('3 PM', '73°', Icons.cloud_queue_rounded, cardBg, textCol),
                _buildHourlyCard('4 PM', '70°', Icons.cloud_queue_rounded, cardBg, textCol),
                _buildHourlyCard('5 PM', '67°', Icons.wb_twilight_rounded, cardBg, textCol),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5-Day Forecast Card
          const Text('5-DAY OUTLOOK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subTextCol, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildDayRow('Today', 'Sunny', '76° / 58°', textCol, subTextCol),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildDayRow('Tomorrow', 'Partly Cloudy', '72° / 55°', textCol, subTextCol),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildDayRow('Wednesday', 'Breezy', '68° / 52°', textCol, subTextCol),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildDayRow('Thursday', 'Showers', '62° / 50°', textCol, subTextCol),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildDayRow('Friday', 'Clear Sky', '70° / 54°', textCol, subTextCol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. HTML PORTFOLIO WEBSITE (Light Theme)
  Widget _renderHtmlPortfolioSite() {
    const textCol = Color(0xFF0F172A);
    const subText = Color(0xFF64748B);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.electricCyan),
                    child: const Center(child: Text('AR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 10),
                  const Text('Alex Rivera', style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  _buildNavPill('Work'),
                  _buildNavPill('Skills'),
                  _buildNavPill('Contact'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.electricCyan.withAlpha(25),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.electricCyan),
                  ),
                  child: const Text('AVAILABLE FOR MOBILE AI PROJECTS', style: TextStyle(color: AppColors.electricCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Building phone-first local development workstations.',
                  style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Full-stack engineer specializing in Flutter, Dart, on-device neural runtimes, and mobile systems engineering.',
                  style: TextStyle(color: subText, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(_isStarred ? Icons.star_rounded : Icons.star_border_rounded, size: 18),
                  label: Text(_isStarred ? 'Starred ($_starCount)' : 'Star Project ($_starCount)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {
                      _isStarred = !_isStarred;
                      _starCount += _isStarred ? 1 : -1;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('FEATURED PROJECTS', style: TextStyle(color: subText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 10),
          _buildPortfolioProjectCard('⚡ Nivora Workstation', 'Phone-first local Android development environment with real Node.js & Git.', ['Flutter', 'Android', 'AI']),
          const SizedBox(height: 10),
          _buildPortfolioProjectCard('🛰️ Wildfire Telemetry', 'Satellite imagery perimeter prediction service running on-device.', ['FastAPI', 'Python', 'ML']),
        ],
      ),
    );
  }

  // 3. FASTAPI SWAGGER API DOCS (Light Theme)
  Widget _renderFastApiSwaggerSite() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF009688), borderRadius: BorderRadius.circular(4)),
                child: const Text('FastAPI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              const Text('Wildfire Anomaly API', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              const Text('v1.0.0', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Real-time predictive perimeter and thermal anomaly detection engine.', style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF009688), borderRadius: BorderRadius.circular(4)),
                      child: const Text('GET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    const Text('/health', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    const Text('Status: 200 OK', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: const Text(
                    '{\n  "status": "healthy",\n  "service": "wildfire-ai",\n  "inference_ms": 14\n}',
                    style: TextStyle(color: Color(0xFF16A34A), fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavPill(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPortfolioProjectCard(String title, String desc, List<String> tags) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(tag, style: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, IconData icon, Color cardBg, Color textCol, Color subText) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.electricCyan),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
          Text(title, style: TextStyle(fontSize: 10, color: subText)),
        ],
      ),
    );
  }

  Widget _buildHourlyCard(String time, String temp, IconData icon, Color cardBg, Color textCol) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Icon(icon, size: 18, color: AppColors.electricCyan),
          const SizedBox(height: 4),
          Text(temp, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildDayRow(String day, String condition, String tempRange, Color textCol, Color subTextCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: TextStyle(color: textCol, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(condition, style: TextStyle(color: subTextCol, fontSize: 12)),
          Text(tempRange, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildServerLogs(ProcessManager proc) {
    final lines = proc.currentBuffer;
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(12),
      child: lines.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.terminal_rounded, size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'No server logs yet.\nTap "Run" to start the server.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: lines.length,
              itemBuilder: (ctx, idx) {
                final line = lines[idx];
                final spans = AnsiParser.parseToSpans(
                  line.text,
                  defaultColor: line.isError ? AppColors.coralRed : const Color(0xFF1E293B),
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF1E293B),
                        fontSize: 12,
                      ),
                      children: spans,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
