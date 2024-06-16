local config = {}


----------------------------------------------------------------------------------------------------
---`createLogLevel`
----------------------------------------------------------------------------------------------------
---@param page mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@param configTable table The config table that your settings use
---@param log mwseLogger Your log you have setup, if you use my bs.getLog then you have to do log.log, sorry.
---Usage:
---```Lua
---     bs.config.createLogLevel(settings, config, log.log) --log.log for bs.getLog, otherwise just use log
---```
function config.createLogLevel(page, configTable, log, ...)
    page:createDropdown{
        label = "Logging Level",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "WARN", value = "WARN"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = configTable},
        callback = function(self)
            log:setLogLevel(self.variable.value)
            log:debug("LogLevel = %s", self.variable.value)
        end,
        ...
    }
end


----------------------------------------------------------------------------------------------------
---`yesNo`
----------------------------------------------------------------------------------------------------
---@param page mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@param label string The Label next to the button
---@param id string The key of the setting in your config table
---@param configTable table The config table that your settings use
---@param options mwseMCMYesNoButton? Optional other args for the tableVariable, ie {inGameOnly = true} 
---Usage:
---```Lua
---     bs.config.yesNo(settings, "Enables test log", "testLog", config, {inGameOnly = true})
---```
function config.yesNo(page, label, id, configTable, options)
    local optionTable = { ---@type mwseMCMYesNoButton
        label = label,
        variable = mwse.mcm.createTableVariable{id = id, table = configTable}
    }
    if options then
        for key, value in pairs(options) do
            optionTable[key] = value
        end
    end
    local yesNo = page:createYesNoButton(optionTable)
    return yesNo
end
----------------------------------------------------------------------------------------------------
---`template`
----------------------------------------------------------------------------------------------------
function config.template(configPath)
    local mcmTemplate = mwse.mcm.createTemplate({ name = configPath })
    return mcmTemplate
end

return config