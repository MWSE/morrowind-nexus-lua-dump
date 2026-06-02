local self = require("openmw.self")
local types = require("openmw.types")
local core = require('openmw.core')

local dremoraPatterns = {
	"dremora",
	-- Tamriel Data
	"t_dae_cre_drem",
	-- TR Mainland
	"tr_m3_q_oe_mg_dremlord",
	"tr_m7_naemun_dremlord",
	"tr_m1_drem_arch_voun",
	"tr_m1_drem_voun",
	"tr_m3_kha_11_dremsewers",
	"tr_m1_q66_ght_el2_dremo",
}

local dremoraBossList = {
	"dremora_lord_khash_uni",
	-- Cutting Room Floor
	"dremora_lord_alta_uni",
	-- OAAB Tombs and Towers
	"dremora_sarano",
}

local function isDremora(actor)
	for _, dremoraPattern in pairs(dremoraPatterns) do
		if actor.recordId:match(dremoraPattern) then
			return true
		end
	end
	return false
end

local function isDremoraBoss(actor)
	for _, dremoraBossId in pairs(dremoraBossList) do
		if actor.recordId:match(dremoraBossId) then
			return true
		end
	end
	return false
end

local function onInit()
	if isDremoraBoss(self.object) then
		core.sendGlobalEvent('updateEquipmentDremoraBoss', self)
	elseif isDremora(self.object) then
		core.sendGlobalEvent('updateEquipmentDremora', self)
	end
end

local function equipWeaponDremora(item)
	equip = {}
	equip[types.Actor.EQUIPMENT_SLOT.CarriedRight] = item
	types.Actor.setEquipment(self, equip)
end

return {
	eventHandlers = {
		equipWeaponDremora = equipWeaponDremora
	},
	engineHandlers = {
		onInit = onInit 
	}
}

