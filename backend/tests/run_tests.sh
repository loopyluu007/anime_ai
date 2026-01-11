#!/bin/bash
# 运行测试脚本

echo "🚀 开始运行测试..."

# 安装测试依赖（如果需要）
if [ ! -d "venv" ]; then
    echo "📦 创建虚拟环境..."
    python -m venv venv
fi

source venv/bin/activate 2>/dev/null || source venv/Scripts/activate 2>/dev/null

echo "📦 安装测试依赖..."
pip install -q -r requirements.txt
pip install -q -r requirements-test.txt

echo "🧪 运行测试..."
pytest "$@"

echo "✅ 测试完成！"
