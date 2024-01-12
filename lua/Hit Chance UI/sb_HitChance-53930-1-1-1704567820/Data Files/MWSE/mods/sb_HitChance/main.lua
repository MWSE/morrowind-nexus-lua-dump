---@type number
local lastHitChance
---@type number
local currentHitChance
---@type mwseTimer
local uiUpdateTimer

local function calcHitChance()
	local weaponSkill = tes3.mobilePlayer:getSkillValue(
		tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon })
	)
	local agility = tes3.mobilePlayer.agility.current
	local luck = tes3.mobilePlayer.luck.current
	local fatigueCurrent = tes3.mobilePlayer.fatigue.current
	local fatigueBase = tes3.mobilePlayer.fatigue.base
	local fortifyAttack = tes3.getEffectMagnitude({ reference = tes3.player, effect = tes3.effect.fortifyAttack })
	local blind = tes3.getEffectMagnitude({ reference = tes3.player, effect = tes3.effect.blind })
	return (weaponSkill + (agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
		+ fortifyAttack
		+ blind
end

---@param mobile tes3mobileNPC|tes3mobileCreature
local function calcEvasion(mobile)
	local agility = mobile.agility.current
	local luck = mobile.luck.current
	local fatigueCurrent = mobile.fatigue.current
	local fatigueBase = mobile.fatigue.base
	local sanctuary = tes3.getEffectMagnitude({ reference = mobile.reference, effect = tes3.effect.sanctuary })
	return ((agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase))) + sanctuary
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
	if
		(e.object.objectType == tes3.objectType.npc or e.object.objectType == tes3.objectType.creature)
		and tes3.mobilePlayer.weaponDrawn
		and tes3.menuMode() == false
	then
		local hitChance = math.max(
			0,
			event.trigger(
				"sb:CalcHitRate",
				{ weapon = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon }) }
			).hitChance or (calcHitChance() - calcEvasion(e.reference.mobile))
		)
		currentHitChance = hitChance
		local elementColour
		if hitChance <= 25 then
			elementColour = { 193 / 255, 63 / 255, 55 / 255 }
		elseif hitChance <= 50 then
			elementColour = { 253 / 255, 241 / 255, 172 / 255 }
		elseif hitChance <= 75 then
			elementColour = { 1, 1, 1 }
		elseif hitChance <= 100 then
			elementColour = { 221 / 255, 255 / 255, 221 / 255 }
		else
			elementColour = { 184 / 255, 102 / 255, 211 / 255 }
		end
		local hitChanceElement = e.tooltip.children[1]:createLabel({
			id = "sb_HitChance",
			text = string.format("%0.2f%%", math.round(hitChance, 2)),
		})
		hitChanceElement.color = elementColour
	else
		currentHitChance = 0
	end
end
event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)

--- @param e loadEventData
local function loadCallback(e)
	if uiUpdateTimer then
		uiUpdateTimer:cancel()
		uiUpdateTimer = nil
	end
end
event.register(tes3.event.load, loadCallback)

--- @param e loadedEventData
local function loadedCallback(e)
	uiUpdateTimer = timer.start({
		duration = 1 / 8,
		iterations = -1,
		callback = function()
			if lastHitChance ~= currentHitChance then
				lastHitChance = currentHitChance
				tes3ui.refreshTooltip()
			end
		end,
	})
end
event.register(tes3.event.loaded, loadedCallback)

--- @param e weaponReadiedEventData|weaponUnreadiedEventData
local function weaponReadiedUnreadiedCallback(e)
	tes3ui.refreshTooltip()
end
event.register(tes3.event.weaponReadied, weaponReadiedUnreadiedCallback)
event.register(tes3.event.weaponUnreadied, weaponReadiedUnreadiedCallback)
