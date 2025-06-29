-- config_conversion_spec.lua
-- 测试配置格式转换功能

local ConfigHandler = require("config_handler")
local ErrorHandler = require("error_handler")
local temp_files = require("tests.fixtures.create_temp_files")

describe("配置格式转换", function()
    -- 在每个测试前创建临时文件
    before_each(function()
        temp_files.create_all_temp_files()
    end)

    -- 在每个测试后清理临时文件
    after_each(function()
        temp_files.remove_temp_files()
        -- 清理转换测试生成的文件
        os.remove("tests/fixtures/test_converted.ini")
        os.remove("tests/fixtures/test_converted.json")
        os.remove("tests/fixtures/test_converted.yaml")
    end)

    -- 辅助函数：比较两个配置数据是否相等
    local function compare_configs(config1, config2)
        if type(config1) ~= "table" or type(config2) ~= "table" then
            return false, "配置对象类型错误"
        end
        
        -- 比较所有节
        local sections1 = config1:get_sections()
        local sections2 = config2:get_sections()
        
        if #sections1 ~= #sections2 then
            return false, "节数量不匹配"
        end
        
        -- 创建节的查找表
        local section_lookup = {}
        for _, section in ipairs(sections2) do
            section_lookup[section] = true
        end
        
        -- 检查每个节是否存在
        for _, section in ipairs(sections1) do
            if not section_lookup[section] then
                return false, "节不匹配: " .. section
            end
            
            -- 比较节中的所有键值对
            local keys1 = config1:get_keys(section)
            local keys2 = config2:get_keys(section)
            
            if #keys1 ~= #keys2 then
                return false, "节 " .. section .. " 中的键数量不匹配"
            end
            
            -- 创建键的查找表
            local key_lookup = {}
            for _, key in ipairs(keys2) do
                key_lookup[key] = true
            end
            
            -- 检查每个键是否存在且值相等
            for _, key in ipairs(keys1) do
                if not key_lookup[key] then
                    return false, "键不匹配: " .. section .. "." .. key
                end
                
                local value1 = config1:get(section, key)
                local value2 = config2:get(section, key)
                
                if value1 ~= value2 then
                    return false, string.format("值不匹配: %s.%s (%s != %s)",
                        section, key, tostring(value1), tostring(value2))
                end
            end
        end
        
        return true
    end

    -- 测试从一种格式转换到另一种格式
    local function test_format_conversion(from_format, to_format)
        -- 加载原始配置
        local source_file = string.format("tests/fixtures/test_config.%s", from_format)
        local config = ConfigHandler.load(source_file)
        assert.is_not_nil(config, "无法加载源配置文件: " .. source_file)
        
        -- 转换到目标格式
        local success, err = config:convert_to(to_format)
        assert.is_true(success, "转换格式失败: " .. (err and err.message or "未知错误"))
        
        -- 保存转换后的配置
        local target_file = string.format("tests/fixtures/test_converted.%s", to_format)
        success, err = ConfigHandler.save(config, target_file)
        assert.is_true(success, "保存转换后的配置失败: " .. (err and err.message or "未知错误"))
        
        -- 重新加载转换后的配置
        local converted_config = ConfigHandler.load(target_file)
        assert.is_not_nil(converted_config, "无法加载转换后的配置文件")
        
        -- 比较原始配置和转换后的配置
        local configs_equal, error_msg = compare_configs(config, converted_config)
        assert.is_true(configs_equal, "配置数据不一致: " .. (error_msg or "未知错误"))
    end

    -- 测试所有格式转换组合
    local formats = {"ini", "json", "yaml"}

    for _, from_format in ipairs(formats) do
        for _, to_format in ipairs(formats) do
            if from_format ~= to_format then
                it(string.format("应该能从 %s 格式转换到 %s 格式", from_format:upper(), to_format:upper()), function()
                    test_format_conversion(from_format, to_format)
                end)
            end
        end
    end

    describe("错误处理", function()
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