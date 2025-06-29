-- 错误处理模块
local ErrorHandler = {}

-- 错误代码分类
ErrorHandler.ERROR_CODES = {
    -- 文件操作错误 (100-199)
    FILE_NOT_FOUND = 101,
    FILE_READ_ERROR = 102,
    FILE_WRITE_ERROR = 103,
    FILE_PERMISSION_DENIED = 104,
    
    -- 配置格式错误 (200-299)
    INVALID_FORMAT = 201,
    UNSUPPORTED_FORMAT = 202,
    PARSE_ERROR = 203,
    SERIALIZE_ERROR = 204,
    
    -- 配置数据错误 (300-399)
    INVALID_CONFIG_DATA = 301,
    MISSING_REQUIRED_FIELD = 302,
    INVALID_VALUE_TYPE = 303,
    
    -- 系统错误 (400-499)
    INTERNAL_ERROR = 401
}

-- 错误消息模板
ErrorHandler.ERROR_MESSAGES = {
    [101] = "文件未找到: %s",
    [102] = "读取文件失败: %s",
    [103] = "写入文件失败: %s",
    [104] = "无权限访问文件: %s",
    
    [201] = "无效的文件格式: %s",
    [202] = "不支持的文件类型: %s",
    [203] = "解析错误: %s",
    [204] = "序列化错误: %s",
    
    [301] = "无效的配置数据: %s",
    [302] = "缺少必填字段: %s",
    [303] = "值类型无效: %s",
    
    [401] = "内部错误: %s"
}

-- 创建新错误对象
function ErrorHandler.new_error(code, message)
    if not ErrorHandler.ERROR_CODES[code] and not ErrorHandler.ERROR_MESSAGES[code] then
        code = ErrorHandler.ERROR_CODES.INTERNAL_ERROR
        message = string.format(ErrorHandler.ERROR_MESSAGES[code], "无效的错误代码")
    end
    
    return {
        code = type(code) == "string" and ErrorHandler.ERROR_CODES[code] or code,
        message = message or string.format(ErrorHandler.ERROR_MESSAGES[code], "未知错误")
    }
end

-- 格式化错误消息
function ErrorHandler.format_error(code, ...)
    local message_template = ErrorHandler.ERROR_MESSAGES[code]
    if not message_template then
        code = ErrorHandler.ERROR_CODES.INTERNAL_ERROR
        message_template = ErrorHandler.ERROR_MESSAGES[code]
    end
    
    return string.format(message_template, ...)
end

-- 检查是否为错误对象
function ErrorHandler.is_error(obj)
    return type(obj) == "table" and obj.code and obj.message
end

return ErrorHandler