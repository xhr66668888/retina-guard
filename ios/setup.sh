#!/bin/bash
# Run this script on a Mac with Xcode installed to generate the .xcodeproj
# Usage: cd ios && ./setup.sh

set -e
cd "$(dirname "$0")"

echo "Creating Xcode project for RetinaGuard..."

# Use xcodegen if available, otherwise manual instructions
if command -v xcodegen &> /dev/null; then
    cat > project.yml << 'EOF'
name: RetinaGuard
options:
  bundleIdPrefix: com.retinaguard
  deploymentTarget:
    iOS: "16.0"
  xcodeVersion: "15.0"
settings:
  base:
    INFOPLIST_FILE: RetinaGuard/Resources/Info.plist
    PRODUCT_BUNDLE_IDENTIFIER: com.retinaguard.app
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: 1
    SWIFT_VERSION: "5.9"
    TARGETED_DEVICE_FAMILY: "1,2"
    ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: Color
    CODE_SIGN_STYLE: Automatic
    DEVELOPMENT_TEAM: ""
targets:
  RetinaGuard:
    type: application
    platform: iOS
    sources:
      - RetinaGuard
    resources:
      - RetinaGuard/Resources
    settings:
      base:
        INFOPLIST_FILE: RetinaGuard/Resources/Info.plist
        PRODUCT_BUNDLE_IDENTIFIER: com.retinaguard.app
    entitlements:
      path: RetinaGuard/Resources/RetinaGuard.entitlements
      properties:
        com.apple.security.application-groups:
          - group.com.retinaguard
EOF
    xcodegen generate
    echo "Done! Open RetinaGuard.xcodeproj in Xcode."
else
    echo "xcodegen not found. Install it: brew install xcodegen"
    echo ""
    echo "Or create the project manually in Xcode:"
    echo "  1. Open Xcode > File > New > Project"
    echo "  2. Choose 'App' template (SwiftUI, Swift)"
    echo "  3. Product Name: RetinaGuard"
    echo "  4. Bundle ID: com.retinaguard.app"
    echo "  5. Save in this ios/ folder"
    echo "  6. Drag all .swift files from RetinaGuard/ into the project"
    echo "  7. Set Info.plist path to RetinaGuard/Resources/Info.plist"
    echo "  8. Add Background Modes capability (Background fetch, BGProcessing)"
fi
