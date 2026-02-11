-- dialogue_data.lua
-- Dialogue-based door entry system
-- Skill calculations and outcomes for persuasive door interaction

local types = require("openmw.types")
local core = require("openmw.core")

-- Dialogue door entry data
local dialogueData = {
    -- Door types with different dialogue difficulties
    doorTypes = {
        shack = {
            admire = {difficulty = 20, baseChance = 0.8},
            intimidate = {difficulty = 15, baseChance = 0.6},
            bribe = {difficulty = 10, baseChance = 0.9, cost = 25},
            name = "Shack Door"
        },
        house = {
            admire = {difficulty = 30, baseChance = 0.7},
            intimidate = {difficulty = 25, baseChance = 0.5},
            bribe = {difficulty = 20, baseChance = 0.85, cost = 50},
            name = "House Door"
        },
        manor = {
            admire = {difficulty = 50, baseChance = 0.5},
            intimidate = {difficulty = 40, baseChance = 0.3},
            bribe = {difficulty = 35, baseChance = 0.7, cost = 100},
            name = "Manor Door"
        },
        shop = {
            admire = {difficulty = 35, baseChance = 0.6},
            intimidate = {difficulty = 30, baseChance = 0.4},
            bribe = {difficulty = 25, baseChance = 0.8, cost = 75},
            name = "Shop Door"
        },
        guild = {
            admire = {difficulty = 40, baseChance = 0.5},
            intimidate = {difficulty = 35, baseChance = 0.3},
            bribe = {difficulty = 30, baseChance = 0.75, cost = 60},
            name = "Guild Door"
        },
        temple = {
            admire = {difficulty = 45, baseChance = 0.5},
            intimidate = {difficulty = 50, baseChance = 0.2},
            bribe = {difficulty = 35, baseChance = 0.7, cost = 80},
            name = "Temple Door"
        },
        tavern = {
            admire = {difficulty = 25, baseChance = 0.7},
            intimidate = {difficulty = 20, baseChance = 0.5},
            bribe = {difficulty = 15, baseChance = 0.85, cost = 40},
            name = "Tavern Door"
        },
        generic = {
            admire = {difficulty = 20, baseChance = 0.75},
            intimidate = {difficulty = 15, baseChance = 0.6},
            bribe = {difficulty = 10, baseChance = 0.9, cost = 30},
            name = "Generic Door"
        }
    },
    
    -- Success and failure messages
    messages = {
        admire = {
            success = {
                "Your charming words convince them to let you in.",
                "They seem impressed by your polite approach.",
                "Your admiration softens their stance.",
                "They find your words persuasive and welcoming."
            },
            failure = {
                "They seem unimpressed by your flattery.",
                "Your attempts at charm fall flat.",
                "They don't seem swayed by your words.",
                "Your polite approach doesn't work this time."
            }
        },
        intimidate = {
            success = {
                "They appear intimidated by your presence.",
                "Your assertive approach makes them reconsider.",
                "They seem nervous about refusing you.",
                "Your forceful personality convinces them."
            },
            failure = {
                "They stand their ground against your threats.",
                "Your intimidation attempt backfires.",
                "They refuse to be bullied.",
                "Your aggressive approach fails completely."
            }
        },
        bribe = {
            success = {
                "A small payment changes their mind.",
                "Your offer proves tempting.",
                "They accept your gesture of goodwill.",
                "Money talks - they let you in."
            },
            failure = {
                "They refuse your offer indignantly.",
                "Your bribe is rejected firmly.",
                "They can't be bought.",
                "Money won't sway their principles."
            }
        }
    },
    
    -- Crime and bounty settings
    crimes = {
        intimidate = {
            success = {bounty = 0, crime = "none"},
            failure = {bounty = 150, crime = "assault"}
        },
        bribe = {
            success = {bounty = 0, crime = "none"},
            failure = {bounty = 200, crime = "bribery"}
        },
        admire = {
            success = {bounty = 0, crime = "none"},
            failure = {bounty = 100, crime = "harassment"}
        }
    },
    
    -- Reputation settings
    reputation = {
        admire = {
            success = {points = 2, type = "persuade_success"},
            failure = {points = -2, type = "persuade_failure"}
        },
        intimidate = {
            success = {points = 1, type = "persuade_success"},
            failure = {points = -1, type = "persuade_failure"}
        },
        bribe = {
            success = {points = 0, type = "neutral"},
            failure = {points = 0, type = "neutral"}
        }
    }
}

-- Get door type for dialogue calculations
local function getDoorDialogueType(door)
    local recordId = door.recordId:lower()
    local cellName = door.cell.name:lower()
    
    -- Determine door type for dialogue difficulty
    if recordId:find("shack") or cellName:find("shack") then
        return "shack"
    elseif recordId:find("house") or cellName:find("house") then
        return "house"
    elseif recordId:find("manor") or cellName:find("manor") then
        return "manor"
    elseif recordId:find("shop") or recordId:find("store") or recordId:find("trade") then
        return "shop"
    elseif recordId:find("guild") or cellName:find("guild") then
        return "guild"
    elseif recordId:find("temple") or cellName:find("temple") then
        return "temple"
    elseif recordId:find("tavern") or recordId:find("inn") then
        return "tavern"
    else
        return "generic"
    end
end

-- Calculate success chance for dialogue attempt
local function calculateDialogueChance(dialogueType, doorType, player)
    local doorConfig = dialogueData.doorTypes[doorType]
    local config = doorConfig[dialogueType]
    
    if not config then return 0 end
    
    local baseChance = config.baseChance
    local difficulty = config.difficulty
    
    -- Get player stats
    local playerStats = {}
    
    if dialogueType == "admire" then
        playerStats.skill = types.NPC.stats.skills.speechcraft(player).current or 0
        playerStats.personality = types.Actor.stats.attributes.personality(player).current or 50
        playerStats.luck = types.Actor.stats.attributes.luck(player).current or 50
        
        -- Admire formula: Speechcraft + Personality + Luck vs Difficulty
        local skillBonus = math.min(playerStats.skill / 100, 0.5) -- Max 50% bonus
        local personalityBonus = (playerStats.personality - 50) / 200 -- -25% to +25%
        local luckBonus = (playerStats.luck - 50) / 400 -- -12.5% to +12.5%
        
        return math.max(0.1, math.min(0.9, baseChance + skillBonus + personalityBonus + luckBonus))
        
    elseif dialogueType == "intimidate" then
        playerStats.strength = types.Actor.stats.attributes.strength(player).current or 50
        playerStats.skill = types.NPC.stats.skills.speechcraft(player).current or 0
        playerStats.level = types.Actor.stats.level(player).current or 1
        
        -- Intimidate formula: Strength + Speechcraft + Level vs Difficulty
        local strengthBonus = (playerStats.strength - 50) / 200 -- -25% to +25%
        local skillBonus = math.min(playerStats.skill / 100, 0.3) -- Max 30% bonus
        local levelBonus = math.min(playerStats.level / 100, 0.2) -- Max 20% bonus
        
        return math.max(0.1, math.min(0.9, baseChance + strengthBonus + skillBonus + levelBonus))
        
    elseif dialogueType == "bribe" then
        playerStats.gold = types.Actor.inventory.getGoldCount(player) or 0
        
        -- Bribe formula: Based on having enough gold + small skill bonus
        if playerStats.gold < config.cost then
            return 0 -- Can't bribe without enough gold
        end
        
        local skillBonus = math.min(types.NPC.stats.skills.speechcraft(player).current / 200, 0.2) -- Max 20% bonus
        
        return math.max(0.1, math.min(0.9, baseChance + skillBonus))
    end
    
    return baseChance
end

-- Get random message for dialogue outcome
local function getDialogueMessage(dialogueType, success)
    local messages = dialogueData.messages[dialogueType]
    if not messages then return "No response." end
    
    local messageSet = success and messages.success or messages.failure
    if not messageSet then return "No response." end
    
    return messageSet[math.random(#messageSet)]
end

-- Get crime data for dialogue attempt
local function getCrimeData(dialogueType, success)
    local crimeConfig = dialogueData.crimes[dialogueType]
    if not crimeConfig then return {bounty = 0, crime = "none"} end
    
    return success and crimeConfig.success or crimeConfig.failure
end

-- Get reputation data for dialogue attempt
local function getReputationData(dialogueType, success)
    local reputationConfig = dialogueData.reputation[dialogueType]
    if not reputationConfig then return {points = 0, type = "neutral"} end
    
    return success and reputationConfig.success or reputationConfig.failure
end

-- Public interface
local M = {}

-- Get dialogue difficulty for door type
M.getDoorDifficulty = function(door)
    local doorType = getDoorDialogueType(door)
    return dialogueData.doorTypes[doorType] or dialogueData.doorTypes.generic
end

-- Calculate success chance for dialogue attempt
M.calculateSuccessChance = function(dialogueType, door, player)
    local doorType = getDoorDialogueType(door)
    return calculateDialogueChance(dialogueType, doorType, player)
end

-- Get message for dialogue outcome
M.getMessage = function(dialogueType, success)
    return getDialogueMessage(dialogueType, success)
end

-- Get crime data for dialogue attempt
M.getCrimeData = function(dialogueType, success)
    return getCrimeData(dialogueType, success)
end

-- Check if player can afford bribe
M.canAffordBribe = function(door, player)
    local difficulty = M.getDoorDifficulty(door)
    local playerGold = types.Actor.stats.gold(player).current or 0
    return playerGold >= (difficulty.bribe.cost or 0)
end

-- Get reputation data for dialogue attempt
M.getReputationData = function(dialogueType, success)
    return getReputationData(dialogueType, success)
end

return M
