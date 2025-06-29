-- create_temp_files.lua
-- 用于测试的临时文件管理工具

local FileUtils = require("file_utils")

local M = {}

-- 确保目录存在
function M.ensure_directory(dir_path)
    if not FileUtils.directory_exists(dir_path) then
        os.execute("mkdir -p " .. dir_path)
    end
end

-- 创建所有测试用的临时文件
function M.create_all_temp_files()
    -- INI 测试文件
    FileUtils.write_file("tests/fixtures/test_config.ini", [[
[__GLOBAL__]
app_name = TestApp
version = 1.0.0

[section1]
key1 = value1
key2 = value2

[section2]
key3 = value3
key4 = value4
]])

    -- JSON 测试文件
    FileUtils.write_file("tests/fixtures/test_config.json", [[
{
    "__GLOBAL__": {
        "app_name": "TestApp",
        "version": "1.0.0"
    },
    "section1": {
        "key1": "value1",
        "key2": "value2"
    },
    "section2": {
        "key3": "value3",
        "key4": "value4"
    }
}
]])

    -- YAML 测试文件
    FileUtils.write_file("tests/fixtures/test_config.yaml", [[
__GLOBAL__:
  app_name: TestApp
  version: 1.0.0
section1:
  key1: value1
  key2: value2
section2:
  key3: value3
  key4: value4
]])
end

-- 清理临时文件
function M.remove_temp_files()
    os.remove("tests/fixtures/test_config.ini")
    os.remove("tests/fixtures/test_config.json")
    os.remove("tests/fixtures/test_config.yaml")
end

return M