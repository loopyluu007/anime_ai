#!/bin/bash
set -e

echo "🚀 开始 Vercel 构建流程..."

# 安装 Flutter SDK
if [ ! -d "flutter" ]; then
    echo "📥 克隆 Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
    echo "🔄 更新 Flutter SDK..."
    cd flutter && git pull && cd ..
fi

# 添加 Flutter 到 PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# 验证 Flutter 安装
echo "✅ Flutter 版本:"
flutter --version

# 启用 Web 支持
echo "🌐 启用 Web 支持..."
flutter config --enable-web

# 获取依赖
echo "📦 获取依赖..."
flutter pub get

# 清理构建缓存（可选，首次构建不需要）
# echo "🧹 清理构建缓存..."
# flutter clean

# 构建 Web 应用
echo "🏗️  构建 Web 应用（Release 模式）..."
flutter build web --release

echo "✅ 构建完成！"
echo "📁 构建输出目录: build/web"
