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
