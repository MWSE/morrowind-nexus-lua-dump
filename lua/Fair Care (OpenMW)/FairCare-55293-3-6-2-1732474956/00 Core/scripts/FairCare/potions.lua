local T = require('openmw.types')
local world = require('openmw.world')

local mSettings = require('scripts.FairCare.settings')
local mMagic = require('scripts.FairCare.magic')
local mData = require('scripts.FairCare.data')
local mTools = require('scripts.FairCare.tools')

local potionsAverageRestoredHealth = {}
for _, potionId in ipairs(mData.restoreHealthPotions) do
    potionsAverageRestoredHealth[potionId] = mMagic.getPotionAverageRestoredHealth(potionId)
end

local function addPotions(actor)
    local actorBaseHealth = T.Actor.stats.dynamic.health(actor).base
    local expectedHealthRatio = math.random(
            mSettings.getStorage(mSettings.potionSettingsKey):get("minRestoredHealthByPotions"),
            mSettings.getStorage(mSettings.potionSettingsKey):get("maxRestoredHealthByPotions")) / 100
    local expectedHealth = actorBaseHealth * expectedHealthRatio
    local restoredHealth = 0
    local messages = {}
    local needPotions = true
    while (needPotions) do
        needPotions = false
        for _, potionId in ipairs(mData.restoreHealthPotions) do
            local potionHealth = potionsAverageRestoredHealth[potionId]
            if not needPotions and restoredHealth + potionHealth <= expectedHealth and potionHealth <= actorBaseHealth then
                table.insert(messages, string.format("\"%s\" (%s HP)",
                        T.Potion.records[potionId].name, potionHealth))
                world.createObject(potionId, 1):moveInto(T.Actor.inventory(actor))
                restoredHealth = restoredHealth + potionHealth
                needPotions = true
            end
        end
    end
    mTools.debugPrint(string.format("%s (%s HP) gained potions to restore %d%% of his HP:\n---- %s",
            mTools.actorId(actor), actorBaseHealth, expectedHealthRatio * 100, table.concat(messages, ", ")))
end

return {
    eventHandlers = {
        fairCare_addPotion = addPotions,
    }
}
