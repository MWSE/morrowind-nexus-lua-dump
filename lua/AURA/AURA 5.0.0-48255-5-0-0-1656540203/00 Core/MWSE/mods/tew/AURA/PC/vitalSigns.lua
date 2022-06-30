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
local vsVol = config.vsVol/200

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

local function onLoaded()

    if tes3.player.object.female then
        genderFatigue = "fatigue_f.mp3"
        genderDisease = "disease_f.wav"
    else
        genderFatigue = "fatigue_m.mp3"
        genderDisease = "disease_m.wav"
    end

    player = tes3.mobilePlayer

end

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

local function playDisease()
    if diseaseFlag == 1 then return end
    if not diseaseTimer then
        diseaseTimer = timer.start{type=timer.real, duration=20, iterations=-1, callback=function()
            tes3.playSound{soundPath="tew\\A\\PC\\"..genderDisease, volume=0.7*vsVol, reference=player}
        end}
    else
        diseaseTimer:resume()
    end
    diseaseFlag = 1
end

local function playBlight()
    if blightFlag == 1 then return end
    if not blightTimer then
        blightTimer = timer.start{type=timer.real, duration=35, iterations=-1, callback=function()
            tes3.playSound{soundPath="tew\\A\\PC\\blight.wav", volume=0.9*vsVol, reference=player}
        end}
    else
        blightTimer:resume()
    end
    blightFlag = 1
end

local function playHealth()
    if healthFlag == 1 then return end
    if not healthTimer then
        healthTimer = timer.start{type=timer.real, duration=1.2, iterations=-1, callback=function()
            tes3.playSound{soundPath="tew\\A\\PC\\health.wav", volume=0.7*vsVol, reference=player}
        end}
    else
        healthTimer:resume()
    end
    healthFlag = 1
end

local function playFatigue()
    if fatigueFlag == 1 then return end
    if not fatigueTimer then
        fatigueTimer = timer.start{type=timer.real, duration=10, iterations=-1, callback=function()
            tes3.say{
                volume=0.9*vsVol,
                soundPath="Vo\\tew\\A\\PC\\"..genderFatigue, reference=player
            }
        end}
    else
        fatigueTimer:resume()
    end
    fatigueFlag = 1
end

local function playMagicka()
    if magickaFlag == 1 then return end
    if not magickaTimer then
        magickaTimer = timer.start{type=timer.real, duration=12, iterations=-1, callback=function()
            tes3.playSound{soundPath="tew\\A\\PC\\magicka.wav", volume=0.6*vsVol, pitch=0.8, reference=player}
        end}
    else
        magickaTimer:resume()
    end
    magickaFlag = 1
end

local function playVitals()

    if PChealth then

        local maxHealth = player.health.base
        local currentHealth = player.health.current

        if currentHealth < maxHealth/3 then
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

        local maxFatigue = player.fatigue.base
        local currentFatigue = player.fatigue.current

        if currentFatigue < maxFatigue/3 then
            playFatigue()
        else
            if fatigueTimer then
                fatigueTimer:pause()
            end
            fatigueFlag = 0
        end
    end

    if PCmagicka then

        local maxMagicka = player.magicka.base
        local currentMagicka = player.magicka.current

        if currentMagicka < maxMagicka/3 then
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

event.register("uiActivated", positionCheck, {filter="MenuSwimFillBar"})
event.register("loaded", onLoaded)
event.register("simulate", playVitals)