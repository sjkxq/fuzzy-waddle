local ConfigHandler = require("config_handler")
local ErrorHandler = require("error_handler")
local FileUtils = require("file_utils")

describe("ConfigHandler", function()
    -- 测试配置处理器创建
    describe("create", function()
        it("应该成功创建配置处理器实例", function()
            local handler = ConfigHandler.create("test.ini")
            assert.is_not_nil(handler)
            assert.equal("function", type(handler.get))
            assert.equal("function", type(handler.set))
        end)

        it("应该处理无效文件路径", function()
            local _, err = ConfigHandler.create(123)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
            assert.matches("未提供文件路径", err.message)
        end)
    end)

    -- 测试配置文件加载
    describe("load", function()
        it("应该成功加载INI文件", function()
            local config, err = ConfigHandler.load("tests/fixtures/test_config.ini")
            assert.is_nil(err)
            assert.is_not_nil(config)
        end)

        it("应该处理不存在的文件", function()
            local _, err = ConfigHandler.load("nonexistent.ini")
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
            assert.matches("nonexistent.ini", err.message)
        end)

        it("应该处理不支持的文件格式", function()
            local _, err = ConfigHandler.load("test.txt")
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT, err.code)
            assert.matches("不支持的文件类型", err.message)
        end)
    end)

    -- 测试配置文件保存
    describe("save", function()
        it("应该成功保存配置", function()
            local handler = ConfigHandler.create("temp_config.ini")
            handler:set("section", "key", "value")
            local success, err = handler:save()
            assert.is_true(success)
            assert.is_nil(err)
            
            -- 清理
            os.remove("temp_config.ini")
        end)

        it("应该处理无效的配置数据", function()
            local success, err = ConfigHandler.save(nil, "test.ini")
            assert.is_false(success)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.INVALID_CONFIG_DATA, err.code)
        end)

        it("应该处理无权限目录", function()
            local handler = ConfigHandler.create("/root/test_config.ini")
            handler:set("section", "key", "value")
            local success, err = handler:save()
            assert.is_false(success)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_PERMISSION_DENIED, err.code)
        end)
    end)

    -- 测试全局配置
    describe("global configuration", function()
        it("应该保存和加载全局值", function()
            local handler = ConfigHandler.create("temp_global.ini")
            handler:set_global("app_name", "MyApp")
            handler:save()
            
            local handler2 = ConfigHandler.create("temp_global.ini")
            handler2:load()
            assert.equal("MyApp", handler2:get_global("app_name"))
            
            -- 清理
            os.remove("temp_global.ini")
        end)
    end)
end)