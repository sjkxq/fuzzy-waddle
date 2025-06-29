-- 基本使用示例
package.path = package.path .. ";../?.lua"  -- 添加父目录到搜索路径

local ConfigFactory = require("src.config_factory")

-- 创建示例配置文件
print("创建 INI 配置文件...")
local ini_config, err = ConfigFactory.create("example_config.ini")
if not ini_config then
    print("创建 INI 配置失败: " .. err)
    return
end

-- 设置配置值
ini_config:set("app", "name", "ExampleApp")
ini_config:set("app", "version", "1.0.0")
ini_config:set("database", "host", "localhost")
ini_config:set("database", "port", 3306)
ini_config:set("database", "enabled", true)

-- 设置全局配置
ini_config:set_global("debug", true)
ini_config:set_global("environment", "development")

-- 保存配置
local success, err = ini_config:save()
if not success then
    print("保存 INI 配置失败: " .. err)
    return
end
print("INI 配置已保存到 example_config.ini")

-- 加载配置文件
print("\n加载 INI 配置文件...")
local loaded_config, err = ConfigFactory.load("example_config.ini")
if not loaded_config then
    print("加载 INI 配置失败: " .. err)
    return
end

-- 显示配置内容
print("应用名称: " .. loaded_config:get("app", "name"))
print("应用版本: " .. loaded_config:get("app", "version"))
print("数据库主机: " .. loaded_config:get("database", "host"))
print("数据库端口: " .. loaded_config:get("database", "port"))
print("数据库启用: " .. tostring(loaded_config:get("database", "enabled")))
print("调试模式: " .. tostring(loaded_config:get_global("debug")))
print("环境: " .. loaded_config:get_global("environment"))

-- 修改配置
print("\n修改配置...")
loaded_config:set("app", "version", "1.1.0")
loaded_config:set("database", "port", 3307)
loaded_config:set_global("environment", "testing")
loaded_config:save()
print("配置已更新")

-- 重新加载配置
loaded_config, err = ConfigFactory.load("example_config.ini")
print("更新后的应用版本: " .. loaded_config:get("app", "version"))
print("更新后的数据库端口: " .. loaded_config:get("database", "port"))
print("更新后的环境: " .. loaded_config:get_global("environment"))

-- 转换为 YAML 格式
print("\n转换为 YAML 格式...")
local success, err = ConfigFactory.convert("example_config.ini", "example_config.yaml")
if not success then
    print("转换配置失败: " .. err)
    return
end
print("配置已转换为 YAML 格式")

-- 加载 YAML 配置
print("\n加载 YAML 配置文件...")
local yaml_config, err = ConfigFactory.load("example_config.yaml")
if not yaml_config then
    print("加载 YAML 配置失败: " .. err)
    return
end

-- 显示 YAML 配置内容
print("YAML 配置 - 应用名称: " .. yaml_config:get("app", "name"))
print("YAML 配置 - 应用版本: " .. yaml_config:get("app", "version"))
print("YAML 配置 - 数据库主机: " .. yaml_config:get("database", "host"))
print("YAML 配置 - 数据库端口: " .. yaml_config:get("database", "port"))
print("YAML 配置 - 调试模式: " .. tostring(yaml_config:get_global("debug")))
print("YAML 配置 - 环境: " .. yaml_config:get_global("environment"))

-- 清理示例文件
print("\n清理示例文件...")
os.remove("example_config.ini")
os.remove("example_config.yaml")
print("示例文件已删除")
print("\n示例运行完成")