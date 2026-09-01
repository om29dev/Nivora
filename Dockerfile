# Multi-stage Dockerfile for Nivora AI Mobile Workstation & In-Sandbox Toolchains
FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential build tools, runtimes & system libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    git \
    git-lfs \
    unzip \
    zip \
    xz-utils \
    build-essential \
    pkg-config \
    cmake \
    ninja-build \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    libglu1-mesa \
    libpulse0 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 & npm / vite
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest vite pnpm yarn && \
    rm -rf /var/lib/apt/lists/*

# Setup Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/build-tools/34.0.0

RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip && \
    mv cmdline-tools latest && \
    rm cmdline-tools.zip && \
    yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Setup Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$FLUTTER_HOME/bin

RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME && \
    flutter config --no-analytics && \
    flutter precache --android && \
    yes | flutter doctor --android-licenses && \
    flutter doctor

# Workspace setup
WORKDIR /workspace/Nivora
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

# Run validation checks
RUN flutter analyze --no-pub
RUN flutter test

EXPOSE 5173 8080 11434

CMD ["bash"]
