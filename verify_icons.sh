#!/bin/bash

# TruckTalk Icon Verification Script
echo "🚛 TruckTalk App Icon Verification"
echo "=================================="

ICON_DIR="TruckTalk/Assets.xcassets/AppIcon.appiconset"

# Required icon files
REQUIRED_ICONS=(
    "AppIcon-20.png"
    "AppIcon-20@2x.png" 
    "AppIcon-20@3x.png"
    "AppIcon-29.png"
    "AppIcon-29@2x.png"
    "AppIcon-29@3x.png"
    "AppIcon-40.png"
    "AppIcon-40@2x.png"
    "AppIcon-40@3x.png"
    "AppIcon-60@2x.png"
    "AppIcon-60@3x.png"
    "AppIcon-76.png"
    "AppIcon-76@2x.png"
    "AppIcon-83.5@2x.png"
    "AppIcon-1024.png"
)

missing_count=0
present_count=0

echo "Checking for required icon files:"
echo ""

for icon in "${REQUIRED_ICONS[@]}"; do
    if [ -f "$ICON_DIR/$icon" ]; then
        echo "✅ $icon"
        present_count=$((present_count + 1))
    else
        echo "❌ $icon (MISSING)"
        missing_count=$((missing_count + 1))
    fi
done

echo ""
echo "Summary:"
echo "✅ Present: $present_count"
echo "❌ Missing: $missing_count"

if [ $missing_count -eq 0 ]; then
    echo ""
    echo "🎉 All icons are present! Your TruckTalk app is ready!"
else
    echo ""
    echo "⚠️  Please add the missing icon files to complete setup."
fi 