@echo off
REM Web端测试脚本 (Windows)
REM 用于快速测试Web应用的基本功能

echo 🚀 开始Web端测试...

REM 检查Flutter是否安装
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter未安装或不在PATH中
    exit /b 1
)

echo ✅ Flutter版本:
flutter --version

REM 检查Web支持
echo.
echo 📦 检查Web支持...
flutter config --enable-web

REM 获取依赖
echo.
echo 📥 获取依赖...
flutter pub get

REM 分析代码
echo.
echo 🔍 分析代码...
flutter analyze

REM 构建Web应用（开发模式）
echo.
echo 🏗️  构建Web应用（开发模式）...
flutter build web --web-renderer html

REM 检查构建结果
if exist "build\web" (
    echo ✅ 构建成功！
    echo 📁 构建文件位置: build\web
    echo.
    echo 🧪 测试建议:
    echo 1. 使用本地服务器测试:
    echo    cd build\web
    echo    python -m http.server 8080
    echo.
    echo 2. 或直接运行:
    echo    flutter run -d chrome
) else (
    echo ❌ 构建失败
    exit /b 1
)

echo.
echo ✨ 测试完成！
