local healthFlag, fatigueFlag, magickaFlag, diseaseFlag, blightFlag = 0, 0, 0, 0, 0

local healthTimer, fatigueTimer, magickaTimer, diseaseTimer, blightTimer
local genderFatigue, genderDisease = "", ""
local player

local config = require("tew.AURA.config")
local PChealth = config.PChealth
local PCfatigue = config.PCfatigue
local PCmagicka = config.PCmagicka
local PCDisease = config.PCDisease
local PCBlight = config.PCBlight
local vsVol = config.volumes.misc.vsVol / 100

-- People don't cough underwater I guess --
local function isPlayerUnderWater()
    local cell = tes3.getPlayerCell()
    if cell.hasWater then
        local waterHeight = cell.waterLevel or 0
        local playerZ = tes3.player.position.z
        local height = playerZ - waterHeight
        if height < -50 then
            return true
        end
    end
    return false
end

-- Determine player g-e-n-d-e-r on load --
-- Awfully binary that one! >:-( --
local function onLoaded()
    if tes3.player.object.female then
        genderFatigue = "fatigue_f.mp3"
        genderDisease = "disease_f.wav"
    else
        genderFatigue = "fatigue_m.mp3"
        genderDisease = "disease_m.wav"
    end
    -- ... right? --
    player = tes3.mobilePlayer
end

-- Check for disease, which is actually a spell type --
local function checkDisease(ref)
    local disease
    for spell in tes3.iterate(ref.object.spells.iterator) do
        if (spell.castType == tes3.spellType.disease) then
            disease = "Disease"
            break
        end
    end
    return disease
end

-- Same as above, just for Blight --
local function checkBlight(ref)
    local blight
    for spell in tes3.iterate(ref.object.spells.iterator) do
        if (spell.castType == tes3.spellType.blight) then
            blight = "Blight"
            break
        end
    end
    return blight
end

-- Play cough stuff if the player is diseased --
local function playDisease()
    if diseaseFlag == 1 then return end
    if not diseaseTimer then
        diseaseTimer = timer.start { type = timer.real, duration = 20, iterations = -1, callback = function()
            tes3.playSound { soundPath = "tew\\A\\PC\\" .. genderDisease, volume = 0.7 * vsVol, reference = player }
        end }
    else
        diseaseTimer:resume()
    end
    diseaseFlag = 1
end

-- Shudder before Ur! --
local function playBlight()
    if blightFlag == 1 then return end
    if not blightTimer then
        blightTimer = timer.start { type = timer.real, duration = 35, iterations = -1, callback = function()
            tes3.playSound { soundPath = "tew\\A\\PC\\blight.wav", volume = 0.9 * vsVol, reference = player }
        end }
    else
        blightTimer:resume()
    end
    blightFlag = 1
end

-- Thum thum, thum thum --
-- Actually it plays nicely with "starving" effect from Ashfall as well --
local function playHealth()
    if healthFlag == 1 then return end
    if not healthTimer then
        healthTimer = timer.start { type = timer.real, duration = 1.2, iterations = -1, callback = function()
            tes3.playSound { soundPath = "tew\\A\\PC\\health.wav", volume = 0.7 * vsVol, reference = player }
        end }
    else
        healthTimer:resume()
    end
    healthFlag = 1
end

-- Me when standing up for a minute: --
local function playFatigue()
    if fatigueFlag == 1 then return end
    if not fatigueTimer then
        fatigueTimer = timer.start { type = timer.real, duration = 10, iterations = -1, callback = function()
            tes3.say {
                volume = 0.9 * vsVol,
                soundPath = "Vo\\tew\\A\\PC\\" .. genderFatigue, reference = player
            }
        end }
    else
        fatigueTimer:resume()
    end
    fatigueFlag = 1
end

-- Weeeeeuuuuiii no casting for ya --
local function playMagicka()
    if magickaFlag == 1 then return end
    if not magickaTimer then
        magickaTimer = timer.start { type = timer.real, duration = 12, iterations = -1, callback = function()
            tes3.playSound { soundPath = "tew\\A\\PC\\magicka.wav", volume = 0.6 * vsVol, pitch = 0.8, reference = player }
        end }
    else
        magickaTimer:resume()
    end
    magickaFlag = 1
end

-- Centralised vitals resolver --
local function playVitals()

    if PChealth then

        local health = player.health.normalized

        if health < 0.33 then
            playHealth()
        else
            if healthTimer then
                healthTimer:pause()
            end
            healthFlag = 0
        end
    end

    if PCfatigue then

        if isPlayerUnderWater() == true then
            if fatigueTimer then
                fatigueTimer:pause()
            end
            fatigueFlag = 0
            return
        end

        local fatigue = player.fatigue.normalized

        if fatigue < 0.33 then
            playFatigue()
        else
            if fatigueTimer then
                fatigueTimer:pause()
            end
            fatigueFlag = 0
        end
    end

    if PCmagicka then

        local magicka = player.magicka.normalized

        if magicka < 0.33 then
            playMagicka()
        else
            if magickaTimer then
                magickaTimer:pause()
            end
            magickaFlag = 0
        end
    end


    if PCDisease then
        local disease = checkDisease(player)
        if disease == "Disease" then
            playDisease()
        else
            if diseaseTimer then
                diseaseTimer:pause()
            end
            diseaseFlag = 0
        end
    end

    if PCBlight then
        local blight = checkBlight(player)
        if blight == "Blight" then
            playBlight()
        else
            if blightTimer then
                blightTimer:pause()
            end
            blightFlag = 0
        end
    end

end

-- For underwater stuff --
local function positionCheck()
    if PCfatigue then
        if fatigueTimer then
            fatigueTimer:pause()
        end
        fatigueFlag = 0
    end
    if PCDisease then
        if diseaseTimer then
            diseaseTimer:pause()
        end
        diseaseFlag = 0
    end

    if PCBlight then
        if blightTimer then
            blightTimer:pause()
        end
        blightFlag = 0
    end
end

event.register("uiActivated", positionCheck, { filter = "MenuSwimFillBar" })
event.register("loaded", onLoaded)
event.register("simulate", playVitals)
