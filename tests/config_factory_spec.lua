local ConfigFactory = require("config_factory")
local ErrorHandler = require("error_handler")

describe("ConfigFactory", function()
    -- 测试配置处理器创建
    describe("create", function()
        it("应该为.ini文件创建INI配置处理器", function()
            local handler = ConfigFactory.create("tests/fixtures/test_config.ini")
            assert.is_not_nil(handler)
            assert.equal("ini", handler:get_format())
        end)

        it("应该返回不支持文件类型的错误", function()
            local handler, err = ConfigFactory.create("test.txt")
            assert.is_nil(handler)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT, err.code)
            assert.matches("不支持的文件类型: txt", err.message)
        end)

        it("应该返回无扩展名文件的错误", function()
            local handler, err = ConfigFactory.create("test")
            assert.is_nil(handler)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT, err.code)
            assert.matches("无扩展名文件", err.message)
        end)
    end)

    -- 测试配置文件加载
    describe("load", function()
        it("应该为.ini文件加载INI配置处理器", function()
            local handler = ConfigFactory.load("tests/fixtures/test_config.ini")
            assert.is_not_nil(handler)
            assert.equal("ini", handler:get_format())
        end)

        it("应该处理不存在的文件", function()
            local handler, err = ConfigFactory.load("nonexistent.ini")
            assert.is_nil(handler)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
        end)
    end)

    -- 测试配置格式转换
    describe("convert", function()
        it("应该从INI格式转换为YAML格式", function()
            local success, err = ConfigFactory.convert(
                "tests/fixtures/test_config.ini",
                "tests/fixtures/temp_config.yaml"
            )
            assert.is_not_nil(success)
            assert.is_nil(err)
            
            -- 清理
            os.remove("tests/fixtures/temp_config.yaml")
        end)

        it("应该返回无效目标文件类型的错误", function()
            local result, err = ConfigFactory.convert(
                "tests/fixtures/test_config.ini",
                "tests/fixtures/temp_config.unsupported"
            )
            assert.is_nil(result)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.UNSUPPORTED_FORMAT, err.code)
        end)
    end)
end)