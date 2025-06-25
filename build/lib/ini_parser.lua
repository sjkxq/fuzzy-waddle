-- ini_parser.lua
local IniParser = {}

function IniParser.parse(content)
    if not content or content == "" then
        return {}, nil
    end
    
    local config = {}
    local current_section = nil
    
    for line in content:gmatch("[^\r\n]+") do
        -- 去除前后空格
        line = line:match("^%s*(.-)%s*$")
        
        -- 跳过空行和注释行
        if line ~= "" and not line:match("^[;#]") then
            -- 检查是否是节名
            local section = line:match("^%[([^%]]+)%]$")
            if section then
                current_section = section
                config[current_section] = config[current_section] or {}
            else
                -- 解析键值对
                local key, value = line:match("^([^=]+)=(.*)$")
                if key and value then
                    key = key:match("^%s*(.-)%s*$")
                    value = value:match("^%s*(.-)%s*$")
                    
                    if current_section then
                        config[current_section][key] = value
                    else
                        config[key] = value
                    end
                end
            end
        end
    end
    
    return config, nil
end

function IniParser.stringify(config)
    if not config or type(config) ~= "table" then
        return nil, {code = 3, message = "无效的配置数据"}
    end
    
    local lines = {}
    
    -- 处理全局键值对（没有节的键值对）
    for key, value in pairs(config) do
        if type(value) ~= "table" then
            table.insert(lines, key .. "=" .. tostring(value))
        end
    end
    
    -- 如果有全局键值对，添加一个空行
    if #lines > 0 then
        table.insert(lines, "")
    end
    
    -- 处理各个节
    for section, items in pairs(config) do
        if type(items) == "table" then
            table.insert(lines, "[" .. section .. "]")
            for key, value in pairs(items) do
                table.insert(lines, key .. "=" .. tostring(value))
            end
            table.insert(lines, "")
        end
    end
    
    return table.concat(lines, "\n"), nil
end

return IniParser