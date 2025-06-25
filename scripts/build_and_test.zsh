#!/usr/bin/env zsh

# 设置颜色输出
autoload -U colors && colors

# 设置项目根目录
PROJECT_ROOT=$(dirname $(dirname $0))
cd $PROJECT_ROOT

# 检查依赖项
check_dependencies() {
  echo "${fg[blue]}检查依赖项...${reset_color}"
  
  # 检查 Lua
  if ! command -v lua &> /dev/null; then
    echo "${fg[red]}错误: Lua 未安装${reset_color}"
    echo "请安装 Lua: https://www.lua.org/download.html"
    exit 1
  fi
  
  # 检查 LuaRocks
  if ! command -v luarocks &> /dev/null; then
    echo "${fg[yellow]}警告: LuaRocks 未安装${reset_color}"
    echo "建议安装 LuaRocks 以管理依赖: https://github.com/luarocks/luarocks/wiki/Download"
  fi
  
  # 检查 busted
  if ! command -v busted &> /dev/null; then
    echo "${fg[yellow]}警告: busted 未安装${reset_color}"
    echo "请安装 busted 测试框架: luarocks install busted"
    exit 1
  fi
  
  echo "${fg[green]}所有依赖项检查通过${reset_color}"
}

# 清理构建目录
clean_build() {
  echo "${fg[blue]}清理构建目录...${reset_color}"
  mkdir -p build
  rm -rf build/*
  echo "${fg[green]}构建目录已清理${reset_color}"
}

# 运行测试
run_tests() {
  echo "${fg[blue]}运行测试...${reset_color}"
  
  # 确保在项目根目录运行测试
  cd $PROJECT_ROOT
  
  # 设置 LUA_PATH 环境变量，使其包含 src 目录
  # 注意：测试文件使用 require("src.ini_parser") 格式导入
  export LUA_PATH="$PROJECT_ROOT/?.lua;$LUA_PATH"
  
  # 使用 busted 运行测试，并指定完整路径
  busted -o TAP "$PROJECT_ROOT/tests/"
  
  local test_result=$?
  if [ $test_result -eq 0 ]; then
    echo "${fg[green]}所有测试通过${reset_color}"
    return 0
  else
    echo "${fg[red]}测试失败${reset_color}"
    return 1
  fi
}

# 构建项目
build_project() {
  echo "${fg[blue]}构建项目...${reset_color}"
  
  # 创建构建目录
  mkdir -p build/lib
  
  # 复制源文件到构建目录，并修改 require 语句
  for file in src/*.lua; do
    base_name=$(basename "$file")
    # 使用 sed 替换 require("src.xxx") 为 require("xxx")
    sed 's/require("src\./require("/g' "$file" > "build/lib/$base_name"
  done
  
  # 创建一个简单的示例配置文件
  cat > build/example.ini << EOF
; 示例配置文件
app_name=Lua INI Config
version=1.0.0

[database]
host=localhost
port=3306
username=user
password=pass

[logging]
level=info
file=app.log
EOF
  
  echo "${fg[green]}项目构建完成${reset_color}"
}

# 创建示例
create_example() {
  echo "${fg[blue]}创建示例脚本...${reset_color}"
  
  cat > build/example.lua << EOF
#!/usr/bin/env lua

-- 添加构建目录到 Lua 路径
package.path = "./lib/?.lua;" .. package.path

-- 导入配置处理器
local ConfigHandler = require("config_handler")

-- 加载配置文件
local config, err = ConfigHandler.load("example.ini")
if not config then
  print("加载配置失败:", err.message)
  os.exit(1)
end

-- 显示配置信息
print("应用名称:", config:get_global("app_name"))
print("版本:", config:get_global("version"))
print("数据库主机:", config:get("database", "host"))
print("数据库端口:", config:get("database", "port"))
print("日志级别:", config:get("logging", "level"))

-- 修改配置
config:set("database", "port", "5432")
config:set("logging", "level", "debug")

-- 保存配置
local success, save_err = config:save()
if not success then
  print("保存配置失败:", save_err.message)
  os.exit(1)
end

print("配置已更新并保存")
EOF
  
  chmod +x build/example.lua
  echo "${fg[green]}示例脚本已创建${reset_color}"
}

# 主函数
main() {
  echo "${fg[cyan]}===== Lua INI 配置库构建和测试 =====${reset_color}"
  
  check_dependencies
  clean_build
  
  # 构建项目
  build_project
  
  # 运行测试
  run_tests
  if [ $? -ne 0 ]; then
    echo "${fg[red]}测试失败，构建终止${reset_color}"
    exit 1
  fi
  
  # 创建示例
  create_example
  
  echo "${fg[cyan]}===== 构建和测试完成 =====${reset_color}"
  echo "你可以运行示例: cd build && ./example.lua"
}

# 执行主函数
main