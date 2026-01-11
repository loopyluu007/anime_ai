#!/bin/bash

# Web端测试脚本
# 用于快速测试Web应用的基本功能

echo "🚀 开始Web端测试..."

# 检查Flutter是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter未安装或不在PATH中"
    exit 1
fi

echo "✅ Flutter版本:"
flutter --version

# 检查Web支持
echo ""
echo "📦 检查Web支持..."
flutter config --enable-web

# 获取依赖
echo ""
echo "📥 获取依赖..."
flutter pub get

# 分析代码
echo ""
echo "🔍 分析代码..."
flutter analyze

# 构建Web应用（开发模式）
echo ""
echo "🏗️  构建Web应用（开发模式）..."
flutter build web --web-renderer html

# 检查构建结果
if [ -d "build/web" ]; then
    echo "✅ 构建成功！"
    echo "📁 构建文件位置: build/web"
    echo ""
    echo "🧪 测试建议:"
    echo "1. 使用本地服务器测试:"
    echo "   cd build/web"
    echo "   python -m http.server 8080"
    echo ""
    echo "2. 或直接运行:"
    echo "   flutter run -d chrome"
else
    echo "❌ 构建失败"
    exit 1
fi

echo ""
echo "✨ 测试完成！"
