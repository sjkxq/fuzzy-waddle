-- tests/json_parser_spec.lua
local JsonParser = require("json_parser")
local ErrorHandler = require("error_handler")

describe("JsonParser", function()
    describe("parse", function()
        it("should parse empty object", function()
            local config, err = JsonParser.parse("{}")
            assert.is_nil(err)
            assert.is_table(config)
            assert.are.equal(0, #config)
        end)

        it("should parse simple key-value pairs", function()
            local content = [[
{
  "app_name": "My App",
  "version": "1.0.0",
  "debug": true
}
]]
            local config, err = JsonParser.parse(content)
            assert.is_nil(err)
            assert.are.equal("My App", config.app_name)
            assert.are.equal("1.0.0", config.version)
            assert.is_true(config.debug)
        end)

        it("should parse nested structures", function()
            local content = [[
{
  "database": {
    "host": "localhost",
    "port": 3306,
    "credentials": {
      "username": "user",
      "password": "pass"
    }
  }
}
]]
            local config, err = JsonParser.parse(content)
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
{
  "string_value": "simple string",
  "string_with_quotes": "string with \"quotes\"",
  "number": 42,
  "float": 3.14,
  "boolean_true": true,
  "boolean_false": false,
  "null_value": null
}
]]
            local config, err = JsonParser.parse(content)
            assert.is_nil(err)
            assert.are.equal("simple string", config.string_value)
            assert.are.equal("string with \"quotes\"", config.string_with_quotes)
            assert.are.equal(42, config.number)
            assert.are.equal(3.14, config.float)
            assert.is_true(config.boolean_true)
            assert.is_false(config.boolean_false)
            assert.is_nil(config.null_value)
        end)

        it("should parse arrays", function()
            local content = [[
{
  "array": [1, 2, 3, 4],
  "mixed_array": [1, "string", true, null],
  "object_array": [
    {"name": "item1", "value": 1},
    {"name": "item2", "value": 2}
  ]
}
]]
            local config, err = JsonParser.parse(content)
            assert.is_nil(err)
            assert.is_table(config.array)
            assert.are.equal(1, config.array[1])
            assert.are.equal(4, config.array[4])
            
            assert.is_table(config.mixed_array)
            assert.are.equal(1, config.mixed_array[1])
            assert.are.equal("string", config.mixed_array[2])
            assert.is_true(config.mixed_array[3])
            assert.is_nil(config.mixed_array[4])
            
            assert.is_table(config.object_array)
            assert.are.equal("item1", config.object_array[1].name)
            assert.are.equal(1, config.object_array[1].value)
            assert.are.equal("item2", config.object_array[2].name)
            assert.are.equal(2, config.object_array[2].value)
        end)

        it("should handle escaped characters", function()
            local content = [[
{
  "escaped": "Line 1\nLine 2\tTabbed\r\nWindows",
  "backslash": "This is a \\ backslash"
}
]]
            local config, err = JsonParser.parse(content)
            assert.is_nil(err)
            assert.are.equal("Line 1\nLine 2\tTabbed\r\nWindows", config.escaped)
            assert.are.equal("This is a \\ backslash", config.backslash)
        end)

        it("should return error for invalid JSON", function()
            local content = [[
{
  "missing": "comma"
  "invalid": true
}
]]
            local config, err = JsonParser.parse(content)
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.are.equal(ErrorHandler.ERROR_CODES.JSON_PARSING_ERROR, err.code)
        end)

        it("should return error for unclosed structures", function()
            local content = [[
{
  "unclosed": {
    "object": true
}
]]
            local config, err = JsonParser.parse(content)
            assert.is_nil(config)
            assert.is_not_nil(err)
            assert.are.equal(ErrorHandler.ERROR_CODES.JSON_PARSING_ERROR, err.code)
        end)
    end)

    describe("serialize", function()
        it("should serialize simple key-value pairs", function()
            local data = {
                app_name = "My App",
                version = "1.0.0",
                debug = true
            }
            local json, err = JsonParser.serialize(data)
            assert.is_nil(err)
            
            -- 重新解析序列化的内容
            local parsed, parse_err = JsonParser.parse(json)
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
            local json, err = JsonParser.serialize(data)
            assert.is_nil(err)
            
            -- 重新解析序列化的内容
            local parsed, parse_err = JsonParser.parse(json)
            assert.is_nil(parse_err)
            assert.are.equal(data.database.host, parsed.database.host)
            assert.are.equal(data.database.port, parsed.database.port)
            assert.are.equal(data.database.credentials.username, parsed.database.credentials.username)
            assert.are.equal(data.database.credentials.password, parsed.database.credentials.password)
        end)

        it("should serialize arrays", function()
            local data = {
                array = {1, 2, 3, 4},
                mixed_array = {1, "string", true, nil},
                object_array = {
                    {name = "item1", value = 1},
                    {name = "item2", value = 2}
                }
            }
            local json, err = JsonParser.serialize(data)
            assert.is_nil(err)
            
            -- 重新解析序列化的内容
            local parsed, parse_err = JsonParser.parse(json)
            assert.is_nil(parse_err)
            assert.are.equal(data.array[1], parsed.array[1])
            assert.are.equal(data.array[4], parsed.array[4])
            assert.are.equal(data.mixed_array[1], parsed.mixed_array[1])
            assert.are.equal(data.mixed_array[2], parsed.mixed_array[2])
            assert.are.equal(data.mixed_array[3], parsed.mixed_array[3])
            assert.are.equal(data.object_array[1].name, parsed.object_array[1].name)
            assert.are.equal(data.object_array[2].value, parsed.object_array[2].value)
        end)

        it("should handle special characters in strings", function()
            local data = {
                escaped = "Line 1\nLine 2\tTabbed",
                quotes = "String with \"quotes\""
            }
            local json, err = JsonParser.serialize(data)
            assert.is_nil(err)
            
            -- 重新解析序列化的内容
            local parsed, parse_err = JsonParser.parse(json)
            assert.is_nil(parse_err)
            assert.are.equal(data.escaped, parsed.escaped)
            assert.are.equal(data.quotes, parsed.quotes)
        end)

        it("should return error for invalid data", function()
            local json, err = JsonParser.serialize(nil)
            assert.is_nil(json)
            assert.is_not_nil(err)
            assert.are.equal(ErrorHandler.ERROR_CODES.JSON_SERIALIZATION_ERROR, err.code)
        end)
    end)
end) 