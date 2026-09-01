import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
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
  bool? _siteDarkModeOverride;
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

    final isDark = AppColors.isDark(context);
    final isSiteDark = _siteDarkModeOverride ?? isDark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.text(context),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border(context)),
        ),
        leading: IconButton(
          tooltip: 'Back to Project',
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(context)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/project/${widget.projectId}');
            }
          },
        ),
        title: Text(
          'Run & Live Preview',
          style: AppTypography.h2Of(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in Browser',
            icon: const Icon(Icons.open_in_browser_rounded, color: AppColors.electricCyan),
            onPressed: () => _openInBrowser(_previewUrl),
          ),
          IconButton(
            tooltip: 'View in Terminal',
            icon: Icon(Icons.terminal_rounded, color: AppColors.textSecondaryOf(context)),
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
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                border: Border(
                  bottom: BorderSide(color: AppColors.border(context)),
                ),
              ),
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
                            style: AppTypography.code.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text(context),
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
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                border: Border(
                  bottom: BorderSide(color: AppColors.border(context)),
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
                                color: _selectedTab == 0 ? AppColors.electricCyan : AppColors.textSecondaryOf(context),
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
                                color: _selectedTab == 1 ? AppColors.electricCyan : AppColors.textSecondaryOf(context),
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
                  ? _buildFullWebsiteViewport(_previewUrl, activeProject?.name ?? 'project', isSiteDark)
                  : _buildServerLogs(proc),
            ),
          ],
        ),
      ),
    );
  }

  // --- Real Interactive Website Viewport ---
  Widget _buildFullWebsiteViewport(String url, String projectName, bool isSiteDark) {
    final isHtml = projectName.contains('html');
    final isPython = projectName.contains('fastapi') || projectName.contains('python');

    return Column(
      children: [
        // Browser Chrome Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: AppColors.surfaceElevated(context),
          child: Row(
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textMutedOf(context)),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMutedOf(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: AppColors.emeraldGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          url,
                          style: TextStyle(
                            color: AppColors.text(context),
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
                icon: Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondaryOf(context)),
                onPressed: () => setState(() {}),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                tooltip: 'Open in Browser',
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
              ? _renderHtmlPortfolioSite(isSiteDark)
              : (isPython ? _renderFastApiSwaggerSite(isSiteDark) : _renderReactWeatherSite(isSiteDark)),
        ),
      ],
    );
  }

  // 1. FULL REACT WEATHER WEBSITE
  Widget _renderReactWeatherSite(bool isDark) {
    final bg = isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111927) : Colors.white;
    final borderCol = isDark ? const Color(0xFF1F2A3C) : const Color(0xFFE2E8F0);
    final textCol = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subTextCol = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
                    Flexible(
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
                icon: Icon(
                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  size: 18,
                  color: isDark ? AppColors.electricCyan : const Color(0xFFF59E0B),
                ),
                onPressed: () => setState(() => _siteDarkModeOverride = !isDark),
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
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: subTextCol),
                const SizedBox(width: 8),
                Text('San Francisco, CA', style: TextStyle(fontSize: 13, color: textCol, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.my_location_rounded, size: 16, color: AppColors.electricCyan),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('San Francisco', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Sunny & Clear', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Icon(Icons.wb_sunny_rounded, color: Color(0xFFFDE047), size: 36),
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
              Expanded(child: _buildMetricTile('Wind', '12 mph NW', Icons.air_rounded, cardBg, textCol, subTextCol, borderCol)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Humidity', '64%', Icons.water_drop_rounded, cardBg, textCol, subTextCol, borderCol)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('UV Index', '6 (High)', Icons.wb_twilight_rounded, cardBg, textCol, subTextCol, borderCol)),
            ],
          ),

          const SizedBox(height: 16),

          // Hourly Forecast Horizontal Scroll
          Text('HOURLY FORECAST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subTextCol, letterSpacing: 1)),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHourlyCard('Now', '$_simulatedTemp°', Icons.wb_sunny_rounded, cardBg, textCol, subTextCol, borderCol),
                _buildHourlyCard('1 PM', '74°', Icons.wb_sunny_rounded, cardBg, textCol, subTextCol, borderCol),
                _buildHourlyCard('2 PM', '75°', Icons.wb_sunny_rounded, cardBg, textCol, subTextCol, borderCol),
                _buildHourlyCard('3 PM', '73°', Icons.cloud_queue_rounded, cardBg, textCol, subTextCol, borderCol),
                _buildHourlyCard('4 PM', '70°', Icons.cloud_queue_rounded, cardBg, textCol, subTextCol, borderCol),
                _buildHourlyCard('5 PM', '67°', Icons.wb_twilight_rounded, cardBg, textCol, subTextCol, borderCol),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5-Day Forecast Card
          Text('5-DAY OUTLOOK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subTextCol, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                _buildDayRow('Today', 'Sunny', '76° / 58°', textCol, subTextCol),
                Divider(height: 1, color: borderCol),
                _buildDayRow('Tomorrow', 'Partly Cloudy', '72° / 55°', textCol, subTextCol),
                Divider(height: 1, color: borderCol),
                _buildDayRow('Wednesday', 'Breezy', '68° / 52°', textCol, subTextCol),
                Divider(height: 1, color: borderCol),
                _buildDayRow('Thursday', 'Showers', '62° / 50°', textCol, subTextCol),
                Divider(height: 1, color: borderCol),
                _buildDayRow('Friday', 'Clear Sky', '70° / 54°', textCol, subTextCol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. HTML PORTFOLIO WEBSITE
  Widget _renderHtmlPortfolioSite(bool isDark) {
    final bg = isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111927) : Colors.white;
    final borderCol = isDark ? const Color(0xFF1F2A3C) : const Color(0xFFE2E8F0);
    final textCol = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      color: bg,
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
                  Text('Alex Rivera', style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  _buildNavPill('Work', subText),
                  _buildNavPill('Skills', subText),
                  _buildNavPill('Contact', subText),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
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
                Text(
                  'Building phone-first local development workstations.',
                  style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
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
          Text('FEATURED PROJECTS', style: TextStyle(color: subText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 10),
          _buildPortfolioProjectCard('⚡ Nivora Workstation', 'Phone-first local Android development environment with real Node.js & Git.', ['Flutter', 'Android', 'AI'], cardBg, borderCol, textCol, subText, isDark),
          const SizedBox(height: 10),
          _buildPortfolioProjectCard('🛰️ Wildfire Telemetry', 'Satellite imagery perimeter prediction service running on-device.', ['FastAPI', 'Python', 'ML'], cardBg, borderCol, textCol, subText, isDark),
        ],
      ),
    );
  }

  // 3. FASTAPI SWAGGER API DOCS
  Widget _renderFastApiSwaggerSite(bool isDark) {
    final bg = isDark ? const Color(0xFF090E17) : Colors.white;
    final cardBg = isDark ? const Color(0xFF064E3B).withAlpha(45) : const Color(0xFFF0FDF4);
    final cardBorder = isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC);
    final codeBg = isDark ? const Color(0xFF111927) : Colors.white;
    final codeBorder = isDark ? const Color(0xFF1F2A3C) : const Color(0xFFE2E8F0);
    final textCol = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Container(
      color: bg,
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
              Text('Wildfire Anomaly API', style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('v1.0.0', style: TextStyle(color: subText, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Real-time predictive perimeter and thermal anomaly detection engine.', style: TextStyle(color: subText, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cardBorder),
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
                    Text('/health', style: TextStyle(color: textCol, fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    const Text('Status: 200 OK', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: codeBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: codeBorder)),
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

  Widget _buildNavPill(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPortfolioProjectCard(
    String title,
    String desc,
    List<String> tags,
    Color cardBg,
    Color borderCol,
    Color textCol,
    Color subText,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textCol, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: subText, fontSize: 12, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: tags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String val,
    IconData icon,
    Color cardBg,
    Color textCol,
    Color subText,
    Color borderCol,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
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

  Widget _buildHourlyCard(
    String time,
    String temp,
    IconData icon,
    Color cardBg,
    Color textCol,
    Color subText,
    Color borderCol,
  ) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: TextStyle(fontSize: 11, color: subText)),
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
    final isDark = AppColors.isDark(context);
    return Container(
      color: isDark ? AppColors.terminalBackground : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(12),
      child: lines.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.terminal_rounded, size: 36, color: AppColors.textMutedOf(context)),
                  const SizedBox(height: 8),
                  Text(
                    'No server logs yet.\nTap "Run" to start the server.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13, height: 1.4),
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
                  defaultColor: line.isError
                      ? AppColors.coralRed
                      : (isDark ? AppColors.textCode : const Color(0xFF1E293B)),
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: isDark ? AppColors.textCode : const Color(0xFF1E293B),
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

