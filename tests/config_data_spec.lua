-- tests/config_data_spec.lua
local ConfigData = require("src.config_data")

describe("ConfigData", function()
    local config_data

    before_each(function()
        config_data = ConfigData.new()
    end)

    describe("initialization", function()
        it("should create empty config data", function()
            assert.is_table(config_data:get_all())
            assert.is_false(config_data:is_modified())
        end)

        it("should initialize with provided data", function()
            local initial_data = {
                section1 = {
                    key1 = "value1"
                }
            }
            local config = ConfigData.new(initial_data)
            assert.are.same(initial_data, config:get_all())
        end)
    end)

    describe("get", function()
        it("should return nil for non-existent section", function()
            local value = config_data:get("nonexistent")
            assert.is_nil(value)
        end)

        it("should return nil for non-existent key", function()
            config_data:set("section1", "key1", "value1")
            local value = config_data:get("section1", "nonexistent")
            assert.is_nil(value)
        end)

        it("should return correct value for existing key", function()
            config_data:set("section1", "key1", "value1")
            local value = config_data:get("section1", "key1")
            assert.are.equal("value1", value)
        end)

        it("should return entire section when no key provided", function()
            config_data:set("section1", "key1", "value1")
            config_data:set("section1", "key2", "value2")
            local section = config_data:get("section1")
            assert.is_table(section)
            assert.are.equal("value1", section.key1)
            assert.are.equal("value2", section.key2)
        end)
    end)

    describe("set", function()
        it("should set value and mark as modified", function()
            local success, err = config_data:set("section1", "key1", "value1")
            assert.is_true(success)
            assert.is_nil(err)
            assert.is_true(config_data:is_modified())
            assert.are.equal("value1", config_data:get("section1", "key1"))
        end)

        it("should return error for invalid section", function()
            local success, err = config_data:set(nil, "key1", "value1")
            assert.is_false(success)
            assert.are.equal(4, err.code)
        end)

        it("should return error for invalid key", function()
            local success, err = config_data:set("section1", nil, "value1")
            assert.is_false(success)
            assert.are.equal(5, err.code)
        end)
    end)

    describe("delete", function()
        before_each(function()
            config_data:set("section1", "key1", "value1")
            config_data:set("section1", "key2", "value2")
            config_data:reset_modified()
        end)

        it("should delete key and mark as modified", function()
            local success, err = config_data:delete("section1", "key1")
            assert.is_true(success)
            assert.is_nil(err)
            assert.is_true(config_data:is_modified())
            assert.is_nil(config_data:get("section1", "key1"))
            assert.are.equal("value2", config_data:get("section1", "key2"))
        end)

        it("should delete entire section when no key provided", function()
            local success, err = config_data:delete("section1")
            assert.is_true(success)
            assert.is_nil(err)
            assert.is_true(config_data:is_modified())
            assert.is_nil(config_data:get("section1"))
        end)

        it("should return error for non-existent section", function()
            local success, err = config_data:delete("nonexistent")
            assert.is_false(success)
            assert.are.equal(6, err.code)
        end)

        it("should return error for non-existent key", function()
            local success, err = config_data:delete("section1", "nonexistent")
            assert.is_false(success)
            assert.are.equal(7, err.code)
        end)
    end)

    describe("modified state", function()
        it("should track modified state correctly", function()
            assert.is_false(config_data:is_modified())
            
            config_data:set("section1", "key1", "value1")
            assert.is_true(config_data:is_modified())
            
            config_data:reset_modified()
            assert.is_false(config_data:is_modified())
            
            config_data:delete("section1", "key1")
            assert.is_true(config_data:is_modified())
        end)
    end)

    describe("global configuration", function()
        it("should get global values correctly", function()
            config_data:set_global("app_name", "MyApp")
            local value = config_data:get_global("app_name")
            assert.are.equal("MyApp", value)
        end)

        it("should set global values and mark as modified", function()
            local success, err = config_data:set_global("version", "1.0.0")
            assert.is_true(success)
            assert.is_nil(err)
            assert.is_true(config_data:is_modified())
            assert.are.equal("1.0.0", config_data:get_global("version"))
        end)

        it("should track modified state for global values", function()
            assert.is_false(config_data:is_modified())
            
            config_data:set_global("app_name", "MyApp")
            assert.is_true(config_data:is_modified())
            
            config_data:reset_modified()
            assert.is_false(config_data:is_modified())
        end)
    end)
end)