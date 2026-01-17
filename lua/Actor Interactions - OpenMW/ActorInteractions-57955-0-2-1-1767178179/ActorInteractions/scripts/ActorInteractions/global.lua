local events = require('scripts.ActorInteractions.events')
local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')

local player = world.players[1]

---@param data {object: Item, from: NPC, to: NPC, count: number}
local function moveItem(data)
        if not data.object or data.object.count < 1 then
                player:sendEvent(events.itemMoved)
                return
        end

        data.object:split(1):moveInto(data.to.type.inventory(data.to))

        player:sendEvent(events.itemMoved)
end

---@param data {spellId: string, target: Actor}
local function teachSpell(data)
        local targetSpells = types.Actor.spells(data.target)
        targetSpells:add(data.spellId)
        player:sendEvent(events.spellTaught, { target = data.target, spellId = data.spellId })
end


---@param data {spellId: string, target: Actor}
local function deleteSpell(data)
        local targetSpells = types.Actor.spells(data.target)
        targetSpells:remove(data.spellId)
        player:sendEvent(events.spellDeleted, { target = data.target, spellId = data.spellId })
end


---@param data {skill: string, target: NPC}
local function trainSkill(data)
        local skillStat = types.NPC.stats.skills[data.skill](data.target)
        skillStat.base = skillStat.base + 1
        player:sendEvent(events.npcTrained)
end


---@param data {items: table<string, number>}
local function refillTrainTokens(data)
        for recordId, count in pairs(data.items) do
                local item = types.Actor.inventory(player):find(recordId)
                if item then
                        item:remove()
                        -- item:split(count):teleport(player.cell, player.position, {
                        --         onGround = true,
                        -- })
                end
        end

        player:sendEvent(events.tokensRefilled)
end



---@param data {gem: GameObject, item: GameObject, max: number}
local function chargeItem(data)
        types.Item.itemData(data.gem).soul = nil
        types.Item.itemData(data.item).enchantmentCharge = data.max
end

---@param data {tool: GameObject, item: GameObject, max: number, owner: GameObject}
local function repairItem(data)
        local tool = data.tool:split(1)
        local toolData = types.Item.itemData(tool)
        toolData.condition = toolData.condition - 1
        if toolData.condition > 0 then
                tool:moveInto(data.owner)
        end

        types.Item.itemData(data.item).condition = data.max
end

return {
        eventHandlers = {
                [events.moveItem] = moveItem,
                [events.teachSpell] = teachSpell,
                [events.deleteNPCSpell] = deleteSpell,
                [events.trainNPCSkill] = trainSkill,
                [events.refillTrainTokens] = refillTrainTokens,
                [events.chargeItem] = chargeItem,
                [events.repairItem] = repairItem,
        },
}
