#!/bin/bash

# Manual Icon Generation Script for TruckTalk
echo "🚛 TruckTalk Manual Icon Generation"
echo "=================================="

SOURCE_ICON="TruckTalk Icon.png"
DEST_DIR="TruckTalk/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Source icon '$SOURCE_ICON' not found!"
    exit 1
fi

echo "📱 Creating icon sizes using sips (macOS built-in tool)..."

# Create all required icon sizes
sips -z 20 20 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-20.png"
sips -z 40 40 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-20@2x.png" 
sips -z 60 60 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-20@3x.png"
sips -z 29 29 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-29.png"
sips -z 58 58 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-29@2x.png"
sips -z 87 87 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-29@3x.png"
sips -z 40 40 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-40.png"
sips -z 80 80 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-40@2x.png"
sips -z 120 120 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-40@3x.png"
sips -z 120 120 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-60@2x.png"
sips -z 180 180 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-60@3x.png"
sips -z 76 76 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-76.png"
sips -z 152 152 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-76@2x.png"
sips -z 167 167 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-83.5@2x.png"
sips -z 1024 1024 "$SOURCE_ICON" --out "$DEST_DIR/AppIcon-1024.png"

echo "✅ All icons created!"
echo "🔍 Running verification..."

./verify_icons.sh 