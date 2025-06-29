 -- json_parser.lua
local ErrorHandler = require("error_handler")
local JsonParser = {}

-- JSON 词法分析器
local function tokenize(str)
    local tokens = {}
    local pos = 1
    local len = #str
    
    while pos <= len do
        local c = str:sub(pos, pos)
        
        -- 跳过空白字符
        if c:match("%s") then
            pos = pos + 1
        -- 处理数字
        elseif c:match("[%d%-]") then
            local num = ""
            while pos <= len do
                c = str:sub(pos, pos)
                if c:match("[%d%.eE%-%+]") then
                    num = num .. c
                    pos = pos + 1
                else
                    break
                end
            end
            table.insert(tokens, {type = "number", value = tonumber(num)})
        -- 处理字符串
        elseif c == '"' then
            local str_value = ""
            pos = pos + 1
            while pos <= len do
                c = str:sub(pos, pos)
                if c == '"' and str:sub(pos-1, pos-1) ~= "\\" then
                    break
                end
                str_value = str_value .. c
                pos = pos + 1
            end
            pos = pos + 1
            -- 处理转义字符
            str_value = str_value:gsub("\\\"", "\"")
                                :gsub("\\\\", "\\")
                                :gsub("\\/", "/")
                                :gsub("\\b", "\b")
                                :gsub("\\f", "\f")
                                :gsub("\\n", "\n")
                                :gsub("\\r", "\r")
                                :gsub("\\t", "\t")
            table.insert(tokens, {type = "string", value = str_value})
        -- 处理特殊值和标点符号
        else
            if c:match("[{%[%]}:,]") then
                table.insert(tokens, {type = "punct", value = c})
                pos = pos + 1
            elseif str:sub(pos, pos + 3) == "true" then
                table.insert(tokens, {type = "boolean", value = true})
                pos = pos + 4
            elseif str:sub(pos, pos + 4) == "false" then
                table.insert(tokens, {type = "boolean", value = false})
                pos = pos + 5
            elseif str:sub(pos, pos + 3) == "null" then
                table.insert(tokens, {type = "null", value = nil})
                pos = pos + 4
            else
                return nil, "无效的JSON字符"
            end
        end
    end
    
    return tokens
end

-- 解析 JSON 数组
local function parse_array(tokens, pos)
    local array = {}
    pos = pos + 1 -- 跳过 '['
    
    while pos <= #tokens do
        local token = tokens[pos]
        if token.type == "punct" and token.value == "]" then
            return array, pos + 1
        end
        
        local value, new_pos = JsonParser.parse_value(tokens, pos)
        if not value then
            return nil, new_pos
        end
        
        table.insert(array, value)
        pos = new_pos
        
        token = tokens[pos]
        if token.type == "punct" then
            if token.value == "," then
                pos = pos + 1
            elseif token.value == "]" then
                return array, pos + 1
            else
                return nil, 301  -- JSON解析错误代码
            end
        end
    end
    
    return nil, 301  -- JSON解析错误代码
end

-- 解析 JSON 对象
local function parse_object(tokens, pos)
    local obj = {}
    pos = pos + 1 -- 跳过 '{'
    
    while pos <= #tokens do
        local token = tokens[pos]
        if token.type == "punct" and token.value == "}" then
            return obj, pos + 1
        end
        
        if token.type ~= "string" then
            return nil, 301  -- JSON解析错误代码
        end
        
        local key = token.value
        pos = pos + 1
        
        token = tokens[pos]
        if token.type ~= "punct" or token.value ~= ":" then
            return nil, 301  -- JSON解析错误代码
        end
        pos = pos + 1
        
        local value, new_pos = JsonParser.parse_value(tokens, pos)
        if not value then
            return nil, new_pos
        end
        
        obj[key] = value
        pos = new_pos
        
        token = tokens[pos]
        if token.type == "punct" then
            if token.value == "," then
                pos = pos + 1
            elseif token.value == "}" then
                return obj, pos + 1
            else
                return nil, 301  -- JSON解析错误代码
            end
        end
    end
    
    return nil, 301  -- JSON解析错误代码
end

-- 解析 JSON 值
function JsonParser.parse_value(tokens, pos)
    local token = tokens[pos]
    
    if not token then
        return nil, 301  -- JSON解析错误代码
    end

    if token.type == "string" or token.type == "number" or 
       token.type == "boolean" then
        return token.value, pos + 1
    elseif token.type == "null" then
        return nil, pos + 1
    elseif token.type == "punct" then
        if token.value == "[" then
            return parse_array(tokens, pos)
        elseif token.value == "{" then
            return parse_object(tokens, pos)
        end
    end
    
    return nil, 301  -- JSON解析错误代码
end

-- 保持局部引用用于内部调用
local parse_value = JsonParser.parse_value

-- 解析 JSON 字符串
function JsonParser.parse(content)
    if not content or content == "" then
        return nil, 302  -- 无效输入错误代码
    end
    
    local tokens, err = tokenize(content)
    if not tokens then
        return nil, err.code or 301  -- JSON解析错误代码
    end
    
    local value, pos = parse_value(tokens, 1)
    if not value then
        return nil, pos
    end
    
    if pos <= #tokens then
        return nil, 301  -- JSON解析错误代码
    end
    
    return value
end

-- 序列化值为 JSON 字符串
local function serialize_value(value)
    local t = type(value)
    
    if t == "string" then
        local success, result = pcall(function()
            return '"' .. value:gsub('[\\"/%c]', {
                ['"'] = '\\"',
                ['\\'] = '\\\\',
                ['/'] = '\\/',
                ['\b'] = '\\b',
                ['\f'] = '\\f',
                ['\n'] = '\\n',
                ['\r'] = '\\r',
                ['\t'] = '\\t'
            }) .. '"'
        end)
        if not success then
            return nil, 301  -- JSON序列化错误代码
        end
        return result
    elseif t == "number" then
        return tostring(value)
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "nil" then
        return "null"
    elseif t == "table" then
        -- 检查是否是数组
        local is_array = true
        local max_index = 0
        
        -- 如果表为空，视为对象
        if next(value) == nil then
            is_array = false
        else
            for k, _ in pairs(value) do
                if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                    is_array = false
                    break
                end
                max_index = math.max(max_index, k)
            end
            
            -- 如果最大索引远大于表的长度，可能不是数组
            if max_index > 2 * #value then
                is_array = false
            end
        end
        
        if is_array then
            local parts = {}
            for i = 1, max_index do
                local val = value[i]
                if val == nil then
                    table.insert(parts, "null")
                else
                    local serialized, err = serialize_value(val)
                    if not serialized then
                        return nil, err
                    end
                    table.insert(parts, serialized)
                end
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            for k, v in pairs(value) do
                if type(k) == "string" then
                    local serialized_key, err = serialize_value(k)
                    if not serialized_key then
                        return nil, err
                    end
                    
                    local serialized_value, err = serialize_value(v)
                    if not serialized_value then
                        return nil, err
                    end
                    
                    table.insert(parts, serialized_key .. ":" .. serialized_value)
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    
    return nil, 302  -- 无效输入错误代码
end

-- 序列化数据为 JSON 格式
function JsonParser.serialize(data)
    if type(data) ~= "table" then
        return nil, 302  -- 无效输入错误代码
    end
    
    local success, result = pcall(serialize_value, data)
    if not success then
        return nil, 301  -- JSON序列化错误代码
    end
    return result
end

-- 添加 stringify 方法作为 serialize 方法的别名
JsonParser.stringify = JsonParser.serialize

return JsonParser