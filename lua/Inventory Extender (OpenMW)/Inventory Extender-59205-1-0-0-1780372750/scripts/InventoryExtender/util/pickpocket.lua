local core = require('openmw.core')
local types = require('openmw.types')

local helpers = require('scripts.InventoryExtender.util.helpers')

local Pickpocket = {}

local function getSneak(actor)
    return types.NPC.stats.skills.sneak(actor).modified
end

local function getAgility(actor)
    return types.Actor.stats.attributes.agility(actor).modified
end

local function getLuck(actor)
    return types.Actor.stats.attributes.luck(actor).modified
end

local function getChance(player, target, valueTerm)
    local pcSneak = getSneak(player)
    local x = (0.2 * getAgility(player) + 0.1 * getLuck(player) + pcSneak) * helpers.getFatigueTerm(player)
    local y = (valueTerm + getSneak(target) + 0.2 * getAgility(target) + 0.1 * getLuck(target)) * helpers.getFatigueTerm(target)
    local t = x - y + x

    local minChance = pcSneak / core.getGMST('iPickMinChance')
    if t < minChance then
        return math.max(0, math.floor(minChance))
    end

    return math.max(0, math.floor(math.min(core.getGMST('iPickMaxChance'), t)))
end

function Pickpocket.isTarget(target)
    return target ~= nil and types.NPC.objectIsInstance(target) and not types.Actor.isDead(target)
end

function Pickpocket.createSession(player, target)
    local visibleItems = {}
    local pcSneak = getSneak(player)

    for _, item in ipairs(target.type.inventory(target):getAll()) do
        if types.Item.isCarriable(item) and not target.type.hasEquipped(target, item) and math.random(100) <= pcSneak then
            visibleItems[item.id] = true
        end
    end

    return {
        active = true,
        resolved = false,
        targetId = target.id,
        visibleItems = visibleItems,
    }
end

function Pickpocket.isVisible(session, item)
    return session == nil or not session.active or session.visibleItems[item.id] == true
end

function Pickpocket.rollTake(player, target, item, stackCount)
    local stackValue = item.type.record(item).value * stackCount
    local valueTerm = 10 * core.getGMST('fPickPocketMod') * stackValue
    local chance = getChance(player, target, valueTerm)
    return math.random(100) <= chance, chance
end

function Pickpocket.rollClose(player, target)
    local chance = getChance(player, target, 0)
    return math.random(100) <= chance, chance
end

return Pickpocket