-- config_formats_spec.lua
-- 测试配置格式支持

local ConfigHandler = require("config_handler")
local ErrorHandler = require("error_handler")
local FileUtils = require("file_utils")
local temp_files = require("tests.fixtures.create_temp_files")

describe("配置格式支持", function()
    -- 在每个测试前创建临时文件
    before_each(function()
        temp_files.create_all_temp_files()
    end)

    -- 在每个测试后清理临时文件
    after_each(function()
        temp_files.remove_temp_files()
    end)

    describe("INI 格式", function()
        it("应该能正确加载和解析 INI 文件", function()
            local config = ConfigHandler.load("tests/fixtures/test_config.ini")
            assert.is_not_nil(config, "配置加载失败")
            
            -- 验证配置内容
            local app_name = config:get("__GLOBAL__", "app_name")
            local version = config:get("__GLOBAL__", "version")
            
            assert.equals("TestApp", app_name)
            assert.equals("1.0.0", version)
        end)

        it("应该能正确写入 INI 文件", function()
            local config = ConfigHandler.new()
            config:set("__GLOBAL__", "app_name", "TestApp")
            config:set("__GLOBAL__", "version", "1.0.0")
            
            local success = ConfigHandler.save(config, "tests/fixtures/temp_config.ini")
            assert.is_true(success, "配置保存失败")
            
            -- 验证写入的文件
            local loaded_config = ConfigHandler.load("tests/fixtures/temp_config.ini")
            assert.is_not_nil(loaded_config, "无法加载保存的配置")
            assert.equals("TestApp", loaded_config:get("__GLOBAL__", "app_name"))
        end)
    end)

    describe("JSON 格式", function()
        it("应该能正确加载和解析 JSON 文件", function()
            local config = ConfigHandler.load("tests/fixtures/test_config.json")
            assert.is_not_nil(config, "配置加载失败")
            
            -- 验证配置内容
            local app_name = config:get("__GLOBAL__", "app_name")
            local version = config:get("__GLOBAL__", "version")
            
            assert.equals("TestApp", app_name)
            assert.equals("1.0.0", version)
        end)

        it("应该能正确写入 JSON 文件", function()
            local config = ConfigHandler.new()
            config:set("__GLOBAL__", "app_name", "TestApp")
            config:set("__GLOBAL__", "version", "1.0.0")
            
            config:convert_to("json")
            local success = ConfigHandler.save(config, "tests/fixtures/temp_config.json")
            assert.is_true(success, "配置保存失败")
            
            -- 验证写入的文件
            local loaded_config = ConfigHandler.load("tests/fixtures/temp_config.json")
            assert.is_not_nil(loaded_config, "无法加载保存的配置")
            assert.equals("TestApp", loaded_config:get("__GLOBAL__", "app_name"))
        end)
    end)

    describe("YAML 格式", function()
        it("应该能正确加载和解析 YAML 文件", function()
            local config = ConfigHandler.load("tests/fixtures/test_config.yaml")
            assert.is_not_nil(config, "配置加载失败")
            
            -- 验证配置内容
            local app_name = config:get("__GLOBAL__", "app_name")
            local version = config:get("__GLOBAL__", "version")
            
            assert.equals("TestApp", app_name)
            assert.equals("1.0.0", version)
        end)

        it("应该能正确写入 YAML 文件", function()
            local config = ConfigHandler.new()
            config:set("__GLOBAL__", "app_name", "TestApp")
            config:set("__GLOBAL__", "version", "1.0.0")
            
            config:convert_to("yaml")
            local success = ConfigHandler.save(config, "tests/fixtures/temp_config.yaml")
            assert.is_true(success, "配置保存失败")
            
            -- 验证写入的文件
            local loaded_config = ConfigHandler.load("tests/fixtures/temp_config.yaml")
            assert.is_not_nil(loaded_config, "无法加载保存的配置")
            assert.equals("TestApp", loaded_config:get("__GLOBAL__", "app_name"))
        end)
    end)

    describe("错误处理", function()
        it("应该正确处理不存在的文件", function()
            local config, err = ConfigHandler.load("non_existent.ini")
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.matches("找不到文件", err.message)
        end)

        it("应该正确处理格式错误的文件", function()
            -- 创建格式错误的文件
            local invalid_content = "这不是一个有效的配置文件"
            FileUtils.write_file("tests/fixtures/invalid_config.ini", invalid_content)
            
            local config, err = ConfigHandler.load("tests/fixtures/invalid_config.ini")
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.matches("解析错误", err.message)
            
            -- 清理临时文件
            os.remove("tests/fixtures/invalid_config.ini")
        end)

        it("应该正确处理不支持的格式转换", function()
            local config = ConfigHandler.load("tests/fixtures/test_config.ini")
            assert.is_not_nil(config)
            
            local success, err = config:convert_to("xml")
            assert.is_false(success)
            assert.is_not_nil(err)
            assert.matches("不支持的配置格式", err.message)
        end)
    end)
end)