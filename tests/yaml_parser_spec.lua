-- tests/yaml_parser_spec.lua
local YamlParser = require("yaml_parser")
local ErrorHandler = require("error_handler")

describe("YamlParser", function()
    describe("parse", function()
        it("should parse empty content", function()
            local config, err = YamlParser.parse("")
            assert.is_nil(err)
            assert.is_table(config)
            assert.are.equal(0, #config)
        end)

        it("should parse simple key-value pairs", function()
            local content = [[
app_name: My App
version: 1.0.0
debug: true
]]
            local config, err = YamlParser.parse(content)
            assert.is_nil(err)
            assert.are.equal("My App", config.app_name)
            assert.are.equal("1.0.0", config.version)
            assert.is_true(config.debug)
        end)

        it("should parse nested structures", function()
            local content = [[
database:
  host: localhost
  port: 3306
  credentials:
    username: user
    password: pass
]]
            local config, err = YamlParser.parse(content)
            assert.is_nil(err)
            assert.is_table(config.database)
            assert.are.equal("localhost", config.database.host)
            assert.are.equal(3306, config.database.port)
            assert.is_table(config.database.credentials)
            assert.are.equal("user", config.database.credentials.username)
            assert.are.equal("pass", config.database.credentials.password)
        end)

        it("should handle different value types", function()
            local content = [[
string_value: simple string
quoted_string: "string with spaces"
single_quoted: 'another string'
number: 42
float: 3.14
boolean_true: true
boolean_false: false
null_value: null
]]
            local config, err = YamlParser.parse(content)
            assert.is_nil(err)
            assert.are.equal("simple string", config.string_value)
            assert.are.equal("string with spaces", config.quoted_string)
            assert.are.equal("another string", config.single_quoted)
            assert.are.equal(42, config.number)
            assert.are.equal(3.14, config.float)
            assert.is_true(config.boolean_true)
            assert.is_false(config.boolean_false)
            assert.is_nil(config.null_value)
        end)

        it("should ignore comments", function()
            local content = [[
# This is a comment
app_name: My App  # Inline comment
# Another comment
version: 1.0.0
]]
            local config, err = YamlParser.parse(content)
            assert.is_nil(err)
            assert.are.equal("My App", config.app_name)
            assert.are.equal("1.0.0", config.version)
        end)

        it("should handle indentation correctly", function()
            local content = [[
level1:
  key1: value1
  level2:
    key2: value2
    level3:
      key3: value3
  key4: value4
]]
            local config, err = YamlParser.parse(content)
            assert.is_nil(err)
            assert.is_table(config.level1)
            assert.are.equal("value1", config.level1.key1)
            assert.is_table(config.level1.level2)
            assert.are.equal("value2", config.level1.level2.key2)
            assert.is_table(config.level1.level2.level3)
            assert.are.equal("value3", config.level1.level2.level3.key3)
            assert.are.equal("value4", config.level1.key4)
        end)

        it("should return error for invalid YAML", function()
            local content = [[
invalid:
  - missing
 wrong_indent:
   key: value
]]
            local config, err = YamlParser.parse(content)
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.are.equal(ErrorHandler.ERROR_CODES.YAML_PARSING_ERROR, err.code)
        end)
    end)

    describe("serialize", function()
        it("should serialize simple key-value pairs", function()
            local data = {
                app_name = "My App",
                version = "1.0.0",
                debug = true
            }
            local yaml, err = YamlParser.serialize(data)
            assert.is_nil(err)
            
            -- 重新解析序列化的内容
            local parsed, parse_err = YamlParser.parse(yaml)
            assert.is_nil(parse_err)
            assert.are.equal(data.app_name, parsed.app_name)
            assert.are.equal(data.version, parsed.version)
            assert.are.equal(data.debug, parsed.debug)
        end)

        it("should serialize nested structures", function()
            local data = {
                database = {
                    host = "localhost",
                    port = 3306,
                    credentials = {
                        username = "user",
                        password = "pass"
                    }
                }
            }
            local yaml, err = YamlParser.serialize(data)
            assert.is_nil(err)
            
            -- 重新解析序列化的内容
            local parsed, parse_err = YamlParser.parse(yaml)
            assert.is_nil(parse_err)
            assert.are.equal(data.database.host, parsed.database.host)
            assert.are.equal(data.database.port, parsed.database.port)
            assert.are.equal(data.database.credentials.username, parsed.database.credentials.username)
            assert.are.equal(data.database.credentials.password, parsed.database.credentials.password)
        end)

        it("should handle special characters in strings", function()
            local data = {
                special = "String with: colon",
                quoted = "String with #hash",
                multiline = "Line 1\nLine 2"
            }
            local yaml, err = YamlParser.serialize(data)
            assert.is_nil(err)
            
            -- 重新解析序列化的内容
            local parsed, parse_err = YamlParser.parse(yaml)
            assert.is_nil(parse_err)
            assert.are.equal(data.special, parsed.special)
            assert.are.equal(data.quoted, parsed.quoted)
            assert.are.equal(data.multiline, parsed.multiline)
        end)

        it("should return error for invalid data", function()
            local yaml, err = YamlParser.serialize(nil)
            assert.is_nil(yaml)
            assert.is_not_nil(err)
            assert.are.equal(ErrorHandler.ERROR_CODES.YAML_SERIALIZATION_ERROR, err.code)
        end)
    end)
end)