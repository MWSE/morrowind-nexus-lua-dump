if  hud_castbar then
	hud_castbar:destroy()
	hud_castbar = nil
end


local makeBorder = require("scripts.hearthstone.ui_makeborder") 
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
hud_castbar = ui.create({
	type = ui.TYPE.Container,
	layer = 'HUD',
	name = "hud_castbar",
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
hud_castbar.layout.content:add(mainFlex)

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
function updateCastProgress(dt)
	if not craftingState.isActive then
		return
	end
	
	-- Check if health dropped or player moved
	local currentHealth = types.Actor.stats.dynamic.health(self).current
	if currentHealth < craftingState.initialHealth or (craftingState.initialPosition - self.position):length()> 10 then
		craftingState.isActive = false
		hud_castbar.layout.props.visible = false
		hud_castbar:update()
		castFailed()
		return
	end
	
	craftingState.elapsedTime = craftingState.elapsedTime + dt
	craftingState.elapsedTime = math.min(craftingState.elapsedTime, craftingState.duration)
	
	
	local progress = craftingState.elapsedTime / craftingState.duration
	
	progressFill.props.relativeSize = v2(progress, 1)
	
	progressText.props.text = f1(-(1-progress)*craftingState.duration) .. "s"

	local targetFxCount = math.max(2, math.ceil(craftingState.duration / 0.7))
	local fxInterval = craftingState.duration / targetFxCount
	local currentFxStep = math.floor((craftingState.elapsedTime+0.001) / fxInterval)
	--print(targetFxCount, craftingState.duration, currentFxStep, craftingState.elapsedTime/ fxInterval)
	local res
	if currentFxStep > craftingState.lastFxStep then
		types.Actor.stats.dynamic.magicka(self).current = math.max(0,types.Actor.stats.dynamic.magicka(self).current - 1)
		craftingState.lastFxStep = currentFxStep
		--core.sendGlobalEvent('SpawnVfx', {model = "meshes/e/magic_hit_conjure.nif", position = res.hitPos-v3(0,0,20), options = {scale  = 0.3}})
		--core.sendGlobalEvent('SimplyMining_setNodeSize', {craftingState.target, 1-currentFxStep*0.02*craftingState.speed})
		ambient.playSound("Alteration Hit", {volume =settingsSection:get("VOLUME") or 1} )
	end
	
	hud_castbar:update()
	
	-- Check if completed
	if craftingState.elapsedTime >= craftingState.duration then
		
		craftingState.isActive = false
		hud_castbar.layout.props.visible = false
		hud_castbar:update()
		castSuccessful()
	end
end


--if onFrameFunctions then
--	table.insert(onFrameFunctions, updateCastProgress)
--end


return function(data)
	if craftingState.isActive then
		return
	end
	
	
	local speed = 1
	
	craftingState.itemName = "Teleporting"
	craftingState.target = target
	
	local color = fontColor

	local duration = data.castTime or 7
	

	craftingState.isActive = true
	craftingState.speed = speed
	craftingState.duration = duration/speed
	
	craftingState.elapsedTime = 0
	craftingState.initialHealth = types.Actor.stats.dynamic.health(self).current
	craftingState.lastFxStep = -1
	craftingState.initialPosition = self.position
	
	-- Berechne optimales FX-Interval
	local targetFxCount = math.ceil(craftingState.duration / 0.7)
	if targetFxCount < 1 then targetFxCount = 1 end
	craftingState.fxInterval = craftingState.duration / targetFxCount
	craftingState.totalFxCount = 0
	
	-- Show the UI
	hud_castbar.layout.props.visible = true
	
	-- Update item name
	itemNameText.props.text = " " .. craftingState.itemName .. " "
	itemNameText.props.textColor = color
	
	-- Reset progress bar
	progressFill.props.size = v2(1, barHeight)

	progressText.props.text = "0%"
	
	hud_castbar:update()
end