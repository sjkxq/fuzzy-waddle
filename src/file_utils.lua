-- file_utils.lua
local FileUtils = {}

function FileUtils.read_file(file_path)
    local file, err = io.open(file_path, "r")
    if not file then
        return nil, {code = 1, message = "文件打开失败: " .. err}
    end
    
    local content = file:read("*a")
    file:close()
    return content, nil
end

function FileUtils.write_file(file_path, content)
    local file, err = io.open(file_path, "w")
    if not file then
        return nil, {code = 2, message = "文件写入失败: " .. err}
    end
    
    file:write(content)
    file:close()
    return true, nil
end

return FileUtils