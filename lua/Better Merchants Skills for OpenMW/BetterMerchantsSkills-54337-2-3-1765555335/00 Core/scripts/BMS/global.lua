local world = require('openmw.world')
local async = require('openmw.async')
local T = require('openmw.types')
local I = require("openmw.interfaces")

local D = require('scripts.BMS.definition')
local S = require('scripts.BMS.settings')
local H = require("scripts.BMS.helpers")

S.initSettings()

if not D.isLuaApiRecentEnough then
    S.globalStorage:set("enabled", false)
    I.Settings.updateRendererArgument(S.globalKey, "enabled", { disabled = true })
end

local function updateSettingArguments(key)
    if key == "minItemSalePricePercent" then
        local argument = H.copyMap(S.maxPercentArgument)
        argument.min = math.max(S.globalStorage:get("minItemSalePricePercent"), S.maxPercentArgument.min)
        I.Settings.updateRendererArgument(S.globalKey, "maxItemSalePricePercent", argument)
    elseif key == "maxItemSalePricePercent" then
        local argument = H.copyMap(S.minPercentArgument)
        argument.max = math.min(S.globalStorage:get("maxItemSalePricePercent"), S.minPercentArgument.max)
        I.Settings.updateRendererArgument(S.globalKey, "minItemSalePricePercent", argument)
    end
end

S.globalStorage:subscribe(async:callback(function(_, key)
    updateSettingArguments(key)
end))
updateSettingArguments("minItemSalePricePercent")
updateSettingArguments("maxItemSalePricePercent")

local function updateSettings()
    local playerLevel = T.Actor.stats.level(world.players[1]).current
    S.difficultyArgument.playerLevel = playerLevel
    for settingKey in pairs(S.difficultySettings) do
        I.Settings.updateRendererArgument(S.globalKey, settingKey, S.difficultyArgument)
    end
end

return {
    eventHandlers = {
        [D.events.updateSettings] = updateSettings,
    }
}
