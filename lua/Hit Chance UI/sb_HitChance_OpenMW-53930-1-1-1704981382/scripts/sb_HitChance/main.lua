local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")

local weaponSkillMap = {
	[types.Weapon.TYPE.AxeOneHand] = "axe",
	[types.Weapon.TYPE.AxeTwoHand] = "axe",
	[types.Weapon.TYPE.BluntOneHand] = "bluntweapon",
	[types.Weapon.TYPE.BluntTwoClose] = "bluntweapon",
	[types.Weapon.TYPE.BluntTwoWide] = "bluntweapon",
	[types.Weapon.TYPE.LongBladeOneHand] = "longblade",
	[types.Weapon.TYPE.LongBladeTwoHand] = "longblade",
	[types.Weapon.TYPE.MarksmanBow] = "marksman",
	[types.Weapon.TYPE.MarksmanCrossbow] = "marksman",
	[types.Weapon.TYPE.MarksmanThrown] = "marksman",
	[types.Weapon.TYPE.ShortBladeOneHand] = "shortBlade",
	[types.Weapon.TYPE.SpearTwoWide] = "spear",
}

local function calcHitChance(weapon)
	local weaponSkill =
		types.NPC.stats.skills[weapon and weaponSkillMap[types.Weapon.record(weapon).type] or "handtohand"](self).modified
	local agility = types.Actor.stats.attributes.agility(self).modified
	local luck = types.Actor.stats.attributes.luck(self).modified
	local fatigueCurrent = types.Actor.stats.dynamic.fatigue(self).current
	local fatigueBase = types.Actor.stats.dynamic.fatigue(self).base
	local fortifyAttack = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FortifyAttack)
	local blind = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Blind)
	return (weaponSkill + (agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
		+ (fortifyAttack and fortifyAttack.magnitude or 0)
		+ (blind and blind.magnitude or 0)
end

local function calcEvasion(target)
	local agility = types.Actor.stats.attributes.agility(target).modified
	local luck = types.Actor.stats.attributes.luck(target).modified
	local fatigueCurrent = types.Actor.stats.dynamic.fatigue(target).current
	local fatigueBase = types.Actor.stats.dynamic.fatigue(target).base
	local sanctuary = types.Actor.activeEffects(target):getEffect(core.magic.EFFECT_TYPE.Sanctuary)
	return ((agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
		+ (sanctuary and sanctuary.magnitude or 0)
end

local hitChanceTextElement = {
	type = ui.TYPE.Text,
	props = {
		text = "%",
		textColor = util.color.rgba(1, 1, 1, 1),
		textSize = 14,
	},
}

local hitChanceElement = ui.create({
	layer = "HUD",
	props = {
		relativePosition = util.vector2(0.5, 0),
		anchor = util.vector2(0.5, 0.5),
		visible = false,
	},
	content = ui.content({
		{
			template = I.MWUI.templates.padding,
			content = ui.content({ hitChanceTextElement }),
		},
	}),
	-- type = ui.TYPE.Flex,
	template = I.MWUI.templates.boxSolid,
})

local tooltipTarget

local function getTooltipTarget()
	local from = camera.getPosition()
	local to = from + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * core.getGMST("iMaxActivateDist")
	nearby.asyncCastRenderingRay(
		async:callback(function(result)
			tooltipTarget = result.hitObject
		end),
		from,
		to
	)
end

local function onUpdate(dt)
	if camera.getMode() == camera.MODE.FirstPerson then
		getTooltipTarget()
	else
		tooltipTarget = nil
	end
	if
		tooltipTarget
		and (types.NPC.objectIsInstance(tooltipTarget) or types.Creature.objectIsInstance(tooltipTarget))
		and types.Actor.getStance(self) == types.Actor.STANCE.Weapon
	then
			local carriedRight = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
			if carriedRight and types.Weapon.objectIsInstance(carriedRight) or carriedRight == nil then
				local hitChance = math.max(0, calcHitChance(carriedRight) - calcEvasion(tooltipTarget))
			hitChanceTextElement.props.text = string.format("%0.2f%%", util.round(hitChance * 100) / 100)
			local elementColour
			if hitChance <= 25 then
				elementColour = { 193 / 255, 63 / 255, 55 / 255, 1 }
			elseif hitChance <= 50 then
				elementColour = { 253 / 255, 241 / 255, 172 / 255, 1 }
			elseif hitChance <= 75 then
				elementColour = { 1, 1, 1, 1 }
			elseif hitChance <= 100 then
				elementColour = { 221 / 255, 255 / 255, 221 / 255, 1 }
			else
				elementColour = { 184 / 255, 102 / 255, 211 / 255, 1 }
			end
			hitChanceTextElement.props.textColor = util.color.rgba(table.unpack(elementColour))
			hitChanceElement.layout.props.visible = true
			local newPos = camera.worldToViewportVector(
				util.vector3(
					tooltipTarget.position.x,
					tooltipTarget.position.y,
					tooltipTarget.position.z
						+ tooltipTarget:getBoundingBox().halfSize.z
						+ tooltipTarget:getBoundingBox().center.z
						+ 12
				)
			)
			hitChanceElement.layout.props.position = util.vector2(0, newPos.y)
			hitChanceElement:update()
		end
	else
		hitChanceElement.layout.props.visible = false
		hitChanceElement:update()
	end
end

return { engineHandlers = { onUpdate = onUpdate } }
