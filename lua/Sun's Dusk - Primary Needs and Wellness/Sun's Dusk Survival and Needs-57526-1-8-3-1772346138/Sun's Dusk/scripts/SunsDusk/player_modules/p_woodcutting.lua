--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk : Woodcutting Module                                     │
│  Chop trees for wood and lumber                                      │
│  Refactored to use central interaction system                        │
╰──────────────────────────────────────────────────────────────────────╯
]]
local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
local treeIgnoreList = {}

-- Progress storage per tree (runtime only)
local treeProgressData = {}
local enableDebug = false

local function dbg(...)
	if enableDebug then
		print(...)
	end
end

-- ════════════════════════════════════════════════════════════════════
-- Woodcutting Target Detection
-- ════════════════════════════════════════════════════════════════════

G_module_woodcutting_activators = {}
table.insert(G_module_woodcutting_activators, 'tree')
table.insert(G_module_woodcutting_activators, 'flora_tree')
table.insert(G_module_woodcutting_activators, 'flora_bc_tree')
table.insert(G_module_woodcutting_activators, 'bark')
table.insert(G_module_woodcutting_activators, 'trunk')
table.insert(G_module_woodcutting_activators, 'log')
table.insert(G_module_woodcutting_activators, 'stump')

G_module_woodcutting_blacklist = {}
table.insert(G_module_woodcutting_blacklist, 'furn_')
table.insert(G_module_woodcutting_blacklist, 'cabin')
table.insert(G_module_woodcutting_blacklist, 'terrace')


function G_isWoodcuttingActivator(object, objectType)
	if not object then return false end
	if treeIgnoreList[object.id] then
		return false
	end
	local recordId = object.recordId
	local refEntry, recordEntry = dbStatics[object.id], dbStatics[recordId]
	local dbEntry = refEntry and refEntry.woodcutting
	if refEntry == nil then
		dbEntry = recordEntry and recordEntry.woodcutting
	end
	
	if dbEntry ~= nil then
		return dbEntry and true
	end
	
	if objectType ~= "Static" then
		if objectType ~= "Activator" then
			return false
		else
			local mwscript = object.type.record(object).mwscript
			if not mwscript then return false end
			if not mwscript:find("colony") or mwscript ~= "colony_d_2_f" and mwscript ~= "colonyfactor3_d" and mwscript ~= "colony_d_3_f" and mwscript ~= "colony_d_1_f" and mwscript ~= "colony_d_1_i" and mwscript ~= "colonyservtraderdisable" and mwscript ~= "colonyfactor1_d" and mwscript ~= "colonyservsmithdisable" then
				return false
			end
		end
	end
	if G_isCookingActivator(object, objectType) then
		return false
	end
	local recordId = object.recordId
	for _, searchString in pairs(G_module_woodcutting_blacklist) do
        if recordId:find(searchString) then
            return false
        end
    end
	for _, searchString in pairs(G_module_woodcutting_activators) do
        if recordId:find(searchString) then
            return true
        end
    end
	return false
end

FALLBACK_WOOD = "sd_wood_1"

-- ════════════════════════════════════════════════════════════════════
-- Tree to Item Lookup
-- ════════════════════════════════════════════════════════════════════

local treeToItemLookup = {
}

local treeDifficulties = {
	["sd_wood_1"] = 25,
}

local attackTypeEffectiveness = {
	slash = 1.0,
	chop = 0.85,
	thrust = 0.6
}

-- ════════════════════════════════════════════════════════════════════
-- UI Setup
-- ════════════════════════════════════════════════════════════════════

local makeBorder = require("scripts.SunsDusk.ui_makeborder")
local borderOffset = 1
local borderFile = "thin"
local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture { path = 'black' },
		relativeSize = v2(1,1),
		alpha = 0.4,
	}
}).borders

-- Woodcutting state
if not woodcuttingState then
	woodcuttingState = {
		isActive = false,
		treeName = "",
		toolWarning = nil,
		target = nil,
		treeSize = 1,
		toolValue = 1,
		progressPerHit = 0,
		maxDistance = 400,
		targetPos = nil,
		skill = "axe",
		weaponQuality = 0.1
	}
end

local barWidth = 180
local barHeight = 16

local progressColor = G_morrowindGold

-- ════════════════════════════════════════════════════════════════════
-- Progress Bar UI
-- ════════════════════════════════════════════════════════════════════

-- Root container for the progress bar
local hud_woodcuttingProgress = ui.create({
	type = ui.TYPE.Container,
	name = "hud_woodcuttingProgress",
	props = {
		relativePosition = v2(0.5, 0.8),
		anchor = v2(0.5, 0.5),
	},
	content = ui.content {}
})

-- Main flex
local mainFlex = {
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
		horizontal = true
	},
	content = ui.content {}
}
hud_woodcuttingProgress.layout.content:add(mainFlex)

-- Header text
local treeNameText = {
	type = ui.TYPE.Text,
	name = "treeNameText",
	props = {
		text = "Tree",
		textColor = WORLD_TOOLTIP_FONT_COLOR,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = true,
		relativePosition = v2(0, 0.5),
		anchor = v2(0, 0.5),
		alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
	}
}

-- Spacer
mainFlex.content:add{ props = { size = v2(1, 1) } }

-- Progress bar container
local progressContainer = {
	type = ui.TYPE.Widget,
	template = borderTemplate,
	props = {
		size = v2(barWidth + 4, math.max(WORLD_TOOLTIP_ICON_SIZE,WORLD_TOOLTIP_FONT_SIZE)-2),
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
		alpha = 1
	}
}
progressContainer.content:add(progressFill)

-- Progress percentage text
local progressText = {
	type = ui.TYPE.Text,
	name = "progressText",
	props = {
		text = "0%",
		textColor = G_morrowindLight,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE - 4),
		textAlignH = ui.ALIGNMENT.End,
		textAlignV = ui.ALIGNMENT.Center,
		relativePosition = v2(1, 0.5),
		anchor = v2(1, 0.5),
		relativeSize = v2(1,1),
		autoSize = true,
		alpha = (WORLD_TOOLTIP_FONT_SIZE - 4) > 0 and 1 or 0,
	}
}
progressContainer.content:add(progressText)


-- Forward declarations
local startWoodcutting
local completeWoodcutting

-- ════════════════════════════════════════════════════════════════════
-- Progress Management Functions
-- ════════════════════════════════════════════════════════════════════

local function updateProgressBar()
	if not woodcuttingState.isActive or not woodcuttingState.target then
		return
	end
	local progress = math.min(1, treeProgressData[woodcuttingState.target.id] or 0)
	if progress > 0 then
		progressContainer.props.alpha = 1
	else
		progressContainer.props.alpha = 0
		return
	end
	progressFill.props.relativeSize = v2(progress, 1)
	
	if woodcuttingState.toolWarning then
		progressText.props.text = woodcuttingState.toolWarning.." / " .. math.floor(progress * 100) .. "%"
	else
		progressText.props.text = math.floor(progress * 100) .. "%"
	end
	hud_woodcuttingProgress:update()
end

-- ════════════════════════════════════════════════════════════════════
-- Woodcutting Start and Completion
-- ════════════════════════════════════════════════════════════════════

startWoodcutting = function(object)
	woodcuttingState.toolWarning = nil
	woodcuttingState.treeName = "Tree"
	woodcuttingState.target = object
	
	-- Calculate size scale multiplier from bounding box
	local bbox = object:getBoundingBox()
	local validBBox = isValidBBox(bbox)
	if validBBox then
		log(3, "tree size:", bbox.halfSize.z)
	end
	
	local recordId = object.recordId
	local refEntry, recordEntry = dbStatics[object.id], dbStatics[recordId]
	local dbEntry = refEntry and refEntry.woodcutting
	if refEntry == nil then
		dbEntry = recordEntry and recordEntry.woodcutting
	end
	
	local dbTreeSize = dbEntry and dbEntry.treeSize
	if dbTreeSize then
		woodcuttingState.treeSize = dbTreeSize / 20
	elseif validBBox then
		woodcuttingState.treeSize = bbox.halfSize.z / 20
	else
		woodcuttingState.treeSize = 1
	end
	
	woodcuttingState.isActive = true
	
	-- Update tree name
	treeNameText.props.text = woodcuttingState.treeName
	treeNameText.props.textColor = WORLD_TOOLTIP_FONT_COLOR
	
	-- Update progress bar with existing progress
	updateProgressBar()
	hud_woodcuttingProgress:update()
end

completeWoodcutting = function()
	if not woodcuttingState.target then
		return
	end
	
	woodcuttingState.isActive = false
	hud_woodcuttingProgress:update()
	
	-- Clear stored progress for this tree
	treeProgressData[woodcuttingState.target] = nil

	local item = treeToItemLookup[woodcuttingState.target.recordId] or FALLBACK_WOOD
	if item then
		local difficulty = treeDifficulties[item] or 25
		local diffMod = 0.7 + difficulty / 70
		
		-- Calculate wood count
		local woodCount = math.random(2, 3)
		woodCount = woodCount * ((woodcuttingState.toolValue-1)/9+1)
		woodCount= woodCount * 0.5
		woodCount = (woodCount + math.max(0.5, math.min(12.0, woodcuttingState.treeSize/9)))/2
		if math.random() < woodCount%1 then
			woodCount = woodCount + 1
		end
		woodCount = math.max(1, math.floor(woodCount))
		log(3, "Wood count:",woodCount)
		
		-- Calculate spawn positions with raycasts
		local spawnPositions = {}
		local airSpawnZ = math.max(woodcuttingState.target.position.z, self.position.z + 100)
		
		for i = 1, woodCount do
			local angle = math.random() * math.pi * 2
			local distance = math.random() * 100 + 50
			local offset = util.vector3(
				math.cos(angle) * distance,
				math.sin(angle) * distance,
				0
			)
			local targetPos = woodcuttingState.target.position + offset
			if not TREES_DESPAWN then
				targetPos = self.position + offset + v3(0,0,30)
			end
			
			local rayStart = util.vector3(targetPos.x, targetPos.y, targetPos.z + 230)
			local rayEnd = util.vector3(targetPos.x, targetPos.y, targetPos.z - 1000)
			
			local castResult = nearby.castRay(rayStart, rayEnd, {ignore = woodcuttingState.target, collisionType = nearby.COLLISION_TYPE.AnyPhysical})
			
			local groundPos
			local groundRotation
			if castResult.hit and (not castResult.hitObject or not types.Actor.objectIsInstance(castResult.hitObject)) then
				groundPos = castResult.hitPos + util.vector3(0, 0, 7)
				
				local hitNormal = castResult.hitNormal
				local up = util.vector3(0, 0, 1)
				local normal = hitNormal:normalize()
				
				local axis = up:cross(normal):normalize()
				local rotAngle = math.acos(math.max(-1, math.min(1, up:dot(normal))))
				local alignRotation = util.transform.rotate(rotAngle, axis)
				
				local alignZ, alignY, alignX = alignRotation:getAnglesZYX()
				local randomYaw = math.random() * math.pi * 2					
				groundRotation = util.transform.rotateZ(randomYaw) * 
								util.transform.rotateY(alignY) *
								util.transform.rotateX(-alignX)
				
				local airSpawnPos
				if woodcuttingState.treeSize < 0.5 then
					-- For small trees, raycast to find ground and spawn just above it
					local spawnRayStart = util.vector3(targetPos.x, targetPos.y, targetPos.z + 300)
					local spawnRayEnd = util.vector3(targetPos.x, targetPos.y, targetPos.z - 1000)
					local spawnCastResult = nearby.castRay(spawnRayStart, spawnRayEnd, {ignore = woodcuttingState.target, collisionType = nearby.COLLISION_TYPE.AnyPhysical})
					
					if spawnCastResult.hit then
						airSpawnPos = util.vector3(targetPos.x, targetPos.y, spawnCastResult.hitPos.z + 100)
					else
						airSpawnPos = util.vector3(targetPos.x, targetPos.y, airSpawnZ-70+math.random()*150)
					end
				else
					airSpawnPos = util.vector3(targetPos.x, targetPos.y, airSpawnZ-70+math.random()*150)
				end
				
				table.insert(spawnPositions, {
					airPosition = airSpawnPos,
					groundPosition = groundPos,
					groundRotation = groundRotation
				})
			end
		end
		
		core.sendGlobalEvent('SunsDusk_spawnFallingWood', {
			itemId = item,
			spawnData = spawnPositions,
			player = self
		})
		
		ambient.playSound("Item Misc Up", {volume = 0.5})
	end
	
	-- Remove tree and track in global saveData
	if TREES_DESPAWN then
		core.sendGlobalEvent('SunsDusk_removeTree', {
			tree = woodcuttingState.target,
		})
	else
		treeIgnoreList[woodcuttingState.target.id] = true
	end
	if types.Activator.objectIsInstance(woodcuttingState.target) then
		core.sendGlobalEvent("SunsDusk_spawnSpriggan", {self})
	end
	if not G_cellInfo.isExterior then
		local playerPos = self.position
		for _, actor in pairs(nearby.actors) do
			if (actor.position - playerPos):length() < 50*22 then
				actor:sendEvent("SunsDusk_aggroPlayer", self)
			end
		end
	end
	
	local expMult = 1
	if woodcuttingState.skill == "axe" then
		expMult = 1.2
	end
	dbg("1.5+"..string.format("%.1f", woodcuttingState.treeSize/10).."exp * ",expMult, woodcuttingState.skill)
	I.SkillProgression.skillUsed(woodcuttingState.skill, {
		skillGain = (1.5+woodcuttingState.treeSize/10)*expMult,
		useType = I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit,
		scale = nil 
	})
	G_refreshTooltips()
end

-- ════════════════════════════════════════════════════════════════════
-- Hit Handler (called by interaction system)
-- ════════════════════════════════════════════════════════════════════

local function handleWoodcuttingHit(object, objectType, groupname, key, swingData, hitPos)

	local isCurrentTarget = woodcuttingState.isActive and object == woodcuttingState.target
	
	-- Auto-start woodcutting on first hit if not active
	if not woodcuttingState.isActive or not isCurrentTarget then
		startWoodcutting(object)
	end
	
	local swingType = swingData.swingType
	
	woodcuttingState.targetPos = hitPos or object.position

	local attackEffectiveness = attackTypeEffectiveness[swingType] or 0.5
	
	-- Get equipped weapon
	local equipped = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
	local weaponRecord = nil
	local isHandToHand = true
	local toolValue = 0.5
	local effectiveDamage = 5
	local attackValue = 0.3
	local swingTypeMult = 0.7
	local durabilityHitMult = 1
	local skillValue = math.max(0,types.NPC.stats.skills.handtohand(self).modified-5)
	local baseDuration = 0.07
	woodcuttingState.toolWarning = "No tool"
	woodcuttingState.skill = "handtohand"
	
	if equipped and types.Weapon.objectIsInstance(equipped) then
		weaponRecord = types.Weapon.record(equipped)
		isHandToHand = false
		local maxDamage = math.max(weaponRecord.slashMaxDamage, weaponRecord.chopMaxDamage, weaponRecord.thrustMaxDamage)
		local swingDamage
		if swingType == "slash" then
			swingDamage = weaponRecord.slashMaxDamage
			swingTypeMult = 1.0
		elseif swingType == "chop" then
			swingDamage = weaponRecord.chopMaxDamage
			swingTypeMult = 0.875
		elseif swingType == "thrust" then
			swingDamage = weaponRecord.thrustMaxDamage
			swingTypeMult = 0.75
		else
			swingDamage = maxDamage
		end
		
		effectiveDamage = (swingDamage + maxDamage) / 2
		
		-- Tool type handling
		if weaponRecord.id == "t_de_ebony_pickaxe_01" or weaponRecord.id == "bm nordic pick" then
			toolValue = 3.75
			attackValue = toolValue * 0.9
			durabilityHitMult = 0.5
			woodcuttingState.toolWarning = nil
			skillValue = types.NPC.stats.skills.axe(self).modified*0.9
			woodcuttingState.skill = "axe"
		elseif weaponRecord.id:lower():find("pick") then
			toolValue = 2.25
			attackValue = toolValue * 0.9
			durabilityHitMult = 0.5
			woodcuttingState.toolWarning = nil
			skillValue = types.NPC.stats.skills.axe(self).modified*0.9
			woodcuttingState.skill = "axe"
		elseif weaponRecord.type == types.Weapon.TYPE.AxeOneHand or weaponRecord.type == types.Weapon.TYPE.AxeTwoHand then
			toolValue = 2.5 + maxDamage / 12
			attackValue = 2.5 + effectiveDamage / 12
			durabilityHitMult = 0.5
			woodcuttingState.toolWarning = nil
			skillValue = types.NPC.stats.skills.axe(self).modified
			woodcuttingState.skill = "axe"
		elseif weaponRecord.type == types.Weapon.TYPE.LongBladeTwoHand then
			toolValue = 1.8 + maxDamage / 15
			attackValue = 1.8 + effectiveDamage / 15
			durabilityHitMult = 0.75
			woodcuttingState.toolWarning = "Wrong tool"
			skillValue = types.NPC.stats.skills.longblade(self).modified*0.65
			woodcuttingState.skill = "longblade"
			baseDuration = 0.075
		elseif weaponRecord.type == types.Weapon.TYPE.LongBladeOneHand  then
			toolValue = 1.3 + maxDamage / 18
			attackValue = 1.3 + effectiveDamage / 18
			durabilityHitMult = 0.95
			woodcuttingState.toolWarning = "Wrong tool"
			skillValue = types.NPC.stats.skills.longblade(self).modified*0.5
			woodcuttingState.skill = "longblade"
			baseDuration = 0.08
		elseif weaponRecord.type == types.Weapon.TYPE.BluntOneHand or weaponRecord.type == types.Weapon.TYPE.BluntTwoClose then
			toolValue = 1.3 + maxDamage / 18
			attackValue = 1.3 + effectiveDamage / 18
			durabilityHitMult = 0.95
			woodcuttingState.toolWarning = "Wrong tool"
			skillValue = types.NPC.stats.skills.bluntweapon(self).modified*0.5
			woodcuttingState.skill = "bluntweapon"
			baseDuration = 0.08
		elseif weaponRecord.type == types.Weapon.TYPE.ShortBladeOneHand then
			toolValue = 1.0 + maxDamage / 21
			attackValue = 1 + effectiveDamage / 21
			durabilityHitMult = 1.1
			woodcuttingState.toolWarning = "Wrong tool"
			skillValue = types.NPC.stats.skills.shortblade(self).modified*0.4
			woodcuttingState.skill = "shortblade"
			baseDuration = 0.09
		elseif weaponRecord.type == types.Weapon.TYPE.SpearTwoWide then
			toolValue = 0.8 + maxDamage / 25
			attackValue = 0.8 + effectiveDamage / 25
			durabilityHitMult = 1.1
			woodcuttingState.toolWarning = "Wrong tool"
			skillValue = types.NPC.stats.skills.spear(self).modified*0.4
			woodcuttingState.skill = "spear"
			baseDuration = 0.095
		elseif weaponRecord.type == types.Weapon.TYPE.MarksmanBow or weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow or weaponRecord.type == types.Weapon.TYPE.MarksmanThrown then
			toolValue = 0.5 + maxDamage / 31
			attackValue = 0.5 + effectiveDamage / 31
			durabilityHitMult = 0.5
			woodcuttingState.toolWarning = "Wrong tool"
			skillValue = types.NPC.stats.skills.marksman(self).modified*0.33
			woodcuttingState.skill = "marksman"
			baseDuration = 0.1
		else
			toolValue = 1.0 + maxDamage / 20
			attackValue = 1 + effectiveDamage / 20
			durabilityHitMult = 0.7
			woodcuttingState.toolWarning = "Wrong tool"
		end
		
		if weaponRecord.id:find("bound") then
			toolValue = toolValue * 0.7
			attackValue = attackValue * 0.8
		end
	end
	
	if isHandToHand then
		if saveData.playerInfo.isKhajiit then
			toolValue = toolValue * 1.7
			attackValue = attackValue * 1.7
			skillValue = skillValue * 1.3
		elseif saveData.playerInfo.isBeast then
			toolValue = toolValue * 1.3
			attackValue = attackValue * 1.3
			skillValue = skillValue * 1.2
		else
			skillValue = skillValue * 1.1
		end
	end
	
	local swingStrength = swingData.swingStrength
	dbg("swingStrength: "..swingStrength)
	
	-- Store tool value for wood drop calculation
	woodcuttingState.toolValue = math.max(2, toolValue)
	
	dbg("tree size: ",woodcuttingState.treeSize+10)
	local strValue =  ((20+typesPlayerStatsSelf.strength.modified)^0.7 / 1.5) - 5.42
	dbg("skill: "..skillValue.." + "..string.format("%.1f", strValue) .." str")
	skillValue = skillValue + strValue
	dbg("attackValue:",attackValue)
	
	local durationExp = 1.75
	local skillMult = 5
	local attackValueMult = 125.0
	local finalMult = 1.1
	local finalAdd = 1.5
	
	local treeSizeMod = woodcuttingState.treeSize
	if treeSizeMod < 0.1 then
		treeSizeMod = 15
	end
	local duration = baseDuration * (treeSizeMod+10)
	
	local normalDuration = duration
	local durationWithExp = duration^durationExp
	
	dbg("normalDur:",normalDuration)
	dbg("durationWithExp:",durationWithExp)
	
	local score = math.max(0, skillValue - 5) * skillMult
	score = score + attackValue * attackValueMult
	score = math.min(1, score / 1100)
	dbg("score:",score)
	local result = normalDuration * score + durationWithExp * (1-score)
	local finalDur = result * finalMult + finalAdd - skillValue/20 - attackValue/4
	finalDur = math.max(2.5, finalDur)
	if types.Activator.objectIsInstance(woodcuttingState.target) then
		finalDur = finalDur * 2
	end
	dbg( "swings needed:",finalDur, " * ".. 1/swingTypeMult)
	
	local progress = 1/finalDur * swingTypeMult * swingStrength * math.max(0, math.min(1, 0.33+swingData.preSwingFatigue/4*0.67))
	
	treeProgressData[woodcuttingState.target.id] = (treeProgressData[woodcuttingState.target.id] or 0) + progress
	
	updateProgressBar()
	
	-- Check completion
	if (treeProgressData[woodcuttingState.target.id] or 0) >= 1 then
		completeWoodcutting()
	end
	
	-- Spawn VFX and sound
	core.sendGlobalEvent("SpawnVfx", {
		model = "meshes/e/magic_hit_conjure.nif",
		position = (hitPos or object.position) - v3(0, 0, 20),
		options = {scale = 0.4}
	})
	ambient.playSoundFile("sound/sunsdusk/woodcutfx-001.ogg",{volume = 1})
	
	if equipped and woodcuttingState.skill ~= "marksman" then
		core.sendGlobalEvent("ModifyItemCondition", {actor = self.object, item = equipped, amount= -durabilityHitMult})
	end
	self:sendEvent("SunsDusk_attackedTree", {woodcuttingState.target, treeProgressData[woodcuttingState.target.id]})
	-- Drain fatigue
	typesPlayerStatsSelf.fatigue.current = math.max(0, typesPlayerStatsSelf.fatigue.current - 2)
end

-- ════════════════════════════════════════════════════════════════════
-- World Interaction Registration
-- ════════════════════════════════════════════════════════════════════

G_worldInteractions.woodcutting = {
	canInteract = function(object, objectType)
		return G_isWoodcuttingActivator(object, objectType)
	end,
	getActions = function(object, objectType)
		-- Initialize state when first targeting a tree
		if not woodcuttingState.isActive or woodcuttingState.target ~= object then
			startWoodcutting(object)
		end
		
		return {{
			label = woodcuttingState.treeName,
			preferred = "Attack",
			
			customContent = function(obj)
				return hud_woodcuttingProgress
			end,
			
			onHit = handleWoodcuttingHit,
		}}
	end
}

-- ════════════════════════════════════════════════════════════════════════════════
-- World Interaction Registration - Firemaking
-- ════════════════════════════════════════════════════════════════════════════════

G_worldInteractions.firemaking_unlit = {
	canInteract = function(object, objectType)
		return logItems[object.recordId] and true or false
	end,
	getActions = function(object, objectType)
		local amountOfLogs = tonumber(object.recordId:sub(-1, -1)) or 0
		local actions = {}
		
		table.insert(actions, {
			label = "Add Firewood",
			preferred = "ToggleWeapon",
			disabled = amountOfLogs >= 5,
			handler = function(obj)
				if amountOfLogs < 5 then
					core.sendGlobalEvent("SunsDusk_upgradeFire", {self, obj})
				end
			end
		})
		
		local canIgnite = amountOfLogs >= 3 and not G_cellInfo.hasPublican
		local waterLevel = object.cell and object.cell.waterLevel or -99999999
		local isUnderwater = (-object.position.z + waterLevel) > 0
		canIgnite = canIgnite and not isUnderwater
		
		local igniteLabel
		if amountOfLogs < 3 then
			igniteLabel = "Light fire [" .. amountOfLogs .. "/3]"
		else
			igniteLabel = "Light fire [" .. (amountOfLogs * 2) .. ":00h]"
		end
		
		table.insert(actions, {
			label = igniteLabel,
			preferred = "ToggleSpell",
			disabled = not canIgnite,
			handler = function(obj)
				if G_cellInfo.hasPublican then
					messageBox(2, messageBoxes_lightFireInInn[math.random(1, #messageBoxes_lightFireInInn)])
				elseif isUnderwater then
					messageBox(2, "You try to light a fire but know in your heart it is pointless ...")
				elseif amountOfLogs >= 3 then
					core.sendGlobalEvent("SunsDusk_igniteFire", {self, obj})
				end
			end
		})
		
		return actions
	end
}

G_worldInteractions.firemaking_lit = {
	canInteract = function(object, objectType)
		return burningLogs[object.recordId] and true or false
	end,
	getActions = function(object, objectType)
		local amountOfLogs = tonumber(object.recordId:sub(-5, -5)) or 0
		
		return {{
			label = "Add Firewood",
			preferred = "ToggleWeapon",
			disabled = amountOfLogs >= 5,
			handler = function(obj)
				if amountOfLogs < 5 then
					core.sendGlobalEvent("SunsDusk_upgradeFire", {self, obj})
				end
			end
		}}
	end
}

-- ════════════════════════════════════════════════════════════════════════════════
-- Settings Changed Handler
-- ════════════════════════════════════════════════════════════════════════════════

local function settingsChanged(sectionName, setting, oldValue)
	if setting == "WORLD_TOOLTIP_FONT_SIZE" then
		treeNameText.props.textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE)
		treeNameText.props.alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0
		progressContainer.props.size = v2(barWidth + 4, math.max(WORLD_TOOLTIP_ICON_SIZE,WORLD_TOOLTIP_FONT_SIZE)-2)
		progressText.props.textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE - 4)
		progressText.props.alpha = (WORLD_TOOLTIP_FONT_SIZE - 4)>0 and 1 or 0
	elseif setting == "WORLD_TOOLTIP_ICON_SIZE" then
		progressContainer.props.size = v2(barWidth + 4, math.max(WORLD_TOOLTIP_ICON_SIZE,WORLD_TOOLTIP_FONT_SIZE)-2)
	elseif setting == "WORLD_TOOLTIP_FONT_COLOR" then
		treeNameText.props.textColor = WORLD_TOOLTIP_FONT_COLOR
	end
end
table.insert(G_settingsChangedJobs, settingsChanged)