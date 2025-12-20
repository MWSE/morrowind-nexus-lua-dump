-- Blackjack Distributor (Global Script)
-- Adds blackjack items to Thieves Guild merchants in Thieves Guild locations.
-- Adds blackjack items to random criminals outside of Thieves Guild locations (one-time chance).

local types = require("openmw.types")
local world = require("openmw.world")
local classification = require("scripts.antitheftai.modules.npc_classification")
local settings = require('scripts.antitheftai.SHOPsettings')

-- State to track which NPCs have been processed for random drops
local injected_random = {}

-- Configuration for Merchant Injection
local BLACKJACK_ITEMS_MERCHANT = {'blackjack-wooden', 'blackjack-iron', 'blackjack-imperial', 'blackjack-dwemer'}

-- Configuration for Random Drops
local DROP_CHANCE = 1 -- Percentage (0-100)
local DROP_CLASSES = {
    ['acrobat'] = true,
    ['agent'] = true,
    ['assassin'] = true,
    ['nightblade'] = true,
    ['rogue'] = true,
    ['smuggler'] = true,
    ['thief'] = true,
    ['catcatcher'] = true,
    ['ratcatcher'] = true,
    ['sailor'] = true
}

-- Full list of possible drops for criminals
local BLACKJACK_ITEMS_DROP = {
    'blackjack-wooden',
    'blackjack-iron',
    'blackjack-imperial',
    'blackjack-dwemer',
    'blackjack-wooden-operative',
    'blackjack-iron-operative',
    'blackjack-imperial-operative',
    'blackjack-dwemer-operative',
    'blackjack-wooden-masterthief',
    'blackjack-iron-masterthief',
    'blackjack-imperial-masterthief',
    'blackjack-dwemer-masterthief',
    'blackjack-wooden-weighted',
    'blackjack-iron-weighted',
    'blackjack-imperial-weighted',
    'blackjack-dwemer-weighted',
    'blackjack-wooden-nimble',
    'blackjack-iron-nimble',
    'blackjack-imperial-nimble',
    'blackjack-dwemer-nimble',
    'blackjack-imperial-masterwork',
    'blackjack-dwemer-masterwork',
    'blackjack-wooden-masterwork',
    'blackjack-iron-masterwork',
    'blackjack-iron-extended',
    'blackjack-imperial-extended',
    'blackjack-dwemer-extended',
    'blackjack-wooden-extended'
}

-- Level requirements for specific blackjack items
local LEVEL_REQUIREMENTS = {
    ['blackjack-wooden'] = 1,
    ['blackjack-iron'] = 5,
    ['blackjack-imperial'] = 10,
    ['blackjack-dwemer'] = 15
}

-- --- Logic A: Merchant Restock ---
-- Targeted at Thieves Guild merchants in TG locations. 
-- Runs every time to ensure stock.
local function processMerchantRestock(actor, cellFaction)
    -- Check if blackjack spawning is enabled
    if not settings.general:get('enableBlackjackSpawning') then
        return
    end
    
    -- Must be in Thieves Guild Location
    if not cellFaction or cellFaction:lower() ~= "thieves guild" then
        return
    end

    -- Must be Merchant
    if not classification.isMerchant(actor, types) then
        return
    end

    -- Must be in Thieves Guild Faction
    local isThievesGuildMember = false
    local factions = types.NPC.getFactions(actor)
    for _, f in ipairs(factions) do
        if f:lower() == "thieves guild" then
            isThievesGuildMember = true
            break
        end
    end

    if not isThievesGuildMember then
        return
    end

    -- Avoid Publicans
    local record = types.NPC.record(actor)
    if record.class and record.class:lower() == "publican" then
        return
    end

    -- Check Player Level
    local player = world.players[1]
    local playerLevel = 1
    if player then
        playerLevel = types.Actor.stats.level(player).current
    end

    -- Process Restock
    local inv = types.Actor.inventory(actor)
    for _, item in ipairs(BLACKJACK_ITEMS_MERCHANT) do
        -- Check Level Requirement
        local reqLevel = LEVEL_REQUIREMENTS[item] or 1
        
        if playerLevel >= reqLevel then
            if inv:countOf(item) == 0 then
                world.createObject(item, 1):moveInto(inv)
                -- print("[BlackjackInjector] Merchant Restock: Added " .. item .. " to " .. record.name)
            end
        end
    end
end

-- --- Logic B: Criminal Random Drop ---
-- Targeted at specific classes everywhere ELSE.
-- Runs ONCE per NPC.
local function processCriminalDrop(actor, cellFaction)
    -- Check if blackjack spawning is enabled
    if not settings.general:get('enableBlackjackSpawning') then
        return
    end
    
    if not actor.id then return end
    
    -- Check if already processed
    if injected_random[actor.id] then
        return
    end
    
    -- Mark as processed immediately so we don't retry same NPC
    injected_random[actor.id] = true
    
    -- Skip if inside Thieves Guild location (handled by Merchant logic or intended safety)
    -- The user requested: "all classes in all cells on cell load (except thieves guild locations)"
    if cellFaction and cellFaction:lower() == "thieves guild" then
        -- print("[BlackjackInjector] Skipping Criminal Drop for " .. types.NPC.record(actor).name .. " (In TG Location)")
        return
    end
    
    local record = types.NPC.record(actor)
    if not record or not record.class then return end
    
    local class = record.class:lower()
    
    -- Check Class
    if DROP_CLASSES[class] then
        -- Roll Chance
        if math.random(100) <= DROP_CHANCE then
            -- Pick random item
            local itemIdx = math.random(#BLACKJACK_ITEMS_DROP)
            local itemId = BLACKJACK_ITEMS_DROP[itemIdx]
            
            -- Add item
            local inv = types.Actor.inventory(actor)
            world.createObject(itemId, 1):moveInto(inv)
            print("[BlackjackInjector] Criminal Drop: Added " .. itemId .. " to " .. record.name .. " (" .. class .. ")")
        else
            -- print("[BlackjackInjector] Criminal Drop: Chance failed for " .. record.name)
        end
    end
end

return {
    engineHandlers = {
        onInit = function()
            -- No special init needed
        end,

        onSave = function()
            return { injected_random = injected_random }
        end,

        onLoad = function(data)
            if data and data.injected_random then
                injected_random = data.injected_random
            end
        end,

        onActorActive = function(actor)
            -- Only care about NPCs
            if actor.type ~= types.NPC then
                return
            end

            -- Shim nearby for cell faction detection
            local cellFaction = nil
            if actor.cell then
                local nearbyShim = { actors = actor.cell:getAll(types.NPC) }
                cellFaction = classification.detectCellFaction(nearbyShim, types)
            end

            -- 1. Merchant Restock (TG Locations)
            processMerchantRestock(actor, cellFaction)

            -- 2. Criminal Drop (Non-TG Locations, Random, One-time)
            processCriminalDrop(actor, cellFaction)
        end
    },
    eventHandlers = {
        AntiTheft_DamageWeapon = function(data)
            if data and data.weapon and data.damage then
                local itemData = types.Item.itemData(data.weapon)
                if itemData then
                    local currentCondition = itemData.condition
                    local newCondition = math.max(0, currentCondition - data.damage)
                    itemData.condition = newCondition
                    -- print("[BlackjackInjector] Reduced weapon condition:", currentCondition, "->", newCondition)
                    
                    if newCondition == 0 and data.owner then
                        data.owner:sendEvent('AntiTheft_ShowMessage', { text = "Your blackjack has broken!" })
                    end
                end
            end
        end
    }
}
