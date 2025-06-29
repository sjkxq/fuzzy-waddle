local lfs = require("lfs")
local os = require("os")

local M = {}
local temp_files = {}

function M.create_temp_config(content)
    local temp_path = os.tmpname()
    local file = io.open(temp_path, "w")
    if file then
        file:write(content or "")
        file:close()
        table.insert(temp_files, temp_path)
    end
    return temp_path
end

function M.create_all_temp_files(files)
    local paths = {}
    if files then
        for name, content in pairs(files) do
            paths[name] = M.create_temp_config(content)
        end
    else
        -- 默认创建一些测试文件
        paths["config1"] = M.create_temp_config("key1=value1")
        paths["config2"] = M.create_temp_config("key2=value2")
    end
    return paths
end

function M.remove_temp_files()
    for _, path in ipairs(temp_files) do
        os.remove(path)
    end
    temp_files = {}
end

function M.cleanup_temp_files(pattern)
    for file in lfs.dir(os.tmpdir()) do
        if file:match(pattern) then
            os.remove(os.tmpdir() .. "/" .. file)
        end
    end
end

return M