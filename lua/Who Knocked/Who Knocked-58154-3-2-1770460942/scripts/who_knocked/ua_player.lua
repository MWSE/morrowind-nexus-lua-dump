-- Universal Activator - Player Script
-- Player-side component for knock-knock interaction
-- Handles UI messages and door responses
-- Enhanced with dialogue-based door entry system

local core = require("openmw.core")
local types = require("openmw.types")
local ui = require("openmw.ui")
local self = require("openmw.self")

-- Import door choice menu
local doorChoiceMenu = require("scripts.who_knocked/door_choice_menu")
local lockpickMenu = require("scripts.who_knocked/lockpick_menu")
local dialogueMenu = require("scripts.who_knocked.dialogue_menu")
local dialogueData = require("scripts.who_knocked.dialogue_data")
-- local lockpickData = require("scripts.who_knocked/lockpick_data")

-- Temporary inline lockpick data
local lockpickData = {
    doorTypes = {
        shack = {strength = 30, security = 20, magic = 25, name = "Shack Door"},
        house = {strength = 40, security = 30, magic = 35, name = "House Door"},
        manor = {strength = 60, security = 50, magic = 40, name = "Manor Door"},
        vault = {strength = 80, security = 90, magic = 70, name = "Vault Door"},
        shop = {strength = 45, security = 40, magic = 30, name = "Shop Door"},
        guild = {strength = 55, security = 45, magic = 50, name = "Guild Door"},
        temple = {strength = 50, security = 35, magic = 60, name = "Temple Door"},
        tavern = {strength = 40, security = 25, magic = 30, name = "Tavern Door"},
        generic = {strength = 30, security = 25, magic = 30, name = "Generic Door"}
    },
    chanceModifiers = {
        force = 0.7,
        pick = 0.6,
        magic = 0.8,
        master = 0.75
    },
    messages = {
        force = {
            success = "You force the door open with your strength!",
            fail = "The door resists your strength."
        },
        pick = {
            success = "Your lockpick skill opens the lock!",
            fail = "The lock proves too complex for your skills."
        },
        magic = {
            success = "Your alteration spell unlocks the door!",
            fail = "The magical resistance is too strong."
        },
        master = {
            success = "Your combined expertise opens the door!",
            fail = "The door defeats all your attempts."
        }
    }
}

local MOD_ID = "UniversalActivator"

-- Helper functions
local function msg(message)
    print("[" .. MOD_ID .. "] " .. message)
end


local function getDoorType(door)
    local recordId = door.recordId:lower()
    local cellName = door.cell.name:lower()
    
    msg("Debug: getDoorType called for " .. recordId)  -- Debug line to force reload
    
    -- Determine door type for response
    if recordId:find("shack") or cellName:find("shack") then
        return "residence"
    elseif recordId:find("house") or cellName:find("house") then
        return "residence"
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





-- Helper functions for inventory and spell validation
local function hasLockpicks()
    local inventory = types.Actor.inventory(self)
    return inventory:find("probe") ~= nil or inventory:find("lockpick") ~= nil
end

local function hasUnlockSpells()
    local playerSpells = types.Actor.spells(self)
    local unlockSpells = {
        "ondusi's open lock",
        "ondusi's open spell", 
        "unlock",
        "open lock",
        "simple unlock"
    }
    
    for _, spell in pairs(playerSpells) do
        if spell.id and spell.name then
            local spellNameLower = string.lower(spell.name)
            for _, unlockSpell in ipairs(unlockSpells) do
                if spellNameLower == string.lower(unlockSpell) or 
                   spellNameLower:find(unlockSpell) then
                    return true
                end
            end
        end
    end
    return false
end

-- Lockpick skill-based functions
local function getDoorDifficulty(door)
    local doorType = getDoorType(door)
    return lockpickData.doorTypes[doorType] or lockpickData.doorTypes.generic
end

local function tryForceLock(door)
    msg("DEBUG: tryForceLock function called")
    -- Safety check for door object
    if not door or not door.recordId then
        msg("Invalid door object in tryForceLock")
        ui.showMessage("Door reference lost. Please try again.")
        return false
    end
    
    -- Check if player has lockpicks for breaking
    if not hasLockpicks() then
        ui.showMessage("You need lockpicks to force locks.")
        return false
    end
    
    local difficulty = getDoorDifficulty(door)
    local playerStrength = types.Actor.stats.attributes.strength(self).current or 30
    local baseStrength = types.Actor.stats.attributes.strength(self).base or 30
    local modifiedStrength = types.Actor.stats.attributes.strength(self).modified or 30
    
    local successChance = (playerStrength / difficulty.strength) * lockpickData.chanceModifiers.force
    
    msg("Force Lock - Base: " .. baseStrength .. ", Current: " .. playerStrength .. ", Modified: " .. modifiedStrength .. " vs " .. difficulty.strength .. " (Chance: " .. successChance .. ")")
    
    msg("Force lock success chance: " .. successChance)
    if math.random() <= successChance then
        -- Send unlock request to global script (player scripts can't unlock doors directly)
        if door then
            core.sendGlobalEvent("UA_UnlockDoor", {
                door = door,
                method = "force",
                message = lockpickData.messages.force.success
            })
            
            ui.showMessage(lockpickData.messages.force.success)
            msg("Successfully forced lock: " .. door.recordId)
            return true
        else
            msg("Door object became invalid before unlock")
            ui.showMessage("Door reference lost during attempt. Please try again.")
            return false
        end
    else
        msg("Force lock FAILED - chance roll failed")
        ui.showMessage(lockpickData.messages.force.fail)
        return false
    end
end

local function tryPickLock(door)
    -- Check if player has lockpicks first
    if not hasLockpicks() then
        ui.showMessage("You need lockpicks to pick locks.")
        return false
    end
    
    local difficulty = getDoorDifficulty(door)
    local playerSecurity = types.NPC.stats.skills.security(self).current or 0
    local successChance = (playerSecurity / difficulty.security) * lockpickData.chanceModifiers.pick
    
    msg("Pick Lock - Security: " .. playerSecurity .. " vs " .. difficulty.security .. " (Chance: " .. successChance .. ")")
    
    if math.random() <= successChance then
        if door then
            core.sendGlobalEvent("UA_UnlockDoor", {
                door = door,
                method = "pick",
                message = lockpickData.messages.pick.success
            })
            
            -- Send reputation crime event
            core.sendGlobalEvent("Reputation_CrimeEvent", {
                type = "pick_lock",
                method = "pick",
                location = door.position
            })
            
            ui.showMessage(lockpickData.messages.pick.success)
            msg("Successfully picked lock: " .. door.recordId)
            return true
        else
            msg("Door object became invalid before unlock")
            ui.showMessage("Door reference lost during attempt. Please try again.")
            return false
        end
    else
        ui.showMessage(lockpickData.messages.pick.fail)
        return false
    end
end

local function tryMagicUnlock(door)
    -- Check if player has unlock spells first
    if not hasUnlockSpells() then
        ui.showMessage("You need unlock spells to use magic.")
        return false
    end
    
    local difficulty = getDoorDifficulty(door)
    local playerAlteration = types.NPC.stats.skills.alteration(self).current or 0
    local successChance = (playerAlteration / difficulty.magic) * lockpickData.chanceModifiers.magic
    
    msg("Magic Unlock - Alteration: " .. playerAlteration .. " vs " .. difficulty.magic .. " (Chance: " .. successChance .. ")")
    
    if math.random() <= successChance then
        if door then
            core.sendGlobalEvent("UA_UnlockDoor", {
                door = door,
                method = "magic",
                message = lockpickData.messages.magic.success
            })
            
            -- Send reputation crime event
            core.sendGlobalEvent("Reputation_CrimeEvent", {
                type = "magic_unlock",
                method = "magic",
                location = door.position
            })
            
            ui.showMessage(lockpickData.messages.magic.success)
            msg("Successfully magically unlocked: " .. door.recordId)
            return true
        else
            msg("Door object became invalid before unlock")
            ui.showMessage("Door reference lost during attempt. Please try again.")
            return false
        end
    else
        ui.showMessage(lockpickData.messages.magic.fail)
        return false
    end
end

local function tryMasterAttempt(door)
    -- Check if player has the required tools
    local hasTools = hasLockpicks() or hasUnlockSpells()
    if not hasTools then
        ui.showMessage("You need lockpicks or unlock spells for the master attempt.")
        return false
    end
    
    local difficulty = getDoorDifficulty(door)
    local playerStrength = types.Actor.stats.attributes.strength(self).current or 30
    local playerSecurity = types.NPC.stats.skills.security(self).current or 0
    local playerAlteration = types.NPC.stats.skills.alteration(self).current or 0
    
    -- Average of all three skills
    local combinedSkill = (playerStrength + playerSecurity + playerAlteration) / 3
    local combinedDifficulty = (difficulty.strength + difficulty.security + difficulty.magic) / 3
    local successChance = (combinedSkill / combinedDifficulty) * lockpickData.chanceModifiers.master
    
    msg("Master Attempt - Combined: " .. combinedSkill .. " vs " .. combinedDifficulty .. " (Chance: " .. successChance .. ")")
    
    if math.random() <= successChance then
        if door then
            core.sendGlobalEvent("UA_UnlockDoor", {
                door = door,
                method = "master",
                message = lockpickData.messages.master.success
            })
            
            -- Send reputation crime event
            core.sendGlobalEvent("Reputation_CrimeEvent", {
                type = "master_unlock",
                method = "master",
                location = door.position
            })
            
            ui.showMessage(lockpickData.messages.master.success)
            msg("Successfully master unlocked: " .. door.recordId)
            return true
        else
            msg("Door object became invalid before unlock")
            ui.showMessage("Door reference lost during attempt. Please try again.")
            return false
        end
    else
        ui.showMessage(lockpickData.messages.master.fail)
        return false
    end
end

-- NEW: Dialogue-based door entry functions
local function tryAdmireLock(door)
    msg("Executing admire attempt on: " .. tostring(door.recordId))
    
    local successChance = dialogueData.calculateSuccessChance("admire", door, self)
    local success = math.random() <= successChance
    
    if success then
        if door then
            core.sendGlobalEvent("UA_UnlockDoor", {
                door = door,
                method = "admire",
                message = dialogueData.getMessage("admire", true)
            })
            
            -- Send reputation success event
            local reputationData = dialogueData.getReputationData("admire", true)
            core.sendGlobalEvent("Reputation_CrimeEvent", {
                type = reputationData.type,
                method = "admire",
                points = reputationData.points,
                location = door.position
            })
            
            ui.showMessage(dialogueData.getMessage("admire", true))
            msg("Successfully admired lock: " .. door.recordId)
            return true
        else
            msg("Door object became invalid before unlock")
            ui.showMessage("Door reference lost during attempt. Please try again.")
            return false
        end
    else
        -- Handle failure - apply bounty and reputation loss
        local crimeData = dialogueData.getCrimeData("admire", false)
        local reputationData = dialogueData.getReputationData("admire", false)
        
        if crimeData.bounty > 0 then
            core.sendGlobalEvent("UA_ApplyBounty", {
                bounty = crimeData.bounty,
                crime = crimeData.crime,
                location = door.position
            })
        end
        
        if reputationData.points ~= 0 then
            core.sendGlobalEvent("Reputation_CrimeEvent", {
                type = reputationData.type,
                method = "admire",
                points = reputationData.points,
                location = door.position
            })
        end
        
        ui.showMessage(dialogueData.getMessage("admire", false))
        return false
    end
end

local function tryIntimidateLock(door)
    msg("Executing intimidate attempt on: " .. tostring(door.recordId))
    
    local successChance = dialogueData.calculateSuccessChance("intimidate", door, self)
    local success = math.random() <= successChance
    
    if success then
        if door then
            core.sendGlobalEvent("UA_UnlockDoor", {
                door = door,
                method = "intimidate",
                message = dialogueData.getMessage("intimidate", true)
            })
            
            -- Send reputation success event
            local reputationData = dialogueData.getReputationData("intimidate", true)
            core.sendGlobalEvent("Reputation_CrimeEvent", {
                type = reputationData.type,
                method = "intimidate",
                points = reputationData.points,
                location = door.position
            })
            
            ui.showMessage(dialogueData.getMessage("intimidate", true))
            msg("Successfully intimidated lock: " .. door.recordId)
            return true
        else
            msg("Door object became invalid before unlock")
            ui.showMessage("Door reference lost during attempt. Please try again.")
            return false
        end
    else
        -- Handle failure - apply bounty and reputation loss
        local crimeData = dialogueData.getCrimeData("intimidate", false)
        local reputationData = dialogueData.getReputationData("intimidate", false)
        
        if crimeData.bounty > 0 then
            core.sendGlobalEvent("UA_ApplyBounty", {
                bounty = crimeData.bounty,
                crime = crimeData.crime,
                location = door.position
            })
        end
        
        if reputationData.points ~= 0 then
            core.sendGlobalEvent("Reputation_CrimeEvent", {
                type = reputationData.type,
                method = "intimidate",
                points = reputationData.points,
                location = door.position
            })
        end
        
        ui.showMessage(dialogueData.getMessage("intimidate", false))
        return false
    end
end

local function tryBribeLock(door)
    msg("Executing bribe attempt on: " .. tostring(door.recordId))
    
    -- Check if player can afford the bribe
    if not dialogueData.canAffordBribe(door, self) then
        ui.showMessage("You don't have enough gold for this bribe.")
        return false
    end
    
    local successChance = dialogueData.calculateSuccessChance("bribe", door, self)
    local success = math.random() <= successChance
    
    if success then
        if door then
            -- Remove gold from player
            local difficulty = dialogueData.getDoorDifficulty(door)
            local bribeCost = difficulty.bribe.cost
            types.Actor.inventory.removeGold(self, bribeCost)
            
            core.sendGlobalEvent("UA_UnlockDoor", {
                door = door,
                method = "bribe",
                message = dialogueData.getMessage("bribe", true)
            })
            
            -- Send reputation event (neutral for bribe)
            local reputationData = dialogueData.getReputationData("bribe", true)
            if reputationData.points ~= 0 then
                core.sendGlobalEvent("Reputation_CrimeEvent", {
                    type = reputationData.type,
                    method = "bribe",
                    points = reputationData.points,
                    location = door.position
                })
            end
            
            ui.showMessage(dialogueData.getMessage("bribe", true))
            msg("Successfully bribed lock: " .. door.recordId)
            return true
        else
            msg("Door object became invalid before unlock")
            ui.showMessage("Door reference lost during attempt. Please try again.")
            return false
        end
    else
        -- Handle failure - apply bounty and reputation loss
        local crimeData = dialogueData.getCrimeData("bribe", false)
        local reputationData = dialogueData.getReputationData("bribe", false)
        
        if crimeData.bounty > 0 then
            core.sendGlobalEvent("UA_ApplyBounty", {
                bounty = crimeData.bounty,
                crime = crimeData.crime,
                location = door.position
            })
        end
        
        if reputationData.points ~= 0 then
            core.sendGlobalEvent("Reputation_CrimeEvent", {
                type = reputationData.type,
                method = "bribe",
                points = reputationData.points,
                location = door.position
            })
        end
        
        ui.showMessage(dialogueData.getMessage("bribe", false))
        return false
    end
end

local function scheduleResponse(data)
    -- Schedule the response after a short delay
    local delay = math.random(1.0, 3.0)
    
    -- Use a simple timer approach
    core.sendGlobalEvent("UA_ScheduleResponse", {
        message = data.message,  -- Fix: use data.message instead of data.response
        door = data.door,
        doorType = data.doorType,
        unlockChance = data.unlockChance,
        delay = delay
    })
end

return {
    eventHandlers = {
        UA_ShowKnockKnock = function(e)
            msg("Showing door choice menu for: " .. tostring(e.door.recordId))
            
            -- Show the choice menu instead of immediate knock
            doorChoiceMenu.showDoorChoice(e.door, self)
        end,
        
        
        UA_ExecuteLockpick = function(e)
            msg("Lockpick attempt on: " .. tostring(e.door.recordId))
            
            -- Check if lockpick system is enabled by sending a query and waiting
            -- For now, we'll use the settings check in the actual lockpick menu
            -- Send lockpick event back to player script
            lockpickMenu.showLockpickMenu(e.door, self)
        end,
        
        -- NEW: Dialogue-based door entry events
        UA_ExecuteDialogue = function(e)
            msg("Dialogue attempt on: " .. tostring(e.door.recordId))
            
            -- Check if dialogue system is enabled by sending a query and waiting
            -- For now, we'll use the settings check in the actual dialogue menu
            -- Send dialogue event back to player script
            dialogueMenu.showDialogueMenu(e.door, self)
        end,
        
        UA_ExecuteAdmire = function(e)
            msg("Executing admire attempt on: " .. tostring(e.door.recordId))
            tryAdmireLock(e.door)
        end,
        
        UA_ExecuteIntimidate = function(e)
            msg("Executing intimidate attempt on: " .. tostring(e.door.recordId))
            tryIntimidateLock(e.door)
        end,
        
        UA_ExecuteBribe = function(e)
            msg("Executing bribe attempt on: " .. tostring(e.door.recordId))
            tryBribeLock(e.door)
        end,
        
        UA_ExecuteForceLock = function(e)
            msg("Executing force lock on: " .. tostring(e.door.recordId))
            msg("Door object type: " .. type(e.door))
            msg("Door object: " .. tostring(e.door))
            tryForceLock(e.door)
        end,
        
        UA_ExecutePickLock = function(e)
            msg("Executing pick lock on: " .. tostring(e.door.recordId))
            tryPickLock(e.door)
        end,
        
        UA_ExecuteMagicUnlock = function(e)
            msg("Executing magic unlock on: " .. tostring(e.door.recordId))
            tryMagicUnlock(e.door)
        end,
        
        UA_ExecuteMasterAttempt = function(e)
            msg("Executing master attempt on: " .. tostring(e.door.recordId))
            tryMasterAttempt(e.door)
        end,
        
                
        UA_SpeechcraftChoice = function(e)
            msg("Speechcraft choice received: " .. e.choice)
            -- Forward to speechcraft module
            if speechcraftIntegration and speechcraftIntegration.handleConsoleCommand then
                speechcraftIntegration.handleConsoleCommand(e.choice)
            end
        end,
        
        -- NEW: Handle settings query responses from global script
        WhoKnocked_LockpickQueryResponse = function(e)
            msg("Lockpick query response: " .. (e.enabled and "ENABLED" or "DISABLED"))
            if e.enabled then
                -- System is enabled, proceed with lockpick menu
                lockpickMenu.showLockpickMenu(e.door, self)
            else
                -- System is disabled, silently return to normal gameplay
                -- No message shown to player
            end
        end,
        
        WhoKnocked_DialogueQueryResponse = function(e)
            msg("Dialogue query response: " .. (e.enabled and "ENABLED" or "DISABLED"))
            if e.enabled then
                -- System is enabled, proceed with dialogue menu
                dialogueMenu.showDialogueMenu(e.door, self)
            else
                -- System is disabled, silently return to normal gameplay
                -- No message shown to player
            end
        end
    }
}
