local types         = require('openmw.types')
local self          = require('openmw.self')
local skp           = require('openmw.interfaces').SkillProgression
local anim          = require('openmw.animation')
local i_AnimControl = require('openmw.interfaces').AnimationController

local Dt            = require('scripts.Skill_Uses_Scaled.data')
local Fn            = require('scripts.Skill_Uses_Scaled.func')
local Mui           = require('scripts.Skill_Uses_Scaled.modui')

for _, _groupname in ipairs(Dt.ATTACK_ANIMATION_GROUPS) do
	--i_AnimControl.addTextKeyHandler(_groupname, function(groupname, key) print('Completion: '..string.format('%.2f', anim.getTextKeyTime(self, 'hit'))..' | Key: '..key) end)
	i_AnimControl.addTextKeyHandler(_groupname, function(groupname, key) Fn.get_attack(groupname, key) end)
end
i_AnimControl.addTextKeyHandler('spellcast', function(groupname, key) Fn.get_spell(groupname, key) end)

Fn.make_scalers()
skp.addSkillUsedHandler(function(skillid, options)
	if Dt.scalers[skillid] then
		options.skillGain = Dt.scalers[skillid].func(options.useType, options.skillGain)
	end
end)

Fn.register_Use_Action_Handler()

local armor = nil          -- create here instead of every frame
local armor_thisframe = {} -- create here instead of every frame
local onUpdate = function(dt)
	armor_thisframe = {}
	armor = Fn.get_equipped_armor()
	for _, _obj in ipairs(armor) do
		armor_thisframe[types.Armor.record(_obj).type] = types.Item.itemData(_obj).condition
	end
	Dt.pc.armor_condition:set_prevframe(armor_thisframe)
end
local onFrame = function(dt)
	if Dt.securiting then
		local target = Fn.get_security_target()
		if target then Dt.pc.security_target = target end
		if Mui.getSetting("SUS_DEBUG") then -- I'd love to not have this here, but it's better to have it.
			local printcounter = Dt.counters.security(1)
			if printcounter > 150.01 then
				print('Scanning lockables...')
				Dt.counters.security(-printcounter)
			end
		end
	end
end

local onInit = function()
	Mui.loadPreset('current')
end
local onSave = function()
	Mui.savePreset('current')
	return { marathon_counter = Dt.counters.athletics(0) }
end
local onLoad = function(data)
	Mui.loadPreset('current')
	if data then if data.marathon_counter then Dt.counters.athletics(data.marathon_counter) end end
end

return {
	engineHandlers = {
		onUpdate = onUpdate,
		onFrame  = onFrame,
		onInit   = onInit,
		onSave   = onSave,
		onLoad   = onLoad,
	},
	eventHandlers = {
		SUS_updateGLOBvar = function(t) Dt.GLOB[t.id] = t.val end,
		UiModeChanged = function(data)
			if not data.newMode then return end
			if data.oldMode then return end
			if not Dt.STANCE.WEAPON[types.Actor.getStance(self)] then return end
			local weapon = types.Actor.getEquipment(self, Dt.SLOTS.WEAPON)
			if not weapon or (weapon.type == types.Weapon) then
				Fn.set_hit_release()
			end
		end,
	}
}
