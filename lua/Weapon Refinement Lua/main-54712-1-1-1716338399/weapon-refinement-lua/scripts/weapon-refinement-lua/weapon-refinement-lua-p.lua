local ui = require('openmw.ui')
local self = require('openmw.self')
local core = require('openmw.core')
local types = require("openmw.types")
local ambient = require("openmw.ambient")
local interface = require('openmw.interfaces')
local skill = require('openmw.interfaces').SkillProgression

--These classes for npcs automatically are given anvils when you try to barter with them
local allowedClasses = {
    ["merchant"] = true,
    ["pawnbroker"] = true,
    ["smuggler"] = true,
    ["trader"] = true,
    ["trader service"] = true,
    ["T_Glb_TraderService"] = true,
    ["T_Glb_Trader"] = true
    --T_Glb entries are for TR
    --originally, wanted to give more npc factions the ability to sell anvils. However, didnt work out due to how openmw's bartering system works. Leaving these commented until I find a workaround.
    --["miner"] = true,
    --["smith"] = true,
    --["Master-at-Arms"] = true,
    --["Drillmaster"] = true,
    --["Warrior"] = true,
    --["Barbarian"] = true
}

local function RefinePlaySound(data)
    local params = {
        timeOffset=0.1,
        volume=0.3,
        scale=false,
        pitch=1.0,
        loop=false
     };
     ambient.playSound(data.sound, params)
end

-- Function to request the record handler to give the player a fancy dagger
local function BoundWeaponHurtPlayer(value)
    local playerHealth = types.Actor.stats.dynamic.health(self).current
    types.Actor.stats.dynamic.health(self).current = (playerHealth - value)
    types.Actor.stats.dynamic.fatigue(self).current = -10
    --ui.showMessage("Before resolution!" .. tostring(refineAttempt))
end

-- Function to request the record handler to give the player a fancy dagger
local function initiateRefineAttempt()
    local playerCharacter = self
    local playerArmorer = self.type.stats.skills.armorer(self).modified
    local playerLuck = self.type.stats.attributes.luck(self).modified
    local playerAgility = self.type.stats.attributes.agility(self).modified
    local playerIntelligence = self.type.stats.attributes.intelligence(self).modified
    local playerFatigue = types.Actor.stats.dynamic.fatigue(self).current
    local playerFatigueMax = types.Actor.stats.dynamic.fatigue(self).base

    local refineAttempt = core.sendGlobalEvent("mainWeaponRefinement",{
        player=playerCharacter,
        armorer=playerArmorer,
        luck=playerLuck,
        agility=playerAgility,
        intelligence=playerIntelligence,
        fatigue=playerFatigue,
        fatigueMax=playerFatigueMax
    })
    types.Actor.stats.dynamic.fatigue(self).current = (playerFatigue - 10)
    --ui.showMessage("Before resolution!" .. tostring(refineAttempt))
end

--Tiny method to give the player a skill up when they refine a weapon
local function skillUpFromRefine(data)
    --Keep this kind of low because you can really easily use refining to make a ton of gold by saving all cheap weapons, refining them a ton, then selling them. ( Aka Skyrim's loop )
    local params = {
        skillGain = 0.4,
        useType = 0
    }
    skill.skillUsed("armorer", params)
end

-- Function to handle the result message from the global script
local function handleResultMessage(data)
    if data then
        --ui.showMessage("Received data")
        -- Debug: Show the entire data structure
        if data.message then
            --ui.showMessage("Message: " .. data.message)
            ui.showMessage(data.message)
        else
            ui.showMessage("Data does not contain 'message' field")
        end
    else
        ui.showMessage("No data received from global script")
    end
end

--This method checks to see, when we talk to a NPC, if we should give them an anvil that we can buy from them.
--It does this by checking 
local function getMerchant(data)
    if data.arg ~= nil and --'data.arg' is a NPC. This means we are talking to something
       data.arg.type == types.NPC and --Get the type of the thing we are talking to, was it a NPC?
       data.oldMode == nil and --We aren't going from one UI mode to another UI mode. Aka we are initiating this UI mode.
       data.newMode == "Dialogue" then --This UI mode is dialogue. Aka, we are talking to a NPC and have initiated the dialogue window.

        local class = types.NPC.record(data.arg).class
        --This prints the class to the dialogue box, pretty cool
        --ui.showMessage(class)

        --If this npc is willing to sell us stuff..
        if types.NPC.record(data.arg).servicesOffered["Barter"] and 
           --If this NPC is in the fighters guild, or this npc is in our allowed classes likely to want to sell us an anvil, give them an anvil.
           (types.NPC.getFactionRank(data.arg, "Fighters Guild") > 0 or allowedClasses[class]) then
            data.player = self
            core.sendGlobalEvent("CreateAnvilForMerchant", data)
        end
    end
end


return {
    eventHandlers = {
        boundWeaponHurtPlayer = BoundWeaponHurtPlayer,
        attemptRefineWeapon = initiateRefineAttempt,
        displayResultMessage = handleResultMessage,
        UiModeChanged = getMerchant,
        refinePlaySound = RefinePlaySound,
        SkillUpFromRefine = skillUpFromRefine
    }
}