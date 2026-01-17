local world = require('openmw.world')
local async = require('openmw.async')
local T = require('openmw.types')
local I = require("openmw.interfaces")

local log = require("scripts.BMS.util.log")
local mDef = require('scripts.BMS.config.definition')
local mS = require('scripts.BMS.config.settings')
local mH = require("scripts.BMS.util.helpers")

mS.initSettings()

if not mDef.isLuaApiRecentEnough then
    mS.globalStorage:set("enabled", false)
    I.Settings.updateRendererArgument(mS.globalKey, "enabled", { disabled = true })
end

local function updateSettingArguments(key)
    if key == "minItemSalePricePercent" then
        local argument = mH.copyMap(mS.maxPercentArgument)
        argument.min = math.max(mS.globalStorage:get("minItemSalePricePercent"), mS.maxPercentArgument.min)
        I.Settings.updateRendererArgument(mS.globalKey, "maxItemSalePricePercent", argument)
    elseif key == "maxItemSalePricePercent" then
        local argument = mH.copyMap(mS.minPercentArgument)
        argument.max = math.min(mS.globalStorage:get("maxItemSalePricePercent"), mS.minPercentArgument.max)
        I.Settings.updateRendererArgument(mS.globalKey, "minItemSalePricePercent", argument)
    end
end

local function updateSettings()
    local playerLevel = T.Actor.stats.level(world.players[1]).current
    mS.difficultyArgument.playerLevel = playerLevel
    for settingKey in pairs(mS.difficultySettings) do
        I.Settings.updateRendererArgument(mS.globalKey, settingKey, mS.difficultyArgument)
    end
end

local function attachNpcScript(npc, player)
    if npc:hasScript(mDef.scripts.npcScriptPath) then
        log(string.format("NPC %s already has his script attached", mH.objectId(npc)))
    else
        log(string.format("Attaching script to NPC %s", mH.objectId(npc)))
        npc:addScript(mDef.scripts.npcScriptPath, {})
    end
    player:sendEvent(mDef.events.onNpcScriptAttached)
end

local function removeNpcScript(npc)
    if npc:hasScript(mDef.scripts.npcScriptPath) then
        log(string.format("Removing script from NPC %s", mH.objectId(npc)))
        npc:removeScript(mDef.scripts.npcScriptPath)
    else
        log(string.format("NPC %s doesn't have his script attached", mH.objectId(npc)))
    end
end

mS.globalStorage:subscribe(async:callback(function(_, key)
    updateSettingArguments(key)
end))
updateSettingArguments("minItemSalePricePercent")
updateSettingArguments("maxItemSalePricePercent")

return {
    eventHandlers = {
        [mDef.events.updateSettings] = updateSettings,
        [mDef.events.attachNpcScript] = function(data) attachNpcScript(data.npc, data.player) end,
        [mDef.events.removeNpcScript] = removeNpcScript,
    }
}
