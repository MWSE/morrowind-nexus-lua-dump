-- Player_Combat_Voice.lua (Volume Removed, Disable/Enable Added, Configurable Trigger Chances, Marksman Sounds - Trigger on Spell Activation via Animation Key - Release Keys, No Cooldown/Delay)

local input = require('openmw.input')
local self = require('openmw.self')
local core = require('openmw.core')
local ui = require('openmw.ui')
local types = require('openmw.types')
local interfaces = require('openmw.interfaces')
local storage = require('openmw.storage')
local animation = require('openmw.animation') -- Required for text key handling

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
local spellCastSounds = {
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
local targetSpellState = "Idle" -- "Idle", "Triggered"
local lastSpellCastTime = 0
-- local spellCastCooldown = 2.0 -- Removed spell cast cooldown
local marksmanPressTime = 0
local triggerMarksmanSound = false
local marksmanDelayTimer = 0
local lastMarksmanSoundTime = 0
local marksmanCooldown = 1.0 -- Increased cooldown for marksman sounds
local spellCastActivationDetected = false -- Flag set by the animation handler
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
    ["wood elf"] = { male = "WOOD ELF MALE", female = "WOOD ELF FEMALE" }
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
        local weaponType = types.Weapon.record(weapon).type
        return weaponType == 0 or weaponType == 1 or weaponType == 2 or weaponType == 3 or weaponType == 4 or weaponType == 6
    else
        return true -- Consider no weapon equipped as Hand-to-hand
    end
end

-- isMarksmanWeaponEquipped (Specific check for Bows and Thrown)
local function isMarksmanWeaponEquipped()
    local weapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon then
        local weaponType = types.Weapon.record(weapon).type
        return weaponType == 9 or weaponType == 11
    else
        return false
    end
end

-- Animation Text Key Handler for Spell Casting
interfaces.AnimationController.addTextKeyHandler('spellcast', function(groupName, key)
    if key == 'self release' or key == 'touch release' or key == 'target release' then
        spellCastActivationDetected = true
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
    local isAttacking = input.isMouseButtonPressed(1)

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
                triggerMarksmanSound = false
                marksmanPressTime = 0
            end
        end
    end

    -- Spell Cast Logic (Trigger on Animation Text Key - Immediate Playback)
    if isSpellReadyStance and spellCastActivationDetected then
        if combatVoiceSettings:get('EnableSpellCastSounds') then
            local triggerChance = combatVoiceSettings:get('SpellCastChance') / 100
            if math.random() <= triggerChance then
                local soundFile = spellCastSounds[math.random(1, #spellCastSounds)]
                local soundPath = getSoundPath(soundFile)
                core.sound.say(soundPath, self, {
                    volume = 1.0,
                    pitch = 0.9 + math.random() * 0.2,
                    isVoice = true,
                    loop = false
                })
                lastSpellCastTime = currentTime -- Still updating this for potential future use
            end
        end
        spellCastActivationDetected = false -- Reset the flag immediately
    end

    -- Melee Attack Logic
    if not isSpellReadyStance then
        if isAttacking then
            pressTime = pressTime + dt
        elseif not isAttacking and wasPressed then
            attackDelayTimer = 0.03
            triggerAttackSound = true
        end

        if triggerAttackSound and attackDelayTimer > 0 then
            attackDelayTimer = attackDelayTimer - dt
            if attackDelayTimer <= 0 then
                if isWeaponStance and pressTime > 0.3 and (currentTime - lastAttackSoundTime >= attackCooldown) and isMeleeWeaponEquipped() then
                    if combatVoiceSettings:get('EnableAttackSounds') then
                        local triggerChance = combatVoiceSettings:get('AttackChance') / 100
                        if math.random() <= triggerChance then
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
            if math.random() < 0.5 then
                if combatVoiceSettings:get('EnableHitSounds') then
                    local triggerChance = combatVoiceSettings:get('HitChance') / 100
                    if math.random() <= triggerChance then
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
    lastHealth = currentHealth
end -- end onUpdate

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}