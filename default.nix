# Nivora Declarative Nix Development Environment
{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "34" "33" "31" ];
    buildToolsVersions = [ "34.0.0" "33.0.1" ];
    includeNDK = true;
    ndkVersions = [ "25.1.8937393" ];
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "x86_64" "arm64-v8a" ];
    includeEmulator = true;
    useGoogleAPIs = true;
  };

  androidSdk = androidComposition.androidsdk;

in pkgs.mkShell {
  name = "nivora-dev-shell";

  buildInputs = with pkgs; [
    # Core Languages & Runtimes
    flutter
    dart
    nodejs_20
    nodePackages.npm
    nodePackages.pnpm
    python311
    python311Packages.pip
    python311Packages.virtualenv

    # Build & System Utilities
    jdk17
    git
    git-lfs
    ripgrep
    fd
    tree
    curl
    wget
    zip
    unzip
    pkg-config
    cmake
    ninja

    # Android SDK
    androidSdk

    # AI & Local Inference Toolchains
    ollama
  ];

  shellHook = ''
    export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
    export JAVA_HOME="${pkgs.jdk17}"
    export PATH="$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"
    export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"

    echo "============================================================"
    echo " ⚡ Welcome to Nivora AI Workstation Development Environment"
    echo " Flutter: $(flutter --version | head -n 1)"
    echo " Android SDK: $ANDROID_SDK_ROOT"
    echo " Java: $JAVA_HOME"
    echo " Node.js: $(node --version)"
    echo " Python: $(python3 --version)"
    echo "============================================================"
  '';
}
