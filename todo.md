### Lua 配置文件处理脚本详细设计文档（增量模型）

#### 1. 项目概述

本文档基于增量模型设计一个模块化的 Lua 配置文件处理脚本，采用分阶段开发策略，逐步增加功能和完善系统。该脚本将提供高效、灵活的配置文件管理能力，支持多种格式并易于扩展。


### 第一阶段：核心框架实现

#### 1.1 阶段目标

实现基本的配置文件读取、解析和访问功能，支持 INI 格式作为初始实现。

#### 1.2 功能列表

1. 文件读取与错误处理
2. INI 格式解析器
3. 基础配置数据模型
4. 简单的访问 API

#### 1.3 模块设计

##### 1.3.1 文件操作模块

```lua
-- file_utils.lua
local FileUtils = {}

function FileUtils.read_file(file_path)
    local file, err = io.open(file_path, "r")
    if not file then
        return nil, {code = 1, message = "文件打开失败: " .. err}
    end
    
    local content = file:read("*a")
    file:close()
    return content, nil
end

function FileUtils.write_file(file_path, content)
    local file, err = io.open(file_path, "w")
    if not file then
        return nil, {code = 2, message = "文件写入失败: " .. err}
    end
    
    file:write(content)
    file:close()
    return true, nil
end

return FileUtils
```

##### 1.3.2 INI 解析器模块

```lua
-- ini_parser.lua
local IniParser = {}

function IniParser.parse(content)
    local config = {}
    local current_section = nil
    
    for line in content:gmatch("[^\r\n]+") do
        line = line:gsub("^%s*(.-)%s*$", "%1") -- 去除首尾空格
        
        -- 忽略空行和注释
        if #line > 0 and not line:match("^;") then
            -- 匹配节(section)
            local section = line:match("^%[(.*)%]$")
            if section then
                config[section] = {}
                current_section = section
            else
                -- 匹配键值对
                local key, value = line:match("^([^=]+)=(.*)$")
                if key and value then
                    key = key:gsub("^%s*(.-)%s*$", "%1")
                    value = value:gsub("^%s*(.-)%s*$", "%1")
                    
                    if current_section then
                        config[current_section][key] = value
                    else
                        config[key] = value -- 全局配置项
                    end
                end
            end
        end
    end
    
    return config
end

return IniParser
```

##### 1.3.3 配置数据模型

```lua
-- config_data.lua
local ConfigData = {}

function ConfigData.new(data)
    local instance = {
        data = data or {}
    }
    setmetatable(instance, {__index = ConfigData})
    return instance
end

function ConfigData:get(key_path)
    local keys = {}
    for part in key_path:gmatch("[^%.]+") do
        table.insert(keys, part)
    end
    
    local current = self.data
    for _, key in ipairs(keys) do
        current = current[key]
        if not current then return nil end
    end
    
    return current
end

function ConfigData:set(key_path, value)
    local keys = {}
    for part in key_path:gmatch("[^%.]+") do
        table.insert(keys, part)
    end
    
    local current = self.data
    local last_key = keys[#keys]
    
    for i = 1, #keys - 1 do
        local key = keys[i]
        if not current[key] then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[last_key] = value
end

return ConfigData
```

##### 1.3.4 主 API 模块

```lua
-- config_handler.lua
local FileUtils = require("file_utils")
local IniParser = require("ini_parser")
local ConfigData = require("config_data")

local ConfigHandler = {}

function ConfigHandler.load_ini(file_path)
    local content, err = FileUtils.read_file(file_path)
    if err then return nil, err end
    
    local parsed_data = IniParser.parse(content)
    return ConfigData.new(parsed_data), nil
end

return ConfigHandler
```


### 第二阶段：格式扩展与功能增强

#### 2.1 阶段目标

扩展支持 JSON 和 YAML 格式，增加配置保存功能和错误处理机制。

#### 2.2 新增功能

1. JSON 解析器
2. YAML 解析器（依赖 lyaml 库）
3. 配置保存功能
4. 统一错误处理

#### 2.3 模块设计

##### 2.3.1 JSON 解析器

```lua
-- json_parser.lua
local JsonParser = {}
local cjson = require("cjson")

function JsonParser.parse(content)
    local success, result = pcall(function()
        return cjson.decode(content)
    end)
    
    if not success then
        return nil, {code = 101, message = "JSON 解析失败: " .. result}
    end
    
    return result, nil
end

function JsonParser.serialize(data)
    local success, result = pcall(function()
        return cjson.encode(data)
    end)
    
    if not success then
        return nil, {code = 102, message = "JSON 序列化失败: " .. result}
    end
    
    return result, nil
end

return JsonParser
```

##### 2.3.2 YAML 解析器

```lua
-- yaml_parser.lua
local YamlParser = {}
local lyaml = require("lyaml")

function YamlParser.parse(content)
    local success, result = pcall(function()
        return lyaml.load(content)
    end)
    
    if not success then
        return nil, {code = 201, message = "YAML 解析失败: " .. result}
    end
    
    return result, nil
end

function YamlParser.serialize(data)
    local success, result = pcall(function()
        return lyaml.dump({data})
    end)
    
    if not success then
        return nil, {code = 202, message = "YAML 序列化失败: " .. result}
    end
    
    return result, nil
end

return YamlParser
```

##### 2.3.3 错误处理模块

```lua
-- error_handler.lua
local ErrorHandler = {}

ErrorHandler.ERROR_CODES = {
    FILE_NOT_FOUND = 1,
    FILE_WRITE_ERROR = 2,
    INI_PARSING_ERROR = 100,
    JSON_PARSING_ERROR = 101,
    JSON_SERIALIZATION_ERROR = 102,
    YAML_PARSING_ERROR = 201,
    YAML_SERIALIZATION_ERROR = 202
}

function ErrorHandler.log_error(err)
    print(string.format("[ERROR %d] %s", err.code, err.message))
end

return ErrorHandler
```

##### 2.3.4 扩展的 API 模块

```lua
-- config_handler.lua
local FileUtils = require("file_utils")
local IniParser = require("ini_parser")
local JsonParser = require("json_parser")
local YamlParser = require("yaml_parser")
local ConfigData = require("config_data")
local ErrorHandler = require("error_handler")

local ConfigHandler = {}

-- 文件格式常量
ConfigHandler.FORMAT_INI = "ini"
ConfigHandler.FORMAT_JSON = "json"
ConfigHandler.FORMAT_YAML = "yaml"

function ConfigHandler.load(file_path, format)
    format = format or ConfigHandler.detect_format(file_path)
    
    local content, err = FileUtils.read_file(file_path)
    if err then
        ErrorHandler.log_error(err)
        return nil, err
    end
    
    local parsed_data, parse_err
    
    if format == ConfigHandler.FORMAT_INI then
        parsed_data = IniParser.parse(content)
    elseif format == ConfigHandler.FORMAT_JSON then
        parsed_data, parse_err = JsonParser.parse(content)
    elseif format == ConfigHandler.FORMAT_YAML then
        parsed_data, parse_err = YamlParser.parse(content)
    else
        parse_err = {code = 300, message = "不支持的格式: " .. format}
    end
    
    if parse_err then
        ErrorHandler.log_error(parse_err)
        return nil, parse_err
    end
    
    return ConfigData.new(parsed_data, format), nil
end

function ConfigHandler.save(config_data, file_path, format)
    format = format or config_data.format
    local serialized_data, err
    
    if format == ConfigHandler.FORMAT_INI then
        serialized_data = IniParser.serialize(config_data.data)
    elseif format == ConfigHandler.FORMAT_JSON then
        serialized_data, err = JsonParser.serialize(config_data.data)
    elseif format == ConfigHandler.FORMAT_YAML then
        serialized_data, err = YamlParser.serialize(config_data.data)
    else
        err = {code = 300, message = "不支持的格式: " .. format}
    end
    
    if err then
        ErrorHandler.log_error(err)
        return nil, err
    end
    
    return FileUtils.write_file(file_path, serialized_data)
end

function ConfigHandler.detect_format(file_path)
    local ext = file_path:match("%.([^%.]+)$")
    if ext then
        ext = ext:lower()
        if ext == "ini" then return ConfigHandler.FORMAT_INI end
        if ext == "json" then return ConfigHandler.FORMAT_JSON end
        if ext == "yaml" or ext == "yml" then return ConfigHandler.FORMAT_YAML end
    end
    return ConfigHandler.FORMAT_INI -- 默认返回INI
end

return ConfigHandler
```


### 第三阶段：高级功能与优化

#### 3.1 阶段目标

增加配置验证、加密支持和配置合并功能，优化性能和用户体验。

#### 3.2 新增功能

1. 配置验证机制
2. 敏感信息加密
3. 配置文件合并
4. 性能优化

#### 3.3 模块设计

##### 3.3.1 配置验证模块

```lua
-- config_validator.lua
local Validator = {}

function Validator.validate(config_data, schema)
    local errors = {}
    
    for key, validator in pairs(schema) do
        local value = config_data:get(key)
        
        if validator.required and value == nil then
            table.insert(errors, string.format("缺少必需配置项: %s", key))
        end
        
        if value ~= nil then
            if validator.type then
                local actual_type = type(value)
                if validator.type == "number" and actual_type == "string" then
                    -- 尝试转换为数字
                    local num = tonumber(value)
                    if not num then
                        table.insert(errors, string.format("配置项 %s 必须是数字类型", key))
                    end
                elseif actual_type ~= validator.type then
                    table.insert(errors, string.format("配置项 %s 必须是 %s 类型，实际是 %s 类型", 
                                                     key, validator.type, actual_type))
                end
            end
            
            if validator.pattern and type(value) == "string" then
                if not value:match(validator.pattern) then
                    table.insert(errors, string.format("配置项 %s 不符合格式要求", key))
                end
            end
            
            if validator.choices and type(value) ~= "table" then
                local valid = false
                for _, choice in ipairs(validator.choices) do
                    if value == choice then
                        valid = true
                        break
                    end
                end
                if not valid then
                    table.insert(errors, string.format("配置项 %s 必须是以下值之一: %s", 
                                                     key, table.concat(validator.choices, ", ")))
                end
            end
        end
    end
    
    return #errors == 0, errors
end

return Validator
```

##### 3.3.2 加密模块

```lua
-- encryption.lua
local Encryption = {}
local crypt = require("crypt") -- LuaCrypto库

Encryption.ALGORITHM = "aes-256-cbc"

function Encryption.encrypt(plain_text, key)
    local cipher = crypt.cipher(Encryption.ALGORITHM)
    local iv = crypt.random(16) -- 初始化向量
    cipher:init("encrypt", key, iv)
    local encrypted = cipher:update(plain_text) .. cipher:final()
    return crypt.hexencode(iv) .. "$" .. crypt.hexencode(encrypted)
end

function Encryption.decrypt(cipher_text, key)
    local iv_part, encrypted_part = cipher_text:match("([^$]+)%$(.*)")
    if not iv_part or not encrypted_part then
        return nil, "无效的加密格式"
    end
    
    local iv = crypt.hexdecode(iv_part)
    local encrypted = crypt.hexdecode(encrypted_part)
    
    local cipher = crypt.cipher(Encryption.ALGORITHM)
    cipher:init("decrypt", key, iv)
    return cipher:update(encrypted) .. cipher:final()
end

return Encryption
```

##### 3.3.3 配置合并模块

```lua
-- config_merger.lua
local Merger = {}

function Merger.merge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            Merger.merge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

return Merger
```

##### 3.3.4 扩展的 API 模块

```lua
-- config_handler.lua
-- ... (保留之前的代码)

local Validator = require("config_validator")
local Encryption = require("encryption")
local Merger = require("config_merger")

-- ... (在ConfigHandler中添加以下方法)

function ConfigHandler.create(format)
    return ConfigData.new({}, format or ConfigHandler.FORMAT_INI)
end

function ConfigHandler.validate(config_data, schema)
    return Validator.validate(config_data, schema)
end

function ConfigHandler.encrypt_value(value, key)
    return Encryption.encrypt(value, key)
end

function ConfigHandler.decrypt_value(cipher_text, key)
    return Encryption.decrypt(cipher_text, key)
end

function ConfigHandler.merge(base_config, override_config)
    local merged_data = Merger.merge(
        vim.deepcopy(base_config.data), 
        override_config.data
    )
    return ConfigData.new(merged_data, base_config.format)
end

return ConfigHandler
```


### 第四阶段：文档完善与测试

#### 4.1 阶段目标

完善用户文档，编写测试用例，确保系统质量和可维护性。

#### 4.2 主要任务

1. 编写用户使用指南
2. 编写 API 文档
3. 创建单元测试
4. 性能测试与优化

#### 4.3 文档示例

##### 4.3.1 用户使用指南

```markdown
# Lua 配置文件处理库使用指南

## 安装

1. 下载所有模块文件到项目目录
2. 确保依赖库已安装:
   - lua-cjson (JSON 解析)
   - lyaml (YAML 解析)
   - luacrypto (加密功能)

## 基本用法

### 加载配置文件

```lua
local Config = require("config_handler")

-- 自动检测格式
local config, err = Config.load("config.ini")
if not config then
    print("加载失败:", err.message)
    return
end

-- 指定格式
local json_config, err = Config.load("settings.json", Config.FORMAT_JSON)
```

### 访问配置项

```lua
-- 获取值
local host = config:get("database.host")
local port = config:get("database.port")

-- 设置值
config:set("database.port", 5433)
config:set("app.debug", true)
```

### 保存配置

```lua
-- 保存到原文件
config:save()

-- 保存到新文件
config:save("new_config.ini")
```

### 配置验证

```lua
local schema = {
    ["database.host"] = {required = true, type = "string"},
    ["database.port"] = {required = true, type = "number"},
    ["app.debug"] = {type = "boolean", default = false}
}

local valid, errors = Config.validate(config, schema)
if not valid then
    for _, err in ipairs(errors) do
        print("验证错误:", err)
    end
end
```

### 加密敏感信息

```lua
local secret_key = "your-secret-key"

-- 加密值
local encrypted_password = Config.encrypt_value("my-password", secret_key)
config:set("database.password", encrypted_password)

-- 解密值
local password = Config.decrypt_value(config:get("database.password"), secret_key)
```
```

##### 4.3.2 API 文档

```markdown
# API 文档

## ConfigHandler 模块

### 加载与保存

- `ConfigHandler.load(file_path, format)`
  - 加载配置文件
  - 返回: ConfigData 实例, 错误对象

- `ConfigHandler.save(config_data, file_path, format)`
  - 保存配置到文件
  - 返回: 成功/失败, 错误对象

### 创建与格式

- `ConfigHandler.create(format)`
  - 创建新配置
  - 返回: ConfigData 实例

- `ConfigHandler.detect_format(file_path)`
  - 检测文件格式
  - 返回: 格式字符串

### 配置操作

- `ConfigHandler.validate(config_data, schema)`
  - 验证配置
  - 返回: 布尔值, 错误列表

- `ConfigHandler.encrypt_value(value, key)`
  - 加密值
  - 返回: 加密后的字符串

- `ConfigHandler.decrypt_value(cipher_text, key)`
  - 解密值
  - 返回: 原始字符串

- `ConfigHandler.merge(base_config, override_config)`
  - 合并两个配置
  - 返回: 合并后的 ConfigData 实例
```


### 开发路线图

1. **第一阶段 (2周)**：完成核心框架和 INI 支持
2. **第二阶段 (3周)**：添加 JSON/YAML 支持和错误处理
3. **第三阶段 (4周)**：实现高级功能和优化
4. **第四阶段 (2周)**：文档完善和测试

这种增量式开发方法允许团队尽早交付可用功能，同时保持系统的可扩展性和可维护性。每个阶段都建立在前一阶段的基础上，确保功能的逐步完善和质量的稳定提升。