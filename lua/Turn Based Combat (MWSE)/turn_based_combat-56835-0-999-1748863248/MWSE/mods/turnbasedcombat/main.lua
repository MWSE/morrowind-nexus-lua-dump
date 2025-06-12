local cprint = (function()
    local logger = mwse.Logger
    local log = logger.new({
        name = "tbcombat",
        logLevel = "TRACE",
        logToConsole = true,
        includeTimestamp = false,
    })
    local function fix_percent_signs(str)
        return string.gsub(str, "%%", "%%%%")
    end
    local function arg_processed(arg, fix)
        arg = string.format("%s", arg)
        if type(arg) == "string" and fix then
            arg = fix_percent_signs(arg)
        end
        return arg
    end
    return function(msg, ...)
        msg = arg_processed(msg, #{...} == 0 and true)
        local args = {}
        for _, arg in ipairs({...}) do
            args[#args+1] = arg_processed(arg, true)
        end
        log:info(msg, table.unpack(args))
    end
end)()

require("turnbasedcombat.turnbasedcombat")(cprint)
