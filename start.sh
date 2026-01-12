#!/bin/bash

# AI漫导统一部署脚本
# 使用方法: ./start.sh [dev|prod] [frontend|backend|all]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录（项目根目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 默认参数
MODE=${1:-prod}
COMPONENT=${2:-all}

# 检查环境
check_requirements() {
    echo -e "${YELLOW}检查环境要求...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: 未找到 Docker，请先安装 Docker${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}错误: 未找到 docker-compose，请先安装 docker-compose${NC}"
        exit 1
    fi
    
    # 检查 Docker 是否运行
    if ! docker info &> /dev/null; then
        echo -e "${RED}错误: Docker 未运行，请启动 Docker${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 环境检查通过${NC}"
}

# 检查 .env 文件
check_env_file() {
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}警告: 未找到 .env 文件${NC}"
        if [ -f ".env.example" ]; then
            echo -e "${YELLOW}正在从 .env.example 创建 .env 文件...${NC}"
            cp .env.example .env
            echo -e "${GREEN}✓ 已创建 .env 文件，请编辑配置后重新运行${NC}"
            echo -e "${YELLOW}提示: 请至少配置以下环境变量:${NC}"
            echo "  - GLM_API_KEY"
            echo "  - TUZI_API_KEY"
            echo "  - GEMINI_API_KEY"
            echo "  - SECRET_KEY"
            exit 1
        else
            echo -e "${YELLOW}提示: 创建 .env 文件并配置必要的环境变量${NC}"
        fi
    fi
}

# 启动服务
start_services() {
    local mode=$1
    local component=$2
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  AI漫导统一部署${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    if [ "$mode" = "dev" ]; then
        echo -e "${YELLOW}模式: 开发环境${NC}"
        echo -e "${YELLOW}注意: 开发环境只启动基础设施（数据库、Redis、MinIO）${NC}"
        echo -e "${YELLOW}服务需要本地运行${NC}\n"
        
        # 开发环境只启动基础设施
        docker-compose up -d postgres redis minio
        
    else
        echo -e "${GREEN}模式: 生产环境${NC}\n"
        
        case $component in
            frontend)
                echo -e "${BLUE}启动前端服务...${NC}"
                docker-compose up -d frontend
                ;;
            backend)
                echo -e "${BLUE}启动后端服务...${NC}"
                docker-compose up -d postgres redis minio agent_service media_service data_service api_gateway
                ;;
            all|*)
                echo -e "${BLUE}启动所有服务...${NC}"
                docker-compose up -d
                ;;
        esac
    fi
    
    echo -e "\n${GREEN}✓ 服务启动完成${NC}"
}

# 显示服务状态
show_status() {
    local mode=$1
    
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  服务状态${NC}"
    echo -e "${YELLOW}========================================${NC}\n"
    
    docker-compose ps
    
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  服务地址${NC}"
    echo -e "${YELLOW}========================================${NC}\n"
    
    if [ "$mode" = "dev" ]; then
        echo -e "${GREEN}基础设施服务:${NC}"
        echo "  - PostgreSQL: localhost:5432"
        echo "  - Redis: localhost:6379"
        echo "  - MinIO: http://localhost:9000"
        echo "  - MinIO Console: http://localhost:9001"
    else
        echo -e "${GREEN}前端服务:${NC}"
        echo "  - Frontend: http://localhost:${FRONTEND_PORT:-8080}"
        echo ""
        echo -e "${GREEN}后端服务:${NC}"
        echo "  - API Gateway: http://localhost:${API_GATEWAY_PORT:-8000}"
        echo "  - Agent Service: http://localhost:${AGENT_SERVICE_PORT:-8001}"
        echo "  - Media Service: http://localhost:${MEDIA_SERVICE_PORT:-8002}"
        echo "  - Data Service: http://localhost:${DATA_SERVICE_PORT:-8003}"
        echo ""
        echo -e "${GREEN}基础设施服务:${NC}"
        echo "  - PostgreSQL: localhost:${POSTGRES_PORT:-5432}"
        echo "  - Redis: localhost:${REDIS_PORT:-6379}"
        echo "  - MinIO: http://localhost:${MINIO_PORT:-9000}"
        echo "  - MinIO Console: http://localhost:${MINIO_CONSOLE_PORT:-9001}"
    fi
    
    echo ""
}

# 主函数
main() {
    check_requirements
    check_env_file
    
    if [ "$MODE" != "dev" ] && [ "$MODE" != "prod" ]; then
        echo -e "${RED}错误: 无效的模式 '$MODE'${NC}"
        echo "使用方法: ./start.sh [dev|prod] [frontend|backend|all]"
        exit 1
    fi
    
    start_services "$MODE" "$COMPONENT"
    sleep 3
    show_status "$MODE"
    
    echo -e "\n${GREEN}部署完成！${NC}"
    echo -e "${YELLOW}提示: 使用 './stop.sh' 停止服务${NC}"
    echo -e "${YELLOW}提示: 使用 'docker-compose logs -f [service_name]' 查看日志${NC}"
}

main "$@"
