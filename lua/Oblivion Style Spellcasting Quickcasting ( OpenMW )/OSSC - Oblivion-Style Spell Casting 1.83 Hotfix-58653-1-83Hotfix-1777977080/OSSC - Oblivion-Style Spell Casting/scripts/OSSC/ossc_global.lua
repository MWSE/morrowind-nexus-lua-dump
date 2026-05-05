-- ============================================================
-- OSSC: Oblivion-Style Spell Casting
-- ossc_global.lua (GLOBAL script)
-- Handles authoritative item/charge consumption & hit Vetoes
-- ============================================================

local core  = require('openmw.core')
local types = require('openmw.types')
local I     = require('openmw.interfaces')

-- [ENCHANT FORMULA] Matches vanilla/LPP logic: cost reduced by Enchant skill
local function getEffectiveCost(baseCost, actor)
    local skill = 0
    pcall(function()
        if actor and (actor.type == types.NPC or actor.type == types.Player) then
            local skills = (actor.type == types.Player) and types.Player.stats.skills or types.NPC.stats.skills
            skill = skills.enchant(actor).modified
        end
    end)
    -- Formula: cost = base * (1.1 - skill/100) (approx 1% reduction per point)
    local result = math.max(1, math.floor(0.01 * (110 - skill) * baseCost))
    print(string.format("[OSSC] Global Cost Calc: base=%s skill=%d result=%d", tostring(baseCost), skill, result))
    return result
end

-- [DEATH GUARD] Removed: Unified Target Filter is now handled natively by MagExp.

return {
    eventHandlers = {
        -- Removes 1 count of a scroll from an actor
        OSSC_ConsumeScroll = function(data)
            if not (data.actor and data.item) then return end
            local inv = types.Actor.inventory(data.actor)
            local item = inv:find(data.item.recordId)
            if item then
                item:remove(1)
            end
        end,

        -- Deducts enchantment charge from an item
        OSSC_ConsumeCharge = function(data)
            if not (data.item and data.cost and data.actor) then 
                print("[OSSC] ConsumeCharge: Missing data (item, cost, or actor)")
                return 
            end
            
            pcall(function()
                local itemData = types.Item.itemData(data.item)
                if itemData then
                    local effectiveCost = getEffectiveCost(data.cost, data.actor)
                    local oldCharge = itemData.enchantmentCharge or 0
                    itemData.enchantmentCharge = math.max(0, oldCharge - effectiveCost)
                    print(string.format("[OSSC] Consumed %d charge from %s (%d -> %d) [Enchant Skill used]", 
                        effectiveCost, data.item.recordId, oldCharge, itemData.enchantmentCharge))
                else
                    print("[OSSC] ConsumeCharge: No itemData found for " .. data.item.recordId)
                end
            end)
        end,
    }
}
