local world = require('openmw.world')
local T = require('openmw.types')

local log = require("scripts.BMS.util.log")
local mDef = require('scripts.BMS.config.definition')
local mStore = require('scripts.BMS.config.store')
local mH = require("scripts.BMS.util.helpers")

mStore.registerGroups()

if not mDef.isLuaApiRecentEnough then
    mStore.settings.enabled.set(false)
    mStore.updateRendererArgument(mStore.settings.enabled, { disabled = true })
end

local function updateSettingArguments(key)
    if key == mStore.settings.minItemSalePricePercent.key then
        local argument = mH.copyMap(mStore.arguments.maxPercent)
        argument.min = math.max(mStore.settings.minItemSalePricePercent.get(), mStore.arguments.maxPercent.min)
        mStore.updateRendererArgument(mStore.settings.maxItemSalePricePercent, argument)
    elseif key == mStore.settings.maxItemSalePricePercent.key then
        local argument = mH.copyMap(mStore.arguments.minPercent)
        argument.max = math.min(mStore.settings.maxItemSalePricePercent.get(), mStore.arguments.minPercent.max)
        mStore.updateRendererArgument(mStore.settings.minItemSalePricePercent, argument)
    end
end

local function updateSettings()
    local playerLevel = T.Actor.stats.level(world.players[1]).current
    mStore.arguments.difficulty.playerLevel = playerLevel
    for _, setting in pairs(mStore.settings) do
        if setting.argument.playerLevel then
            mStore.updateRendererArgument(setting, mStore.arguments.difficulty)
        end
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

mStore.addTrackerCallback(function(key, _)
    updateSettingArguments(key)
end)

updateSettingArguments(mStore.settings.minItemSalePricePercent.key)
updateSettingArguments(mStore.settings.maxItemSalePricePercent.key)

return {
    eventHandlers = {
        [mDef.events.updateSettings] = updateSettings,
        [mDef.events.attachNpcScript] = function(data) attachNpcScript(data.npc, data.player) end,
        [mDef.events.removeNpcScript] = removeNpcScript,
    }
}
