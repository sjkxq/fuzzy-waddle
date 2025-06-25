-- tests/ini_parser_spec.lua
local IniParser = require("src.ini_parser")

describe("IniParser", function()
    describe("parse", function()
        it("should parse empty content", function()
            local config, err = IniParser.parse("")
            assert.is_nil(err)
            assert.is_table(config)
            assert.are.equal(0, #config)
        end)

        it("should parse global key-value pairs", function()
            local content = [[
key1=value1
key2=value2
]]
            local config, err = IniParser.parse(content)
            assert.is_nil(err)
            assert.are.equal("value1", config.key1)
            assert.are.equal("value2", config.key2)
        end)

        it("should parse sections with key-value pairs", function()
            local content = [[
[section1]
key1=value1
key2=value2

[section2]
key3=value3
]]
            local config, err = IniParser.parse(content)
            assert.is_nil(err)
            assert.is_table(config.section1)
            assert.are.equal("value1", config.section1.key1)
            assert.are.equal("value2", config.section1.key2)
            assert.is_table(config.section2)
            assert.are.equal("value3", config.section2.key3)
        end)

        it("should ignore comments and empty lines", function()
            local content = [[
; This is a comment
key1=value1

# Another comment
[section1]

key2=value2
]]
            local config, err = IniParser.parse(content)
            assert.is_nil(err)
            assert.are.equal("value1", config.key1)
            assert.is_table(config.section1)
            assert.are.equal("value2", config.section1.key2)
        end)
    end)

    describe("stringify", function()
        it("should stringify config to INI format", function()
            local config = {
                key1 = "value1",
                section1 = {
                    key2 = "value2",
                    key3 = "value3"
                },
                section2 = {
                    key4 = "value4"
                }
            }
            
            local content, err = IniParser.stringify(config)
            assert.is_nil(err)
            
            -- 重新解析生成的内容，验证结果
            local parsed_config, parse_err = IniParser.parse(content)
            assert.is_nil(parse_err)
            assert.are.equal("value1", parsed_config.key1)
            assert.are.equal("value2", parsed_config.section1.key2)
            assert.are.equal("value3", parsed_config.section1.key3)
            assert.are.equal("value4", parsed_config.section2.key4)
        end)

        it("should return error for invalid config", function()
            local content, err = IniParser.stringify(nil)
            assert.is_nil(content)
            assert.is_not_nil(err)
            assert.are.equal(3, err.code)
        end)
    end)
end)