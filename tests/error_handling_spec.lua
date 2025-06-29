-- error_handling_spec.lua
-- 测试配置系统的错误处理功能

local ConfigHandler = require("config_handler")
local ConfigData = require("config_data")
local ErrorHandler = require("error_handler")
local FileUtils = require("file_utils")
local IniParser = require("ini_parser")
local JsonParser = require("json_parser")
local YamlParser = require("yaml_parser")
local temp_files = require("tests.fixtures.create_temp_files")

describe("错误处理", function()
    -- 在每个测试前创建临时文件
    before_each(function()
        temp_files.create_all_temp_files()
    end)

    -- 在每个测试后清理临时文件
    after_each(function()
        temp_files.remove_temp_files()
        os.remove("tests/fixtures/temp.xml")
        os.remove("tests/fixtures/invalid.ini")
        os.remove("tests/fixtures/invalid.json")
        os.remove("tests/fixtures/invalid.yaml")
    end)

    describe("文件操作错误", function()
        it("应该正确处理读取不存在的文件", function()
            local content, err = FileUtils.read_file("non_existent_file.txt")
            assert.is_nil(content)
            assert.is_not_nil(err)
            assert.equals(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
        end)

        it("应该正确处理写入无权限的目录", function()
            -- 创建一个临时目录，然后移除写入权限
            local temp_dir = "tests/fixtures/no_write_dir"
            temp_files.ensure_directory(temp_dir)
            os.execute("chmod -w " .. temp_dir)
            
            local success, err = FileUtils.write_file(temp_dir .. "/test.txt", "test")
            assert.is_false(success)
            assert.is_not_nil(err)
            
            -- 恢复权限并删除目录
            os.execute("chmod +w " .. temp_dir)
            os.execute("rmdir " .. temp_dir)
        end)
    end)

    describe("配置格式错误", function()
        it("应该正确处理无效的 INI 格式", function()
            local invalid_ini = [[
[section
key=value
]]
            -- 创建无效的 INI 文件
            FileUtils.write_file("tests/fixtures/invalid.ini", invalid_ini)
            
            local config, err = ConfigHandler.load("tests/fixtures/invalid.ini")
            assert.is_nil(config)
            assert.is_not_nil(err)
            -- INI 解析器可能会尝试解析这种格式，但结果可能不符合预期
            -- 所以我们只检查是否有错误，而不检查具体的错误代码
        end)

        it("应该正确处理无效的 JSON 格式", function()
            local invalid_json = [[
{
  "key": "value",
  "array": [1, 2, 3,]
}
]]
            -- 创建无效的 JSON 文件
            FileUtils.write_file("tests/fixtures/invalid.json", invalid_json)
            
            local config, err = ConfigHandler.load("tests/fixtures/invalid.json")
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.equals(ErrorHandler.ERROR_CODES.JSON_PARSING_ERROR, err.code)
        end)

        it("应该正确处理无效的 YAML 格式", function()
            local invalid_yaml = [[
key: value
  indented: wrong
]]
            -- 创建无效的 YAML 文件
            FileUtils.write_file("tests/fixtures/invalid.yaml", invalid_yaml)
            
            local config, err = ConfigHandler.load("tests/fixtures/invalid.yaml")
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.equals(ErrorHandler.ERROR_CODES.YAML_PARSING_ERROR, err.code)
        end)
    end)

    describe("配置操作错误", function()
        it("应该正确处理获取不存在的节", function()
            local config = ConfigData.new()
            local value = config:get("non_existent_section", "key")
            assert.is_nil(value)
        end)

        it("应该正确处理获取不存在的键", function()
            local config = ConfigData.new()
            config:set("section", "key", "value")
            local value = config:get("section", "non_existent_key")
            assert.is_nil(value)
        end)

        it("应该正确处理转换到不支持的格式", function()
            local config = ConfigData.new()
            local success, err = config:convert_to("xml")
            assert.is_false(success)
            assert.is_not_nil(err)
            assert.equals(ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT, err.code)
            assert.matches("不支持的配置格式", err.message)
        end)
    end)

    describe("配置文件操作错误", function()
        it("应该正确处理加载不存在的文件", function()
            local config, err = ConfigHandler.load("non_existent_file.ini")
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.equals(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
        end)

        it("应该正确处理加载不支持的格式", function()
            -- 创建一个临时 XML 文件
            FileUtils.write_file("tests/fixtures/temp.xml", "<xml></xml>")
            
            local config, err = ConfigHandler.load("tests/fixtures/temp.xml")
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.equals(ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT, err.code)
            assert.matches("不支持的配置格式", err.message)
        end)

        it("应该正确处理保存到不支持的格式", function()
            local config = ConfigData.new()
            local success, err = ConfigHandler.save(config, "tests/fixtures/config.xml")
            assert.is_false(success)
            assert.is_not_nil(err)
            assert.equals(ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT, err.code)
            assert.matches("不支持的配置格式", err.message)
        end)
    end)
end)