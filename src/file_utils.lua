local ErrorHandler = require("error_handler")

local FileUtils = {}

-- 检查文件是否存在
function FileUtils.file_exists(file_path)
    if not file_path then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            "未提供文件路径"
        )
    end
    
    local file = io.open(file_path, "r")
    if file then
        file:close()
        return true
    end
    return false, ErrorHandler.new_error(
        ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
        "找不到文件: " .. file_path
    )
end

-- 读取文件内容
function FileUtils.read_file(file_path)
    if not file_path then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            "未提供文件路径"
        )
    end
    
    local file, err = io.open(file_path, "r")
    if not file then
        return nil, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_READ_ERROR,
            "无法读取文件: " .. file_path
        )
    end
    
    local content = file:read("*a")
    file:close()
    return content
end

-- 写入文件内容
function FileUtils.write_file(file_path, content)
    if not file_path then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            "未提供文件路径"
        )
    end
    
    -- 尝试写入文件
    local file, err = io.open(file_path, "w")
    if not file then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_WRITE_ERROR,
            "无法写入文件: " .. file_path
        )
    end
    
    file:write(content)
    file:close()
    return true
end

-- 确保目录存在
function FileUtils.ensure_directory(dir_path)
    if not dir_path then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_NOT_FOUND,
            "未提供目录路径"
        )
    end
    
    -- 检查目录是否已存在
    local file = io.open(dir_path, "r")
    if file then
        file:close()
        return true
    end
    
    -- 尝试创建目录
    local success, err = pcall(function()
        os.execute("mkdir -p " .. dir_path)
    end)
    
    if not success then
        return false, ErrorHandler.new_error(
            ErrorHandler.ERROR_CODES.FILE_PERMISSION_DENIED,
            "无权限创建目录: " .. dir_path
        )
    end
    
    return true
end

return FileUtils