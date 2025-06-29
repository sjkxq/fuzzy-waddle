local ConfigHandler = require("config_handler")
local ErrorHandler = require("error_handler")

local ConfigFactory = {
    _instances = {}
}

-- 创建配置处理器
function ConfigFactory.create(file_path, format)
    if not file_path then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            "未提供文件路径"
        )
    end

    -- 检查文件类型支持
    local ext = file_path:match("%.([^%.]+)$")
    if not ext then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
            "无扩展名文件"
        )
    end

    ext = ext:lower()
    if ext ~= "ini" and ext ~= "json" and ext ~= "yaml" and ext ~= "yml" then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
            ext
        )
    end

    -- 创建配置处理器实例
    local handler, err = ConfigHandler.create(file_path, format)
    if not handler then
        return nil, err
    end

    table.insert(ConfigFactory._instances, handler)
    return handler
end

-- 加载配置文件
function ConfigFactory.load(file_path)
    local handler, err = ConfigFactory.create(file_path)
    if not handler then
        return nil, err
    end

    local success, load_err = handler:load()
    if not success then
        return nil, load_err
    end

    return handler
end

-- 转换配置格式
function ConfigFactory.convert(source_path, target_path)
    -- 验证源文件
    local source_handler, err = ConfigFactory.load(source_path)
    if not source_handler then
        return nil, err
    end

    -- 验证目标文件类型
    local target_ext = target_path:match("%.([^%.]+)$")
    if not target_ext or 
       (target_ext:lower() ~= "ini" and 
        target_ext:lower() ~= "json" and 
        target_ext:lower() ~= "yaml" and 
        target_ext:lower() ~= "yml") then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT,
            target_ext or "无扩展名"
        )
    end

    -- 创建目标处理器
    local target_handler, err = ConfigFactory.create(target_path)
    if not target_handler then
        return nil, err
    end

    -- 复制配置数据
    target_handler.config.data = source_handler.config.data
    target_handler.config.modified = true

    -- 保存转换后的文件
    local success, save_err = target_handler:save()
    if not success then
        return nil, save_err
    end

    return target_handler
end

return ConfigFactory