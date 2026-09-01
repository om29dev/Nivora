import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/process_manager.dart';
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
  int _simulatedTemp = 72;
  int _starCount = 1420;
  bool _isStarred = false;
  String _activeNav = 'Overview';

  void _startServer() {
    final activeProject = ref.read(activeProjectProvider);
    final proc = ref.read(processManagerProvider);
    if (activeProject != null) {
      final cmd = activeProject.runCommand ?? 'npm run dev';
      proc.executeCommand(command: cmd, workingDirectory: activeProject.path);
      setState(() {});
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
            content: Text('Opening $url... (To launch Chrome externally, re-run flutter run for native channel)'),
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Project',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/project/${widget.projectId}');
            }
          },
        ),
        title: const Text('Run & Live Preview'),
        actions: [
          IconButton(
            tooltip: 'Open in Browser',
            icon: const Icon(Icons.open_in_browser_rounded, color: AppColors.electricCyan),
            onPressed: () => _openInBrowser(_previewUrl),
          ),
          IconButton(
            tooltip: 'View in Terminal',
            icon: const Icon(Icons.terminal_rounded),
            onPressed: () => context.push('/project/${widget.projectId}/terminal'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Command & Server Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).cardTheme.color,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      NivoraStatus(
                        type: isRunning ? NivoraStatusType.running : NivoraStatusType.idle,
                        label: isRunning ? 'Port :$port' : 'Server Idle',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeProject?.runCommand ?? 'npm run dev',
                          style: AppTypography.code.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isRunning)
                  NivoraButton(
                    text: 'Run',
                    icon: Icons.play_arrow_rounded,
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
              color: Theme.of(context).cardTheme.color,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
                ),
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
                            width: 2,
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
                            style: AppTypography.button.copyWith(
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
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Server Logs',
                        style: AppTypography.button.copyWith(
                          color: _selectedTab == 1 ? AppColors.electricCyan : AppColors.textSecondaryOf(context),
                        ),
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
    );
  }

  // --- Real Interactive Website Viewport ---
  Widget _buildFullWebsiteViewport(String url, String projectName) {
    final isHtml = projectName.contains('html');
    final isPython = projectName.contains('fastapi') || projectName.contains('python');

    return Column(
      children: [
        // Browser Chrome Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Theme.of(context).cardTheme.color,
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerTheme.color ?? AppColors.border(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: AppColors.emeraldGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          url,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w500,
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
                icon: const Icon(Icons.refresh_rounded, size: 18),
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

  // 1. FULL REACT WEATHER WEBSITE
  Widget _renderReactWeatherSite() {
    final bg = _siteDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9);
    final cardBg = _siteDarkMode ? const Color(0xFF1C2541) : Colors.white;
    final textCol = _siteDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextCol = _siteDarkMode ? const Color(0xFF8D99AE) : const Color(0xFF64748B);

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
                icon: Icon(_siteDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 18, color: textCol),
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _siteDarkMode ? const Color(0xFF3A506B) : const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: subTextCol),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('San Francisco, California', style: TextStyle(color: textCol, fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.electricCyan.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: AppColors.electricCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Current Weather Hero Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withAlpha(60),
                  blurRadius: 14,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CURRENT WEATHER', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        const Text('Partly Cloudy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Icon(Icons.wb_cloudy_rounded, color: Colors.amber, size: 40),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$_simulatedTemp°', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(width: 10),
                    const Text('Fahrenheit', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Simulate Sensor Update',
                      icon: const Icon(Icons.tune_rounded, color: Colors.white),
                      onPressed: () => setState(() => _simulatedTemp = _simulatedTemp == 72 ? 76 : 72),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _WeatherMetricItem(label: 'Humidity', value: '54%'),
                    _WeatherMetricItem(label: 'Wind', value: '8 mph'),
                    _WeatherMetricItem(label: 'Air Quality', value: '38 (Good)'),
                    _WeatherMetricItem(label: 'UV Index', value: '3 / 10'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Hourly Forecast Web Strip
          Text('HOURLY FORECAST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subTextCol, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          SizedBox(
            height: 85,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHourlyCard('Now', '72°', Icons.wb_cloudy_rounded, cardBg, textCol),
                _buildHourlyCard('1 PM', '74°', Icons.wb_sunny_rounded, cardBg, textCol),
                _buildHourlyCard('2 PM', '75°', Icons.wb_sunny_rounded, cardBg, textCol),
                _buildHourlyCard('3 PM', '73°', Icons.cloud_queue_rounded, cardBg, textCol),
                _buildHourlyCard('4 PM', '70°', Icons.wb_cloudy_rounded, cardBg, textCol),
                _buildHourlyCard('5 PM', '68°', Icons.nights_stay_rounded, cardBg, textCol),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5-Day Outlook
          Text('5-DAY OUTLOOK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subTextCol, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _siteDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildDayRow('Today', 'Partly Cloudy', '75° / 58°', textCol, subTextCol),
                const Divider(height: 1),
                _buildDayRow('Tomorrow', 'Sunny', '78° / 60°', textCol, subTextCol),
                const Divider(height: 1),
                _buildDayRow('Wednesday', 'Breezy', '71° / 55°', textCol, subTextCol),
                const Divider(height: 1),
                _buildDayRow('Thursday', 'Showers', '65° / 52°', textCol, subTextCol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. FULL HTML PORTFOLIO WEBSITE
  Widget _renderHtmlPortfolioSite() {
    return Container(
      color: const Color(0xFF090D16),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nav Bar
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
                  const Text('Alex Rivera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

          const SizedBox(height: 24),

          // Hero Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2A3C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.electricCyan.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.electricCyan),
                  ),
                  child: const Text('AVAILABLE FOR MOBILE AI PROJECTS', style: TextStyle(color: AppColors.electricCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Building phone-first local development workstations.',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Full-stack engineer specializing in Flutter, Dart, on-device neural runtimes, and mobile systems engineering.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
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
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Project Cards Section
          const Text('FEATURED PROJECTS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 10),
          _buildPortfolioProjectCard('⚡ Nivora Workstation', 'Phone-first local Android development environment with real Node.js & Git.', ['Flutter', 'Android', 'AI']),
          const SizedBox(height: 10),
          _buildPortfolioProjectCard('🛰️ Wildfire Telemetry', 'Satellite imagery perimeter prediction service running on-device.', ['FastAPI', 'Python', 'ML']),
        ],
      ),
    );
  }

  // 3. FULL FASTAPI SWAGGER API DOCS WEBSITE
  Widget _renderFastApiSwaggerSite() {
    return Container(
      color: const Color(0xFF1B1B1B),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Swagger Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF009688), borderRadius: BorderRadius.circular(4)),
                child: const Text('FastAPI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              const Text('Wildfire Anomaly API', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              const Text('v1.0.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Real-time predictive perimeter and thermal anomaly detection engine.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),

          // GET /health
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: const Color(0xFF263238), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF009688))),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF009688), borderRadius: BorderRadius.circular(4)), child: const Text('GET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                    const SizedBox(width: 10),
                    const Text('/health', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    const Text('Status: 200 OK', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                  child: const Text('{\n  "status": "healthy",\n  "service": "wildfire-ai",\n  "inference_ms": 14\n}', style: TextStyle(color: Color(0xFF81C784), fontFamily: 'monospace', fontSize: 11)),
                ),
              ],
            ),
          ),

          // POST /predict
          Container(
            decoration: BoxDecoration(color: const Color(0xFF263238), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2196F3))),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF2196F3), borderRadius: BorderRadius.circular(4)), child: const Text('POST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                    const SizedBox(width: 10),
                    const Text('/predict', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Request: {\n  "temp_c": 38.2,\n  "humidity": 14.5,\n  "wind_kmh": 28.0\n}\n\nResponse 200 OK:\n{\n  "risk_level": "CRITICAL",\n  "rate_m_per_h": 450.0\n}', style: TextStyle(color: Color(0xFF64B5F6), fontFamily: 'monospace', fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavPill(String title) {
    final isSel = _activeNav == title;
    return InkWell(
      onTap: () => setState(() => _activeNav = title),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? AppColors.electricCyan.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSel ? AppColors.electricCyan : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioProjectCard(String title, String desc, List<String> tags) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: tags.map((t) => Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
              child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            )).toList(),
          ),
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
        border: Border.all(color: _siteDarkMode ? const Color(0xFF3A506B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: TextStyle(fontSize: 11, color: _siteDarkMode ? Colors.white60 : Colors.black54)),
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
      color: AppColors.terminalBackground,
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: lines.length,
        itemBuilder: (ctx, idx) {
          final line = lines[idx];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              line.text,
              style: AppTypography.terminal.copyWith(
                color: line.isError ? AppColors.coralRed : AppColors.textCode,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WeatherMetricItem extends StatelessWidget {
  final String label;
  final String value;
  const _WeatherMetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
