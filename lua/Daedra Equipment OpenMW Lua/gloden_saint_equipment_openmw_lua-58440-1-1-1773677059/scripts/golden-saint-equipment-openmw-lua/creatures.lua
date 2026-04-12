local self = require("openmw.self")
local types = require("openmw.types")
local core = require('openmw.core')

local goldenSaintPatterns = {
	"golden saint",
	-- OAAB
	"ab_dae_darkseducer",
	-- OAAB Grazelands
	"abtv_dae_goldstvault",
	-- OAAB Tel Mora
	"abtm_dae_darkschanil",
	-- Tamriel Data
	"t_dae_cre_gsaintcyr",
	-- TR Mainland
	"tr_m4_goldensaint_issmi",
	"tr_m7_ns_mg_goldsaint",
}

local function isGoldenSaint(actor)
	for _, goldenSaintPattern in pairs(goldenSaintPatterns) do
		if actor.recordId:match(goldenSaintPattern) then
			return true
		end
	end
	return false
end

local function equipWeaponAndShieldGS(items)
	equipWeapon = {}
	equipWeapon[types.Actor.EQUIPMENT_SLOT.CarriedRight] = items.weapon
	types.Actor.setEquipment(self, equipWeapon)

	equipShield = {}
	equipShield[types.Actor.EQUIPMENT_SLOT.CarriedLeft] = items.shield
	types.Actor.setEquipment(self, equipShield)
end

local function onInit()
	if isGoldenSaint(self.object) then
		core.sendGlobalEvent('updateEquipmentGS', self)
	end
end

return {
	eventHandlers = {
		equipWeaponAndShieldGS = equipWeaponAndShieldGS
	},
	engineHandlers = {
		onInit = onInit 
	}
}

