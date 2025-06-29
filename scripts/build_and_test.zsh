#!/bin/zsh

# 设置错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo "${color}${message}${NC}"
}

# 检查必要的工具
check_dependencies() {
    print_message $YELLOW "检查依赖项..."
    
    # 检查 lua 是否安装
    if ! command -v lua &> /dev/null; then
        print_message $RED "错误: 未找到 lua"
        exit 1
    fi
    
    # 检查 luarocks 是否安装
    if ! command -v luarocks &> /dev/null; then
        print_message $RED "错误: 未找到 luarocks"
        exit 1
    fi
    
    # 检查 busted 是否安装
    if ! command -v busted &> /dev/null; then
        print_message $YELLOW "未找到 busted，正在安装..."
        luarocks install busted
    fi
    
    print_message $GREEN "所有依赖项检查通过"
}

# 运行测试
run_tests() {
    print_message $YELLOW "运行测试..."
    
    # 确保在项目根目录
    if [[ ! -d "src" ]] || [[ ! -d "tests" ]]; then
        print_message $RED "错误: 请在项目根目录运行此脚本"
        exit 1
    fi
    
    # 添加 src 目录到 LUA_PATH
    export LUA_PATH="./src/?.lua;$LUA_PATH"
    
    # 运行所有测试
    if busted --verbose tests; then
        print_message $GREEN "所有测试通过"
        return 0
    else
        print_message $RED "测试失败"
        return 1
    fi
}

# 清理临时文件
cleanup() {
    print_message $YELLOW "清理临时文件..."
    rm -f tests/fixtures/temp_config.*
    rm -f tests/fixtures/test_converted.*
    print_message $GREEN "清理完成"
}

# 主函数
main() {
    print_message $YELLOW "开始构建和测试..."
    
    # 检查依赖
    check_dependencies
    
    # 运行测试
    if run_tests; then
        # 清理临时文件
        cleanup
        print_message $GREEN "构建和测试成功完成"
        exit 0
    else
        # 清理临时文件
        cleanup
        print_message $RED "构建和测试失败"
        exit 1
    fi
}

# 运行主函数
main