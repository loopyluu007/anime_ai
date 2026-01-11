@echo off
REM 运行测试脚本 (Windows)

echo 🚀 开始运行测试...

REM 检查虚拟环境
if not exist "venv" (
    echo 📦 创建虚拟环境...
    python -m venv venv
)

call venv\Scripts\activate.bat

echo 📦 安装测试依赖...
pip install -q -r requirements.txt
pip install -q -r requirements-test.txt

echo 🧪 运行测试...
pytest %*

echo ✅ 测试完成！
