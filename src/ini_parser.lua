-- ini_parser.lua
local ErrorHandler = require("error_handler")
local IniParser = {}

-- 解析 INI 格式的内容
function IniParser.parse(content)
    if not content or content == "" then
        return {}, nil
    end
    
    local data = {}
    local current_section = "__GLOBAL__"
    data[current_section] = {}
    
    -- 按行处理内容
    for line in content:gmatch("[^\r\n]+") do
        -- 去除前后空白
        line = line:match("^%s*(.-)%s*$")
        
        -- 跳过空行和注释
        if line ~= "" and not line:match("^[;#]") then
            -- 检查是否是节定义
            local section = line:match("^%[([^%]]+)%]$")
            if section then
                current_section = section
                if not data[current_section] then
                    data[current_section] = {}
                end
            else
                -- 检查是否是键值对
                local key, value = line:match("^([^=]+)=(.*)$")
                if key and value then
                    -- 去除键和值的前后空白
                    key = key:match("^%s*(.-)%s*$")
                    value = value:match("^%s*(.-)%s*$")
                    
                    -- 处理引号包裹的值
                    if value:match('^"(.*)"$') or value:match("^'(.*)'$") then
                        value = value:sub(2, -2)
                    end
                    
                    -- 尝试转换数值
                    local num_value = tonumber(value)
                    if num_value then
                        value = num_value
                    elseif value == "true" then
                        value = true
                    elseif value == "false" then
                        value = false
                    end
                    
                    data[current_section][key] = value
                end
            end
        end
    end
    
    -- 将全局键值对移动到顶层
    local result = {}
    for section, section_data in pairs(data) do
        if section == "__GLOBAL__" then
            for k, v in pairs(section_data) do
                result[k] = v
            end
        else
            result[section] = section_data
        end
    end
    
    return result, nil
end

-- 获取配置中的所有节名
function IniParser.get_sections(data)
    if type(data) ~= "table" then
        return nil, 302  -- 无效输入错误代码
    end
    
    local sections = {}
    for key, value in pairs(data) do
        if type(value) == "table" then
            table.insert(sections, key)
        end
    end
    return sections
end

-- 序列化数据为 INI 格式
function IniParser.serialize(data)
    if type(data) ~= "table" then
        return nil, 302  -- 无效输入错误代码
    end
    
    local lines = {}
    local global_keys = {}
    
    -- 收集全局键值对
    for key, value in pairs(data) do
        if type(value) ~= "table" then
            table.insert(global_keys, key)
        end
    end
    
    -- 处理全局配置项
    for _, key in ipairs(global_keys) do
        local value = data[key]
        -- 转换值为字符串
        local str_value = tostring(value)
        
        -- 如果值包含空格，用引号包裹
        if str_value:match("%s") then
            str_value = '"' .. str_value .. '"'
        end
        
        table.insert(lines, key .. "=" .. str_value)
    end
    
    -- 如果有全局配置项，添加一个空行
    if #global_keys > 0 then
        table.insert(lines, "")
    end
    
    -- 处理各节配置项
    for section, section_data in pairs(data) do
        if type(section_data) == "table" then
            table.insert(lines, "[" .. section .. "]")
            
            for key, value in pairs(section_data) do
                -- 转换值为字符串
                local str_value = tostring(value)
                
                -- 如果值包含空格，用引号包裹
                if str_value:match("%s") then
                    str_value = '"' .. str_value .. '"'
                end
                
                table.insert(lines, key .. "=" .. str_value)
            end
            
            -- 在节之间添加一个空行
            table.insert(lines, "")
        end
    end
    
    -- 移除最后一个空行
    if #lines > 0 and lines[#lines] == "" then
        table.remove(lines)
    end
    
    return table.concat(lines, "\n"), nil
end

-- 显式定义 stringify 方法
function IniParser.stringify(data)
    return IniParser.serialize(data)
end

return IniParser