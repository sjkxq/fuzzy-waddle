#!/usr/bin/env lua
-- config_converter.lua
-- 配置文件格式转换命令行工具

local ConfigHandler = require("config_handler")
local ErrorHandler = require("error_handler")

-- 显示使用帮助
local function show_help()
    print("配置文件格式转换工具")
    print("用法: lua config_converter.lua <输入文件> <输出文件> [--format=<格式>]")
    print("")
    print("参数:")
    print("  <输入文件>        要转换的配置文件路径")
    print("  <输出文件>        转换后的配置文件保存路径")
    print("  --format=<格式>   指定输出格式 (ini, json, yaml)")
    print("                    如果未指定，将根据输出文件扩展名自动确定")
    print("")
    print("示例:")
    print("  lua config_converter.lua config.ini config.json")
    print("  lua config_converter.lua config.json config.yaml --format=yaml")
    print("")
    print("支持的格式: ini, json, yaml")
end

-- 解析命令行参数
local function parse_args(args)
    if #args < 2 then
        return nil, "缺少必要参数"
    end
    
    local input_file = args[1]
    local output_file = args[2]
    local format = nil
    
    -- 检查是否指定了格式
    for i = 3, #args do
        local format_arg = args[i]:match("^%-%-format=(.+)$")
        if format_arg then
            format = format_arg:lower()
        end
    end
    
    -- 如果未指定格式，从输出文件扩展名推断
    if not format then
        local ext = output_file:match("%.([^%.]+)$")
        if ext then
            format = ext:lower()
        end
    end
    
    return {
        input_file = input_file,
        output_file = output_file,
        format = format
    }
end

-- 主函数
local function main(args)
    -- 解析命令行参数
    if #args == 0 or args[1] == "--help" or args[1] == "-h" then
        show_help()
        return 0
    end
    
    local options, err = parse_args(args)
    if not options then
        print("错误: " .. err)
        show_help()
        return 1
    end
    
    -- 检查输入文件是否存在
    local f = io.open(options.input_file, "r")
    if not f then
        print("错误: 输入文件不存在 - " .. options.input_file)
        return 1
    end
    f:close()
    
    -- 检查输出格式是否支持
    if options.format and options.format ~= "ini" and options.format ~= "json" and options.format ~= "yaml" then
        print("错误: 不支持的输出格式 - " .. options.format)
        print("支持的格式: ini, json, yaml")
        return 1
    end
    
    -- 加载配置文件
    print("加载配置文件: " .. options.input_file)
    local config, err = ConfigHandler.load(options.input_file)
    if not config then
        print("加载配置文件失败:")
        ErrorHandler.log_error(err)
        return 1
    end
    
    -- 转换格式
    if options.format then
        print("转换到 " .. options.format:upper() .. " 格式")
        local success, err = config:convert_to(options.format)
        if not success then
            print("格式转换失败:")
            ErrorHandler.log_error(err)
            return 1
        end
    end
    
    -- 保存配置文件
    print("保存配置文件: " .. options.output_file)
    local success, err = ConfigHandler.save(config, options.output_file)
    if not success then
        print("保存配置文件失败:")
        ErrorHandler.log_error(err)
        return 1
    end
    
    print("转换成功!")
    return 0
end

-- 如果直接运行此脚本，执行主函数
if arg and arg[0]:match("config_converter%.lua$") then
    os.exit(main(arg))
end

-- 导出模块
return {
    main = main,
    parse_args = parse_args,
    show_help = show_help
}