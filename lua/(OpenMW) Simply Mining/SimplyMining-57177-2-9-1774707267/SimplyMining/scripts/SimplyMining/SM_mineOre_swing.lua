-- ====================================================================
-- ====================================================================
--
-- Swing-based mining module
--
-- ====================================================================
-- ====================================================================



local oreProgressData = {} -- Progress storage per ore node
local lastHit = 0
local startedUse = nil
local isUsing
local stopOnce = true
local slot1, slot2, slot3 = {0, 0}, {0, 0}, {0, 0}
local nextSlot = 1
local preSwingFatigue = types.Actor.stats.dynamic.fatigue(self).current
local justMined = nil

local attackTypeEffectiveness = {
	chop = 1.0,
	slash = 0.9,
	thrust = 0.8,
}

-- ====================================================================
-- Raycast
-- ====================================================================

local function getRayResult(callback, synchronous, ...)
	-- SharedRay: always synchronous
	if I.SharedRay then
		callback(I.SharedRay.get(), ...)
		return
	end
	local cameraPos = camera.getPosition()
	local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
	local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance()
	local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
	if telekinesis then
		activationDistance = activationDistance + (telekinesis.magnitude * 22)
	end
	activationDistance = activationDistance + 0.1
	local endPos = cameraPos + camera.viewportToWorldVector(v2(0.5, 0.5)) * activationDistance
	local function wrapResult(res)
		return {
			hit = res.hit,
			hitPos = res.hitPos,
			hitNormal = res.hitNormal,
			hitObject = res.hitObject,
			hitTypeName = res.hitObject and tostring(res.hitObject.type) or nil,
		}
	end
	if synchronous then
		callback(wrapResult(nearby.castRenderingRay(cameraPos, endPos, { ignore = self })), ...)
	else
		local args = {...}
		nearby.asyncCastRenderingRay(async:callback(function(res)
			callback(wrapResult(res), table.unpack(args))
		end), cameraPos, endPos, { ignore = self })
	end
end


-- ====================================================================
-- UI Constants and helpers
-- ====================================================================

local makeBorder = require("scripts.SimplyMining.ui_makeborder")
local borderOffset = 1
local borderFile = "thin"
local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture { path = 'black' },
		relativeSize = v2(1, 1),
		alpha = 0.4,
	}
}).borders

-- Mining state
if not swingMiningState then
	swingMiningState = {
		isActive = false,
		oreName = "",
		toolWarning = nil,
		target = nil,
		isVanillaOre = false,
	}
end

local fontSize = 18
local iconSize = 20
local barWidth = 180
local barHeight = 16

local function f1dot(number)
	return string.format("%.1f", number + 0.05)
end

local function f1(number)
	local formatted = string.format("%.1f", number)
	if formatted:sub(#formatted, #formatted) == "0" then
		return tonumber(string.format("%.0f", number))
	end
	return formatted
end

local function getColorByChance(chance)
	if chance < 0.7 then
		return util.color.rgb(1, chance / 0.7, 0)
	else
		local red = 1 - (chance - 0.7) / 2
		return util.color.rgb(math.max(0, red), 1, 0)
	end
end

local function getColorFromGameSettings(colorTag)
	local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1, 1, 1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local fontColor = getColorFromGameSettings("FontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("FontColor_color_normal")
local morrowindBlue = getColorFromGameSettings("fontColor_color_journal_link")
local progressColor = morrowindBlue

-- ====================================================================
-- UI
-- ====================================================================

if hud_swingMiningProgress then
	hud_swingMiningProgress:destroy()
	hud_swingMiningProgress = nil
end

-- Progress bar widget (embedded into tooltip later)
hud_swingMiningProgress = ui.create({
	type = ui.TYPE.Container,
	name = "hud_swingMiningProgress",
	props = {
		relativePosition = v2(0.5, 0.8),
		anchor = v2(0.5, 0.5),
	},
	content = ui.content {}
})

-- Horizontal flex: progress bar
local mainFlex = {
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
		horizontal = true,
	},
	content = ui.content {}
}
hud_swingMiningProgress.layout.content:add(mainFlex)

-- Spacer
mainFlex.content:add{ props = { size = v2(1, 1) } }

-- Progress bar container
local progressContainer = {
	type = ui.TYPE.Widget,
	template = borderTemplate,
	props = {
		size = v2(barWidth + 4, barHeight + 4),
		alpha = 0,
	},
	content = ui.content {}
}
mainFlex.content:add(progressContainer)

-- Progress fill
local progressFill = {
	type = ui.TYPE.Image,
	name = "progressFill",
	props = {
		resource = ui.texture { path = 'white' },
		color = progressColor,
		relativeSize = v2(0, 1),
		alpha = 1,
	}
}
progressContainer.content:add(progressFill)

-- Progress percentage text
local progressText = {
	type = ui.TYPE.Text,
	name = "progressText",
	props = {
		text = "0%",
		textColor = fontColor,
		textShadow = true,
		textShadowColor = util.color.rgba(0, 0, 0, 1),
		textSize = fontSize - 4,
		textAlignH = ui.ALIGNMENT.End,
		textAlignV = ui.ALIGNMENT.Center,
		relativePosition = v2(1, 0.5),
		anchor = v2(1, 0.5),
		relativeSize = v2(1, 1),
		autoSize = true,
	}
}
progressContainer.content:add(progressText)

-- Attack icon (added to tooltip row, not progress bar)
local attackIcon = {
	type = ui.TYPE.Image,
	name = "attackIcon",
	props = {
		resource = ui.texture { path = "textures/SimplyMining/attack.dds" },
		tileH = false,
		tileV = false,
		size = v2(iconSize, iconSize),
		alpha = 0.6,
		color = fontColor,
	}
}

-- Ore name text (inline, next to icon)
local oreNameText = {
	type = ui.TYPE.Text,
	name = "oreNameText",
	props = {
		text = "Ore",
		textColor = morrowindGold,
		textShadow = true,
		textShadowColor = util.color.rgba(0, 0, 0, 1),
		textSize = fontSize,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = true,
		relativePosition = v2(0, 0.5),
		anchor = v2(0, 0.5),
	}
}

local function destroyTooltip()
	if miningTooltip then
		miningTooltip:destroy()
		miningTooltip = nil
	end
end

local function createTooltip()
	destroyTooltip()

	-- Reset progress bar to match current target
	local currentProgress = swingMiningState.target and (oreProgressData[swingMiningState.target.id] or 0) or 0
	if currentProgress > 0 then
		progressContainer.props.alpha = 1
		progressFill.props.relativeSize = v2(math.min(1, currentProgress), 1)
		progressText.props.text = math.floor(math.min(1, currentProgress) * 100) .. "%"
	else
		progressContainer.props.alpha = 0
		progressFill.props.relativeSize = v2(0, 1)
		progressText.props.text = "0%"
	end
	hud_swingMiningProgress:update()

	miningTooltip = ui.create({
		layer = 'Scene',
		name = "swingMiningTooltip",
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			autoSize = true,
			relativePosition = v2(0.52, 0.5),
			anchor = v2(0, 0.5),
			arrange = ui.ALIGNMENT.Start,
		},
		content = ui.content {}
	})
	-- Row 1: attack icon + ore name
	local firstRow = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			autoSize = true,
			arrange = ui.ALIGNMENT.Start,
		},
		content = ui.content {}
	}
	miningTooltip.layout.content:add(firstRow)
	firstRow.content:add(attackIcon)
	firstRow.content:add(oreNameText)

	-- Spacer between name row and progress bar
	miningTooltip.layout.content:add{ props = { size = v2(1, 1) * 2 } }

	-- Row 2: progress bar widget
	miningTooltip.layout.content:add(hud_swingMiningProgress)
end

-- UI update
local function updateProgressBar()
	if not swingMiningState.isActive or not swingMiningState.target then
		return
	end
	local progress = math.min(1, oreProgressData[swingMiningState.target.id] or 0)
	if progress > 0 then
		progressContainer.props.alpha = 1
	else
		progressContainer.props.alpha = 0
		return
	end
	progressFill.props.relativeSize = v2(progress, 1)

	if swingMiningState.toolWarning then
		progressText.props.text = swingMiningState.toolWarning .. " / " .. math.floor(progress * 100) .. "%"
	else
		progressText.props.text = math.floor(progress * 100) .. "%"
	end
	hud_swingMiningProgress:update()
end

-- ====================================================================
-- Mining Start and Completion
-- ====================================================================

local function startMining(object, isVanillaOre)
	swingMiningState.toolWarning = nil
	swingMiningState.oreName = object.type.record(object).name or ""
	swingMiningState.target = object
	swingMiningState.isVanillaOre = isVanillaOre or false
	swingMiningState.isActive = true

	local item = nodeToItemLookup[object.recordId]
	local color = fontColor
	if item then
		local chance = calcChance(item)
		color = swingMiningState.isVanillaOre and morrowindGold or getColorByChance(chance)
		if item == "ingred_diamond_01" then
			chance = chance / 2
		end
		swingMiningState.oreName = swingMiningState.oreName .. " (" .. (swingMiningState.isVanillaOre and 0.7*S_YIELD_MULT/100 or f1(chance * 2)) .. ")"
		if swingMiningState.isVanillaOre and isTheft(object) then
			color = THEFT_COLOR
		end
	end

	oreNameText.props.text = " " .. swingMiningState.oreName .. " "
	oreNameText.props.textColor = color

	createTooltip()
	updateProgressBar()
end

local function completeMining(ray)
	if not swingMiningState.target then
		return
	end
	justMined = swingMiningState.target
	swingMiningState.isActive = false
	destroyTooltip()

	oreProgressData[swingMiningState.target.id] = nil

	core.sendGlobalEvent('SimplyMining_removeNode', swingMiningState.target)
	local item = nodeToItemLookup[swingMiningState.target.recordId]
	if item then
		local diffMod = 0.7 + (db_difficulties[item] or 1) / 70
		print("mined: +" .. f1dot(diffMod * 2.1) .. " exp")
		grantSkillExp(diffMod * 2.1)
		local hitPos = ray.hitPos or swingMiningState.target.position
		if item == "ingred_diamond_01" then
			core.sendGlobalEvent('SimplyMining_getItem', {self, item, calcChance(item), swingMiningState.target, swingMiningState.isVanillaOre, hitPos})
		else
			core.sendGlobalEvent('SimplyMining_getItem', {self, item, calcChance(item) * 2, swingMiningState.target, swingMiningState.isVanillaOre, hitPos})
		end

		local expMult = 1
		if swingMiningState.skill == "bluntweapon" then
			expMult = 1.15
		end
		if swingMiningState.skill then
			I.SkillProgression.skillUsed(swingMiningState.skill, {
				skillGain = (0.8 + (db_difficulties[item] or 15) / 40) * expMult,
				useType = I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit,
				scale = nil
			})
		end
	end
end

-- ====================================================================
-- Mouseclick
-- ====================================================================

input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	if use and not isUsing then
		startedUse = core.getSimulationTime()
		isUsing = true
	elseif not use and isUsing then
		preSwingFatigue = types.Actor.stats.dynamic.fatigue(self).current
		local currentTime = core.getSimulationTime()
		local holdDuration = math.max(0, currentTime - startedUse)
		local swingStrength = math.min(holdDuration, 1.0)
		local slot = nextSlot == 1 and slot1 or (nextSlot == 2 and slot2 or slot3)
		slot[1], slot[2] = currentTime, swingStrength
		nextSlot = (nextSlot % 3) + 1
		isUsing = false
		startedUse = nil
	end
	return use
end), {})


-- ====================================================================
-- Animation Handler
-- ====================================================================

local function processHit(ray, groupname, key)
	local hitItem = nodeToItemLookup[ray.hitObject.recordId]

	local now = core.getSimulationTime()
	local weaponSpeed = animation.getSpeed(self, groupname)
	if now < lastHit + 0.35 / weaponSpeed then
		return
	end
	lastHit = now

	local isCurrentTarget = swingMiningState.isActive and ray.hitObject == swingMiningState.target
	local isVanillaOre = not saveData.spawnedOres[ray.hitObject.id] and not unavailableOres[hitItem]
	if not swingMiningState.isActive or not isCurrentTarget then
		startMining(ray.hitObject, isVanillaOre)
	end

	-- Parse swing type
	local swingType = key:match("^(%S+)")
	local requiredWindUp = 0.5
	local startTime = animation.getTextKeyTime(self, groupname .. ": " .. swingType .. " start")
	local chargedTime = animation.getTextKeyTime(self, groupname .. ": " .. swingType .. " max attack")
	if startTime and chargedTime then
		requiredWindUp = (chargedTime - startTime) * 0.9
	end

	local swingTypeMult = attackTypeEffectiveness[swingType] or 0.9

	-- Get equipped weapon
	local equipped = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
	local weaponRecord = nil
	local isHandToHand = true
	local durabilityHitMult = 0
	local baseSwings = 12
	local gapScale = 2
	local weaponSkill = 1
	swingMiningState.skill = nil
	
	
	--function getSkillLevel()
	--	if USE_MINING_SKILL and G_skillRegistered then
	--		local skillStat = I.SkillFramework.getSkillStat(MINING_SKILL_ID)
	--		return skillStat and skillStat.modified or 5
	--	else
	--		return types.NPC.stats.skills.armorer(self).modified
	--	end
	--end
	
	if equipped and types.Weapon.objectIsInstance(equipped) then
		weaponRecord = types.Weapon.record(equipped)
		weaponSpeed = weaponSpeed * weaponRecord.speed
		isHandToHand = false

		-- Pickaxes
		if weaponRecord.id == "t_de_ebony_pickaxe_01" then
			durabilityHitMult = 0.35
			baseSwings = 3.5
			gapScale = 0.9
			swingMiningState.toolWarning = nil
			swingMiningState.skill = nil
			weaponSkill = getSkillLevel()
		elseif weaponRecord.id == "bm nordic pick" then
			durabilityHitMult = 0.4
			baseSwings = 4
			gapScale = 1.0
			swingMiningState.toolWarning = nil
			swingMiningState.skill = nil
			weaponSkill = getSkillLevel()
		elseif weaponRecord.id:lower():find("pick") then
			durabilityHitMult = 0.45
			baseSwings = 4.5
			gapScale = 1.0
			swingMiningState.toolWarning = nil
			swingMiningState.skill = nil
			weaponSkill = getSkillLevel()
		-- Blunt weapons
		elseif weaponRecord.type == types.Weapon.TYPE.BluntOneHand or weaponRecord.type == types.Weapon.TYPE.BluntTwoClose then
			durabilityHitMult = 0.6
			baseSwings = 5
			gapScale = 1.1
			swingMiningState.toolWarning = nil
			swingMiningState.skill = "bluntweapon"
			weaponSkill = types.NPC.stats.skills.bluntweapon(self).modified
		-- Axes
		elseif weaponRecord.type == types.Weapon.TYPE.AxeOneHand or weaponRecord.type == types.Weapon.TYPE.AxeTwoHand then
			durabilityHitMult = 0.8
			baseSwings = 5.5
			gapScale = 1.2
			swingMiningState.toolWarning = "Wrong tool"
			swingMiningState.skill = "axe"
			weaponSkill = types.NPC.stats.skills.axe(self).modified
		-- 2H Long blades
		elseif weaponRecord.type == types.Weapon.TYPE.LongBladeTwoHand then
			durabilityHitMult = 1.0
			baseSwings = 6
			gapScale = 1.3
			swingMiningState.toolWarning = "Wrong tool"
			swingMiningState.skill = "longblade"
			weaponSkill = types.NPC.stats.skills.longblade(self).modified
		-- 1H Long blades
		elseif weaponRecord.type == types.Weapon.TYPE.LongBladeOneHand then
			durabilityHitMult = 1.1
			baseSwings = 6.5
			gapScale = 1.4
			swingMiningState.toolWarning = "Wrong tool"
			swingMiningState.skill = "longblade"
			weaponSkill = types.NPC.stats.skills.longblade(self).modified
		-- Short blades
		elseif weaponRecord.type == types.Weapon.TYPE.ShortBladeOneHand then
			durabilityHitMult = 1.2
			baseSwings = 7.5
			gapScale = 1.5
			swingMiningState.toolWarning = "Wrong tool"
			swingMiningState.skill = "shortblade"
			weaponSkill = types.NPC.stats.skills.shortblade(self).modified
		-- Spears
		elseif weaponRecord.type == types.Weapon.TYPE.SpearTwoWide then
			durabilityHitMult = 1.2
			baseSwings = 6.5
			gapScale = 1.4
			swingMiningState.toolWarning = "Wrong tool"
			swingMiningState.skill = "spear"
			weaponSkill = types.NPC.stats.skills.spear(self).modified
		-- Marksman
		elseif weaponRecord.type == types.Weapon.TYPE.MarksmanBow or weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow or weaponRecord.type == types.Weapon.TYPE.MarksmanThrown then
			durabilityHitMult = 0
			baseSwings = 12
			gapScale = 2.5
			swingMiningState.toolWarning = "Wrong tool"
			swingMiningState.skill = "marksman"
			weaponSkill = types.NPC.stats.skills.marksman(self).modified
		else
			durabilityHitMult = 0.8
			baseSwings = 12
			gapScale = 1.8
			swingMiningState.toolWarning = "Wrong tool"
			swingMiningState.skill = nil
			weaponSkill = types.NPC.stats.skills.handtohand(self).modified
		end

		-- Bound weapon penalty
		if weaponRecord.id:find("bound") then
			baseSwings = math.ceil(baseSwings * 1.1)
		end
	else -- Handtohand
		durabilityHitMult = 0
		baseSwings = 12
		gapScale = 2
		swingMiningState.toolWarning = "No tool"
		swingMiningState.skill = "handtohand"
		weaponSkill = types.NPC.stats.skills.handtohand(self).modified
	end
	

	-- Swing strength from held clicks
	local cutoff = now - 0.8
	local maxStrength = 0
	if slot1[1] >= cutoff and slot1[2] > maxStrength then maxStrength = slot1[2] end
	if slot2[1] >= cutoff and slot2[2] > maxStrength then maxStrength = slot2[2] end
	if slot3[1] >= cutoff and slot3[2] > maxStrength then maxStrength = slot3[2] end

	if maxStrength == 0 then
		local mostRecent = slot1
		if slot2[1] > mostRecent[1] then mostRecent = slot2 end
		if slot3[1] > mostRecent[1] then mostRecent = slot3 end
		maxStrength = mostRecent[2]
	end

	local swingStrength = math.min(1, weaponSpeed * maxStrength / requiredWindUp)

	local item = nodeToItemLookup[swingMiningState.target.recordId]
	local difficulty = db_difficulties[item] or 15
	local miningSkill = getSkillLevel() + (types.Actor.stats.attributes.strength(self).modified - 40) / 20  -- str: 40→+0, 100→+3
	local gap = difficulty - miningSkill
	if isVanillaOre then
		gap = gap/10
		baseSwings = (baseSwings-4)/5 + 4
	end
	local perfectBase = 3.5
	local perfectGapScale = 0.9
	if isVanillaOre then
		perfectBase = (perfectBase - 4) / 5 + 4
	end
	local diff = (S_MINING_DIFFICULTY or 100) / 100 

	local function calcSwingAdj(gap, scale)
		if gap >= 0 then
			local adj = math.min(7, gap) / 20
			gap = gap - 7
			if gap > 0 then
				adj = adj + math.min(7, gap) / 25
				gap = gap - 7
			end
			if gap > 0 then
				adj = adj + gap / 35
			end
			return adj * scale
		else
			local easyGap = -gap
			local easyAdj = math.min(5, easyGap) / 20
			easyGap = easyGap - 5
			if easyGap > 0 then
				easyAdj = easyAdj + math.min(5, easyGap) / 25
				easyGap = easyGap - 5
			end
			if easyGap > 0 then
				easyAdj = easyAdj + easyGap / 30
			end
			local tempScale = (1 + scale) / 2
			return -1 * (easyAdj / tempScale)
		end
	end
	
	
	local swingAdj = calcSwingAdj(gap, gapScale)
	local swingsNeeded = baseSwings * (0.3 + diff * 0.7) + swingAdj * (0.1 + diff * 0.9)
	--return swingsNeeded
	local perfectSwingAdj = calcSwingAdj(gap, perfectGapScale)
	local perfectSwingsNeeded = math.max(1, perfectBase * (0.2 + diff * 0.8) + perfectSwingAdj * (0.1 + diff * 0.9))

	
	
	local skillFactor = math.min(1, weaponSkill / 120)
	swingsNeeded = (1-skillFactor) * swingsNeeded + (skillFactor) * perfectSwingsNeeded

	swingsNeeded = math.max(1, swingsNeeded)
	--print("swings needed:", swingsNeeded)
	local fatigueMult = math.max(0, math.min(1, 0.33 + preSwingFatigue / 4 * 0.67))
	local progress = (1 / swingsNeeded) * swingTypeMult * swingStrength * fatigueMult
	--print("other mult:",  swingTypeMult * swingStrength * fatigueMult)
	oreProgressData[swingMiningState.target.id] = (oreProgressData[swingMiningState.target.id] or 0) + progress
	
	local sentProgress = progress
	if (oreProgressData[swingMiningState.target.id] or 0) >= 1 then
		sentProgress = sentProgress - ((oreProgressData[swingMiningState.target.id] or 0)-1)
	end
	updateProgressBar()

	-- VFX + sound
	core.sendGlobalEvent("SpawnVfx", {
		model = "meshes/e/magic_hit_conjure.nif",
		position = ray.hitPos - v3(0, 0, 20),
		options = { scale = 0.3 }
	})
	if swingMiningState.toolWarning == "Wrong tool" and not I.impactEffects then
		core.sendGlobalEvent('SpawnVfx', {model = "meshes/SimplyMining/stoneSpark.nif", position = ray.hitPos , options = {scale  = 0.7}})
	end
	core.sendGlobalEvent('SimplyMining_setNodeSize', {
		swingMiningState.target,
		1 - math.min(1, oreProgressData[swingMiningState.target.id] or 0) * 0.15,
		sentProgress,
		oreProgressData[swingMiningState.target.id],
		S_USE_MINING_SKILL and G_skillRegistered and MINING_SKILL_ID or "armorer",
		getSkillLevel()
	})
	if swingMiningState.toolWarning == "No tool" then
		--ambient.playSoundFile("sound/simplymining/Foley_Unbreakable_Surface_stone_01_0"..math.random(2,2)..".ogg", {volume =S_VOLUME/100*1.4})
		--ambient.playSoundFile("sound/simplymining/action_mining_stone_04_0"..math.random(1,4)..".ogg", {volume =S_VOLUME/100*0.7})
		ambient.playSoundFile("sound/simplymining/foley_stone_pile_02_0"..math.random(1,4)..".ogg", {volume =S_VOLUME/100*0.7})
	elseif swingMiningState.toolWarning == nil then
		ambient.playSound("Heavy Armor Hit", { volume = S_VOLUME/100 })
		ambient.playSoundFile("sound/simplymining/break_stone_01_0"..math.random(1,4)..".ogg", {volume =S_VOLUME/100*0.7})
	elseif swingMiningState.toolWarning == "Wrong tool" then
		ambient.playSoundFile("sound/simplymining/Foley_Unbreakable_Surface_Metal_01_0"..math.random(1,4)..".ogg", {volume =S_VOLUME/100*1.2})
		ambient.playSoundFile("sound/simplymining/break_stone_01_0"..math.random(1,4)..".ogg", {volume =S_VOLUME/100*0.6})
	end
	-- condition
	if durabilityHitMult > 0 then
		local maxCondition = types.Weapon.records[equipped.recordId] and types.Weapon.records[equipped.recordId].health or 0
		core.sendGlobalEvent("ModifyItemCondition", { actor = self.object, item = equipped, amount = -maxCondition/200*durabilityHitMult - durabilityHitMult })
	elseif swingMiningState.toolWarning == "No tool" then
		if weaponSkill < 20 then
			types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - 2 - types.Actor.stats.dynamic.health(self).base/100
			types.Actor.activeSpells(self):add({
				id = "sm_hurtyourself",
				effects = {0},
				ignoreResistances = true,
				ignoreSpellAbsorption = true,
				ignoreReflect = true,
				--name = buffName,
			})
			G_onFrameFunctions["removeOuchEffect"] =  function()
				for _, s in pairs(types.Actor.activeSpells(self)) do
					--print(s.id)
					if s.id == "sm_hurtyourself" then
						types.Actor.activeSpells(self):remove(s.activeSpellId)
						break
					end
				end
				--G_onFrameFunctions["removeOuchEffect"] = nil
			end
		end
	end
	
	-- fatigue
	types.Actor.stats.dynamic.fatigue(self).current = math.max(0, types.Actor.stats.dynamic.fatigue(self).current - 3)
	
	-- mined
	if (oreProgressData[swingMiningState.target.id] or 0) >= 1 then
		completeMining(ray)
	end
end

local function handleHitWithRay(ray, groupname, key)
	-- direct crosshair hit on ore
	local directHit = ray.hitObject
		and nodeToItemLookup[ray.hitObject.recordId]
		and types.Container.objectIsInstance(ray.hitObject)
		and not types.Container.content(ray.hitObject):isResolved()

	if directHit then
		processHit(ray, groupname, key)
		return
	end

	-- assisted mining: find nearby ore in front hemisphere
	if not S_ASSISTED_MINING or camera.getMode() ~= camera.MODE.Preview then return end

	local playerPos = self.position
	local playerYaw = self.rotation:getYaw()
	local facingDir = v3(math.sin(playerYaw), math.cos(playerYaw), 0)
	local ASSIST_MAX_DIST = 300

	-- prefer current target if still valid and in front
	local bestOre = nil
	if swingMiningState.isActive and swingMiningState.target
		and swingMiningState.target:isValid() then
		local toOre = swingMiningState.target.position - playerPos
		if toOre:length() < ASSIST_MAX_DIST then
			local dirFlat = v3(toOre.x, toOre.y, 0)
			if dirFlat:length() > 0 and facingDir:dot(dirFlat:normalize()) > 0 then
				bestOre = swingMiningState.target
			end
		end
	end

	-- scan nearby containers for closest ore
	if not bestOre then
		local bestDist = ASSIST_MAX_DIST
		for _, cont in pairs(nearby.containers) do
			if nodeToItemLookup[cont.recordId]
				and types.Container.objectIsInstance(cont)
				and not types.Container.content(cont):isResolved() then
				local toOre = cont.position - playerPos
				local dist = toOre:length()
				if dist < bestDist and dist > 0 then
					local dirFlat = v3(toOre.x, toOre.y, 0)
					if dirFlat:length() > 0 and facingDir:dot(dirFlat:normalize()) > 0 then
						bestOre = cont
						bestDist = dist
					end
				end
			end
		end
	end

	-- verify ore has exposed surface
	if not bestOre then return end

	local faceDir = v3(math.sin(playerYaw), math.cos(playerYaw), 0)
	-- pickaxe swing arc: high in front -> low further out
	local swingStart = playerPos + faceDir * 50 + v3(0, 0, 170)
	local swingEnd = playerPos + faceDir * 127 + v3(0, 0, 60)

	local box = bestOre:getBoundingBox()
	local center = box.center
	local hs = box.halfSize

	local vfxPos = nil
	-- try swing arc ray first
	local res = nearby.castRay(swingStart, swingEnd, {
		collisionType = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.HeightMap,
		ignore = self,
	})
	if res.hit and res.hitObject == bestOre then
		vfxPos = res.hitPos
	end
	-- fallback: sample upper bounding box from player chest
	if not vfxPos then
		local playerBox = self:getBoundingBox()
		local rayStart = v3(playerPos.x, playerPos.y, playerBox.center.z)
		local samples = {
			center + v3(0, 0, hs.z * 0.8),
			center + v3(0, 0, hs.z * 0.3),
			center,
			center + v3(hs.x * 0.5, 0, hs.z * 0.5),
			center + v3(-hs.x * 0.5, 0, hs.z * 0.5),
		}
		for _, sample in ipairs(samples) do
			res = nearby.castRay(rayStart, sample, {
				collisionType = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.HeightMap,
				ignore = self,
			})
			if not res.hit then
				vfxPos = sample
				break
			elseif res.hitObject == bestOre then
				vfxPos = res.hitPos
				break
			end
		end
	end
	if not vfxPos then return end

	-- snap character to face ore
	local toTarget = vfxPos - playerPos
	local targetYaw = math.atan2(toTarget.x, toTarget.y)
	local yawDelta = util.normalizeAngle(targetYaw - self.rotation:getYaw())
	if math.abs(yawDelta) > math.rad(5) then
		self.controls.yawChange = yawDelta
	end

	-- async render ray for precise VFX position, then process the hit
	local playerBox = self:getBoundingBox()
	-- start from swing arc origin, aim through ore center
	local renderDir = (center - swingStart):normalize()
	local renderEnd = center + renderDir * 127
	nearby.asyncCastRenderingRay(async:callback(function(renderRes)
		if not bestOre:isValid() then return end
		local hitPos
		if renderRes.hit then
			hitPos = renderRes.hitPos
		else
			-- nudge toward player height
			local nudge = vfxPos.z < playerBox.center.z and 8 or -8
			hitPos = v3(vfxPos.x, vfxPos.y, vfxPos.z + nudge)
		end
		processHit({
			hitObject = bestOre,
			hitPos = hitPos,
		}, groupname, key)
	end), swingStart, renderEnd, { ignore = self })
end

local function handleHit(groupname, key)
	if not S_SWING_MINING then return end
	getRayResult(handleHitWithRay, false, groupname, key)
end

-- Registration
I.AnimationController.addTextKeyHandler('', function(groupname, key)
	if stopOnce and key:find("stop") then
		startedUse = core.getSimulationTime() + 0.04
		stopOnce = false
	elseif key:find("hit") then
		startedUse = core.getSimulationTime() + 0.04
		handleHit(groupname, key)
		stopOnce = true
	end
end)

-- ====================================================================
-- Frame update: tooltip visibility based on look target
-- ====================================================================

local function updateSwingMiningTooltip(ray)
	local lookingAtValidTarget = ray.hitObject
		and types.Container.objectIsInstance(ray.hitObject)
		and nodeToItemLookup[ray.hitObject.recordId]
		and not types.Container.content(ray.hitObject):isResolved()
		and ray.hitObject ~= justMined

	if swingMiningState.isActive and swingMiningState.target then
		-- Active mining: validate target
		if not swingMiningState.target:isValid() then
			swingMiningState.isActive = false
			swingMiningState.target = nil
			destroyTooltip()
			return
		end
		if (self.position - swingMiningState.target.position):length() > 500 then
			swingMiningState.isActive = false
			swingMiningState.target = nil
			destroyTooltip()
			return
		end
		-- Show/hide tooltip based on whether we're looking at our target
		if lookingAtValidTarget and ray.hitObject == swingMiningState.target then
			if not miningTooltip then
				createTooltip()
				updateProgressBar()
			end
		elseif miningTooltip then
			destroyTooltip()
		end
	elseif lookingAtValidTarget then
		-- Not mining yet, but looking at a valid ore node - show preview tooltip
		if not miningTooltip or swingMiningState.target ~= ray.hitObject then
			local item = nodeToItemLookup[ray.hitObject.recordId]
			swingMiningState.target = ray.hitObject
			swingMiningState.isVanillaOre = not saveData.spawnedOres[ray.hitObject.id] and not unavailableOres[item]
			swingMiningState.oreName = ray.hitObject.type.record(ray.hitObject).name or ""

			local color = fontColor
			if item then
				local chance = calcChance(item)
				color = swingMiningState.isVanillaOre and morrowindGold or getColorByChance(chance)
				if item == "ingred_diamond_01" then
					chance = chance / 2
				end
				swingMiningState.oreName = swingMiningState.oreName .. " (" .. (swingMiningState.isVanillaOre and 0.7*S_YIELD_MULT/100 or f1(chance * 2)) .. ")"
				if swingMiningState.isVanillaOre and isTheft(ray.hitObject) then
					color = THEFT_COLOR
				end
			end

			oreNameText.props.text = " " .. swingMiningState.oreName .. " "
			oreNameText.props.textColor = color
			createTooltip()
		end
	else
		-- Not looking at anything minable
		if miningTooltip then
			destroyTooltip()
		end
		if not swingMiningState.isActive then
			swingMiningState.target = nil
		end
	end
end

local function onFrameSwingMining(dt)
	--if I.SharedRay is available, show world tooltip
	if not I.SharedRay and not swingMiningState.isActive then
		return
	end
	if not S_SWING_MINING then return end
	getRayResult(updateSwingMiningTooltip)
end

table.insert(G_onFrameFunctions, onFrameSwingMining)

-- ====================================================================
-- Activation handler (only does something when I.SharedRay is not available)
-- ====================================================================

return function(data)
	local target = data[1]
	local isVanillaOre = data[2]
	if not target then
		return
	end
	if swingMiningState.isActive and target == swingMiningState.target then
		return
	end
	startMining(target, isVanillaOre)
end