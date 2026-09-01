import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/project.dart';
import 'storage_service.dart';

class MockDemoSeeder {
  final StorageService storageService;

  MockDemoSeeder(this.storageService);

  Future<List<Project>> seedDemoProjects() async {
    final projectsDir = await storageService.getProjectsDirectory();

    // 1. Seed React Weather Dashboard
    final reactPath = p.join(projectsDir.path, 'react-weather-dashboard');
    final reactDir = Directory(reactPath);
    if (!await reactDir.exists()) {
      await reactDir.create(recursive: true);
      await _createReactFiles(reactPath);
    }

    final reactProject = Project(
      id: 'demo-react-weather',
      name: 'react-weather-dashboard',
      path: reactPath,
      remoteUrl: 'https://github.com/nivora-dev/react-weather-dashboard',
      currentBranch: 'main',
      language: 'TypeScript',
      runtime: 'Node.js',
      packageManager: 'npm',
      lastOpened: DateTime.now(),
      isClean: false,
      runCommand: 'npm run dev',
      buildCommand: 'npm run build',
      testCommand: 'npm test',
    );
    await storageService.saveProject(reactProject);

    // 2. Seed FastAPI Wildfire AI
    final pythonPath = p.join(projectsDir.path, 'fastapi-wildfire-ai');
    final pythonDir = Directory(pythonPath);
    if (!await pythonDir.exists()) {
      await pythonDir.create(recursive: true);
      await _createPythonFiles(pythonPath);
    }

    final pythonProject = Project(
      id: 'demo-fastapi-wildfire',
      name: 'fastapi-wildfire-ai',
      path: pythonPath,
      remoteUrl: 'https://github.com/nivora-dev/fastapi-wildfire-ai',
      currentBranch: 'main',
      language: 'Python',
      runtime: 'Python 3',
      packageManager: 'pip',
      lastOpened: DateTime.now().subtract(const Duration(hours: 2)),
      isClean: true,
      runCommand: 'uvicorn main:app --reload',
      buildCommand: 'pip install -r requirements.txt',
      testCommand: 'pytest',
    );
    await storageService.saveProject(pythonProject);

    // 3. Seed Short HTML/CSS/JS Demo Project
    final htmlPath = p.join(projectsDir.path, 'html-portfolio-demo');
    final htmlDir = Directory(htmlPath);
    if (!await htmlDir.exists()) {
      await htmlDir.create(recursive: true);
      await _createHtmlFiles(htmlPath);
    }

    final htmlProject = Project(
      id: 'demo-html-portfolio',
      name: 'html-portfolio-demo',
      path: htmlPath,
      remoteUrl: 'https://github.com/nivora-dev/html-portfolio-demo',
      currentBranch: 'main',
      language: 'HTML/CSS/JS',
      runtime: 'Browser / Node.js',
      packageManager: 'npx',
      lastOpened: DateTime.now().subtract(const Duration(minutes: 30)),
      isClean: true,
      runCommand: 'npx serve .',
      buildCommand: 'echo "Static build complete"',
      testCommand: 'echo "Static tests passed"',
    );
    await storageService.saveProject(htmlProject);

    return [reactProject, pythonProject, htmlProject];
  }

  Future<void> _createReactFiles(String root) async {
    // package.json
    await File(p.join(root, 'package.json')).writeAsString('''{
  "name": "react-weather-dashboard",
  "private": true,
  "version": "1.2.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "test": "vitest"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "lucide-react": "^0.395.0"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.4.5",
    "vite": "^5.2.11"
  }
}''');

    // README.md
    await File(p.join(root, 'README.md')).writeAsString('''# React Weather Dashboard
A high-performance weather intelligence workstation dashboard built with React 18, Vite, and TypeScript.

## Purpose
Provides hyper-local meteorological forecasts and atmospheric telemetry for developers and on-call teams.

## Development
Run the local development server:
`npm run dev`

Build for production:
`npm run build`

Run unit tests:
`npm test`

## Architecture
- `src/App.tsx`: Main application entry and reactive layout container
- `src/components/Dashboard.tsx`: Primary telemetry grid, charts, and metrics
- `src/theme.ts`: Modern developer dark-first palette configuration
- `src/api/weather.ts`: Sensor polling client
''');

    // src/
    final src = Directory(p.join(root, 'src'));
    await src.create(recursive: true);

    // src/theme.ts
    await File(p.join(src.path, 'theme.ts')).writeAsString('''export interface ThemeConfig {
  mode: 'dark' | 'light';
  colors: {
    primary: string;
    background: string;
    surface: string;
  };
}

export const defaultTheme: ThemeConfig = {
  mode: 'dark',
  colors: {
    primary: '#06B6D4',
    background: '#090D16',
    surface: '#111827',
  },
};
''');

    // src/components/
    final comps = Directory(p.join(src.path, 'components'));
    await comps.create(recursive: true);

    // src/components/Dashboard.tsx
    await File(p.join(comps.path, 'Dashboard.tsx')).writeAsString('''import React, { useState } from 'react';

export interface WeatherData {
  city: string;
  temp: number;
  humidity: number;
  condition: string;
}

export function Dashboard() {
  const [weather] = useState<WeatherData>({
    city: 'San Francisco',
    temp: 68,
    humidity: 55,
    condition: 'Partly Cloudy',
  });

  return (
    <div className="dashboard-container">
      <header className="dashboard-header">
        <h2>Atmospheric Telemetry</h2>
        <span className="live-badge">LIVE</span>
      </header>

      <div className="metrics-card">
        <h3>{weather.city}</h3>
        <p className="temperature">{weather.temp}°F</p>
        <p className="condition">{weather.condition}</p>
        <p className="humidity">Humidity: {weather.humidity}%</p>
      </div>
    </div>
  );
}
''');

    // src/App.tsx
    await File(p.join(src.path, 'App.tsx')).writeAsString('''import React, { useState } from 'react';
import { Dashboard } from './components/Dashboard';
import { defaultTheme } from './theme';

export function App() {
  const [theme, setTheme] = useState(defaultTheme);

  return (
    <div className={`app-shell theme-\${theme.mode}`}>
      <nav className="navbar">
        <h1>Nivora Weather Dashboard</h1>
        <button onClick={() => setTheme(prev => ({
          ...prev,
          mode: prev.mode === 'dark' ? 'light' : 'dark'
        }))}>
          Toggle Theme
        </button>
      </nav>

      <main className="content">
        <Dashboard />
      </main>
    </div>
  );
}

export default App;
''');
  }

  Future<void> _createPythonFiles(String root) async {
    // requirements.txt
    await File(p.join(root, 'requirements.txt')).writeAsString('''fastapi==0.111.0
uvicorn[standard]==0.30.1
pydantic==2.7.4
pytest==8.2.2
requests==2.32.3
''');

    // README.md
    await File(p.join(root, 'README.md')).writeAsString('''# FastAPI Wildfire AI
Real-time thermal satellite ingestion and predictive wildfire spread model service.

## Development
Start development server with live reload:
`uvicorn main:app --reload`

Run tests:
`pytest`

## Endpoints
- `GET /health`: Healthcheck telemetry
- `POST /predict`: Predict perimeter spread using wind, humidity, and fuel moisture
''');

    // main.py
    await File(p.join(root, 'main.py')).writeAsString('''from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Wildfire Prediction Engine", version="1.0.0")

class TelemetryInput(BaseModel):
    temperature_celsius: float
    relative_humidity: float
    wind_speed_kmh: float

class SpreadPrediction(BaseModel):
    risk_level: str
    estimated_rate_m_per_h: float

@app.get("/health")
def healthcheck():
    return {"status": "healthy", "service": "wildfire-ai"}

@app.post("/predict", response_model=SpreadPrediction)
def predict_spread(telemetry: TelemetryInput):
    if telemetry.temperature_celsius > 35 and telemetry.relative_humidity < 20:
        return SpreadPrediction(risk_level="CRITICAL", estimated_rate_m_per_h=450.0)
    return SpreadPrediction(risk_level="MODERATE", estimated_rate_m_per_h=85.5)
''');
  }

  Future<void> _createHtmlFiles(String root) async {
    // index.html
    await File(p.join(root, 'index.html')).writeAsString('''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nivora Mobile Portfolio</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <div class="container">
    <header class="header">
      <span class="badge">NIVORA WEB DEMO</span>
      <h1>Alex Rivera</h1>
      <p class="role">Mobile Systems & AI Workstation Engineer</p>
    </header>

    <section class="card">
      <h2>Featured Mobile Engineering</h2>
      <div class="project-item">
        <h3>⚡ Nivora Android Dev Workstation</h3>
        <p>Code, build, debug, and preview real GitHub repositories on phone.</p>
      </div>
      <div class="project-item">
        <h3>🛰️ Thermal Wildfire ML</h3>
        <p>Satellite telemetry anomaly detection with on-device AI.</p>
      </div>
    </section>

    <section class="card stats-grid">
      <div class="stat-card">
        <span class="stat-num" id="starCount">2,840</span>
        <span class="stat-label">GitHub Stars</span>
      </div>
      <div class="stat-card">
        <span class="stat-num" id="commitCount">418</span>
        <span class="stat-label">Commits</span>
      </div>
    </section>

    <button id="starBtn" class="action-btn">⭐ Star This Project</button>
  </div>
  <script src="app.js"></script>
</body>
</html>
''');

    // styles.css
    await File(p.join(root, 'styles.css')).writeAsString('''* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

body {
  background-color: #090D16;
  color: #F8FAFC;
  display: flex;
  justify-content: center;
  padding: 24px 16px;
  min-height: 100vh;
}

.container {
  width: 100%;
  max-width: 480px;
}

.header {
  text-align: center;
  margin-bottom: 24px;
}

.badge {
  display: inline-block;
  background: rgba(6, 182, 212, 0.15);
  color: #06B6D4;
  border: 1px solid #06B6D4;
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 1px;
  margin-bottom: 12px;
}

h1 {
  font-size: 26px;
  font-weight: 800;
  color: #F8FAFC;
  margin-bottom: 6px;
}

.role {
  color: #94A3B8;
  font-size: 14px;
}

.card {
  background: #111827;
  border: 1px solid #1F2A3C;
  border-radius: 16px;
  padding: 20px;
  margin-bottom: 16px;
}

.card h2 {
  font-size: 16px;
  color: #06B6D4;
  margin-bottom: 14px;
}

.project-item {
  margin-bottom: 14px;
}

.project-item:last-child {
  margin-bottom: 0;
}

.project-item h3 {
  font-size: 14px;
  color: #F8FAFC;
  margin-bottom: 4px;
}

.project-item p {
  font-size: 12px;
  color: #94A3B8;
  line-height: 1.4;
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  background: transparent;
  border: none;
  padding: 0;
}

.stat-card {
  background: #111827;
  border: 1px solid #1F2A3C;
  border-radius: 14px;
  padding: 16px;
  text-align: center;
}

.stat-num {
  display: block;
  font-size: 22px;
  font-weight: 800;
  color: #06B6D4;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 11px;
  color: #94A3B8;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.action-btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #06B6D4, #0EA5E9);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 4px 14px rgba(6, 182, 212, 0.3);
  transition: transform 0.1s ease;
}

.action-btn:active {
  transform: scale(0.98);
}
''');

    // app.js
    await File(p.join(root, 'app.js')).writeAsString('''let stars = 2840;
const starBtn = document.getElementById('starBtn');
const starCount = document.getElementById('starCount');

if (starBtn && starCount) {
  starBtn.addEventListener('click', () => {
    stars += 1;
    starCount.textContent = stars.toLocaleString();
    starBtn.textContent = '⭐ Starred (' + stars.toLocaleString() + ')';
    starBtn.style.background = '#10B981';
  });
}
''');

    // README.md
    await File(p.join(root, 'README.md')).writeAsString('''# HTML Mobile Portfolio Demo
A lightweight static HTML, modern CSS, and vanilla JavaScript developer portfolio.

## Development
Run a local HTTP static file server:
`npx serve .`

Or with Python:
`python -m http.server 3000`

## Features
- Mobile-optimized responsive layout
- Modern dark developer palette
- Interactive live stars counter via vanilla JavaScript
''');
  }
}
