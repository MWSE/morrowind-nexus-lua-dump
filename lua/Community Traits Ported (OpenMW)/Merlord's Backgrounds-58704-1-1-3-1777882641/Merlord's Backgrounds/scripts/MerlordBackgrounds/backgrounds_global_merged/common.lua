local world = require("openmw.world")
local core = require("openmw.core")

local function addItems(eventData)
    for _, itemData in ipairs(eventData) do
        local items = world.createObject(itemData.itemId, itemData.count)
        ---@diagnostic disable-next-line: discard-returns
        items:moveInto(itemData.player)

        if itemData.autoEquip then
            core.sendGlobalEvent("UseItem", {
                object = items,
                actor = itemData.player,
            })
        end
    end
end

local function multScale(data)
    data.obj:setScale(data.obj.scale * data.mult)
end

local function safeSpawn(data)
    local actor = world.createObject(data.actor)
    actor:teleport(data.player.cell, data.pos)
    if data.script then
        actor:addScript(
            data.script,
            {
                player = data.player,
                script = data.script,
            }
        )
    end
end

local function onScriptedActorDeath(data)
    if data.script then
        data.actor:removeScript(data.script)
    end

    if data.clearInventory then
        for _, item in ipairs(data.actor.type.inventory(data.actor):getAll()) do
            item:remove()
        end
    end
end

return {
    eventHandlers = {
        MerlordsTraits_multScale = multScale,
        MerlordsTraits_addItems = addItems,
        MerlordsTraits_safeSpawn = safeSpawn,
        MerlordsTraits_onScriptedActorDeath = onScriptedActorDeath,
    }
}