local function AcidRain()
    if (tes3.mobilePlayer.cell.isOrBehavesAsExterior == false) then
        return
    end
    
local weather 
weather = tes3.getCurrentWeather()
weatherCheck = weather.index

    if (weatherCheck == 4 or weatherCheck == 5) then
        tes3.messageBox("You should find a shelter, the rain is hurting you.")
        tes3.mobilePlayer:applyDamage({ damage = 1, applyArmor = true, resistAttribute = 9 })
    end
end

local function StartTimer()
    timer.register("AcidRainMyTimer", AcidRain)
    timer.start({ persist = true, duration = 1, callback = "AcidRainMyTimer", iterations = -1})
end

local function initialized()
    event.register("loaded", StartTimer)
    print("[Acid Rain] Acid Rain initialized")
end

event.register("initialized", initialized)