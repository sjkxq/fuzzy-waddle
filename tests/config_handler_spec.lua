-- tests/config_handler_spec.lua
local ConfigHandler = require("src.config_handler")

describe("ConfigHandler", function()
    local test_file = "build/test_config.ini"
    
    after_each(function()
        os.remove(test_file)
    end)
    
    describe("create", function()
        it("should create a new config handler instance", function()
            local handler, err = ConfigHandler.create(test_file)
            assert.is_nil(err)
            assert.is_table(handler)
            assert.are.equal(test_file, handler.file_path)
        end)
    end)
    
    describe("load", function()
        it("should return error when file doesn't exist", function()
            local handler, err = ConfigHandler.load("nonexistent.ini")
            assert.is_nil(handler)
            assert.is_not_nil(err)
        end)
        
        it("should load existing config file", function()
            -- 先创建并保存一个配置文件
            local handler, err = ConfigHandler.create(test_file)
            handler:set("section1", "key1", "value1")
            local success, save_err = handler:save()
            assert.is_true(success)
            assert.is_nil(save_err)
            
            -- 测试加载
            local loaded_handler, load_err = ConfigHandler.load(test_file)
            assert.is_nil(load_err)
            assert.is_table(loaded_handler)
            assert.are.equal("value1", loaded_handler:get("section1", "key1"))
        end)
    end)
    
    describe("save", function()
        it("should save config to file", function()
            local handler, err = ConfigHandler.create(test_file)
            handler:set("section1", "key1", "value1")
            handler:set("section2", "key2", "value2")
            
            local success, save_err = handler:save()
            assert.is_true(success)
            assert.is_nil(save_err)
            
            -- 验证保存的内容
            local loaded_handler, load_err = ConfigHandler.load(test_file)
            assert.is_nil(load_err)
            assert.are.equal("value1", loaded_handler:get("section1", "key1"))
            assert.are.equal("value2", loaded_handler:get("section2", "key2"))
        end)
        
        it("should not save if not modified", function()
            local handler, err = ConfigHandler.create(test_file)
            handler:set("section1", "key1", "value1")
            handler:save()
            
            -- 修改文件内容
            local file = io.open(test_file, "w")
            file:write("[section1]\nkey1=modified\n")
            file:close()
            
            -- 不修改配置，直接保存
            local success, save_err = handler:save()
            assert.is_true(success)
            assert.is_nil(save_err)
            
            -- 验证文件内容没有被覆盖
            local loaded_handler, load_err = ConfigHandler.load(test_file)
            assert.is_nil(load_err)
            assert.are.equal("modified", loaded_handler:get("section1", "key1"))
        end)
    end)
    
    describe("get and set", function()
        it("should get and set values correctly", function()
            local handler, err = ConfigHandler.create(test_file)
            
            -- 测试设置值
            handler:set("section1", "key1", "value1")
            assert.are.equal("value1", handler:get("section1", "key1"))
            
            -- 测试修改值
            handler:set("section1", "key1", "new_value")
            assert.are.equal("new_value", handler:get("section1", "key1"))
            
            -- 测试获取整个部分
            local section = handler:get("section1")
            assert.is_table(section)
            assert.are.equal("new_value", section.key1)
        end)
    end)
    
    describe("delete", function()
        it("should delete keys and sections", function()
            local handler, err = ConfigHandler.create(test_file)
            handler:set("section1", "key1", "value1")
            handler:set("section1", "key2", "value2")
            handler:set("section2", "key3", "value3")
            
            -- 删除键
            handler:delete("section1", "key1")
            assert.is_nil(handler:get("section1", "key1"))
            assert.are.equal("value2", handler:get("section1", "key2"))
            
            -- 删除部分
            handler:delete("section2")
            assert.is_nil(handler:get("section2"))
        end)
    end)
    
    describe("get_all", function()
        it("should return all config data", function()
            local handler, err = ConfigHandler.create(test_file)
            handler:set("section1", "key1", "value1")
            handler:set("section2", "key2", "value2")
            
            local all_data = handler:get_all()
            assert.is_table(all_data)
            assert.is_table(all_data.section1)
            assert.are.equal("value1", all_data.section1.key1)
            assert.is_table(all_data.section2)
            assert.are.equal("value2", all_data.section2.key2)
        end)
    end)

    describe("global configuration", function()
        it("should get and set global values correctly", function()
            local handler, err = ConfigHandler.create(test_file)
            handler:set_global("app_name", "MyApp")
            handler:set_global("version", "1.0.0")
            
            assert.are.equal("MyApp", handler:get_global("app_name"))
            assert.are.equal("1.0.0", handler:get_global("version"))
        end)

        it("should save and load global values", function()
            local handler, err = ConfigHandler.create(test_file)
            handler:set_global("app_name", "MyApp")
            handler:set_global("version", "1.0.0")
            handler:save()

            local loaded_handler, load_err = ConfigHandler.load(test_file)
            assert.is_nil(load_err)
            assert.are.equal("MyApp", loaded_handler:get_global("app_name"))
            assert.are.equal("1.0.0", loaded_handler:get_global("version"))
        end)

        it("should track modified state for global values", function()
            local handler, err = ConfigHandler.create(test_file)
            assert.is_false(handler:is_modified())
            
            handler:set_global("app_name", "MyApp")
            assert.is_true(handler:is_modified())
            
            handler:reset_modified()
            assert.is_false(handler:is_modified())
        end)
    end)
end)