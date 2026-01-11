#!/bin/bash

# AI漫导后端服务停止脚本
# 使用方法: ./stop.sh [dev|prod]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 停止服务
stop_services() {
    local mode=$1
    
    echo -e "${YELLOW}停止服务...${NC}"
    
    if [ "$mode" = "dev" ]; then
        docker-compose -f docker-compose.dev.yml down
    else
        docker-compose down
    fi
    
    echo -e "${GREEN}✓ 服务已停止${NC}"
}

# 主函数
main() {
    local mode=${1:-prod}
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  AI漫导后端服务停止脚本${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    if [ "$mode" = "dev" ] || [ "$mode" = "prod" ]; then
        stop_services "$mode"
    else
        echo -e "${RED}错误: 无效的模式 '$mode'${NC}"
        echo "使用方法: ./stop.sh [dev|prod]"
        exit 1
    fi
}

main "$@"
