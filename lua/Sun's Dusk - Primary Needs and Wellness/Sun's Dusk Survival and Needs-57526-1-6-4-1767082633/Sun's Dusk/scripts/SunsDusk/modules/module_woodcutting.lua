--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk : Woodcutting Module                                     │
│  Chop trees for wood and lumber                                      │
│  Modified: Animation-based progress system                           │
╰──────────────────────────────────────────────────────────────────────╯
]]
local iMaxActivateDist = core.getGMST("iMaxActivateDist") + 0.1
local treeIgnoreList = {}

-- Progress storage per tree (runtime only)
local treeProgressData = {}
local targettedTreeTime = nil
local targettingTree = false
local lastHit = 0
local startedUse = nil
local isUsing
local stopOnce = true
local slot1, slot2, slot3 = {0, 0}, {0, 0}, {0, 0}
local nextSlot = 1
local enableDebug = false
local preSwingFatigue = types.Actor.stats.dynamic.fatigue(self).current

local function dbg(...)
	if enableDebug then
		print(...)
	end
end


input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	if use and not isUsing then
		startedUse = core.getSimulationTime()
		isUsing = true
	elseif not use and isUsing then
		preSwingFatigue = types.Actor.stats.dynamic.fatigue(self).current
		local currentTime = core.getSimulationTime()
		local holdDuration = math.max(0,currentTime - startedUse)
		local swingStrength = math.min(holdDuration, 1.0)
		-- Write to next slot (circular)
		local slot = nextSlot == 1 and slot1 or (nextSlot == 2 and slot2 or slot3)
		slot[1], slot[2] = currentTime, swingStrength
		nextSlot = (nextSlot % 3) + 1
		isUsing = false
		startedUse = nil
	end
	
	return use
end), {})


-- ════════════════════════════════════════════════════════════════════
-- Woodcutting Target Detection
-- ════════════════════════════════════════════════════════════════════

local logItems = {
	["sd_wood_1"] = true,
	["sd_wood_2"] = true,
	["sd_wood_3"] = true,
	["sd_wood_4"] = true,
	["sd_wood_5"] = true,
}

local litLogItems = {
	["sd_wood_1_lit"] = true,
	["sd_wood_2_lit"] = true,
	["sd_wood_3_lit"] = true,
	["sd_wood_4_lit"] = true,
	["sd_wood_5_lit"] = true,
}

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
	local dbEntry = dbStatics[object.recordId] and dbStatics[object.recordId].woodcutting
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
	if treeIgnoreList[object.id] then
		return false
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

-- Difficulty settings for different tree types
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
		maxDistance = 400, -- Distance in units before progress bar disappears
		targetPos = nil,
		skill = "axe",
		weaponQuality = 0.1
	}
end

local barWidth = 180
local barHeight = 16

-- Helper functions
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
		return util.color.rgb(1, chance/0.7, 0)
	else
		local red = 1 - (chance - 0.7) / 2
		return util.color.rgb(math.max(0, red), 1, 0)
	end
end



-- Colors
local progressColor = G_morrowindGold

-- ════════════════════════════════════════════════════════════════════
-- Progress Bar UI
-- ════════════════════════════════════════════════════════════════════

-- Root
hud_woodcuttingProgress = ui.create({
	type = ui.TYPE.Container,
	--layer = 'HUD',
	name = "hud_woodcuttingProgress",
	props = {
		relativePosition = v2(0.5, 0.8),
		anchor = v2(0.5, 0.5),
		--visible = false,
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
	--hud_woodcuttingProgress.layout.props.visible = true
	hud_woodcuttingProgress:update()
end

-- ════════════════════════════════════════════════════════════════════
-- Woodcutting Start and Completion
-- ════════════════════════════════════════════════════════════════════

startWoodcutting = function(target)

	
	woodcuttingState.toolWarning = nil
		
	--woodcuttingState.treeName = target.type.record(target).name or "Tree"
	woodcuttingState.treeName = "Tree"
	woodcuttingState.target = target
	
	-- Calculate size scale multiplier from bounding box
	local bbox = target:getBoundingBox()
	log(3, "tree size:", bbox.halfSize.z)
	
	
	
	local dbTreeSize = dbStatics[target.recordId] and dbStatics[target.recordId].woodcutting and dbStatics[target.recordId].woodcutting.treeSize
	if dbTreeSize then
		woodcuttingState.treeSize = dbTreeSize / 20
	else
		woodcuttingState.treeSize = bbox.halfSize.z / 20
	end
	
	
	woodcuttingState.isActive = true

	
	-- Show the UI
	--hud_woodcuttingProgress.layout.props.visible = true
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
	--hud_woodcuttingProgress.layout.props.visible = false
	hud_woodcuttingProgress:update()
	
	-- Clear stored progress for this tree

	treeProgressData[woodcuttingState.target] = nil

	
	local item = treeToItemLookup[woodcuttingState.target.recordId] or FALLBACK_WOOD
	if item then
		local difficulty = treeDifficulties[item] or 25
		local diffMod = 0.7 + difficulty / 70
		
		-- Calculate wood count
		local woodCount = math.random(2, 3)
		-- Tool quality affects wood drops (toolValue already set in handleHit)
		woodCount = woodCount * ((woodcuttingState.toolValue-1)/9+1)
		woodCount= woodCount * 0.5
		-- Scale drop amount by tree size
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
			-- Add random offset to spread items around the tree
			local angle = math.random() * math.pi * 2
			local distance = math.random() * 100 + 50  -- 40-120 units from tree
			local offset = util.vector3(
				math.cos(angle) * distance,
				math.sin(angle) * distance,
				0
			)
			local targetPos = woodcuttingState.target.position + offset
			if not TREES_DESPAWN then
				targetPos =self.position + offset + v3(0,0,30)
			end
			
			-- Raycast downward to find ground
			local rayStart = util.vector3(targetPos.x, targetPos.y, targetPos.z + 200)
			local rayEnd = util.vector3(targetPos.x, targetPos.y, targetPos.z - 1000)
			
			local castResult = nearby.castRay(rayStart, rayEnd, {ignore = woodcuttingState.target, collisionType = nearby.COLLISION_TYPE.AnyPhysical})
			
			local groundPos
			local groundRotation
			if castResult.hit and (not castResult.hitObject or not types.Actor.objectIsInstance(castResult.hitObject)) then
				groundPos = castResult.hitPos + util.vector3(0, 0, 7)
				
				local hitNormal = castResult.hitNormal
				local up = util.vector3(0, 0, 1)
				local normal = hitNormal:normalize()
				
				-- Get perfect alignment rotation
				local axis = up:cross(normal):normalize()
				local rotAngle = math.acos(math.max(-1, math.min(1, up:dot(normal))))
				local alignRotation = util.transform.rotate(rotAngle, axis)
				
				-- Apply random yaw
				local alignZ, alignY, alignX = alignRotation:getAnglesZYX()
				local randomYaw = math.random() * math.pi * 2					
				groundRotation = util.transform.rotateZ(randomYaw) * 
								util.transform.rotateY(alignY) *
								util.transform.rotateX(-alignX)
				
				local airSpawnPos = util.vector3(targetPos.x, targetPos.y, airSpawnZ-70+math.random()*150)
				
				table.insert(spawnPositions, {
					airPosition = airSpawnPos,
					groundPosition = groundPos,
					groundRotation = groundRotation
				})
			end
		end
		
		-- Spawn wood items that will fall
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
	dbg("1.5+"..f1dot(woodcuttingState.treeSize/10).."exp * ",expMult, woodcuttingState.skill)
	I.SkillProgression.skillUsed(woodcuttingState.skill, {
		skillGain = (1.5+woodcuttingState.treeSize/10)*expMult,
		useType = I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit,
		scale = nil 
	})
end

-- ════════════════════════════════════════════════════════════════════
-- Animation Handler
-- ════════════════════════════════════════════════════════════════════
local function handleHit(groupname, key)
	-- Check if this object is a valid woodcutting target
	local isValidTarget = G_raycastResultType and G_isWoodcuttingActivator(G_raycastResult.hitObject, G_raycastResultType)
	if isValidTarget then
		local now = core.getSimulationTime()
		local weaponSpeed = animation.getSpeed(self, groupname)
		if now < lastHit+0.35/weaponSpeed then
			return
		end
		lastHit = now
	
		local isCurrentTarget = woodcuttingState.isActive and G_raycastResult.hitObject == woodcuttingState.target
		
		-- Auto-start woodcutting on first hit if not active
		if not woodcuttingState.isActive or not isCurrentTarget then
			startWoodcutting(G_raycastResult.hitObject)
		end
		
		-- If this is our active target, add progress
		--if woodcuttingState.isActive and G_raycastResult.hitObject == woodcuttingState.target then
			-- Find max from valid swings
			local swingType = key:match("^(%S+)")
			local requiredWindUp = 0.5
			local startTime = animation.getTextKeyTime(self, groupname..": "..swingType.." start")
			local chargedTime = animation.getTextKeyTime(self, groupname..": "..swingType.." max attack")	
			if startTime and chargedTime then
				requiredWindUp = (chargedTime - startTime)*0.9
			end
		
			woodcuttingState.targetPos = G_raycastResult.hitPos

			-- Attack type effectiveness lookup

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
				weaponSpeed = weaponSpeed * weaponRecord.speed
				isHandToHand = false
				-- Get swing-specific damage
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
				
				-- Get max damage and chop damage
				
				
				-- Mix 50:50 to avoid extremes
				effectiveDamage = (swingDamage + maxDamage) / 2
				
				-- Calculate toolValue based on maxDamage (for wood drops)
				-- Special pickaxe handling
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
				-- Axes - the recommended tool
				elseif weaponRecord.type == types.Weapon.TYPE.AxeOneHand or weaponRecord.type == types.Weapon.TYPE.AxeTwoHand then
					toolValue = 2.5 + maxDamage / 12
					attackValue = 2.5 + effectiveDamage / 12
					durabilityHitMult = 0.5
					woodcuttingState.toolWarning = nil
					skillValue = types.NPC.stats.skills.axe(self).modified
					woodcuttingState.skill = "axe"
				-- 2H Long blades - okay
				elseif weaponRecord.type == types.Weapon.TYPE.LongBladeTwoHand then
					toolValue = 1.8 + maxDamage / 15
					attackValue = 1.8 + effectiveDamage / 15
					durabilityHitMult = 0.75
					woodcuttingState.toolWarning = "Wrong tool"
					skillValue = types.NPC.stats.skills.longblade(self).modified*0.65
					woodcuttingState.skill = "longblade"
					baseDuration = 0.075
				-- Long blades - poor
				elseif weaponRecord.type == types.Weapon.TYPE.LongBladeOneHand  then
					toolValue = 1.3 + maxDamage / 18
					attackValue = 1.3 + effectiveDamage / 18
					durabilityHitMult = 0.95
					woodcuttingState.toolWarning = "Wrong tool"
					skillValue = types.NPC.stats.skills.longblade(self).modified*0.5
					woodcuttingState.skill = "longblade"
					baseDuration = 0.08
				-- Blunt - poor
				elseif weaponRecord.type == types.Weapon.TYPE.BluntOneHand or weaponRecord.type == types.Weapon.TYPE.BluntTwoClose then
					toolValue = 1.3 + maxDamage / 18
					attackValue = 1.3 + effectiveDamage / 18
					durabilityHitMult = 0.95
					woodcuttingState.toolWarning = "Wrong tool"
					skillValue = types.NPC.stats.skills.bluntweapon(self).modified*0.5
					woodcuttingState.skill = "bluntweapon"
					baseDuration = 0.08
				-- Short blades - very poor
				elseif weaponRecord.type == types.Weapon.TYPE.ShortBladeOneHand then
					toolValue = 1.0 + maxDamage / 21
					attackValue = 1 + effectiveDamage / 21
					durabilityHitMult = 1.1
					woodcuttingState.toolWarning = "Wrong tool"
					skillValue = types.NPC.stats.skills.shortblade(self).modified*0.4
					woodcuttingState.skill = "shortblade"
					baseDuration = 0.09
				-- Spears - terrible
				elseif weaponRecord.type == types.Weapon.TYPE.SpearTwoWide then
					toolValue = 0.8 + maxDamage / 25
					attackValue = 0.8 + effectiveDamage / 25
					durabilityHitMult = 1.1
					woodcuttingState.toolWarning = "Wrong tool"
					skillValue = types.NPC.stats.skills.spear(self).modified*0.4
					woodcuttingState.skill = "spear"
					baseDuration = 0.095
				-- Marksman weapons - worst
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
				
				-- Bound weapon penalty
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
				
			local cutoff = now - 0.8
			local maxStrength = 0
			if slot1[1] >= cutoff and slot1[2] > maxStrength then maxStrength = slot1[2] end
			if slot2[1] >= cutoff and slot2[2] > maxStrength then maxStrength = slot2[2] end
			if slot3[1] >= cutoff and slot3[2] > maxStrength then maxStrength = slot3[2] end
	
			-- If all expired, use the most recent one
			if maxStrength == 0 then
				local mostRecent = slot1
				if slot2[1] > mostRecent[1] then mostRecent = slot2 end
				if slot3[1] > mostRecent[1] then mostRecent = slot3 end
				maxStrength = mostRecent[2]
			end
			
			local swingStrength = math.min(1, weaponSpeed * maxStrength/requiredWindUp)
			dbg("click: "..maxStrength, "speed: "..weaponSpeed, "windUp: "..requiredWindUp, "= "..swingStrength)
			
			
			
			-- Store tool value for wood drop calculation
			woodcuttingState.toolValue = math.max(2, toolValue)
			
			dbg("tree size: ",woodcuttingState.treeSize+10)
			-- Calculate multipliers
			local strValue =  ((20+types.Actor.stats.attributes.strength(self).modified)^0.7 / 1.5) - 5.42
			dbg("skill: "..skillValue.." + "..math.floor(strValue*10)/10 .." str")
			skillValue = skillValue + strValue
			dbg("attackValue:",attackValue)
			
			--baseDuration = 0.07 - 0.09
			local durationExp = 1.75
			local skillMult = 5
			local attackValueMult = 125.0
			local finalMult = 1.1
			local finalAdd = 1.5
			
			local duration = baseDuration * (woodcuttingState.treeSize+10)  -- Scale duration by tree size (0.1-70)
			
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
			--woodcuttingState.duration = math.max(2, finalDur)
			
			
			
			
			
			-- Calculate final progress amount
			--local baseProgress = 10
			--local progress = baseProgress * attackEffectiveness * (effectiveDamage / 10) * (toolValue / 2.5) * skillMult * strengthMult * swingStrength

			local progress = 1/finalDur * swingTypeMult * swingStrength * math.max(0, math.min(1, 0.33+preSwingFatigue/4*0.67))
			
			treeProgressData[woodcuttingState.target.id] = (treeProgressData[woodcuttingState.target.id] or 0) + progress
			
			updateProgressBar()
			
			-- Check if completed
			if treeProgressData[woodcuttingState.target.id] >= 1 then
				completeWoodcutting()
			end
			
			-- Spawn VFX and sound
			core.sendGlobalEvent("SpawnVfx", {
				model = "meshes/e/magic_hit_conjure.nif",
				position = G_raycastResult.hitPos - v3(0, 0, 20),
				options = {scale = 0.4}
			})
			ambient.playSoundFile("sound/sunsdusk/woodcutfx-001.ogg",{volume = 1})
			if equipped then
				core.sendGlobalEvent("ModifyItemCondition", {actor = self.object, item = equipped, amount= -durabilityHitMult})
			end
			
			-- Drain fatigue
			types.Actor.stats.dynamic.fatigue(self).current = math.max(0, types.Actor.stats.dynamic.fatigue(self).current - 2)
		--end
	elseif G_raycastResultType == "Activator" and (G_raycastResult.hitObject.recordId == "sd_campingobject_tent" or G_raycastResult.hitObject.recordId == "sd_campingobject_bedroll") then
		core.sendGlobalEvent("SunsDusk_destroyCamp", G_raycastResult.hitObject)
		-- Spawn VFX and sound
		core.sendGlobalEvent("SpawnVfx", {
			model = "meshes/e/magic_hit_conjure.nif",
			position = G_raycastResult.hitPos - v3(0, 0, 20),
			options = {scale = 0.4}
		})
		ambient.playSoundFile("sound/sunsdusk/woodcutfx-001.ogg",{volume = 1})
	--else
		-- Not hitting a valid tree
		--ambient.playSound("SwishL", {volume = 0.5})
	end
end
	
I.AnimationController.addTextKeyHandler('', function(groupname, key)
	if stopOnce and key:find("stop") then
		startedUse = core.getSimulationTime()+0.04
		stopOnce = false
	elseif key:find("hit") then
		startedUse = core.getSimulationTime()+0.04
		handleHit(groupname, key) --(0.2 + math.min(1, maxStrength * animation.getSpeed(self, groupname)/ 0.45)*0.8) ^1.5)
		stopOnce = true
	end
end)




-- ════════════════════════════════════════════════════════════════════
-- Tooltip and Activation
-- ════════════════════════════════════════════════════════════════════

local woodcuttingTooltip = nil

-- Calculating anchor based on offset from center
local function alignAxis(value)
	local center = 0.5
	local threshold = 0.01
	local dist = math.abs(value - center)
	local t = math.min(dist / threshold, 1)
	if value > center then
		return 0.5 - (t * 0.5)
	else
		return 0.5 + (t * 0.5)
	end
end

local function alignAnchor(pos)
	local alignedX = alignAxis(pos.x)
	local alignedY = alignAxis(pos.y)
	return v2(alignedX, alignedY)
end

local function raycastChanged()
	if not G_raycastResult then
		return
	end
	

	
	-- Check if this is a valid woodcutting target
	if G_isWoodcuttingActivator(G_raycastResult.hitObject, G_raycastResultType) and I.UI.isHudVisible() then
		if woodcuttingTooltip then
			woodcuttingTooltip:destroy()
		end
		targettedTreeTime = core.getSimulationTime()
		targettingTree = true
		local treeRecordId = G_raycastResult.hitObject.recordId
		--local treeName = G_raycastResult.hitObject.type.record(G_raycastResult.hitObject).name or "Tree"
		local treeName = "Tree"
		
		local item = treeToItemLookup[treeRecordId] or FALLBACK_WOOD
		
		local anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100))
		
		woodcuttingTooltip = ui.create({
			layer = 'Scene',
			name = "woodcuttingTooltip",
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				autoSize = true,
				relativePosition = v2(TOOLTIP_RELATIVE_X/100,TOOLTIP_RELATIVE_Y/100),
				anchor = anchor,
				arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center,
				anchor = v2(0,0.25),
			},
			content = ui.content{}
		})
		local firstRow = {
			layer = 'Scene',
			name = "woodcuttingTooltip",
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = true,
				relativePosition = v2(TOOLTIP_RELATIVE_X/100,TOOLTIP_RELATIVE_Y/100),
				anchor = anchor,
				arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
			},
			content = ui.content{}
		}
		woodcuttingTooltip.layout.content:add(firstRow)
		
		firstRow.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/attack.dds"),
				tileH = false,
				tileV = false,
				size = v2(WORLD_TOOLTIP_ICON_SIZE, WORLD_TOOLTIP_ICON_SIZE),
				alpha = 0.6,
				color = WORLD_TOOLTIP_FONT_COLOR,
			}
		}
		firstRow.content:add(treeNameText)	
		
		woodcuttingTooltip.layout.content:add{props={size=v2(1,1)*2}}
		woodcuttingTooltip.layout.content:add(hud_woodcuttingProgress)
		
		startWoodcutting(G_raycastResult.hitObject)
		--woodcuttingTooltip.layout.content:add{
		--	type = ui.TYPE.Text,
		--	props = {
		--		text = " "..treeName,
		--		textColor = WORLD_TOOLTIP_FONT_COLOR,
		--		textShadow = true,
		--		textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
		--		alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
		--	}
		--}
	elseif woodcuttingTooltip then
		woodcuttingTooltip:destroy()
		woodcuttingTooltip = nil
		targettedTreeTime = core.getSimulationTime()
		targettingTree = false
		woodcuttingState.isActive = false
		woodcuttingState.target = nil
	end
	local keepFiremakingTooltip = false
	---------------- FIREMAKING ----------------
	if G_raycastResult.hitObject and not saveData.playerInfo.isInWerewolfForm and logItems[G_raycastResult.hitObject.recordId] then
		keepFiremakingTooltip = true
		if firemakingTooltip then
			firemakingTooltip:destroy()
			firemakingTooltip = nil
		end
		
		if I.UI.isHudVisible() then
			local amountOfLogs = tonumber(G_raycastResult.hitObject.recordId:sub(-1,-1))
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false) 
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
			
			local anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100))
			
			
			local validIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
			validIconHsv[2] = validIconHsv[2]*0.6
			validIconHsv[3] = math.min(1,validIconHsv[3]*1.8)
			local validIconRgb = util.color.rgb(hsvToRgb(validIconHsv[1],validIconHsv[2],validIconHsv[3]))
			
			local invalidIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
			invalidIconHsv[2] = invalidIconHsv[2]*0.3
			invalidIconHsv[3] = math.min(1,invalidIconHsv[3]*0.4)
			local invalidIconRgb = util.color.rgb(hsvToRgb(invalidIconHsv[1],invalidIconHsv[2],invalidIconHsv[3]))
			
			
			local addIconColor = validIconRgb
			local addTextColor = WORLD_TOOLTIP_FONT_COLOR
			if amountOfLogs >= 5 then
				addIconColor = invalidIconRgb
				addTextColor = invalidIconRgb
			end
			
			
			local igniteIconColor = validIconRgb
			local igniteTextColor = WORLD_TOOLTIP_FONT_COLOR
			local igniteText = "Light the fire ["..(amountOfLogs*2)..":00h]"
			if amountOfLogs < 3 or G_cellInfo.hasPublican then
				igniteIconColor = invalidIconRgb
				igniteTextColor = invalidIconRgb
				igniteText = "Light the fire ["..amountOfLogs.."/3]"
			end
			
			firemakingTooltip = ui.create({
				layer = 'Scene',
				name = "firemakingTooltip",
				type = ui.TYPE.Flex,
				props = {
					relativePosition = v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100),
					anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100)),
					horizontal = false,
					autoSize = true,
					arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
				},
				content = ui.content{}
			})
			local line1 = {
				layer = 'Scene',
				name = "firemakingTooltip",
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
					autoSize = true,
					arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
				},
				content = ui.content{}
			}
			firemakingTooltip.layout.content:add(line1)
			
			--if anchor.x>0.4 -- flip order of elements... overkill?
			
			line1.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/f.dds"),
					tileH = false,
					tileV = false,
					size  = v2(WORLD_TOOLTIP_ICON_SIZE,WORLD_TOOLTIP_ICON_SIZE),
					alpha = 0.6,
					color = addIconColor,
				}
			}
			line1.content:add{
				type = ui.TYPE.Text,
				props = {
					text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "").."Add more Firewood",
					textColor = addTextColor,
					textShadow = true,
					textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
					alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
				}
			}
			local line2 = {
				layer = 'Scene',
				name = "firemakingTooltip",
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
					autoSize = true,
					arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
				},
				content = ui.content{}
			}
			firemakingTooltip.layout.content:add(line2)
			
			--if anchor.x>0.4 -- flip order of elements... overkill?
			
			line2.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/r.dds"),
					tileH = false,
					tileV = false,
					size  = v2(WORLD_TOOLTIP_ICON_SIZE,WORLD_TOOLTIP_ICON_SIZE),
					alpha = 0.6,
					color = igniteIconColor,
				}
			}
			line2.content:add{
				type = ui.TYPE.Text,
				props = {
					text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "")..igniteText,
					textColor = igniteTextColor,
					textShadow = true,
					textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
					alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
				}
			}
		elseif firemakingTooltip then
			firemakingTooltip:destroy()
			firemakingTooltip = nil
		end
	elseif firemakingTooltip then
		firemakingTooltip:destroy()
		firemakingTooltip = nil
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true) 
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
	end
	
	if G_raycastResult.hitObject and not saveData.playerInfo.isInWerewolfForm and litLogItems[G_raycastResult.hitObject.recordId] then
		if firemakingTooltip then
			firemakingTooltip:destroy()
			firemakingTooltip = nil
		end
		
		if I.UI.isHudVisible() then
			local amountOfLogs = tonumber(G_raycastResult.hitObject.recordId:sub(-5,-5))
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false) 
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
			
			
			local anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100))
			
			
			local validIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
			validIconHsv[2] = validIconHsv[2]*0.6
			validIconHsv[3] = math.min(1,validIconHsv[3]*1.8)
			local validIconRgb = util.color.rgb(hsvToRgb(validIconHsv[1],validIconHsv[2],validIconHsv[3]))
			
			local invalidIconHsv = {rgbToHsv(WORLD_TOOLTIP_FONT_COLOR)}
			invalidIconHsv[2] = invalidIconHsv[2]*0.3
			invalidIconHsv[3] = math.min(1,invalidIconHsv[3]*0.4)
			local invalidIconRgb = util.color.rgb(hsvToRgb(invalidIconHsv[1],invalidIconHsv[2],invalidIconHsv[3]))
			
			
			local addIconColor = validIconRgb
			local addTextColor = WORLD_TOOLTIP_FONT_COLOR
			if amountOfLogs >= 5 then
				addIconColor = invalidIconRgb
				addTextColor = invalidIconRgb
			end
			
			firemakingTooltip = ui.create({
				layer = 'Scene',
				name = "firemakingTooltip",
				type = ui.TYPE.Flex,
				props = {
					relativePosition = v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100),
					anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100, TOOLTIP_RELATIVE_Y/100)),
					horizontal = false,
					autoSize = true,
					arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
				},
				content = ui.content{}
			})
			local cookingText = "Cook"
			if checkHasDirtyWater() then
				cookingText = "Purify water"
			end
			firemakingTooltip.layout.content:add{
				name = "cookingTooltip",
				type = ui.TYPE.Text,
				props = {
					text = cookingText,
					relativePosition = v2(TOOLTIP_RELATIVE_X/100,TOOLTIP_RELATIVE_Y/100),
					anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100,TOOLTIP_RELATIVE_Y/100)),
					textColor = WORLD_TOOLTIP_FONT_COLOR,
					textShadow = true,
					textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
					alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
				}
			}
			
			
			local line1 = {
				layer = 'Scene',
				name = "firemakingTooltip",
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
					autoSize = true,
					arrange = anchor.x<0.4 and ui.ALIGNMENT.Start or anchor.x>0.4 and ui.ALIGNMENT.End or ui.ALIGNMENT.Center
				},
				content = ui.content{}
			}
			firemakingTooltip.layout.content:add(line1)
			
			--if anchor.x>0.4 -- flip order of elements... overkill?
			
			line1.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures/SunsDusk/worldTooltips/"..WORLD_TOOLTIP_SKIN.."/f.dds"),
					tileH = false,
					tileV = false,
					size  = v2(WORLD_TOOLTIP_ICON_SIZE,WORLD_TOOLTIP_ICON_SIZE),
					alpha = 0.6,
					color = addIconColor,
				}
			}
			line1.content:add{
				type = ui.TYPE.Text,
				props = {
					text = (WORLD_TOOLTIP_ICON_SIZE > 0 and " " or "").."Add more Firewood",
					textColor = addTextColor,
					textShadow = true,
					textSize = math.max(1,WORLD_TOOLTIP_FONT_SIZE),
					alpha = WORLD_TOOLTIP_FONT_SIZE > 0 and 1 or 0,
				}
			}
			
		elseif firemakingTooltip then
			firemakingTooltip:destroy()
			firemakingTooltip = nil
		end
	elseif firemakingTooltip and not keepFiremakingTooltip then
		firemakingTooltip:destroy()
		firemakingTooltip = nil
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true) 
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
	end
end

local function refreshTooltip()
	if cookingTooltip then
		cookingTooltip:destroy()
		cookingTooltip = nil
	end
	raycastChanged()
end
table.insert(G_refreshTooltipJobs, refreshTooltip)

input.registerTriggerHandler("ToggleSpell", async:callback(function(dt, use, sneak, run)
	if firemakingTooltip and G_raycastResult.hitObject and logItems[G_raycastResult.hitObject.recordId] then
		local amountOfLogs = tonumber(G_raycastResult.hitObject.recordId:sub(-1,-1))
		if G_cellInfo.hasPublican then
			messageBox(2, messageBoxes_lightFireInInn[math.random(1,#messageBoxes_lightFireInInn)])
		elseif amountOfLogs >= 3 then
			core.sendGlobalEvent("SunsDusk_igniteFire", {self, G_raycastResult.hitObject})
		end
	end
end))

input.registerTriggerHandler("ToggleWeapon", async:callback(function(dt, use, sneak, run)
	if firemakingTooltip and G_raycastResult.hitObject and (logItems[G_raycastResult.hitObject.recordId] or litLogItems[G_raycastResult.hitObject.recordId]) then
		local amountOfLogs = tonumber(G_raycastResult.hitObject.recordId:sub(-1,-1)) or tonumber(G_raycastResult.hitObject.recordId:sub(-5,-5))
		if amountOfLogs < 5 then
			core.sendGlobalEvent("SunsDusk_upgradeFire", {self, G_raycastResult.hitObject})
		end
	end
end))

-- Register jobs
table.insert(G_raycastChangedJobs, raycastChanged)
table.insert(G_refreshWidgetJobs, raycastChanged)

dbg("[Sun's Dusk] Woodcutting module loaded")


local function UiModeChanged(data)
	if data.oldMode == "Barter" then
		core.sendGlobalEvent("SunsDusk_convertPurchasedWood", self)
	end
end
 table.insert(G_UiModeChangedJobs, UiModeChanged)
 

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
