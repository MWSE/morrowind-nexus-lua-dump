local self    = require('openmw.self')
local I       = require('openmw.interfaces')
local core    = require('openmw.core')
local types   = require('openmw.types')
local storage = require('openmw.storage')
local util = require('openmw.util')

local function isClothingBelt(t)
  return t == types.Clothing.TYPE.Belt
end

local beltId = "rg_henshin_belt"

local function getBelt(attacker)
	local eq = types.Actor.getEquipment(attacker)
	if not eq then return nil end
	for _, item in pairs(eq) do
		if types.Clothing.objectIsInstance(item) then
			local rec = types.Clothing.record(item)
			if rec and isClothingBelt(rec.type) then
				if rec.id == beltId then
					return true
				else
					return false
				end
			end
		end
	end
	return nil
end

local registered = false

local function register()
  if registered then return end
  I.Combat.addOnHitHandler(function(attack)
    if not attack or not attack.successful then return end
    if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end
    if attack.weapon ~= nil then return end
    if not (attack.attacker and types.Player.objectIsInstance(attack.attacker)) then return end
	if getBelt(attack.attacker) ~= true then return end
	if attack.damage.health and not attack.damage.fatigue then return end
      attack.damage = attack.damage or {}
	  attack.damage.fatigue = (util.round(attack.damage.fatigue / 2))
      attack.damage.health = (attack.damage.health or 0) + attack.damage.fatigue
	  
  end)
  registered = true
end

return {
  engineHandlers = {
    onInit = register,
    onLoad = function() registered = false; register() end,
  },
}
