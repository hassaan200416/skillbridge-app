#!/bin/bash
set -e

echo "=== SkillBridge Vercel Build ==="

# Generate assets/app.env from Vercel environment variables
echo "Generating assets/app.env..."
mkdir -p assets/icons
cat > assets/app.env << EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
GROQ_API_KEY=$GROQ_API_KEY
EOF

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git \
  --depth 1 -b stable /opt/flutter 2>/dev/null || true
export PATH="/opt/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

echo "Building Flutter web..."
flutter build web --release

echo "Build complete."
