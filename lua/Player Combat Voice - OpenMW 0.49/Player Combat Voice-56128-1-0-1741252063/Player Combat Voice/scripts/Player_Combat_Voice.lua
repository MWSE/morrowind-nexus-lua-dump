local input = require('openmw.input')
local self = require('openmw.self')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local interfaces = require('openmw.interfaces')

-- Base sound lists
local attackSounds = {
    "A1.wav", "A2.wav", "A3.wav", "A4.wav", "A5.wav",
    "A6.wav", "A7.wav", "A8.wav", "A9.wav"
}
local hitSounds = {
    "H1.wav", "H2.wav", "H3.wav", "H4.wav", "H5.wav", "H6.wav"
}
local silentSound = "silent_hit.wav"
local breathSound = "breath.wav"

local wasPressed = false
local attackDelayTimer = 0
local triggerAttackSound = false
local pressTime = 0
local lastHealth = nil
local lastAttackSoundTime = 0
local attackCooldown = 1.0
local breathSoundId = nil
local checkTimer = 0
local breathShouldPlay = false
local isInventoryOpen = false 
local wasInventoryKeyPressed = false 

local raceGenderFolders = {
    ["argonian"] = { male = "ARGONIAN MALE", female = "ARGONIAN FEMALE" },
    ["breton"] = { male = "BRETON MALE", female = "BRETON FEMALE" },
    ["dark elf"] = { male = "DARK ELF MALE", female = "DARK ELF FEMALE" },
    ["high elf"] = { male = "HIGH ELF MALE", female = "HIGH ELF FEMALE" },
    ["imperial"] = { male = "IMPERIAL MALE", female = "IMPERIAL FEMALE" },
    ["khajiit"] = { male = "KHAJIIT MALE", female = "KHAJIIT FEMALE" },
    ["nord"] = { male = "NORD MALE", female = "NORD FEMALE" },
    ["orc"] = { male = "ORC MALE", female = "ORC FEMALE" },
    ["redguard"] = { male = "REDGUARD MALE", female = "REDGUARD FEMALE" },
    ["wood elf"] = { male = "WOOD ELF MALE", female = "WOOD ELF FEMALE" }
}

local function getVoiceFolder()
    local npcRecord = types.NPC.record(self)
    local race = npcRecord.race:lower()
    local isMale = npcRecord.isMale
    local folder = raceGenderFolders[race]
    if folder then
        return folder[isMale and "male" or "female"]
    else
        return "CUSTOM RACE"
    end
end

local function getSoundPath(filename)
    local basePath = "Sound\\Vo\\Player-Voice\\"
    local voiceFolder = getVoiceFolder()
    return basePath .. voiceFolder .. "\\" .. filename
end

local function isMarksmanWeaponEquipped()
    local weapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon and weapon.type == types.Weapon then
        local weaponType = types.Weapon.record(weapon).type
        return weaponType == types.Weapon.TYPE.MarksmanBow or
               weaponType == types.Weapon.TYPE.MarksmanCrossbow or
               weaponType == types.Weapon.TYPE.MarksmanThrown
    end
    return false
end

local function onUpdate(dt)
    local isPaused = core.isWorldPaused()
    local isPressed = input.isMouseButtonPressed(1)
    local isDialogue = interfaces.UI and interfaces.UI:getMode() == "Dialogue"
    local inventoryKeyPressed = input.isActionPressed(input.ACTION.Inventory)
    local currentTime = core.getSimulationTime()

    if inventoryKeyPressed and not wasInventoryKeyPressed then
        isInventoryOpen = not isInventoryOpen
    end
    wasInventoryKeyPressed = inventoryKeyPressed

    if isPaused or isDialogue then
        return
    end

    local currentHealth = types.Actor.stats.dynamic.health(self).current
    local isWeaponStance = types.Actor.stance(self) == types.Actor.STANCE.Weapon

    if not isInventoryOpen then
        if isPressed then
            pressTime = pressTime + dt
        elseif not isPressed and wasPressed then
            attackDelayTimer = 0.03
            triggerAttackSound = true
        end
        if triggerAttackSound and attackDelayTimer > 0 then
            attackDelayTimer = attackDelayTimer - dt
            if attackDelayTimer <= 0 then
                if isWeaponStance and pressTime > 0.5 and (currentTime - lastAttackSoundTime >= attackCooldown) and not isMarksmanWeaponEquipped() then
                    local soundFile = attackSounds[math.random(1, #attackSounds)]
                    local soundPath = getSoundPath(soundFile)
                    core.sound.say(soundPath, self, { volume = 1.0, pitch = 0.9 + math.random() * 0.2, isVoice = true, loop = false })
                    lastAttackSoundTime = currentTime
                end
                triggerAttackSound = false
                pressTime = 0
            end
        end
    end
    wasPressed = isPressed

    if lastHealth == nil then
        lastHealth = currentHealth
    elseif currentHealth < lastHealth then
        local damageTaken = lastHealth - currentHealth
        local silentPath = getSoundPath(silentSound)
        core.sound.say(silentPath, self, { volume = 1.0, pitch = 1.0, isVoice = true })
        
        if damageTaken >= 4 or types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight) == nil then 
            if math.random() < 0.5 then
                local soundFile = hitSounds[math.random(1, #hitSounds)]
                local soundPath = getSoundPath(soundFile)
                core.sound.say(soundPath, self, { volume = 1.0, pitch = 0.9 + math.random() * 0.2, isVoice = true })
            end
        end
    end
    lastHealth = currentHealth
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
