local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local ui = require('openmw.ui')
local anim = require('openmw.animation')
local Controls = require('openmw.interfaces').Controls

local I = require('openmw.interfaces')

local BlockButton = 3

local mySkills = types.NPC.stats.skills
local myAttributes = types.NPC.stats.attributes
local myBlock = mySkills.block(self).modifier
local isBlocking = false


local function canBlock()
	local shield = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedLeft)
	local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
	local weaponRecord = types.Weapon.records[weapon.recordId]
	local weaponTypes = types.Weapon.TYPE
	local isOneHanded = weaponRecord.type == weaponTypes.AxeOneHand or
	weaponRecord.type == weaponTypes.ShortBladeOneHand or
	weaponRecord.type == weaponTypes.LongBladeOneHand or
	weaponRecord.type == weaponTypes.BluntOneHand 



	return shield ~= nil
		and shield.type == types.Armor
		and types.Actor.getStance(self) == types.Actor.STANCE.Weapon
		and isBlocking == false
		and isOneHanded == true


end

local function blockBegin(button)
	if button == BlockButton and canBlock() then
		isBlocking = true
		mySkills.block(self).modifier = mySkills.block(self).modifier + 9999999
		Controls.overrideCombatControls(true)


		I.AnimationController.playBlendedAnimation('activeblock', {
			startkey = 'start',
			stopkey = 'stop',
			priority = {
				[anim.BONE_GROUP.RightArm] = anim.PRIORITY.Default,
				[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
				[anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
				[anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Default,
			},
			autodisable = false,
			blendmask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso,
		})
	end
end

local function onMouseButtonRelease(button)
	if button == BlockButton and isBlocking then
		mySkills.block(self).modifier = mySkills.block(self).modifier - 9999999
		isBlocking = false
		Controls.overrideCombatControls(false)

		I.AnimationController.playBlendedAnimation('idle1',
			{
				startkey = 'loop start',
				stopkey = 'loop stop',
				priority = {
					[anim.BONE_GROUP.RightArm] = anim.PRIORITY.Default,
					[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
					[anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
					[anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Default,
				},
				autodisable = true,
			})
	end
end

return {
	engineHandlers = {
		onMouseButtonPress = blockBegin,
		onMouseButtonRelease = onMouseButtonRelease,
		onInputAction = onInputAction,
	}
}
