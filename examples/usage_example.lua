-- usage_example.lua
-- 多格式配置系统使用示例

-- 添加 src 目录到模块搜索路径
package.path = "../src/?.lua;" .. package.path

local ConfigHandler = require("config_handler")

-- 辅助函数：打印配置内容
local function print_config(config, section)
    if section then
        print(string.format("\n[%s]", section))
        local keys = config:get_keys(section)
        for _, key in ipairs(keys) do
            print(string.format("%s = %s", key, config:get(section, key)))
        end
    else
        local sections = config:get_sections()
        for _, sec in ipairs(sections) do
            print_config(config, sec)
        end
    end
end

print("===== 多格式配置系统使用示例 =====\n")

-- 1. 加载 INI 格式配置文件
print("1. 加载 INI 格式配置文件")
print("-------------------------")
local config = ConfigHandler.load("config.ini")
if config then
    print("成功加载 INI 配置文件")
    print("\n当前配置内容:")
    print_config(config)
else
    print("加载 INI 配置文件失败")
end

-- 2. 修改配置
print("\n2. 修改配置")
print("-------------------------")
if config then
    -- 修改现有值
    config:set("database", "port", 3307)
    print("修改数据库端口为 3307")
    
    -- 添加新配置项
    config:set("server", "max_connections", 1000)
    print("添加服务器最大连接数设置")
    
    -- 添加新配置节
    config:set("email", "smtp_server", "smtp.example.com")
    config:set("email", "smtp_port", 587)
    config:set("email", "username", "user@example.com")
    config:set("email", "password", "password123")
    print("添加邮件服务器配置节")
    
    print("\n更新后的配置内容:")
    print_config(config)
end

-- 3. 转换到 JSON 格式
print("\n3. 转换到 JSON 格式")
print("-------------------------")
if config then
    local success, err = config:convert_to("json")
    if success then
        print("成功转换到 JSON 格式")
        success, err = ConfigHandler.save(config, "converted_config.json")
        if success then
            print("成功保存 JSON 格式配置文件")
        else
            print("保存 JSON 格式配置文件失败:", err.message)
        end
    else
        print("转换到 JSON 格式失败:", err.message)
    end
end

-- 4. 转换到 YAML 格式
print("\n4. 转换到 YAML 格式")
print("-------------------------")
if config then
    local success, err = config:convert_to("yaml")
    if success then
        print("成功转换到 YAML 格式")
        success, err = ConfigHandler.save(config, "converted_config.yaml")
        if success then
            print("成功保存 YAML 格式配置文件")
        else
            print("保存 YAML 格式配置文件失败:", err.message)
        end
    else
        print("转换到 YAML 格式失败:", err.message)
    end
end

-- 5. 读取特定配置值
print("\n5. 读取特定配置值")
print("-------------------------")
if config then
    local db_host = config:get("database", "host")
    local db_port = config:get("database", "port")
    print(string.format("数据库连接信息: %s:%d", db_host, db_port))
    
    local log_level = config:get("logging", "level")
    local log_file = config:get("logging", "file")
    print(string.format("日志配置: 级别=%s, 文件=%s", log_level, log_file))
    
    local smtp_server = config:get("email", "smtp_server")
    local smtp_port = config:get("email", "smtp_port")
    print(string.format("邮件服务器: %s:%d", smtp_server, smtp_port))
end

-- 6. 检查配置项是否存在
print("\n6. 检查配置项是否存在")
print("-------------------------")
if config then
    local has_redis = config:has_section("redis")
    print("是否配置了Redis:", has_redis and "是" or "否")
    
    local has_cache = config:has_section("cache")
    print("是否配置了Cache:", has_cache and "是" or "否")
    
    local has_db_password = config:has_key("database", "password")
    print("是否设置了数据库密码:", has_db_password and "是" or "否")
end

print("\n示例运行完成")