#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# 脚本功能：
#   本脚本用于在Linux系统上自动配置Lua开发环境，支持检测系统权限、
#   安装Lua及相关工具，并验证安装结果，输出版本信息。
#
# 使用说明：
#   1. 将脚本保存为 setup_lua_dev_env.zsh
#   2. 赋予执行权限：chmod +x setup_lua_dev_env.zsh
#   3. 执行脚本：./setup_lua_dev_env.zsh
#
# 使用注意事项：
#   1. 脚本需要root权限或sudo权限才能正常运行
#   2. 目前支持Debian/Ubuntu和RedHat/CentOS/Fedora系的Linux发行版
#   3. 执行前请确保网络连接畅通
#   4. 脚本默认安装Lua 5.4版本，如需其他版本请修改LUA_VERSION变量
#-------------------------------------------------------------------------------

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Lua版本配置（可修改为所需版本）
LUA_VERSION="5.4"

# 检查是否为root用户
check_root() {
  if [[ $EUID -eq 0 ]]; then
    echo -e "${GREEN}当前用户是root用户，拥有足够权限执行安装操作。${NC}"
    return 0
  else
    echo -e "${YELLOW}当前用户不是root用户，检查是否可以使用sudo...${NC}"
    return 1
  fi
}

# 检查sudo命令
check_sudo() {
  if command -v sudo &>/dev/null; then
    echo -e "${GREEN}系统中存在sudo命令，将尝试使用sudo执行安装操作。${NC}"
    SUDO="sudo"
    return 0
  else
    echo -e "${RED}系统中不存在sudo命令，且当前用户不是root用户，无法继续执行。${NC}"
    return 1
  fi
}

# 检测Linux发行版
detect_distribution() {
  if [[ -f /etc/debian_version ]]; then
    echo "debian"
  elif [[ -f /etc/redhat-release ]]; then
    echo "redhat"
  else
    echo -e "${RED}无法识别的Linux发行版，脚本可能无法正常工作。${NC}"
    return 1
  fi
}

# 安装Lua
install_lua() {
  local distro=$(detect_distribution)
  if [[ $distro == "debian" ]]; then
    echo -e "${YELLOW}检测到Debian/Ubuntu系统，准备安装Lua...${NC}"
    $SUDO apt-get update -y
    $SUDO apt-get install -y lua${LUA_VERSION} lua${LUA_VERSION}-dev luarocks
  elif [[ $distro == "redhat" ]]; then
    echo -e "${YELLOW}检测到RedHat/CentOS/Fedora系统，准备安装Lua...${NC}"
    $SUDO yum update -y
    $SUDO yum install -y lua lua-devel luarocks
  else
    echo -e "${RED}不支持的发行版，无法安装Lua。${NC}"
    return 1
  fi
}

# 验证安装
verify_installation() {
  if command -v lua &>/dev/null && command -v luarocks &>/dev/null; then
    echo -e "${GREEN}Lua开发环境已成功安装！${NC}"
    return 0
  else
    echo -e "${RED}Lua开发环境安装失败，请检查错误信息。${NC}"
    return 1
  fi
}

# 获取版本信息
get_version() {
  echo -e "${GREEN}Lua版本信息：${NC}"
  lua -v
  echo -e "${GREEN}LuaRocks版本信息：${NC}"
  luarocks --version
}

# 主函数
main() {
  echo -e "${YELLOW}===== 开始配置Lua开发环境 ====${NC}"
  
  # 检查权限
  if ! check_root; then
    if ! check_sudo; then
      exit 1
    fi
  fi
  
  # 安装Lua
  install_lua
  
  # 验证安装
  if verify_installation; then
    # 获取版本信息
    get_version
    echo -e "${GREEN}===== Lua开发环境配置完成 ====${NC}"
  else
    echo -e "${RED}===== Lua开发环境配置失败 ====${NC}"
    exit 1
  fi
}

# 执行主函数
main    