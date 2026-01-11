#!/bin/bash

# AI漫导后端服务启动脚本
# 使用方法: ./start.sh [dev|prod]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查环境
check_requirements() {
    echo -e "${YELLOW}检查环境要求...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: 未找到 Docker，请先安装 Docker${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}错误: 未找到 docker-compose，请先安装 docker-compose${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 环境检查通过${NC}"
}

# 检查 .env 文件
check_env_file() {
    if [ ! -f "../../.env" ]; then
        echo -e "${YELLOW}警告: 未找到 .env 文件${NC}"
        echo -e "${YELLOW}正在从 .env.example 创建 .env 文件...${NC}"
        if [ -f "../../.env.example" ]; then
            cp ../../.env.example ../../.env
            echo -e "${GREEN}✓ 已创建 .env 文件，请编辑配置后重新运行${NC}"
            echo -e "${YELLOW}提示: 请至少配置以下环境变量:${NC}"
            echo "  - GLM_API_KEY"
            echo "  - TUZI_API_KEY"
            echo "  - GEMINI_API_KEY"
            echo "  - SECRET_KEY"
            exit 1
        else
            echo -e "${RED}错误: 未找到 .env.example 文件${NC}"
            exit 1
        fi
    fi
}

# 启动服务
start_services() {
    local mode=$1
    
    if [ "$mode" = "dev" ]; then
        echo -e "${GREEN}启动开发环境...${NC}"
        echo -e "${YELLOW}注意: 开发环境只启动基础设施（数据库、Redis、MinIO）${NC}"
        echo -e "${YELLOW}服务需要本地运行${NC}"
        docker-compose -f docker-compose.dev.yml up -d
    else
        echo -e "${GREEN}启动生产环境...${NC}"
        docker-compose up -d
    fi
    
    echo -e "${GREEN}✓ 服务启动完成${NC}"
}

# 显示服务状态
show_status() {
    echo -e "\n${YELLOW}服务状态:${NC}"
    if [ "$1" = "dev" ]; then
        docker-compose -f docker-compose.dev.yml ps
    else
        docker-compose ps
    fi
    
    echo -e "\n${YELLOW}服务地址:${NC}"
    echo "  - API Gateway: http://localhost:8000"
    echo "  - Agent Service: http://localhost:8001"
    echo "  - Media Service: http://localhost:8002"
    echo "  - Data Service: http://localhost:8003"
    echo "  - MinIO Console: http://localhost:9001"
    echo "  - PostgreSQL: localhost:5432"
    echo "  - Redis: localhost:6379"
}

# 主函数
main() {
    local mode=${1:-prod}
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  AI漫导后端服务启动脚本${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    check_requirements
    check_env_file
    
    if [ "$mode" = "dev" ] || [ "$mode" = "prod" ]; then
        start_services "$mode"
        sleep 3
        show_status "$mode"
    else
        echo -e "${RED}错误: 无效的模式 '$mode'${NC}"
        echo "使用方法: ./start.sh [dev|prod]"
        exit 1
    fi
}

main "$@"
