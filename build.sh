#!/bin/bash

echo "🔨 Building React app..."
cd software/frontend
npm install
npm run build
cd ../..

echo "🐳 Starting Docker containers..."
docker-compose up --build -d

echo ""
echo "✅ Build complete!"
echo "🌐 Frontend: http://localhost (https://localhost)"
echo "🔧 API: http://localhost:8080"
echo "💾 PHPMyAdmin: http://localhost:9002"