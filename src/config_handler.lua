-- config_handler.lua
local FileUtils = require("src.file_utils")
local IniParser = require("src.ini_parser")
local ConfigData = require("src.config_data")

local ConfigHandler = {}

-- 特殊节名，用于存储全局配置
local GLOBAL_SECTION = "_global"

function ConfigHandler.load(file_path)
    local content, err = FileUtils.read_file(file_path)
    if err then
        return nil, err
    end
    
    local config_table, parse_err = IniParser.parse(content)
    if parse_err then
        return nil, parse_err
    end
    
    -- 处理全局配置项（顶层键值对）
    local processed_config = {}
    processed_config[GLOBAL_SECTION] = {}
    
    for key, value in pairs(config_table) do
        if type(value) == "table" then
            -- 这是一个节
            processed_config[key] = value
        else
            -- 这是一个全局配置项
            processed_config[GLOBAL_SECTION][key] = value
        end
    end
    
    local config_data = ConfigData.new(processed_config)
    
    local instance = {
        file_path = file_path,
        config_data = config_data
    }
    
    setmetatable(instance, {__index = ConfigHandler})
    return instance, nil
end

function ConfigHandler.create(file_path)
    local config_data = ConfigData.new({})
    
    local instance = {
        file_path = file_path,
        config_data = config_data
    }
    
    setmetatable(instance, {__index = ConfigHandler})
    return instance, nil
end

function ConfigHandler:save()
    if not self.config_data:is_modified() then
        return true, nil  -- 没有修改，无需保存
    end
    
    local config_data = self.config_data:get_all()
    local output_config = {}
    
    -- 处理全局配置项（特殊节中的键值对）
    local global_section = config_data[GLOBAL_SECTION]
    if global_section then
        for key, value in pairs(global_section) do
            output_config[key] = value
        end
    end
    
    -- 复制其他节
    for section, values in pairs(config_data) do
        if section ~= GLOBAL_SECTION then
            output_config[section] = values
        end
    end
    
    local content, stringify_err = IniParser.stringify(output_config)
    if stringify_err then
        return false, stringify_err
    end
    
    local success, write_err = FileUtils.write_file(self.file_path, content)
    if write_err then
        return false, write_err
    end
    
    self.config_data:reset_modified()
    return true, nil
end

function ConfigHandler:get(section, key)
    return self.config_data:get(section, key)
end

function ConfigHandler:set(section, key, value)
    return self.config_data:set(section, key, value)
end

-- 获取全局配置项
function ConfigHandler:get_global(key)
    return self.config_data:get(GLOBAL_SECTION, key)
end

-- 设置全局配置项
function ConfigHandler:set_global(key, value)
    return self.config_data:set(GLOBAL_SECTION, key, value)
end

function ConfigHandler:delete(section, key)
    return self.config_data:delete(section, key)
end

function ConfigHandler:get_all()
    return self.config_data:get_all()
end

function ConfigHandler:is_modified()
    return self.config_data:is_modified()
end

function ConfigHandler:reset_modified()
    return self.config_data:reset_modified()
end

return ConfigHandler