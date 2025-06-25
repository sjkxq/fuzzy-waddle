#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
# 脚本功能：
#   本脚本用于在Linux系统上自动安装Busted（Lua单元测试框架），支持检测系统权限、
#   安装Busted及相关依赖，并验证安装结果，输出版本信息。
#
# 使用说明：
#   1. 将脚本保存为 install_busted.zsh
#   2. 赋予执行权限：chmod +x install_busted.zsh
#   3. 执行脚本：./install_busted.zsh
#
# 使用注意事项：
#   1. 脚本需要root权限或sudo权限才能正常运行
#   2. 目前支持Debian/Ubuntu和RedHat/CentOS/Fedora系的Linux发行版
#   3. 执行前请确保已安装Lua和LuaRocks（可通过lua-dev-env-setup脚本安装）
#   4. 若安装失败，可能需要手动更新LuaRocks仓库：luarocks update
#-------------------------------------------------------------------------------

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

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

# 验证Lua环境
verify_lua_environment() {
  if ! command -v lua &>/dev/null; then
    echo -e "${RED}未检测到Lua环境，请先安装Lua。${NC}"
    return 1
  fi
  
  if ! command -v luarocks &>/dev/null; then
    echo -e "${RED}未检测到LuaRocks，请先安装LuaRocks。${NC}"
    return 1
  fi
  
  echo -e "${GREEN}Lua环境检测通过。${NC}"
  return 0
}

# 安装Busted
install_busted() {
  echo -e "${YELLOW}准备安装Busted测试框架...${NC}"
  
  # 使用LuaRocks安装Busted
  $SUDO luarocks install busted
  
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Busted安装失败，请检查错误信息。${NC}"
    return 1
  fi
  
  echo -e "${GREEN}Busted安装完成！${NC}"
  return 0
}

# 验证安装
verify_installation() {
  if command -v busted &>/dev/null; then
    echo -e "${GREEN}Busted已成功安装！${NC}"
    return 0
  else
    echo -e "${RED}Busted安装失败，请检查错误信息。${NC}"
    return 1
  fi
}

# 获取版本信息
get_version() {
  echo -e "${GREEN}Busted版本信息：${NC}"
  busted --version
}

# 主函数
main() {
  echo -e "${YELLOW}===== 开始安装Busted测试框架 ====${NC}"
  
  # 检查权限
  if ! check_root; then
    if ! check_sudo; then
      exit 1
    fi
  fi
  
  # 验证Lua环境
  if ! verify_lua_environment; then
    exit 1
  fi
  
  # 安装Busted
  install_busted
  
  # 验证安装
  if verify_installation; then
    # 获取版本信息
    get_version
    echo -e "${GREEN}===== Busted测试框架安装完成 ====${NC}"
    echo -e "${BLUE}使用示例：busted path/to/tests${NC}"
  else
    echo -e "${RED}===== Busted测试框架安装失败 ====${NC}"
    exit 1
  fi
}

# 执行主函数
main    