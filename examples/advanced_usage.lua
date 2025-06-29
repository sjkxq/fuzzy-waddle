-- 高级使用示例
package.path = package.path .. ";../?.lua"  -- 添加父目录到搜索路径

local ConfigFactory = require("src.config_factory")
local lfs = require("lfs")

-- 创建示例目录
local function ensure_dir(path)
    if not lfs.attributes(path, "mode") then
        lfs.mkdir(path)
        print("创建目录: " .. path)
    end
end

ensure_dir("example_app")
ensure_dir("example_app/config")

-- 创建默认配置文件
print("创建默认配置文件...")
local default_config, err = ConfigFactory.create("example_app/config/default.yaml")
if not default_config then
    print("创建默认配置失败: " .. err)
    return
end

-- 设置默认配置
default_config:set_global("app_name", "AdvancedApp")
default_config:set_global("version", "2.0.0")

default_config:set("server", "host", "0.0.0.0")
default_config:set("server", "port", 8080)
default_config:set("server", "workers", 4)

default_config:set("database", "type", "mysql")
default_config:set("database", "host", "localhost")
default_config:set("database", "port", 3306)
default_config:set("database", "name", "app_db")
default_config:set("database", "user", "root")
default_config:set("database", "password", "")
default_config:set("database", "pool_size", 10)

default_config:set("logging", "level", "info")
default_config:set("logging", "file", "logs/app.log")
default_config:set("logging", "console", true)
default_config:set("logging", "syslog", false)

default_config:set("security", "enable_csrf", true)
default_config:set("security", "session_timeout", 3600)
default_config:set("security", "allowed_hosts", {"localhost", "127.0.0.1"})

default_config:save()
print("默认配置已保存")

-- 创建用户配置文件
print("\n创建用户配置文件...")
local user_config, err = ConfigFactory.create("example_app/config/user.ini")
if not user_config then
    print("创建用户配置失败: " .. err)
    return
end

-- 设置用户配置（只覆盖部分设置）
user_config:set_global("environment", "development")

user_config:set("server", "port", 3000)
user_config:set("server", "debug", true)

user_config:set("database", "password", "secret")
user_config:set("database", "pool_size", 5)

user_config:set("logging", "level", "debug")
user_config:set("logging", "console", true)

user_config:save()
print("用户配置已保存")

-- 应用配置管理器
local AppConfig = {}

function AppConfig.new()
    local self = {}
    
    -- 加载默认配置
    self.default_config, err = ConfigFactory.load("example_app/config/default.yaml")
    if not self.default_config then
        error("无法加载默认配置: " .. err)
    end
    
    -- 尝试加载用户配置
    self.user_config = nil
    local user_config_path = "example_app/config/user.ini"
    if lfs.attributes(user_config_path, "mode") then
        self.user_config, err = ConfigFactory.load(user_config_path)
        if not self.user_config then
            print("警告: 无法加载用户配置: " .. err)
        end
    end
    
    -- 获取配置值，优先使用用户配置
    function self:get(section, key)
        if self.user_config and self.user_config:get(section, key) ~= nil then
            return self.user_config:get(section, key)
        end
        return self.default_config:get(section, key)
    end
    
    -- 获取全局配置值，优先使用用户配置
    function self:get_global(key)
        if self.user_config and self.user_config:get_global(key) ~= nil then
            return self.user_config:get_global(key)
        end
        return self.default_config:get_global(key)
    end
    
    -- 获取合并后的所有配置
    function self:get_all()
        local result = {}
        
        -- 复制默认配置
        local default_data = self.default_config:get_all()
        for section, section_data in pairs(default_data) do
            result[section] = {}
            for key, value in pairs(section_data) do
                result[section][key] = value
            end
        end
        
        -- 覆盖用户配置
        if self.user_config then
            local user_data = self.user_config:get_all()
            for section, section_data in pairs(user_data) do
                if not result[section] then
                    result[section] = {}
                end
                for key, value in pairs(section_data) do
                    result[section][key] = value
                end
            end
        end
        
        return result
    end
    
    -- 获取合并后的全局配置
    function self:get_all_global()
        local result = {}
        
        -- 复制默认全局配置
        local default_global = self.default_config:get_global()
        for key, value in pairs(default_global) do
            result[key] = value
        end
        
        -- 覆盖用户全局配置
        if self.user_config then
            local user_global = self.user_config:get_global()
            for key, value in pairs(user_global) do
                result[key] = value
            end
        end
        
        return result
    end
    
    return self
end

-- 使用应用配置管理器
print("\n使用应用配置管理器...")
local app_config = AppConfig.new()

-- 显示合并后的配置
print("\n应用名称: " .. app_config:get_global("app_name"))
print("版本: " .. app_config:get_global("version"))
print("环境: " .. (app_config:get_global("environment") or "未设置"))

print("\n服务器配置:")
print("  主机: " .. app_config:get("server", "host"))
print("  端口: " .. app_config:get("server", "port"))
print("  工作进程: " .. app_config:get("server", "workers"))
print("  调试模式: " .. tostring(app_config:get("server", "debug") or false))

print("\n数据库配置:")
print("  类型: " .. app_config:get("database", "type"))
print("  主机: " .. app_config:get("database", "host"))
print("  端口: " .. app_config:get("database", "port"))
print("  数据库名: " .. app_config:get("database", "name"))
print("  用户: " .. app_config:get("database", "user"))
print("  密码: " .. app_config:get("database", "password"))
print("  连接池大小: " .. app_config:get("database", "pool_size"))

print("\n日志配置:")
print("  级别: " .. app_config:get("logging", "level"))
print("  文件: " .. app_config:get("logging", "file"))
print("  控制台输出: " .. tostring(app_config:get("logging", "console")))
print("  系统日志: " .. tostring(app_config:get("logging", "syslog")))

-- 模拟应用程序
print("\n模拟应用程序启动...")
print("应用 " .. app_config:get_global("app_name") .. " v" .. app_config:get_global("version") .. " 正在启动")
print("环境: " .. (app_config:get_global("environment") or "production"))
print("监听 " .. app_config:get("server", "host") .. ":" .. app_config:get("server", "port"))
print("数据库连接到 " .. app_config:get("database", "host") .. ":" .. app_config:get("database", "port") .. "/" .. app_config:get("database", "name"))
print("日志级别: " .. app_config:get("logging", "level"))

-- 清理示例文件
print("\n清理示例文件...")
os.remove("example_app/config/default.yaml")
os.remove("example_app/config/user.ini")
os.remove("example_app/config")
os.remove("example_app")
print("示例文件已删除")
print("\n高级示例运行完成")