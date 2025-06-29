-- config_data.lua
local ConfigData = {}
local ErrorHandler = require("error_handler")

function ConfigData.new(data, format)
    local instance = {
        data = data or {},
        modified = false,
        format = format or "ini" -- 默认格式为 INI
    }
    
    setmetatable(instance, {__index = ConfigData})
    return instance
end

function ConfigData:get(section, key)
    if not section then
        return nil, {code = 4, message = "未提供节名"}
    end
    
    if not key then
        return self.data[section]
    end
    
    if not self.data[section] then
        return nil
    end
    
    return self.data[section][key]
end

function ConfigData:set(section, key, value)
    if not section then
        return false, {code = 4, message = "未提供节名"}
    end
    
    if not key then
        return false, {code = 5, message = "未提供键名"}
    end
    
    self.data[section] = self.data[section] or {}
    self.data[section][key] = value
    self.modified = true
    
    return true, nil
end

function ConfigData:delete(section, key)
    if not section then
        return false, {code = 4, message = "未提供节名"}
    end
    
    if not self.data[section] then
        return false, {code = 6, message = "节不存在"}
    end
    
    if not key then
        self.data[section] = nil
    else
        if not self.data[section][key] then
            return false, {code = 7, message = "键不存在"}
        end
        self.data[section][key] = nil
    end
    
    self.modified = true
    return true, nil
end

function ConfigData:get_all()
    return self.data
end

function ConfigData:is_modified()
    return self.modified
end

function ConfigData:reset_modified()
    self.modified = false
end

function ConfigData:get_global(key)
    return self:get("__GLOBAL__", key)
end

function ConfigData:set_global(key, value)
    if not key then
        return false, {code = 5, message = "未提供键名"}
    end
    
    return self:set("__GLOBAL__", key, value)
end

-- 获取当前配置格式
function ConfigData:get_format()
    return self.format
end

-- 获取所有节名
function ConfigData:get_sections()
    local sections = {}
    for section, _ in pairs(self.data) do
        table.insert(sections, section)
    end
    return sections
end

-- 获取指定节的所有键
function ConfigData:get_keys(section)
    if type(self.data) ~= "table" then
        return {}
    end
    if not self.data[section] then
        return {}
    end
    if type(self.data[section]) ~= "table" then
        return {}
    end
    local keys = {}
    for key, _ in pairs(self.data[section]) do
        table.insert(keys, key)
    end
    return keys
end

-- 转换配置到其他格式
function ConfigData:convert_to(new_format)
    if not new_format then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.INVALID_CONFIG_DATA,
            "未提供目标格式"
        )
    end
    
    -- 检查格式是否支持
    local supported_formats = {ini = true, json = true, yaml = true}
    if not supported_formats[new_format:lower()] then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
            "不支持的配置格式: " .. new_format
        )
    end
    
    -- 如果格式相同，无需转换
    if new_format:lower() == self.format:lower() then
        return true
    end
    
    self.format = new_format:lower()
    self.modified = true
    
    return true
end

return ConfigData