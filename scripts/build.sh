#!/bin/bash
# FinanceApp Build Script
# Usage: ./scripts/build.sh [setup|generate|build|run|clean]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="FinanceApp"
SIMULATOR_NAME="iPhone 16"
DERIVED_DATA="$PROJECT_DIR/.build"
BUNDLE_ID="com.sergiofinance.FinanceApp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step()  { echo -e "\n${GREEN}▸ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠ $1${NC}"; }
err()   { echo -e "${RED}✗ $1${NC}"; }
info()  { echo -e "${BLUE}ℹ $1${NC}"; }

case "${1:-help}" in
  setup)
    step "Setting up development environment..."

    if ! command -v xcodegen &> /dev/null; then
      info "Installing XcodeGen..."
      brew install xcodegen
    else
      info "XcodeGen already installed ($(xcodegen --version))"
    fi

    if ! command -v xcpretty &> /dev/null; then
      info "Installing xcpretty..."
      gem install xcpretty 2>/dev/null || sudo gem install xcpretty
    else
      info "xcpretty already installed"
    fi

    step "Setup complete!"
    ;;

  generate)
    step "Generating Xcode project..."
    cd "$PROJECT_DIR"
    xcodegen generate
    step "Project generated: FinanceApp.xcodeproj"
    ;;

  build)
    step "Building FinanceApp for iOS Simulator..."
    cd "$PROJECT_DIR"

    # Generate project if needed
    if [ ! -d "FinanceApp.xcodeproj" ]; then
      step "Generating Xcode project first..."
      xcodegen generate
    fi

    # Check if static library exists
    if [ ! -f "libs/libfinance_ffi.a" ]; then
      warn "libs/libfinance_ffi.a not found!"
      warn "Build will fail at linking. Place the compiled Rust static library in libs/"
      warn "Continuing anyway to check for Swift compilation errors..."
    fi

    step "Running xcodebuild..."
    if command -v xcpretty &> /dev/null; then
      set -o pipefail
      xcodebuild build \
        -project FinanceApp.xcodeproj \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
        -derivedDataPath "$DERIVED_DATA" \
        2>&1 | xcpretty
    else
      xcodebuild build \
        -project FinanceApp.xcodeproj \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
        -derivedDataPath "$DERIVED_DATA"
    fi

    step "Build succeeded!"
    ;;

  run)
    # Build first
    "$0" build

    step "Launching on iOS Simulator..."

    # Find the built app
    APP_PATH=$(find "$DERIVED_DATA" -name "FinanceApp.app" -path "*/Debug-iphonesimulator/*" | head -1)

    if [ -z "$APP_PATH" ]; then
      err "Could not find built app bundle"
      exit 1
    fi

    info "App path: $APP_PATH"

    # Find simulator device
    DEVICE_ID=$(xcrun simctl list devices available | grep "$SIMULATOR_NAME" | head -1 | grep -oE '[A-F0-9\-]{36}')

    if [ -z "$DEVICE_ID" ]; then
      err "Simulator '$SIMULATOR_NAME' not found. Available simulators:"
      xcrun simctl list devices available | grep "iPhone"
      exit 1
    fi

    info "Using simulator: $SIMULATOR_NAME ($DEVICE_ID)"

    # Boot simulator if needed
    xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true

    # Install and launch
    xcrun simctl install "$DEVICE_ID" "$APP_PATH"
    xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

    # Open Simulator.app
    open -a Simulator

    step "App launched on $SIMULATOR_NAME!"
    ;;

  clean)
    step "Cleaning build artifacts..."
    rm -rf "$DERIVED_DATA"
    rm -rf "$PROJECT_DIR/FinanceApp.xcodeproj"
    step "Clean complete!"
    ;;

  *)
    echo ""
    echo "FinanceApp Build Script"
    echo "======================"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  setup      Install required tools (XcodeGen, xcpretty)"
    echo "  generate   Generate Xcode project from project.yml"
    echo "  build      Build for iOS Simulator"
    echo "  run        Build and launch on iOS Simulator"
    echo "  clean      Remove build artifacts and generated project"
    echo ""
    ;;
esac
