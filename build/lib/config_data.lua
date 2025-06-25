-- config_data.lua
local ConfigData = {}

function ConfigData.new(data)
    local instance = {
        data = data or {},
        modified = false
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

return ConfigData