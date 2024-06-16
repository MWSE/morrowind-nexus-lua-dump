--[[
Just sneaking one last mod in :)

This is just the start of possibly a much larger mod.

Enchanted Pools

There is a new small pool that has appeared at the end of a valley just west of Dagon Fel. 
It appears to have magical properties under certain weather conditions.

Future development:
Add more pools everywhere and with different effects depending on weather conditions, time of day/night etc.

local weatherTypes = { "Clear", "Cloudy", "Foggy", "Overcast", "Rain", "Thunderstorm", "Ash", "Blight", "Snow", "Blizzard" }

-]]

-- Debug message to ensure the script is loaded
mwse.log("[Enchanted Pools] Loaded successfully.")

-- Function to check if it is raining
local function isRaining()
    local weather = tes3.getCurrentWeather()
    return weather.index == tes3.weather.rain or weather.index == tes3.weather.thunder
end

-- Define the start and end times for night (in hours)
-- local nightStart = 20  -- 8 PM
-- local nightEnd = 6     -- 6 AM
-- -- Function to check if it's night
-- local function isNight()
--     local hour = tes3.worldController.hour.value
--     return hour >= nightStart or hour < nightEnd
-- end
-- Function to check if it is sunny
-- local function isRaining()
--     local weather = tes3.getCurrentWeather()
--     return weather.index == tes3.weather.clear or weather.index == tes3.weather.cloudy
-- end
-- Function to check if it is snowy
-- local function isRaining()
--     local weather = tes3.getCurrentWeather()
--     return weather.index == tes3.weather.snow or weather.index == tes3.weather.blizzard
-- end
-- Function to check if it is ash
-- local function isRaining()
--     local weather = tes3.getCurrentWeather()
--     return weather.index == tes3.weather.ash or weather.index == tes3.weather.blight
-- end

-- Function to grant the player full health, stamina, and magicka
local function grantFullStats()
    local player = tes3.player.mobile
    player.health.current = player.health.base
    player.fatigue.current = player.fatigue.base
    player.magicka.current = player.magicka.base
    tes3.messageBox("As you drink from the pool you have been granted full health, stamina, and magicka.")
end

-- Function to activate the enchanted pool
local function activateRainPool()
    if isRaining() then
        grantFullStats()
        tes3.messageBox("The enchanted pool has been activated because it is raining.")
    else
        tes3.messageBox("The enchanted pool can only be activated when it is raining.")
    end
end

-- Example usage: Activate the enchanted pool when the player activates a specific object
local function tw_ActivatePool(e)
    if e.target.id == "tw_pool00" then  -- Rain pool object
        activateRainPool()  -- "Rain", "Thunderstorm"
        return false  -- Prevents the default activation action
	--elseif e.target.id == "tw_pool01" then
    --    activateSunPool()  -- "Clear", "Cloudy" and do what???
    --    return false  -- Prevents the default activation action
	--elseif e.target.id == "tw_pool02" then  
    --    activateAshPool()   -- "Ash", "Blight" and do what??? 
    --    return false  -- Prevents the default activation action
	--elseif e.target.id == "tw_pool03" then   
    --    activateIcePool()  -- "Snow", "Blizzard" and do what???
    --    return false  -- Prevents the default activation action
 	--elseif e.target.id == "tw_pool04" then   
    --    activateMoonPool()  -- night time/ moon cycle and do what???
    --    return false  -- Prevents the default activation action
    end
end

-- Register the event listener for object activation
event.register("activate", tw_ActivatePool)

--[[  Possible effects for different times and random skill advancement.....

-- List of player skills
local skills = {
    "block", "armorer", "mediumarmor", "heavyarmor", "bluntweapon",
    "longblade", "axe", "spear", "athletics", "enchant", "destruction",
    "alteration", "illusion", "conjuration", "mysticism", "restoration",
    "alchemy", "unarmored", "security", "sneak", "acrobatics", "lightarmor",
    "shortblade", "marksman", "mercantile", "speechcraft", "handtohand"
}

-- Function to grant a random skill increase to the player
local function grantRandomSkill()
    local skillIndex = math.random(1, #skills)
    local skillName = skills[skillIndex]

    -- Get the player's current skill value
    local skillValue = tes3.mobilePlayer[skillName].current
    -- Increase the skill value by 5
    tes3.setStatistic{
        reference = tes3.player,
        skill = skillName,
        value = skillValue + 5
    }

    -- Notify the player
    tes3.messageBox("Your %s skill has increased!", skillName)
end

-- Function to activate the lava pool
local function activateLavaPool()

    local currentTime = tes3.worldController.hour.value + (tes3.worldController.daysPassed.value * 24)
    if lastActivationTime and (currentTime - lastActivationTime < cooldownPeriod) then
        tes3.messageBox("The enchanted pool can only be activated once every 24 hours.")
        return
    end

    if isNight() then
        grantRandomSkill()
        tes3.messageBox("The enchanted pool has been activated because it is night.")
    else
        tes3.messageBox("The enchanted pool can only be activated at night.")
    end
end

-- Example usage: Activate the lava pool when the player activates a specific object
local function onActivate(e)
    if e.target.id == "your_lava_pool_id" then  -- Replace with the actual ID of your lava pool object
        activateLavaPool()
        return false  -- Prevents the default activation action
    end
end

-- Register the event listener for object activation
event.register("activate", onActivate)

-- Debug message to ensure the script is loaded
tes3.messageBox("Lava Pool Activation Script loaded.")

=-=-=-=-=-=-=-=--=

-- Define the lunar cycle lengths in days for Masser and Secunda
local masserCycleLength = 32
local secundaCycleLength = 27

-- List of player skills
local skills = {
    "block", "armorer", "mediumarmor", "heavyarmor", "bluntweapon",
    "longblade", "axe", "spear", "athletics", "enchant", "destruction",
    "alteration", "illusion", "conjuration", "mysticism", "restoration",
    "alchemy", "unarmored", "security", "sneak", "acrobatics", "lightarmor",
    "shortblade", "marksman", "mercantile", "speechcraft", "handtohand"
}

-- Function to check if both moons are visible
local function areBothMoonsVisible()
    local daysPassed = tes3.worldController.daysPassed.value
    local masserPhase = daysPassed % masserCycleLength
    local secundaPhase = daysPassed % secundaCycleLength

    -- Define full moon phase for both moons
    local fullMoonMasser = 16
    local fullMoonSecunda = 13.5

    -- Check if both moons are visible (full moon phase)
    return (masserPhase >= fullMoonMasser - 1 and masserPhase <= fullMoonMasser + 1) and 
           (secundaPhase >= fullMoonSecunda - 1 and secundaPhase <= fullMoonSecunda + 1)
end

-- Function to grant a random skill increase to the player
local function grantRandomSkill()
    local skillIndex = math.random(1, #skills)
    local skillName = skills[skillIndex]

    -- Get the player's current skill value
    local skillValue = tes3.mobilePlayer[skillName].current
    -- Increase the skill value by 1
    tes3.setStatistic{
        reference = tes3.player,
        skill = skillName,
        value = skillValue + 1
    }

    -- Notify the player
    tes3.messageBox("Your %s skill has increased!", skillName)
end

-- Function to activate the lava pool
local function activateLavaPool()
    if areBothMoonsVisible() then
        grantRandomSkill()
        tes3.messageBox("The lava pool has been activated because both moons are visible.")
    else
        tes3.messageBox("The lava pool can only be activated when both moons are visible.")
    end
end

-- Example usage: Activate the lava pool when the player activates a specific object
local function onActivate(e)
    if e.target.id == "your_lava_pool_id" then  -- Replace with the actual ID of your lava pool object
        activateLavaPool()
        return false  -- Prevents the default activation action
    end
end

-- Register the event listener for object activation
event.register("activate", onActivate)

-- Debug message to ensure the script is loaded
tes3.messageBox("Lava Pool Activation Script loaded.")

--]]
