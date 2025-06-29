# Lua 配置库

这是一个用于 Lua 的配置文件处理库，支持 INI 和 YAML 格式的配置文件。

## 特性

- 支持 INI 和 YAML 格式的配置文件
- 提供统一的 API 接口
- 支持配置文件格式转换
- 支持全局配置和分段配置
- 跟踪配置修改状态
- 提供完整的测试覆盖

## 安装

```bash
luarocks install lua-config-lib
```

## 依赖

- Lua 5.1+ 或 LuaJIT
- [LuaFileSystem](https://github.com/keplerproject/luafilesystem) (用于测试)
- [lyaml](https://github.com/gvvaughan/lyaml) (用于 YAML 支持)

## 使用方法

### 使用配置工厂

配置工厂会根据文件扩展名自动选择合适的配置处理器：

```lua
local ConfigFactory = require("config_factory")

-- 创建新的配置文件
local config, err = ConfigFactory.create("config.ini")
if not config then
    print("创建配置失败: " .. err)
    return
end

-- 设置配置值
config:set("app", "name", "MyApp")
config:set("app", "version", "1.0.0")
config:set("database", "host", "localhost")
config:set("database", "port", 3306)

-- 设置全局配置
config:set_global("debug", true)

-- 保存配置
local success, err = config:save()
if not success then
    print("保存配置失败: " .. err)
    return
end

-- 加载配置文件
local config, err = ConfigFactory.load("config.ini")
if not config then
    print("加载配置失败: " .. err)
    return
end

-- 获取配置值
local app_name = config:get("app", "name")
local db_host = config:get("database", "host")
local debug_mode = config:get_global("debug")

print("应用名称: " .. app_name)
print("数据库主机: " .. db_host)
print("调试模式: " .. tostring(debug_mode))

-- 获取整个部分
local app_section = config:get("app")
print("应用版本: " .. app_section.version)

-- 获取所有配置
local all_config = config:get_all()
for section, section_data in pairs(all_config) do
    print("部分: " .. section)
    for key, value in pairs(section_data) do
        print("  " .. key .. " = " .. tostring(value))
    end
end

-- 删除配置
config:delete("database", "port")  -- 删除特定键
config:delete("app")  -- 删除整个部分

-- 转换配置文件格式
local success, err = ConfigFactory.convert("config.ini", "config.yaml")
if not success then
    print("转换配置失败: " .. err)
    return
end
```

### 直接使用特定格式的配置处理器

如果你确定要使用特定格式的配置文件，可以直接使用相应的配置处理器：

```lua
-- INI 格式
local ConfigHandler = require("config_handler")
local ini_config = ConfigHandler.create("config.ini")

-- YAML 格式
local YamlConfigHandler = require("yaml_config_handler")
local yaml_config = YamlConfigHandler.create("config.yaml")
```

## API 参考

### ConfigFactory

- `ConfigFactory.create(file_path)` - 根据文件扩展名创建合适的配置处理器
- `ConfigFactory.load(file_path)` - 根据文件扩展名加载配置文件
- `ConfigFactory.convert(source_file, target_file)` - 将配置从一种格式转换为另一种格式

### ConfigHandler / YamlConfigHandler

- `create(file_path)` - 创建新的配置处理器
- `load(file_path)` - 从文件加载配置
- `save()` - 保存配置到文件
- `get(section, key)` - 获取配置值
- `set(section, key, value)` - 设置配置值
- `delete(section, key)` - 删除配置
- `get_all()` - 获取所有配置数据
- `set_global(key, value)` - 设置全局配置值
- `get_global(key)` - 获取全局配置值
- `is_modified()` - 检查是否已修改
- `reset_modified()` - 重置修改状态

## 格式比较

### INI 格式

INI 格式简单易读，适合简单的配置需求：

```ini
[app]
name=MyApp
version=1.0.0

[database]
host=localhost
port=3306
```

### YAML 格式

YAML 格式支持更复杂的数据结构，适合复杂的配置需求：

```yaml
_global:
  debug: true

app:
  name: MyApp
  version: 1.0.0

database:
  host: localhost
  port: 3306
  credentials:
    username: user
    password: pass
```