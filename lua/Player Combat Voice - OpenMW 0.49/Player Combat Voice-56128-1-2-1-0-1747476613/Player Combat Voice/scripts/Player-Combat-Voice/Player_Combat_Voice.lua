local input = require('openmw.input')
local self = require('openmw.self')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local interfaces = require('openmw.interfaces')
local storage = require('openmw.storage')
local animation = require('openmw.animation') 

-- Load settings
local combatVoiceSettings = storage.globalSection('SettingsPlayerCombatVoice')

-- Base sound lists
local attackSounds = {
    "A1.wav", "A2.wav", "A3.wav", "A4.wav", "A5.wav",
    "A6.wav", "A7.wav", "A8.wav", "A9.wav",
    "AL1.wav", "AL2.wav", "AL3.wav", "AL4.wav", "AL5.wav"
}
local hitSounds = {
    "H1.wav", "H2.wav", "H3.wav", "H4.wav", "H5.wav", "H6.wav"
}

local selfSpellSounds = { -- For self-cast spells
    "AL1.wav", "AL2.wav", "AL3.wav", "AL4.wav", "AL5.wav"
}
local touchTargetSpellSounds = { -- For touch and target spells
    "A1.wav", "A2.wav", "A3.wav", "A4.wav", "A5.wav", "A6.wav",
    "AL1.wav", "AL2.wav", "AL3.wav", "AL4.wav", "AL5.wav"
}

local marksmanSounds = {
    "AL1.wav", "AL2.wav", "AL3.wav", "AL4.wav", "AL5.wav"
}
local silentSound = "silent_hit.wav"

-- State variables
local wasPressed = false
local attackDelayTimer = 0
local triggerAttackSound = false
local pressTime = 0
local lastHealth = nil
local lastAttackSoundTime = 0
local attackCooldown = 1.0 -- Default value, not loaded from settings
local checkTimer = 0
-- local targetSpellState = "Idle" -- "Idle", "Triggered" -- This variable is not used in the current logic
local lastSpellCastTime = 0
-- local spellCastCooldown = 2.0 -- Removed spell cast cooldown
local marksmanPressTime = 0
local triggerMarksmanSound = false
local marksmanDelayTimer = 0
local lastMarksmanSoundTime = 0
local marksmanCooldown = 1.0 
local spellCastActivationDetected = false -- Flag set by the animation handler
local spellCastType = nil -- ADDED: To store the type of spell cast ('self' or 'touchtarget')
-- local spellCastDelayTimer = 0 -- Removed spell cast delay timer
-- local spellCastDelay = 0.9 -- Removed spell cast delay

-- Race/Gender folders
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
    ["wood elf"] = { male = "WOOD ELF FEMALE", female = "WOOD ELF FEMALE" }
}

-- getVoiceFolder
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

-- getSoundPath
local function getSoundPath(filename)
    local basePath = "Sound\\Vo\\Player-Voice\\"
    local voiceFolder = getVoiceFolder()
    return basePath .. voiceFolder .. "\\" .. filename
end

-- isMeleeWeaponEquipped
local function isMeleeWeaponEquipped()
    local weapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon then
        -- Check if the equipped item is actually a weapon and not a tool like lockpick or probe
        if not types.Lockpick.objectIsInstance(weapon) and not types.Probe.objectIsInstance(weapon) then
            local weaponRecord = types.Weapon.record(weapon)
            if weaponRecord then
                local weaponType = weaponRecord.type
                -- Melee weapon types (0-8)
                return weaponType >= 0 and weaponType <= 8
            end
        end
        return false -- It's a tool or not a weapon
    else
        return true -- Consider no weapon equipped as Hand-to-hand
    end
end

-- isMarksmanWeaponEquipped (Specific check for Bows and Thrown)
local function isMarksmanWeaponEquipped()
    local weapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon then
        -- Check if the equipped item is actually a weapon and not a tool like lockpick or probe
        if not types.Lockpick.objectIsInstance(weapon) and not types.Probe.objectIsInstance(weapon) then
            local weaponRecord = types.Weapon.record(weapon)
            if weaponRecord then
                local weaponType = weaponRecord.type
                -- Marksman weapon types (9-11)
                return weaponType >= 9 and weaponType <= 11
            end
        end
    end
    return false
end

-- Animation Text Key Handler for Spell Casting
-- MODIFIED: To set spellCastType based on the release key
interfaces.AnimationController.addTextKeyHandler('spellcast', function(groupName, key)
    if key == 'self release' then
        spellCastActivationDetected = true
        spellCastType = "self"
    elseif key == 'touch release' or key == 'target release' then
        spellCastActivationDetected = true
        spellCastType = "touchtarget"
    end
end)

-- onUpdate
local function onUpdate(dt)
    local isPaused = core.isWorldPaused()
    local mode = interfaces.UI and interfaces.UI:getMode()
    if isPaused or mode == "Dialogue" or mode == "Inventory" or mode == "Barter" or mode == "Container" or mode == "Alchemy" or mode == "Enchanting" or mode == "MerchantRepair" or mode == "SpellBuying" or mode == "SpellCreation" or mode == "Training" or mode == "Travel" or mode == "Companion" or mode == "Book" or mode == "Scroll" or mode == "Journal" or mode == "QuickKeysMenu" then
        return
    end

    local currentTime = core.getSimulationTime()
    local currentHealth = types.Actor.stats.dynamic.health(self).current
    local isWeaponStance = types.Actor.stance(self) == types.Actor.STANCE.Weapon
    local isSpellReadyStance = types.Actor.stance(self) == types.Actor.STANCE.Spell
    local isAttacking = input.isActionPressed(input.ACTION.Use)

    -- Marksman Sound Logic (Mimicking Melee for Bows and Thrown)
    if isWeaponStance and isMarksmanWeaponEquipped() then
        if isAttacking then
            marksmanPressTime = marksmanPressTime + dt
        elseif not isAttacking and wasPressed then
            marksmanDelayTimer = 0.03
            triggerMarksmanSound = true
        end

        if triggerMarksmanSound and marksmanDelayTimer > 0 then
            marksmanDelayTimer = marksmanDelayTimer - dt
            if marksmanDelayTimer <= 0 then
                if marksmanPressTime > 0.4 and (currentTime - lastMarksmanSoundTime >= marksmanCooldown) then
                    if combatVoiceSettings:get('EnableMarksmanSounds') then
                        local triggerChance = combatVoiceSettings:get('MarksmanChance') / 100
                        if math.random() <= triggerChance then
                            if #marksmanSounds > 0 then -- ADDED: Safety check
                                local soundFile = marksmanSounds[math.random(1, #marksmanSounds)]
                                local soundPath = getSoundPath(soundFile)
                                core.sound.say(soundPath, self, {
                                    volume = 1.0,
                                    pitch = 0.9 + math.random() * 0.2,
                                    isVoice = true,
                                    loop = false
                                })
                                lastMarksmanSoundTime = currentTime
                            end
                        end
                    end
                end
                triggerMarksmanSound = false
                marksmanPressTime = 0
            end
        end
    end

    -- Spell Cast Logic (Trigger on Animation Text Key - Immediate Playback)
    
    if isSpellReadyStance and spellCastActivationDetected and spellCastType then
        if combatVoiceSettings:get('EnableSpellCastSounds') then
            local triggerChance = combatVoiceSettings:get('SpellCastChance') / 100
            if math.random() <= triggerChance then
                local soundFile = nil
                if spellCastType == "self" then
                    if #selfSpellSounds > 0 then -- Check if the list is not empty
                        soundFile = selfSpellSounds[math.random(1, #selfSpellSounds)]
                    end
                elseif spellCastType == "touchtarget" then
                    if #touchTargetSpellSounds > 0 then -- Check if the list is not empty
                        soundFile = touchTargetSpellSounds[math.random(1, #touchTargetSpellSounds)]
                    end
                end

                if soundFile then -- Only play if a soundFile was selected
                    local soundPath = getSoundPath(soundFile)
                    core.sound.say(soundPath, self, {
                        volume = 1.0,
                        pitch = 0.9 + math.random() * 0.2,
                        isVoice = true,
                        loop = false
                    })
                    lastSpellCastTime = currentTime
                end
            end
        end
        spellCastActivationDetected = false -- Reset the flag
        spellCastType = nil -- Reset the type
    end

    -- Melee Attack Logic
    if not isSpellReadyStance then -- Ensure melee logic doesn't run if spell is ready (relevant if player switches stance quickly)
        if isAttacking then
            pressTime = pressTime + dt
        elseif not isAttacking and wasPressed then
            attackDelayTimer = 0.01
            triggerAttackSound = true
        end

        if triggerAttackSound and attackDelayTimer > 0 then
            attackDelayTimer = attackDelayTimer - dt
            if attackDelayTimer <= 0 then
                if isWeaponStance and pressTime > 0.3 and (currentTime - lastAttackSoundTime >= attackCooldown) and isMeleeWeaponEquipped() then
                    if combatVoiceSettings:get('EnableAttackSounds') then
                        local triggerChance = combatVoiceSettings:get('AttackChance') / 100
                        if math.random() <= triggerChance then
                             if #attackSounds > 0 then -- ADDED: Safety check
                                local soundFile = attackSounds[math.random(1, #attackSounds)]
                                local soundPath = getSoundPath(soundFile)
                                core.sound.say(soundPath, self, {
                                    volume = 1.0,
                                    pitch = 0.9 + math.random() * 0.2,
                                    isVoice = true,
                                    loop = false
                                })
                                lastAttackSoundTime = currentTime
                            end
                        end
                    end
                end
                triggerAttackSound = false
                pressTime = 0
            end
        end
    end

    wasPressed = isAttacking

    -- Health Check Logic for Hits
    if lastHealth == nil then
        lastHealth = currentHealth
    elseif currentHealth < lastHealth then
        local damageTaken = lastHealth - currentHealth
        local silentPath = getSoundPath(silentSound)
        if silentPath then core.sound.say(silentPath, self, { volume = 1.0, pitch = 1.0, isVoice = true }) end
        if damageTaken >= 4 then
            if math.random() < 0.5 then -- Original script had a 50% chance here, separate from HitChance
                if combatVoiceSettings:get('EnableHitSounds') then
                    local triggerChance = combatVoiceSettings:get('HitChance') / 100
                    if math.random() <= triggerChance then
                        if #hitSounds > 0 then -- ADDED: Safety check
                            local soundFile = hitSounds[math.random(1, #hitSounds)]
                            local soundPath = getSoundPath(soundFile)
                            core.sound.say(soundPath, self, {
                                volume = 1.0,
                                pitch = 0.9 + math.random() * 0.2,
                                isVoice = true
                            })
                        end
                    end
                end
            end
        end
    end
    lastHealth = currentHealth
end -- end onUpdate

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}