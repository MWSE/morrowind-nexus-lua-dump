-----------------------------------
-- Khajiiti fall damage reduction
-----------------------------------

local common = include("q.PredatorBeastRaces.common")

local khajiitFallDamageSmall = common.khajiitFallDamageSmall
local khajiitFallDamageMedium = common.khajiitFallDamageMedium
local khajiitFallDamageBig = common.khajiitFallDamageBig

local function getFallDamage(raceID, damage)

	if khajiitFallDamageSmall[raceID] then

		damage = damage * 0.25

		if damage < 10 then
			damage = 0
		end

	elseif khajiitFallDamageMedium[raceID] then

		damage = damage * 0.5

		if damage < 5 then
			damage = 0
		end

	elseif khajiitFallDamageBig[raceID] then

		damage = damage * 0.75
	end

	return damage
end

local function onFall(e)
	if e.source ~= "fall" then return end

	local raceID = e.reference.object.race.id:lower()

	if not khajiitFallDamageSmall[raceID] and
	   not khajiitFallDamageMedium[raceID] and
	   not khajiitFallDamageBig[raceID] then
		return
	end

	local damage = getFallDamage( raceID, e.damage )

	if damage == 0 then
		e.block = true
	else
		e.damage = damage
	end
end

-----------------------------------

event.register("initialized", function ()
	event.register("damage", onFall)
end)
