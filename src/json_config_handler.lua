local JsonParser = require("json_parser")

-- JSON配置处理器
local JsonConfigHandler = {}

-- 错误代码定义
local ERROR_CODES = {
    INVALID_FILE_PATH = 101,
    LOAD_FAILED = 104,
    SAVE_FAILED = 106,
    INVALID_DATA = 302
}

-- 创建新的JSON配置处理器
function JsonConfigHandler.create(file_path)
    if not file_path then
        return nil, ERROR_CODES.INVALID_FILE_PATH
    end
    
    local handler = {
        file_path = file_path,
        format = "json",
        data = {},
        modified = false
    }
    
    return setmetatable(handler, { __index = JsonConfigHandler })
end

-- 从文件加载JSON配置
function JsonConfigHandler.load(file_path)
    if not file_path then
        return nil, ERROR_CODES.INVALID_FILE_PATH
    end
    
    local file = io.open(file_path, "r")
    if not file then
        return nil, ERROR_CODES.LOAD_FAILED
    end
    
    local content = file:read("*a")
    file:close()
    
    local data, err = JsonParser.parse(content)
    if not data then
        return nil, err or ERROR_CODES.LOAD_FAILED
    end
    
    local handler = {
        file_path = file_path,
        format = "json",
        data = data,
        modified = false
    }
    
    return setmetatable(handler, { __index = JsonConfigHandler })
end

-- 保存JSON配置到文件
function JsonConfigHandler.save(self)
    if not self.file_path then
        return nil, ERROR_CODES.INVALID_FILE_PATH
    end
    
    local json_str, err = JsonParser.serialize(self.data)
    if not json_str then
        return nil, err or ERROR_CODES.SAVE_FAILED
    end
    
    local file = io.open(self.file_path, "w")
    if not file then
        return nil, ERROR_CODES.SAVE_FAILED
    end
    
    file:write(json_str)
    file:close()
    self.modified = false
    
    return true
end

-- 获取配置值
function JsonConfigHandler.get(self, key)
    return self.data[key]
end

-- 设置配置值
function JsonConfigHandler.set(self, key, value)
    self.data[key] = value
    self.modified = true
    return true
end

-- 获取所有配置
function JsonConfigHandler.get_all(self)
    return self.data
end

-- 获取全局配置值
function JsonConfigHandler.get_global(self)
    return self.data
end

-- 设置全局配置值
function JsonConfigHandler.set_global(self, value)
    if type(value) ~= "table" then
        return nil, ERROR_CODES.INVALID_DATA
    end
    self.data = value
    self.modified = true
    return true
end

-- 检查配置是否被修改
function JsonConfigHandler.is_modified(self)
    return self.modified
end

-- 重置修改标志
function JsonConfigHandler.reset_modified(self)
    self.modified = false
    return true
end

-- 获取配置格式
function JsonConfigHandler.get_format(self)
    return self.format
end

return JsonConfigHandler