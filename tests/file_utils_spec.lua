local FileUtils = require("file_utils")
local ErrorHandler = require("error_handler")

describe("FileUtils", function()
    -- 测试文件存在检查
    describe("file_exists", function()
        it("应该正确判断文件是否存在", function()
            local exists = FileUtils.file_exists("tests/fixtures/test_config.ini")
            assert.is_true(exists)
        end)

        it("应该处理不存在的文件", function()
            local exists, err = FileUtils.file_exists("nonexistent.txt")
            assert.is_false(exists)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
            assert.matches("找不到文件", err.message)
        end)

        it("应该处理无效文件路径", function()
            local exists, err = FileUtils.file_exists(nil)
            assert.is_false(exists)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
        end)
    end)

    -- 测试文件读取
    describe("read_file", function()
        it("应该成功读取文件内容", function()
            local content = FileUtils.read_file("tests/fixtures/test_config.ini")
            assert.is_not_nil(content)
            assert.matches("app_name", content)
        end)

        it("应该处理不存在的文件", function()
            local content, err = FileUtils.read_file("nonexistent.txt")
            assert.is_nil(content)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_READ_ERROR, err.code)
        end)

        it("应该处理无效文件路径", function()
            local content, err = FileUtils.read_file(nil)
            assert.is_nil(content)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
        end)
    end)

    -- 测试文件写入
    describe("write_file", function()
        it("应该成功写入文件", function()
            local success = FileUtils.write_file("temp_test.txt", "test content")
            assert.is_true(success)
            
            -- 清理
            os.remove("temp_test.txt")
        end)

        it("应该处理无效文件路径", function()
            local success, err = FileUtils.write_file(nil, "content")
            assert.is_false(success)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
        end)

        it("应该处理无权限目录", function()
            local success, err = FileUtils.write_file("/root/test.txt", "content")
            assert.is_false(success)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_PERMISSION_DENIED, err.code)
        end)
    end)

    -- 测试目录创建
    describe("ensure_directory", function()
        it("应该成功创建目录", function()
            local success = FileUtils.ensure_directory("temp_dir")
            assert.is_true(success)
            
            -- 清理
            os.remove("temp_dir")
        end)

        it("应该处理无效目录路径", function()
            local success, err = FileUtils.ensure_directory(nil)
            assert.is_false(success)
            assert.is_not_nil(err)
            assert.equal(ErrorHandler.ERROR_CODES.FILE_NOT_FOUND, err.code)
        end)
    end)
end)