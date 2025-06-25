-- tests/file_utils_spec.lua
local FileUtils = require("src.file_utils")

describe("FileUtils", function()
    local test_file = "build/test.txt"
    local test_content = "Hello, World!"

    after_each(function()
        os.remove(test_file)
    end)

    describe("write_file", function()
        it("should write content to file successfully", function()
            local success, err = FileUtils.write_file(test_file, test_content)
            assert.is_true(success)
            assert.is_nil(err)

            local file = io.open(test_file, "r")
            assert.is_not_nil(file)
            local content = file:read("*a")
            file:close()
            assert.are.equal(test_content, content)
        end)
    end)

    describe("read_file", function()
        it("should read content from file successfully", function()
            -- 先写入文件
            local file = io.open(test_file, "w")
            file:write(test_content)
            file:close()

            -- 测试读取
            local content, err = FileUtils.read_file(test_file)
            assert.is_nil(err)
            assert.are.equal(test_content, content)
        end)

        it("should return error when file doesn't exist", function()
            local content, err = FileUtils.read_file("nonexistent.txt")
            assert.is_nil(content)
            assert.is_not_nil(err)
            assert.are.equal(1, err.code)
        end)
    end)
end)