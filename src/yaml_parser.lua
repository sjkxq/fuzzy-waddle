local ErrorHandler = require("error_handler")

local YamlParser = {}

-- 解析 YAML 值
local function parse_yaml_value(value)
    if not value or value == "" then
        return nil
    end
    
    -- 移除前后空格
    value = value:match("^%s*(.-)%s*$")
    
    if value == "true" then
        return true
    elseif value == "false" then
        return false
    elseif value == "null" or value == "~" then
        return nil
    elseif tonumber(value) then
        return tonumber(value)
    else
        -- 检查是否有引号
        local quoted = value:match('^"(.*)"$') or value:match("^'(.*)'$")
        if quoted then
            -- 处理转义字符
            return quoted:gsub('\\"', '"'):gsub("\\'", "'")
        end
        -- 移除行内注释
        return value:gsub("%s*#.*$", "")
    end
end

-- 解析 YAML 格式的配置文件
function YamlParser.parse(content)
    if type(content) ~= "string" then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.INVALID_INPUT,
            "输入必须是字符串"
        )
    end

    local result = {}
    local lines = {}
    
    -- 将内容分割成行
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    -- 如果内容为空，返回空表
    if #lines == 0 then
        return {}
    end
    
    -- 跟踪当前缩进级别和路径
    local current_path = {}
    local indent_levels = {0}  -- 第一个元素是根级别的缩进（0）
    
    for i, line in ipairs(lines) do
        -- 跳过空行和注释行
        if not line:match("^%s*$") and not line:match("^%s*#") then
            -- 移除行内注释
            line = line:gsub("%s*#.*$", "")
            
            -- 获取缩进级别
            local indent = line:match("^(%s*)"):len()
            local content_line = line:match("^%s*(.+)$")
            
            if content_line then
                -- 处理键值对
                local key, value = content_line:match("^([^:]+):%s*(.*)")
                
                if key and key ~= "" then
                    -- 去除键的前后空白
                    key = key:match("^%s*(.-)%s*$")
                    
                    -- 根据缩进调整当前路径
                    while #indent_levels > 1 and indent < indent_levels[#indent_levels] do
                        table.remove(indent_levels)
                        table.remove(current_path)
                    end
                    
                    -- 检查是否是新的缩进级别
                    if indent > indent_levels[#indent_levels] then
                        -- 新的缩进级别，将上一个键添加到路径中
                        if #current_path > 0 then
                            -- 确保上一级存在
                            local parent_path = {}
                            local current_obj = result
                            
                            for j = 1, #current_path - 1 do
                                local path_key = current_path[j]
                                if not current_obj[path_key] then
                                    current_obj[path_key] = {}
                                end
                                current_obj = current_obj[path_key]
                                table.insert(parent_path, path_key)
                            end
                            
                            -- 确保当前键存在
                            local last_key = current_path[#current_path]
                            if not current_obj[last_key] then
                                current_obj[last_key] = {}
                            end
                        end
                        
                        table.insert(indent_levels, indent)
                    end
                    
                    -- 检查是否是新节
                    if value == "" or value == nil then
                        -- 创建新节
                        local new_path = {}
                        for j = 1, #current_path do
                            table.insert(new_path, current_path[j])
                        end
                        table.insert(new_path, key)
                        current_path = new_path
                        
                        -- 确保路径存在
                        local current_obj = result
                        for j = 1, #current_path - 1 do
                            local path_key = current_path[j]
                            if not current_obj[path_key] then
                                current_obj[path_key] = {}
                            end
                            current_obj = current_obj[path_key]
                        end
                        
                        -- 创建新节
                        local last_key = current_path[#current_path]
                        if not current_obj[last_key] then
                            current_obj[last_key] = {}
                        end
                    else
                        -- 处理键值对
                        local current_obj = result
                        for j = 1, #current_path do
                            local path_key = current_path[j]
                            if not current_obj[path_key] then
                                current_obj[path_key] = {}
                            end
                            current_obj = current_obj[path_key]
                        end
                        
                        -- 设置值
                        current_obj[key] = parse_yaml_value(value)
                    end
                else
                    -- 无效的 YAML 行
                    return nil, ErrorHandler.new_error(
                        ErrorHandler.ERROR_CODES.YAML_PARSING_ERROR,
                        "无效的 YAML 行: " .. content_line .. " (行 " .. i .. ")"
                    )
                end
            end
        end
    end
    
    return result
end

-- 序列化值为 YAML 格式
local function serialize_yaml_value(value, current_indent)
    local t = type(value)
    
    if t == "string" then
        -- 处理多行字符串
        if value:find("\n") then
            local indent = current_indent and string.rep("  ", current_indent + 1) or "  "
            return "|\n" .. indent .. value:gsub("\n", "\n" .. indent)
        -- 处理包含特殊字符的字符串
        elseif value:match("[:%s#{}]") or value == "true" or value == "false" or value == "null" or value == "~" then
            return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
        else
            return value
        end
    elseif t == "number" then
        return tostring(value)
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "nil" then
        return "null"
    elseif t == "table" then
        -- 表不应该在这里序列化，应该由外部函数处理
        return nil
    else
        -- 其他类型不能序列化
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.YAML_SERIALIZATION_ERROR,
            "无法序列化类型: " .. t
        )
    end
end

-- 递归序列化表为 YAML 格式
local function serialize_table(data, indent_level)
    if not indent_level then
        indent_level = 0
    end
    
    local lines = {}
    local indent = string.rep("  ", indent_level)
    
    -- 首先处理非表类型的值
    for key, value in pairs(data) do
        if type(value) ~= "table" then
            local serialized, err = serialize_yaml_value(value)
            if err then
                return nil, err
            elseif serialized == nil then
                return nil, ErrorHandler.new_error(
                    ErrorHandler.ERROR_CODES.YAML_SERIALIZATION_ERROR,
                    "无法序列化键 '" .. key .. "' 的值"
                )
            end
            table.insert(lines, indent .. key .. ": " .. serialized)
        end
    end
    
    -- 然后处理嵌套表
    for key, value in pairs(data) do
        if type(value) == "table" then
            table.insert(lines, indent .. key .. ":")
            local nested_lines, err = serialize_table(value, indent_level + 1)
            if err then
                return nil, err
            end
            for _, line in ipairs(nested_lines) do
                table.insert(lines, line)
            end
        end
    end
    
    return lines
end

-- 序列化配置为 YAML 格式
function YamlParser.serialize(data)
    if type(data) ~= "table" then
        return nil, 302  -- 无效数据错误代码
    end
    
    local lines, err = serialize_table(data)
    if err then
        return nil  -- 特殊字符处理失败返回nil
    end
    
    return table.concat(lines, "\n")
end

-- 添加 stringify 方法作为 serialize 的别名
YamlParser.stringify = YamlParser.serialize

return YamlParser