local FileUtils = require("file_utils")
local ConfigData = require("config_data")
local IniParser = require("ini_parser")
local ErrorHandler = require("error_handler")

-- 尝试加载 JSON 和 YAML 解析器
local JsonParser, YamlParser
local has_json, json_err = pcall(function() JsonParser = require("json_parser") end)
local has_yaml, yaml_err = pcall(function() YamlParser = require("yaml_parser") end)

local ConfigHandler = {
    _instances = {}
}

-- 根据文件扩展名确定配置格式
local function get_format_from_path(file_path)
    if type(file_path) ~= "string" then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.INVALID_ARGUMENT,
            "文件路径必须是字符串"
        )
    end
    
    local ext = file_path:match("%.([^%.]+)$")
    if not ext then
        return "ini" -- 没有扩展名，默认为 INI
    end
    
    ext = ext:lower()
    
    if ext == "json" then
        return "json"
    elseif ext == "yml" or ext == "yaml" then
        return "yaml"
    else
        return "ini" -- 默认为 INI
    end
end

-- 创建一个新的配置处理器实例
function ConfigHandler.create(file_path, format)
    -- 参数验证
    if not file_path then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            "未提供文件路径"
        )
    end

    -- 获取文件格式
    local file_format, format_err
    if format then
        file_format = format:lower()
    else
        file_format, format_err = get_format_from_path(file_path)
        if format_err then
            return nil, format_err
        end
    end

    -- 检查格式支持
    if file_format == "json" and not has_json then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
            "json"
        )
    elseif (file_format == "yaml" or file_format == "yml") and not has_yaml then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
            "yaml"
        )
    end

    local instance = {
        file_path = file_path,
        format = file_format,
        config = ConfigData.new({}, file_format)
    }
    
    -- 添加实例方法
    instance.load = function(self)
        local config, err = ConfigHandler.load(self.file_path, self.format)
        if not config then
            return false, err
        end
        self.config = config
        return true
    end
    
    instance.save = function(self)
        if not self.config:is_modified() then
            return true -- 没有修改，不需要保存
        end
        return ConfigHandler.save(self.config, self.file_path)
    end
    
    instance.get = function(self, section, key)
        return self.config:get(section, key)
    end
    
    instance.set = function(self, section, key, value)
        return self.config:set(section, key, value)
    end
    
    instance.delete = function(self, section, key)
        return self.config:delete(section, key)
    end
    
    instance.get_all = function(self)
        return self.config:get_all()
    end
    
    instance.get_global = function(self, key)
        return self.config:get_global(key)
    end
    
    instance.set_global = function(self, key, value)
        return self.config:set_global(key, value)
    end

    instance.is_modified = function(self)
        return self.config:is_modified()
    end

    instance.reset_modified = function(self)
        return self.config:reset_modified()
    end

    instance.get_format = function(self)
        return self.format
    end
    
    -- 存储实例
    table.insert(ConfigHandler._instances, instance)
    
    return instance
end

-- 加载配置文件
function ConfigHandler.load(file_path, format)
    -- 参数验证
    if not file_path then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            "未提供文件路径"
        )
    end
    
    -- 检查文件是否存在
    local exists, err = FileUtils.file_exists(file_path)
    if not exists then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            file_path
        )
    end
    
    -- 读取文件内容
    local content, read_err = FileUtils.read_file(file_path)
    if not content then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_READ_ERROR,
            read_err.message or "未知错误"
        )
    end
    
    -- 获取文件格式
    local file_format = format or get_format_from_path(file_path)
    local data, parse_err
    
    -- 根据格式解析内容
    if file_format == "json" then
        if not has_json then
            return nil, ErrorHandler.new_error(
                ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
                "json"
            )
        end
        data, parse_err = JsonParser.parse(content)
    elseif file_format == "yaml" or file_format == "yml" then
        if not has_yaml then
            return nil, ErrorHandler.new_error(
                ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
                "yaml"
            )
        end
        data, parse_err = YamlParser.parse(content)
    else -- ini
        data, parse_err = IniParser.parse(content)
    end
    
    if not data then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.PARSE_ERROR,
            parse_err.message or "未知错误"
        )
    end
    
    -- 创建配置数据对象
    local config = ConfigData.new(data, file_format)
    config:reset_modified()
    
    return config
end

-- 保存配置到文件
function ConfigHandler.save(config, file_path)
    -- 参数验证
    if not config then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.INVALID_CONFIG_DATA,
            "未提供配置数据"
        )
    end
    
    if not file_path then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            "未提供文件路径"
        )
    end
    
    -- 获取配置格式
    local format = config:get_format()
    if not format then
        -- 根据文件扩展名确定格式
        format = get_format_from_path(file_path)
    end
    
    local content, serialize_err
    
    -- 根据格式序列化内容
    if format == "json" then
        if not has_json then
            return false, ErrorHandler.new_error(
                ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
                "json"
            )
        end
        content, serialize_err = JsonParser.serialize(config.data)
    elseif format == "yaml" or format == "yml" then
        if not has_yaml then
            return false, ErrorHandler.new_error(
                ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
                "yaml"
            )
        end
        content, serialize_err = YamlParser.serialize(config.data)
    else -- ini
        content, serialize_err = IniParser.serialize(config.data)
    end
    
    if not content then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.SERIALIZE_ERROR,
            serialize_err.message or "未知错误"
        )
    end
    
    -- 写入文件
    local success, write_err = FileUtils.write_file(file_path, content)
    if not success then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_WRITE_ERROR,
            write_err.message or "未知错误"
        )
    end
    
    -- 重置修改标志
    config:reset_modified()
    
    return true
end

return ConfigHandler