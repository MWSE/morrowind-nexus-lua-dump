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

configHelp.rgb = {
    answerColor = { 0.588, 0.196, 0.118 },
    activeColor = { 0.376, 0.439, 0.792 },
    activeOverColor = { 0.624, 0.663, 0.875 },
    activePressedColor = { 0.875, 0.886, 0.957 },
    answerOverColor = { 0.875, 0.788, 0.624 },
    answerPressedColor = { 0.953, 0.929, 0.867 },
    backgroundColor = { 0.0, 0.0, 0.0 },
    bigAnswerColor = { 0.588, 0.196, 0.118 },
    bigAnswerOverColor = { 0.875, 0.788, 0.624 },
    bigAnswerPressedColor = { 0.953, 0.929, 0.086 },
    bigHeaderColor = { 0.875, 0.788, 0.624 },
    bigLinkOverColor = { 0.561, 0.608, 0.855 },
    bigLinkPressedColor = { 0.686, 0.722, 0.894 },
    bigNormalColor = { 0.792, 0.647, 0.376 },
    bigNormalOverColor = { 0.875, 0.788, 0.624 },
    bigNormalPressedColor = { 0.953, 0.929, 0.867 },
    bigNotifyColor = { 0.875, 0.788, 0.624 },
    blackColor = { 0.0, 0.0, 0.0 },
    bsNiceRed = { 0.941, 0.38, 0.38 },
    bsPrettyBlue = { 0.235, 0.616, 0.949 },
    bsPrettyGreen = { 0.38, 0.941, 0.525 },
    bsGoodGrey = {0.76, 0.76, 0.71},
    countColor = { 0.875, 0.788, 0.624 },
    disabledColor = { 0.702, 0.659, 0.529 },
    disabledOverColor = { 0.875, 0.788, 0.624 },
    disabledPressedColor = { 0.953, 0.929, 0.867 },
    fatigueColor = { 0.0, 0.588, 0.235 },
    focusColor = { 0.314, 0.314, 0.314 },
    healthNpcColor = { 1.0, 0.729, 0.0 },
    journalFinishedQuestColor = { 0.235, 0.235, 0.235 },
    journalFinishedQuestOverColor = { 0.392, 0.392, 0.392 },
    journalFinishedQuestPressedColor = { 0.863, 0.863, 0.863 },
    journalLinkColor = { 0.145, 0.192, 0.439 },
    journalLinkOverColor = { 0.227, 0.302, 0.686 },
    journalLinkPressedColor = { 0.439, 0.494, 0.812 },
    journalTopicColor = { 0.0, 0.0, 0.0 },
    journalTopicOverColor = { 0.227, 0.302, 0.686 },
    journalTopicPressedColor = { 0.439, 0.494, 0.812 },
    linkColor = { 0.439, 0.494, 0.812 },
    linkOverColor = { 0.561, 0.608, 0.855 },
    linkPressedColor = { 0.686, 0.722, 0.894 },
    magicColor = { 0.208, 0.271, 0.624 },
    magicFillColor = { 0.784, 0.235, 0.118 },
    negativeColor = { 0.784, 0.235, 0.118 },
    normalColor = { 0.792, 0.647, 0.376 },
    normalOverColor = { 0.875, 0.788, 0.624 },
    normalPressedColor = { 0.953, 0.929, 0.867 },
    notifyColor = { 0.875, 0.788, 0.624 },
    positiveColor = { 0.875, 0.788, 0.624 },
    weaponFillColor = { 0.784, 0.235, 0.118 },
    whiteColor = { 1.0, 1.0, 1.0 },
}

function configHelp.colorDropdown()
    local options = {}

    for name, color in pairs(configHelp.rgb) do
        table.insert(options, {label = name, value = color})
    end
    table.sort(options, function(a, b)    --Sort table from A-Z
        return a.label < b.label
    end)
    return options
end


function configHelp.inspect(table)
    local inspect = require("inspect").inspect

    local bsF = debug.getinfo(1, "nSl")
    local bsC = debug.getinfo(2, "nSl")

    mwse.log("[ ---------------------------- | bsF | %s | ---------------------------- ]", bsF.name)
    mwse.log("[Source: %s, Line: %d]", bsC.short_src, bsC.currentline)
    mwse.log("%s", inspect(table))

end

return configHelp