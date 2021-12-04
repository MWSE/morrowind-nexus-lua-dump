--[[
-- MWSE Alchemy Takes Time (inpv edit)
-- by baldamundo, Merlord and inpv, 2021

-- Alchemical process now takes time, based on potion's value and player's skill
]]

local baseTimeMinutes = 30 -- Time taken before multipliers
local valueMulti = 2.0 --Multiplier at 100 gold value
local skillMulti = 0.5 --Multiplier at 100 alchemy skill

local function calculateBrewTime(potion)
    --calculate effect of potion value
    local value = potion.value
    local valueEffect = math.remap(value, 0, 100, 1.0, valueMulti)
    --clamp values so really expensive potions don't take forever
    valueEffect = math.clamp(valueEffect, 1.0, valueMulti)

    --calculate effect of player alchemy skill
    local alchemySkill = tes3.mobilePlayer.alchemy.current
    local skillEffect = math.remap(alchemySkill, 0, 100, 1.0, skillMulti)
    --clamp values so really high skill doesn't set time to 0
    skillEffect = math.clamp(skillEffect, 100, skillMulti)

    --return brew time in hours
    return (baseTimeMinutes / 60) * valueEffect * skillEffect
end

local function calculateAlchemyTime(e)
	local gameHour = tes3.getGlobal('GameHour')
	local potionMade = e.object
	local timeMod = calculateBrewTime(potionMade)

	gameHour = gameHour + timeMod
	tes3.setGlobal('GameHour', gameHour)
	tes3.messageBox("You take the time to brew the concoction.")
end

 -- The function to call on the initialized event.
 local function initialized()
	event.register("potionBrewed", calculateAlchemyTime)

    -- Print a "Ready!" statement to the MWSE.log file.
    print("[MWSE Alchemy Takes Time: INFO] MWSE Alchemy Takes Time Initialized")
 end

 -- Register our initialized function to the initialized event.
 event.register("initialized", initialized)