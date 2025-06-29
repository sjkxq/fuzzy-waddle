local yaml = require("lyaml")

-- YamlConfigHandler 类
local YamlConfigHandler = {}
YamlConfigHandler.__index = YamlConfigHandler

-- 创建新的配置处理器
function YamlConfigHandler.create(file_path)
    local self = setmetatable({}, YamlConfigHandler)
    self.file_path = file_path
    self.data = {}
    self.global = {}
    self.modified = false
    return self, nil
end

-- 从文件加载配置
function YamlConfigHandler.load(file_path)
    local file, err = io.open(file_path, "r")
    if not file then
        return nil, "无法打开文件: " .. (err or "未知错误")
    end
    
    local content = file:read("*all")
    file:close()
    
    local self = setmetatable({}, YamlConfigHandler)
    self.file_path = file_path
    self.modified = false
    
    -- 解析YAML内容
    local success, result = pcall(function()
        return yaml.load(content)
    end)
    
    if not success then
        return nil, "YAML解析错误: " .. tostring(result)
    end
    
    -- 提取全局配置和部分配置
    self.global = result._global or {}
    self.data = result
    self.data._global = nil  -- 从数据中移除全局部分
    
    return self, nil
end

-- 保存配置到文件
function YamlConfigHandler:save()
    if not self.modified then
        return true, nil
    end
    
    local file, err = io.open(self.file_path, "w")
    if not file then
        return false, "无法打开文件进行写入: " .. (err or "未知错误")
    end
    
    -- 准备要保存的数据
    local save_data = {}
    for k, v in pairs(self.data) do
        save_data[k] = v
    end
    
    -- 添加全局配置
    if next(self.global) then
        save_data._global = self.global
    end
    
    -- 转换为YAML
    local yaml_content = yaml.dump({save_data})
    
    -- 写入文件
    file:write(yaml_content)
    file:close()
    
    self.modified = false
    return true, nil
end

-- 获取配置值
function YamlConfigHandler:get(section, key)
    if not section then
        return nil
    end
    
    if not key then
        return self.data[section]
    end
    
    if not self.data[section] then
        return nil
    end
    
    return self.data[section][key]
end

-- 设置配置值
function YamlConfigHandler:set(section, key, value)
    if not section or not key then
        return false
    end
    
    if not self.data[section] then
        self.data[section] = {}
    end
    
    self.data[section][key] = value
    self.modified = true
    return true
end

-- 删除配置
function YamlConfigHandler:delete(section, key)
    if not section then
        return false
    end
    
    if not key then
        -- 删除整个部分
        if self.data[section] then
            self.data[section] = nil
            self.modified = true
            return true
        end
        return false
    end
    
    -- 删除特定键
    if self.data[section] and self.data[section][key] then
        self.data[section][key] = nil
        self.modified = true
        return true
    end
    
    return false
end

-- 获取所有配置数据
function YamlConfigHandler:get_all()
    return self.data
end

-- 设置全局配置值
function YamlConfigHandler:set_global(key, value)
    if not key then
        return false
    end
    
    self.global[key] = value
    self.modified = true
    return true
end

-- 获取全局配置值
function YamlConfigHandler:get_global(key)
    if not key then
        return self.global
    end
    
    return self.global[key]
end

-- 检查是否已修改
function YamlConfigHandler:is_modified()
    return self.modified
end

-- 重置修改状态
function YamlConfigHandler:reset_modified()
    self.modified = false
end

return YamlConfigHandler