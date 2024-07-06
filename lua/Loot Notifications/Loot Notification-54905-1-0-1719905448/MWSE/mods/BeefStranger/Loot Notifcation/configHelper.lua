local configHelp = {}

----------------------------------------------------------------------------------------------------
---`yesNo`
----------------------------------------------------------------------------------------------------
---@param settings mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@param label string The Label next to the button
---@param id string The key of the setting in your config table
---@param config table The config table that your settings use
---@param options mwseMCMYesNoButton[]? Optional other args for the tableVariable, ie {inGameOnly = true} 
--[[ Usage:
```Lua
     bs.config.yesNo(settings, "Enables test log", "testLog", config, {inGameOnly = true})
``` ]]
function configHelp.yesNo(settings, label, id, config, options)
    local optionTable = { ---@type mwseMCMYesNoButton
        label = label,
        variable = mwse.mcm.createTableVariable{id = id, table = config}
    }
    if options then
        for key, value in pairs(options) do
            optionTable[key] = value
        end
    end
    local yesNo = settings:createYesNoButton(optionTable)
    return yesNo
end

function configHelp.YN(settings, label, id, config, desc, callback)
    local optionTable = { ---@type mwseMCMYesNoButton
        label = label,
        variable = mwse.mcm.createTableVariable{id = id, table = config},
        description = desc,
        callback = callback
    }

    local yesNo = settings:createYesNoButton(optionTable)
    return yesNo
end

configHelp.tVar = mwse.mcm.createTableVariable

return configHelp