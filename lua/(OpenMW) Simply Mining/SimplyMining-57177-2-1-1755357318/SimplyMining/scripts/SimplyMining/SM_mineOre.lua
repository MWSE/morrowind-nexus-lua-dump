if hud_craftingProgress then
	hud_craftingProgress:destroy()
	hud_craftingProgress = nil
end


local makeBorder = require("scripts.SimplyMining.ui_makeborder") 
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
	

-- crafting state
if not craftingState then
	craftingState = {
		isActive = false,
		duration = 0,
		itemName = "",
		elapsedTime = 0,
		initialHealth = 0,
		lastFxStep = -1,
		noTool = false,
		speed = 1,
		isVanillaOre = false,
	}
end

local fontSize = 18
local barWidth = 180
local barHeight = 16

local function f1dot(number)
	return string.format("%.1f",number+0.05)
end
local function f1(number)
	local formatted = string.format("%.1f", number)
	if formatted:sub(#formatted, #formatted) == "0" then
		-- Verwende math.modf oder tonumber um korrekt zu runden
		return tonumber(string.format("%.0f", number))
	end
	return formatted
end

function getColorByChance(chance)
    if chance < 0.7 then
        return util.color.rgb(1, chance/0.7, 0)  -- Rot zu Gelb
    else
		local red = 1 - (chance - 0.7) / 2       
		return util.color.rgb(math.max(0, red), 1, 0)  -- Gelb zu Grün
    end
end

-- Color functions
local function getColorFromGameSettings(colorTag)
	local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
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

local function mixColors(color1, color2, ratio)
	ratio = ratio or 0.5
	return util.color.rgb(
		color1.r * (1 - ratio) + color2.r * ratio,
		color1.g * (1 - ratio) + color2.g * ratio,
		color1.b * (1 - ratio) + color2.b * ratio
	)
end

local function darkenColor(color, mult)
	return util.color.rgb(color.r*mult, color.g*mult, color.b*mult)
end

-- Colors
local fontColor = getColorFromGameSettings("FontColor_color_normal_over")
local morrowindGold = getColorFromGameSettings("FontColor_color_normal")
local goldenMix =  mixColors(fontColor, morrowindGold)
local morrowindBlue = getColorFromGameSettings("fontColor_color_journal_link")
local morrowindBlue2 = getColorFromGameSettings("fontColor_color_journal_link_over")
local morrowindBlue3 = getColorFromGameSettings("fontColor_color_journal_link_pressed")
local progressColor = morrowindBlue

-- Root
hud_craftingProgress = ui.create({
	type = ui.TYPE.Container,
	layer = 'HUD',
	name = "hud_craftingProgress",
	props = {
		relativePosition = v2(0.5, 0.8),
		anchor = v2(0.5, 0.5),
		visible = false,
	},
	content = ui.content {}
})

-- Main flex
local mainFlex = {
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
	},
	content = ui.content {}
}
hud_craftingProgress.layout.content:add(mainFlex)

-- Header text
local itemNameText = {
	type = ui.TYPE.Text,
	name = "itemNameText",
	props = {
		text = "Crafting...",
		textColor = morrowindGold,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = fontSize,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = true,
	}
}
mainFlex.content:add(itemNameText)

-- Spacer
mainFlex.content:add{ props = { size = v2(1, 1) } }

-- Progress bar container
local progressContainer = {
	type = ui.TYPE.Widget,
	template = borderTemplate,
	props = {
		size = v2(barWidth + 4, barHeight + 4),
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
		--size = v2(15, barHeight),
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
		textColor = fontColor,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = fontSize - 4,
		textAlignH = ui.ALIGNMENT.End,
		textAlignV = ui.ALIGNMENT.Center,
		relativePosition = v2(1, 0.5),
		anchor = v2(1, 0.5),
		relativeSize = v2(1,1),
		autoSize = true,
	}
}
progressContainer.content:add(progressText)

-- onFrameFunction
local function updateCraftingProgress(dt)
	if not craftingState.isActive then
		return
	end
	
	-- Check if health dropped or player moved
	local currentHealth = types.Actor.stats.dynamic.health(self).current
	if currentHealth < craftingState.initialHealth then
		craftingState.isActive = false
		hud_craftingProgress.layout.props.visible = false
		hud_craftingProgress:update()
		return
	end
		
		
	
	craftingState.elapsedTime = craftingState.elapsedTime + dt
	craftingState.elapsedTime = math.min(craftingState.elapsedTime, craftingState.duration)
	
	
	local progress = craftingState.elapsedTime / craftingState.duration
	
	progressFill.props.relativeSize = v2(progress, 1)
	
	if not craftingState.noTool then
		progressText.props.text = f1(-(1-progress)*craftingState.duration) .. "s"
	end
	
	
	
	
	local targetFxCount = math.max(2, math.ceil(craftingState.duration / 0.7))
	local fxInterval = craftingState.duration / targetFxCount
	local currentFxStep = math.floor((craftingState.elapsedTime+0.001) / fxInterval)
	--print(targetFxCount, craftingState.duration, currentFxStep, craftingState.elapsedTime/ fxInterval)
	local res
	if currentFxStep > craftingState.lastFxStep then
		types.Actor.stats.dynamic.fatigue(self).current = math.max(0,types.Actor.stats.dynamic.fatigue(self).current - 4)
		local cameraPos = camera.getPosition()
		local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
		local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance();
		local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
		if (telekinesis) then
			activationDistance = activationDistance + (telekinesis.magnitude * 22);
		end
		activationDistance = activationDistance+0.1
		res = nearby.castRenderingRay(
			cameraPos,
			cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance,
			{ ignore = self }
		)
		
		if res.hitObject and res.hitObject == craftingState.target  then
			craftingState.lastFxStep = currentFxStep
			core.sendGlobalEvent('SpawnVfx', {model = "meshes/e/magic_hit_conjure.nif", position = res.hitPos-v3(0,0,20), options = {scale  = 0.3}})
			core.sendGlobalEvent('SimplyMining_setNodeSize', {craftingState.target, 1-currentFxStep*0.02*craftingState.speed})
			ambient.playSound("Heavy Armor Hit", {volume =playerSection:get("VOLUME")})
		else
			ambient.playSound("SwishL", {volume =playerSection:get("VOLUME")})
			craftingState.elapsedTime = math.max(0, craftingState.elapsedTime - fxInterval)
			if (self.position - craftingState.target.position):length() > 300 then
				craftingState.isActive = false
				hud_craftingProgress.layout.props.visible = false
				hud_craftingProgress:update()
				return
			end
		end
	
	end
	
	hud_craftingProgress:update()
	
	-- Check if completed
	if craftingState.elapsedTime >= craftingState.duration then
		if not res then
			local cameraPos = camera.getPosition()
			local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
			local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance();
			local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
			if (telekinesis) then
				activationDistance = activationDistance + (telekinesis.magnitude * 22);
			end
			activationDistance = activationDistance+0.1
			res = nearby.castRenderingRay(
				cameraPos,
				cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance,
				{ ignore = self }
			)
		end
		
		craftingState.isActive = false
		hud_craftingProgress.layout.props.visible = false
		hud_craftingProgress:update()
		core.sendGlobalEvent('SimplyMining_removeNode', craftingState.target)
		local item = nodeToItemLookup[craftingState.target.recordId]
		if item then
			local diffMod = 0.7+(db_difficulties[item] or 1)/70
			print("mined: +"..f1dot(diffMod*2.1).." exp")
			I.SkillProgression.skillUsed('armorer', {skillGain=diffMod*2.1, useType = I.SkillProgression.SKILL_USE_TYPES.Armorer_Repair, scale = nil})
			if item == "ingred_diamond_01" then
				core.sendGlobalEvent('SimplyMining_getItem', {self, item, calcChance(item), craftingState.target, craftingState.isVanillaOre, res.hitPos or craftingState.target.position})
			else
				core.sendGlobalEvent('SimplyMining_getItem', {self, item, calcChance(item)*2, craftingState.target, craftingState.isVanillaOre, res.hitPos or craftingState.target.position})
			end
		end
	end
end


if onFrameFunctions then
	table.insert(onFrameFunctions, updateCraftingProgress)
end


return function(data)
	local target = data[1]
	craftingState.isVanillaOre = data[2]
	if craftingState.isActive and target == craftingState.target or not target then
		return
	end
	
	local armorerSkill = types.NPC.stats.skills.armorer(self).modified
	local speed = 1+armorerSkill/100
	local pickMult = 0.55
	craftingState.noTool = true
	--local eq = types.Actor.getEquipment(self)
	if types.Player.inventory(self):find("T_De_Ebony_Pickaxe_01") then
		pickMult = 1.2
		craftingState.noTool = false
		--eq[16] = types.Player.inventory(self):find("T_De_Ebony_Pickaxe_01")
		--types.Actor.setEquipment(self, eq)
	elseif types.Player.inventory(self):find("BM Nordic Pick") then
		pickMult = 1.0
		craftingState.noTool = false
	elseif  types.Player.inventory(self):find("miner's pick") then
		pickMult = 0.9
		craftingState.noTool = false
	elseif types.Player.inventory(self):find("misc_de_muck_shovel_01") or types.Player.inventory(self):find("T_Com_FireplaceShovel_01") or types.Player.inventory(self):find("T_Com_Farm_Shovel_01") then
		pickMult = 0.75
		craftingState.noTool = false
	end
	
	craftingState.itemName = target.type.record(target).name or ""
	craftingState.target = target
	
	local color = fontColor
	local item = nodeToItemLookup[craftingState.target.recordId]
	local difficulty = 1
	if item then
		difficulty = db_difficulties[item] or difficulty
		local chance = calcChance(item)
		color = craftingState.isVanillaOre and morrowindGold or getColorByChance(chance)
		if item == "ingred_diamond_01" then
			chance = chance/2
		end
		craftingState.itemName = craftingState.itemName.." ("..(craftingState.isVanillaOre and 0.7 or f1(chance*2))..")"
	else
		return
	end
	local duration = 3.75
	if difficulty > armorerSkill then
		duration = duration + (difficulty-armorerSkill)/10
	else
		duration = math.max(1,duration - (armorerSkill-difficulty)/100)
	end
	if craftingState.isVanillaOre then
		duration = duration*0.66
	end
	--animation.playBlended(self, "weapontwohand", {startKey = "chop", loops =1, priority=1000, speed=0.5})
	--I.AnimationController.playBlendedAnimation('weapontwohand', { startkey = 'chop max attack', priority = {
    -- [animation.BONE_GROUP.RightArm] = animation.PRIORITY.Weapon,
    -- [animation.BONE_GROUP.LeftArm] = animation.PRIORITY.Weapon,
    -- [animation.BONE_GROUP.Torso] = animation.PRIORITY.Weapon,
    -- [animation.BONE_GROUP.LowerBody] = animation.PRIORITY.WeaponLowerBody
    -- } })
	--print(eq[18])-- shield
	speed = speed*pickMult
	craftingState.isActive = true
	craftingState.speed = speed
	craftingState.duration = duration/speed
	
	craftingState.elapsedTime = 0
	craftingState.initialHealth = types.Actor.stats.dynamic.health(self).current
	craftingState.lastFxStep = -1
	
	-- Berechne optimales FX-Interval
	local targetFxCount = math.ceil(craftingState.duration / 0.7)
	if targetFxCount < 1 then targetFxCount = 1 end
	craftingState.fxInterval = craftingState.duration / targetFxCount
	craftingState.totalFxCount = 0
	
	-- Show the UI
	hud_craftingProgress.layout.props.visible = true
	
	-- Update item name
	itemNameText.props.text = " " .. craftingState.itemName .. " "
	itemNameText.props.textColor = color
	
	-- Reset progress bar
	progressFill.props.size = v2(1, barHeight)
	if craftingState.noTool then
		progressText.props.text = "no appropiate tool "
	else
		progressText.props.text = "0%"
	end
	
	hud_craftingProgress:update()
end