-- weather transitions !!!!!
-- generated stews have warmthValue
-- cap cold warmthValue at 15°
-- add info text to stew showing warmth value + longlasting



-- icon size:
-- aspect ratio property? <-------------------------
-- or callback function?
-- estimate based on current aspect ratio?

-- update in mousewheel event?
-- or set G_iconSizeChanged = true? <----------------------


local wetnessWidgetPulsing = true
local wetnessWidgetLastSize = 0
local wetnessBarHorizontal = nil
local wetnessBarVertical = nil
local temperatureBar = nil
local temperatureBarTarget = nil
local temperatureBarArrow = nil
local temperatureBarSegments = nil
local lastbartargetsize, lastbarsize


function G_destroyTemperatureUis()
	wetnessBarHorizontal = nil
    wetnessBarVertical = nil
	temperatureBar = nil
	temperatureBarTarget = nil
	temperatureBarArrow = nil
	if temperatureBarSegments then
		temperatureBarSegments:destroy()
		temperatureBarSegments = nil
	end
	if G_rowWidgets.m_wetness then
		G_rowWidgets.m_wetness:destroy()
		G_rowWidgets.m_wetness = nil
	end
	if G_rowWidgets.m_temp then
		G_rowWidgets.m_temp:destroy()
		G_rowWidgets.m_temp = nil
	end
	if G_columnWidgets.m_tempThermometer then
		G_columnWidgets.m_tempThermometer:destroy()
		G_columnWidgets.m_tempThermometer = nil
	end
	if G_columnWidgets.m_tempText then
		G_columnWidgets.m_tempText:destroy()
		G_columnWidgets.m_tempText = nil
	end
	G_columnsNeedUpdate = true
	G_rowsNeedUpdate = true
	G_updateSDHUD()
	updateTemperatureWidget()
end
table.insert(G_destroyHudJobs, G_destroyTemperatureUis)

---------------------------------------------------------------------------------------------------------------------------------- DEBUG WIDGET ------------------------------------------------------------------------------------------------------------------------------------------------------
if TESTING_WIDGET then
	tempDbg2 	= require("scripts.SunsDusk.ui_debugWidget")("	=============== Temperature ===============")
	armorDbg2 =  require("scripts.SunsDusk.ui_debugWidget")("	===== Armor Equip =====")
	weatherDbg	= require("scripts.SunsDusk.ui_debugWidget")("	=============== Weather ===============")
end
tempDbg = {}
tempDbg.display = function(level,...)
	if level%10 <= TEMP_DEBUG_LEVEL then
		if level >= 10 then
			if tempDbg2 then
				tempDbg2.display(...)
			end
		end
		if TEMP_PRINT_CONSOLE and level < 20 then
			print(...)
		end
	end
end
tempDbg.p = function(level,...) 
	if (level%10) <= TEMP_DEBUG_LEVEL then
		if level >= 10 then
			for _, str in pairs({...}) do 
				G_temperatureWidgetTooltip = G_temperatureWidgetTooltip..str.." " 
			end 
			G_temperatureWidgetTooltip = G_temperatureWidgetTooltip.."\n" 
			if tempDbg2 then
				tempDbg2.p(level%10,...)
			end
		end
		if TEMP_PRINT_CONSOLE and level < 20 then
			print(...)
		end
	end
end
tempDbg.clear = function()
	if tempDbg2 then
		tempDbg2.clear()
	end
end
armorDbg = {}
armorDbg.display = function(level,...)
	if level%10 <= TEMP_DEBUG_LEVEL then
		if level >= 10 then
			if armorDbg2 then
				armorDbg2.display(...)
			end
		end
		if TEMP_PRINT_CONSOLE and level < 20 then
			print(...)
		end
	end
end
armorDbg.p = function(level,...)
	if level%10 <= TEMP_DEBUG_LEVEL then
		if level >= 10 then
			if armorDbg2 then
				armorDbg2.p(level%10,...)
			end
		end
		if TEMP_PRINT_CONSOLE and level < 20 then
			print(...)
		end
	end
end
armorDbg.clear = function()
	if armorDbg2 then
		armorDbg2.clear()
	end
end

---------------------------------------------------------------------------------------------------------------------------------- GRADIENT CROPPER ------------------------------------------------------------------------------------------------------------------------------------------------------
local cachedSegments = {}
local myAtlas = "textures/SunsDusk/gradient.png"

local function makeBarSegment(normalizedTemp, parentWidth, parentHeight)
	-- Check cache first
	local cacheKey = normalizedTemp .. "_" .. parentWidth .. "_" .. parentHeight
	if cachedSegments[cacheKey] then
		return cachedSegments[cacheKey]
	end
	
	local barWidth = 512
	local barHeight = 32
	local margin = 10
	local usableWidth = barWidth - (margin * 2)  -- 492
	local center = math.floor(margin + usableWidth / 2)  -- 256
	
	local scaleX = parentWidth / barWidth
	local scaleY = parentHeight / barHeight
	
	local segment, position, size
	local centerScaled = math.floor(center * scaleX)
	
	if normalizedTemp < 0.5 then
		-- Left side - grows from center to left margin
		local width = math.floor((0.5 - normalizedTemp) * usableWidth)
		local xPos = center - width
		
		segment = ui.texture {
			path = myAtlas,
			offset = v2(xPos, 0),
			size = v2(width, barHeight),
		}
		
		-- Calculate start position, size is difference to center
		local startX = math.floor(xPos * scaleX)
		position = v2(startX, 0)
		size = v2(centerScaled - startX, parentHeight)
	else
		-- Right side - grows from center to right margin
		local width = math.floor((normalizedTemp - 0.5) * usableWidth)
		local xPos = center
		
		segment = ui.texture {
			path = myAtlas,
			offset = v2(xPos, 0),
			size = v2(width, barHeight),
		}
		
		-- Start at center, size is scaled width
		position = v2(centerScaled, 0)
		size = v2(math.floor(width * scaleX), parentHeight)
	end
	
	-- Cache and return
	local result = {
		texture = segment,
		position = position,
		size = size
	}
	cachedSegments[cacheKey] = result
	return result
end

local cachedSegments2 = {}
local function makeBarSegment2(normalizedTemp, parentWidth, parentHeight)
	
	local barWidth = 512
	local barHeight = 32
	local margin = 20
	local marginTop = 7
	local marginBottom = 6
	local usableWidth = barWidth - (margin * 2)  -- 472
	local usableHeight = barHeight - marginTop - marginBottom
	local centerInTexture = margin + usableWidth / 2  -- 256
	
	
	local cacheKey = normalizedTemp .. "_" .. tostring(parentWidth) .. "_" .. tostring(parentHeight)
	
	if cachedSegments[cacheKey] then
		return cachedSegments[cacheKey]
	end
	
	if normalizedTemp == 1337 then
		local segment = ui.texture {
			path = myAtlas,
			offset = v2(margin, marginTop),
			size = v2(usableWidth, usableHeight),
		}
		cachedSegments[cacheKey] = segment
		return segment
	end
	local centerInParent = math.floor(parentWidth / 2)  -- Fixed center point
	local segment, position, size
	
	if normalizedTemp < 0.5 then
		-- Left side: 0 = full, 0.5 = empty
		local fillAmount = (0.5 - normalizedTemp) * 2  -- 0 to 1
		local textureWidth = fillAmount * (usableWidth / 2)
		local textureStart = centerInTexture - textureWidth
		
		segment = ui.texture {
			path = myAtlas,
			offset = v2(textureStart, marginTop),
			size = v2(textureWidth, usableHeight),
		}
		
		local renderWidth = fillAmount * centerInParent
		local renderStart = math.floor(centerInParent - renderWidth)
		
		position = v2(renderStart, 0)
		size = v2(centerInParent - renderStart, parentHeight)  -- Always ends at center
	else
		-- Right side: 0.5 = empty, 1 = full
		local fillAmount = (normalizedTemp - 0.5) * 2  -- 0 to 1
		local textureWidth = fillAmount * (usableWidth / 2)
		
		segment = ui.texture {
			path = myAtlas,
			offset = v2(centerInTexture, marginTop),
			size = v2(textureWidth, usableHeight),
		}
		
		local renderWidth = fillAmount * centerInParent
		
		position = v2(centerInParent, 0)
		size = v2(math.floor(renderWidth), parentHeight)
	end
	
	local result = {
		texture = segment,
		position = position,
		size = size
	}
	cachedSegments[cacheKey] = result
	return result
end

---------------------------------------------------------------------------------------------------------------------------------- SEGMENT MARKERS ------------------------------------------------------------------------------------------------------------------------------------------------------
-- Add this helper function near the top with your other functions
local function createTempMarker(temperature, minTemp, maxTemp, totalWidth, barHeight, borderOffset)
	-- Convert temperature to normalized value using the same range as the bar
	local tempRange = maxTemp - minTemp
	local normalizedTemp = math.min(1, math.max(0, (temperature - minTemp) / tempRange))
	
	-- Calculate relative position (0 to 1)
	local relativeX
	
	if normalizedTemp < 0.5 then
		-- Left side: map 0-0.5 to 0-0.5
		relativeX = normalizedTemp
	else
		-- Right side: map 0.5-1 to 0.5-1
		relativeX = normalizedTemp
	end
	
	return {
		type = ui.TYPE.Image,
		props = {
			resource = getTexture('textures/menu_thin_border_left.dds'),
			color = util.color.rgb(0.5, 0.5, 0.5),  -- Gray color
			size = v2(2, 0),
			relativeSize = v2(0.002, 1),
			relativePosition = v2(relativeX, 0),
			tileH = false,
			tileV = false,
			alpha = 0.5,
		}
	}
end

local function createStylizedTempMarker(temperature, minTemp, maxTemp, totalWidth, barHeight)
	-- Normalize temperature to 0-1 range
	local tempRange = maxTemp - minTemp
	local normalizedTemp = math.min(1, math.max(0, (temperature - minTemp) / tempRange))
	
	-- Account for 10px margins on 512px bar (margins at 0.0195 and 0.9805)
	local leftMargin = 10 / 512
	local rightMargin = 10 / 512
	local usableRange = 1 - leftMargin - rightMargin
	local center = 0.5
	
	local relativeX
	
	if normalizedTemp < 0.5 then
		-- Left side: interpolate between leftMargin and center
		local t = normalizedTemp * 2  -- 0 to 1 within left half
		relativeX = leftMargin + (center - leftMargin) * (1 - t)
	else
		-- Right side: interpolate between center and (1 - rightMargin)
		local t = (normalizedTemp - 0.5) * 2  -- 0 to 1 within right half
		relativeX = center + ((1 - rightMargin) - center) * t
	end
	
	return {
		type = ui.TYPE.Image,
		props = {
			resource = getTexture('white'),
			color = util.color.rgb(0.15, 0.15, 0.15),  -- Gray color
			size = v2(2, 0),
			relativeSize = v2(0.002, 0.85),
			relativePosition = v2(relativeX, 0.1),
			tileH = false,
			tileV = false,
			alpha = 1,
		}
	}
end

local borderFile = "thin"
local borderOffset = 1
local borderTemplates = {}
local borderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = makeBarSegment2(1337),
		color = util.color.rgb(0.08,0.08,0.08),
		relativeSize = v2(1,1),
		size = v2(0,-borderOffset*2),
		position = v2(0,borderOffset),
		alpha = 0.95,
	}
}).borders
---------------------------------------------------------------------------------------------------------------------------------- MAIN UPDATER ------------------------------------------------------------------------------------------------------------------------------------------------------
function updateTemperatureWidget()
	if not NEEDS_TEMP then return end
	--local TEMP_BAR_STYLE = "ownly"
	--local TEMP_BAR_STYLE = "stylized bar"
	--local TEMP_BAR_STYLE = "vanilla bar"
	--local TEMP_BAR_STYLE = "velothi"
	
	local function getTempAlpha() -- PLACEHOLDER; ADD ALPHA CALCULATION 
		return 1				  -- PLACEHOLDER; ADD ALPHA CALCULATION 
	end						   -- PLACEHOLDER; ADD ALPHA CALCULATION 
	
	if TEMPERATURE_WIDGET then
		if not G_columnWidgets.m_tempText then
			G_columnsNeedUpdate = true
			G_iconSizeChanged = true
		end
		local text = formatTemperatureShort(saveData.m_temp.currentTemp)..">"..formatTemperatureShort(saveData.m_temp.targetTemp)
		
		-- Initialize widget if it doesn't exist
		if not G_columnWidgets.m_tempText then
			G_columnWidgets.m_tempText = ui.create{
				name = "m_tempText",
				type = ui.TYPE.Widget,
				aspectRatio = 2.2,
				props = {
					size = v2(HUD_ICON_SIZE*2.2,HUD_ICON_SIZE),
				},
				order = "3needs-xtempText",
			}
			G_columnsNeedUpdate = true
		end
		
		-- Set the content
		G_columnWidgets.m_tempText.layout.content = ui.content {
			{
				name = 'text',
				type = ui.TYPE.Text,
				props = {
					text = text,
					textColor = TEMP_TEXT_COLOR,
					textShadow = true,
					textShadowColor = util.color.rgb(0,0,0),
					textSize = HUD_ICON_SIZE*0.65*math.min(1,1-(#text-8)/20),
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
					--position = v2(marginWidth,0),
					relativePosition = v2(0,0.5),
					anchor = v2(0,0.5),
					size = v2(HUD_ICON_SIZE*2.2,HUD_ICON_SIZE),
					autoSize = false,
					alpha = 1,
				},
			}
		}
		G_columnWidgets.m_tempText:update()
		
	end
	
	if TEMP_BAR_STYLE == "Thermometer" then
		--config
		local skinData = iconPacks.temp["Modern (Staged)"] 
		local racialThresholds = getRacialTemperatureThresholds()
		local minTemp = -11  -- Freezing/Cold boundary
		local maxTemp = racialThresholds.hotMin + 10  -- Hot/Scorching boundary
		local tempRange = (maxTemp - minTemp) / 0.95  -- Divide by 0.95 so maxTemp appears at 95%
		
		local normalizedValue = math.min(1, math.max(0, (saveData.m_temp.currentTemp - minTemp) / tempRange))
		local normalizedValueTarget = math.min(1, math.max(0, (saveData.m_temp.targetTemp - minTemp) / tempRange))
		
		if normalizedValueTarget < normalizedValue then
			normalizedValueTarget, normalizedValue = normalizedValue, normalizedValueTarget
		end
		--local normalizedValue = math.min(1,math.max(0,(saveData.m_temp.currentTemp + 10) / 60)) -- min -15 degrees, -15+60 = 45 degrees
		local severityScale = 0.8
		local relativePosition = v2(1-severityScale, (1-severityScale)/2)
		local TEMP_BACKGROUND = "Shadow"
		local arrow = nil
		local arrowScale = 1
		local arrowColor = util.color.rgb(0.5,0.5,0.5)
		local diff = (saveData.m_temp.targetTemp - saveData.m_temp.currentTemp) * G_temperatureRate

		if diff > 17 then
			arrow = "rising2"
			arrowColor = util.color.rgb(0.8,0.5,0.1)
		elseif diff > 7 then
			arrow = "rising1"
			arrowColor = util.color.rgb(0.6,0.5,0.1)
		elseif diff > 0 then
			arrow = "rising1"
			arrowColor = util.color.rgb(0.5,0.5,0)
			arrowScale = arrowScale * diff/7
		elseif diff < -17 then
			arrow = "falling2"
			arrowColor = util.color.rgb(0.5,0.5,1)
		elseif diff < -7 then
			arrow = "falling1"
			arrowColor = util.color.rgb(0.5,0.5,0.8)
		elseif diff < 0 then
			arrow = "falling1"
			arrowScale = arrowScale * (-diff)/7
			arrowColor = util.color.rgb(0.3,0.3,0.5)
		end

		local tempTexture
		local severityTextureTarget
		if skinData.stages > 1 then
			local displayedLevel = math.max(0, math.floor(normalizedValue * skinData.stages - 0.00001))
			severityTexture = getTexture(skinData.base.."temp_"..displayedLevel..skinData.extension)
			local displayedLevelTarget = math.max(0, math.floor(normalizedValueTarget * skinData.stages - 0.00001))
			severityTextureTarget = getTexture(skinData.base.."temp_"..displayedLevelTarget..skinData.extension)
		else
			severityTexture =  getTexture(skinData.base.."temp"..skinData.extension)
		end
		
		-- Initialize widget if it doesn't exist
		if not G_columnWidgets.m_tempThermometer then
			G_columnWidgets.m_tempThermometer = ui.create{
				name = "m_tempThermometer",
				type = ui.TYPE.Widget,
				aspectRatio = 1,
				props = {
					size = v2(HUD_ICON_SIZE,HUD_ICON_SIZE),
				},
				order = "5needs-temp",
			}
			G_columnsNeedUpdate = true
		end
		
		-- Set the content
		G_columnWidgets.m_tempThermometer.layout.content = ui.content {
			TEMP_BACKGROUND ~= "No Background" and { -- Damage Bar r.2.lag
				name = "temp_background",
				type = ui.TYPE.Image,
				props = {
					resource = TEMP_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or severityTexture,
					color = TEMP_BACKGROUND == "Classic" and TEMP_BACKGROUND_COLOR or util.color.rgb(0,0,0),
					tileH = false,
					tileV = false,
					position = v2(-HUD_ICON_SIZE/5,0),
					relativeSize  = v2(severityScale,severityScale),
					relativePosition = TEMP_BACKGROUND == "Shadow" and relativePosition+v2(0.04,0.027) or nil,
					alpha = TEMP_BACKGROUND == "Classic" and (HUD_ALPHA == "Static" and 1 or getWidgetAlpha(normalizedValue)^2) or 0.5,
				}
			} or {},
			severityTextureTarget and {
				name = "target_icon",
				type = ui.TYPE.Image,
				props = {
					resource = severityTextureTarget,
					color =  TEMP_COLOR,
					tileH = false,
					tileV = false,
					position = v2(-HUD_ICON_SIZE/5,0),
					relativeSize  = v2(severityScale,severityScale),
					relativePosition = relativePosition,
					alpha = (HUD_ALPHA == "Static" and 1 or getWidgetAlpha(normalizedValue))*0.2,
				}
			} or {},
			{
				name = "temp_icon",
				type = ui.TYPE.Image,
				props = {
					resource = severityTexture,
					color =  TEMP_COLOR,
					tileH = false,
					tileV = false,
					position = v2(-HUD_ICON_SIZE/5,0),
					relativeSize  = v2(severityScale,severityScale),
					relativePosition = relativePosition,
					alpha = HUD_ALPHA == "Static" and 1 or getWidgetAlpha(normalizedValue),
				}
			},
		}
		if arrow then
			G_columnWidgets.m_tempThermometer.layout.content:add{
				name = "temp_arrow",
				type = ui.TYPE.Image,
				props = {
					resource = getTexture(skinData.base..arrow..skinData.extension),
					color =  TEMP_COLOR,
					tileH = false,
					tileV = false,
					relativeSize  = v2(0.4*arrowScale,0.4*arrowScale),
					relativePosition = v2(0.4,0.5),
					anchor = v2(1,0.5),
					color = arrowColor,
					alpha = 0.5,
					alpha = HUD_ALPHA == "Static" and 1 or getWidgetAlpha(normalizedValue),
				}
			}
		end	
		if TEMP_WETNESS_BAR then
			local waterColor = util.color.hex("0a5e8f")
			if saveData.weatherInfo.isInRain then
				local currentTime = core.getRealTime()
				local pulseSpeed = 2 -- Adjust this value: higher = faster pulsing
				local intensity = math.max(0.2,math.sin(currentTime * pulseSpeed) + 1) / 2 -- Oscillates between 0 and 1
				wetnessWidgetPulsing = true
				waterColor = util.color.rgb(0.055 + (0.745 * intensity), 0.529 + (0.371 * intensity), 0.8 + (0.2 * intensity))
			else
				wetnessWidgetPulsing = false
			end
			wetnessBarVertical = {
				type = ui.TYPE.Image,
				props = {
					resource = getTexture('white'),
					color = waterColor, 
					--size = v2(5, 2),
					relativeSize = v2(0.15,saveData.m_temp.water.wetness*0.82),
					relativePosition = v2(0.8,0.91),
					position = v2(0,0),
					anchor = v2(0,1),
					--color = morrowindGold,
					--position = v2(markerPos, 0),
					tileH = true,
					tileV = false,
					alpha = 0.8,
				}
			}
			G_columnWidgets.m_tempThermometer.layout.content:add(wetnessBarVertical)
		end
		
		G_columnWidgets.m_tempThermometer:update()
		addTooltip(G_columnWidgets.m_tempThermometer.layout, G_temperatureWidgetTooltip)
		--local tooltipStr = math.floor(thirstData.thirst*100).."%\n"
		--if thirstData.longLastingDuration then
		--	tooltipStr = tooltipStr.."Well fed: "..formatTimeLeft(thirstData.longLastingDuration).."\n"
		--end
		--tooltipStr = tooltipStr..(tooltips[thirstData.currentThirstBuff] or "ERROR: "..tostring(thirstData.currentThirstBuff))
		--addTooltip(widget,tooltipStr)
	else
		---------------------------------------------------------- Bar: Calculate elements ----------------------------------------------------------
		local totalWidth = 0
		local barHeight = 0
		local thicknessMult = 0.1
		local minThicknessByIconSize = 0.4
		
		
		if G_rowWidgets.m_temp then
			totalWidth = G_rowWidgets.m_temp.layout.props.size.x
			barHeight = G_rowWidgets.m_temp.layout.props.size.y
		else
			for widget_index, widget in pairs(G_columnWidgets) do
				--for widget_index, widget in pairs(module_widgets) do
	
					if widget.props and widget.props.size then
						totalWidth = totalWidth + widget.props.size.x
					elseif widget.layout and widget.layout.props and widget.layout.props.size then
						totalWidth = totalWidth + widget.layout.props.size.x
					end
				--end
			end
			barHeight = math.floor(math.max(HUD_ICON_SIZE*minThicknessByIconSize, totalWidth*thicknessMult))--+borderOffset

		end
		-- Replace the normalization calculation with dynamic range
		local racialThresholds = getRacialTemperatureThresholds()
		local minTemp = -10  -- Freezing/Cold boundary
		local maxTemp = racialThresholds.hotMin + 10  -- Hot/Scorching boundary
		local tempRange = maxTemp - minTemp
		
		local normalizedValue = math.min(1, math.max(0, (saveData.m_temp.currentTemp - minTemp) / tempRange))
		local normalizedValueTarget = math.min(1, math.max(0, (saveData.m_temp.targetTemp - minTemp) / tempRange))
		
		
		
		--if not stackedWidgets.temp then
		--local normalizedValue = math.min(1,math.max(0,(saveData.m_temp.currentTemp + 10) / 55))
		--local normalizedValueTarget = math.min(1,math.max(0,(saveData.m_temp.targetTemp + 10) / 55))
		local bartarget
		local bar
		if TEMP_BAR_STYLE == "Stylized Bar" then
			bartarget = makeBarSegment(normalizedValueTarget, totalWidth, barHeight)
			bar = makeBarSegment(normalizedValue, totalWidth, barHeight)
		else
			bartarget = makeBarSegment2(normalizedValueTarget, totalWidth, barHeight-borderOffset*2)
			bar = makeBarSegment2(normalizedValue, totalWidth, barHeight-borderOffset*2)
		end
		-- bar.texture - the ui.texture
		-- bar.relativePosition - normalized position (0-1) as v2
		-- bar.relativeSize - normalized size (0-1) as v2
		local arrowPosition, arrowAnchor, arrow
		local arrowSize = 0
		local tempDiff = math.abs(saveData.m_temp.targetTemp - saveData.m_temp.currentTemp) * G_temperatureRate
		if tempDiff > 1 then
			arrowSize = math.min(barHeight*0.7,3+math.floor(tempDiff/30 * HUD_ICON_SIZE))
			if normalizedValue < 0.5 then
				-- Left side: position at left edge, anchor right
				arrowPosition = v2(math.max(arrowSize,bar.position.x), math.floor(barHeight/ 2) + 1) 
				arrowAnchor = v2(1, 0.5)
			else
				-- Right side: position at right edge, anchor left
				arrowPosition = v2(math.min(totalWidth-arrowSize,bar.position.x + bar.size.x), math.floor(barHeight/ 2) + 1) 
				arrowAnchor = v2(0, 0.5)
			end
			if saveData.m_temp.targetTemp > saveData.m_temp.currentTemp then
				arrow = "arrowRight"
				arrowColor = util.color.rgb(0.8,0.5,0.1)
			else
				arrow = "arrowLeft"
				arrowColor = util.color.rgb(0.5,0.5,1)
			end
			if tempDiff > 10 then
				arrow = arrow.."2"
				tempDiff = tempDiff/2
			end
			if TEMP_BAR_STYLE ~= "Stylized Bar" then
				arrowPosition = arrowPosition - v2(0,borderOffset+1)
			end
		end
		--local sameSide = (normalizedValue < 0.5) == (normalizedValueTarget < 0.5)
		--if sameSide and math.abs(normalizedValueTarget - 0.5) < math.abs(normalizedValue - 0.5) then
		--	bar, bartarget = bartarget, bar
		--end
		
		local sameSide = (normalizedValue < 0.5) == (normalizedValueTarget < 0.5)

		if sameSide then
			local targetCloser = math.abs(normalizedValueTarget - 0.5) < math.abs(normalizedValue - 0.5)
		
			-- Always swap when on same side
			bar, bartarget = bartarget, bar
		
			if targetCloser then
				-- target is closer to mid → target strong, bar weak
				bar.alpha = 1.0
				bartarget.alpha       = 0.4
			else
				-- target farther → target weak, bar strong
				bar.alpha = 0.4
				bartarget.alpha       = 1.0
			end
		else
			-- different sides → both weak
			bar.alpha       = 0.4
			bartarget.alpha = 0.4
		end
		
		---------------------------------------------------------- Initialize Bar ----------------------------------------------------------
		if not G_rowWidgets.m_temp then
			temperatureBar = {
						name = "gradient",
						type = ui.TYPE.Image,
						props = {
							resource = bar.texture,
							tileH = false,
							tileV = false,
							size  = bar.size,
							position = bar.position,
							alpha = bar.alpha,
						}
					}
			temperatureBarTarget = {
						name = "gradienttarget",
						type = ui.TYPE.Image,
						props = {
							resource = bartarget.texture,
							tileH = false,
							tileV = false,
							size  = bartarget.size,
							position = bartarget.position,
							alpha = bartarget.alpha,
						}
					}
			temperatureBarArrow = {
					name = 'arrow',
					type = ui.TYPE.Image,
					props = {
						resource = getTexture("textures/SunsDusk/"..(arrow or "arrowLeft")..".png"),
						color = arrowColor,
						size = v2(arrowSize,arrowSize),
						position = arrowPosition,
						anchor = arrowAnchor,
						tileH = false,
						tileV = false,
					},
				}
			
			local thresholdTemps = {
					---10,  -- Freezing/Cold
					5,    -- Cold/Chilly
					racialThresholds.comfortableMin,  -- Chilly/Comfortable
					racialThresholds.comfortableMax,  -- Comfortable/Warm
					racialThresholds.warmMax,         -- Warm/Hot
					--racialThresholds.hotMin + 10,     -- Hot/Scorching
				}
			--for a,b in pairs(thresholdTemps) do
			--print(a,b)
			--end
			if TEMP_SEGMENTS then
				
				temperatureBarSegments = ui.create{
					name = "barSegments",
					type = ui.TYPE.Widget,
					--template = TEMP_BAR_STYLE ~= "Stylized Bar" and borderTemplate or nil,
					props = {
						--size = v2(totalWidth, barHeight),
						relativeSize = v2(1,1),
					},
					order = "zzzneeds-temp",
					content = ui.content {}
				}
				for _, temp in ipairs(thresholdTemps) do
					if TEMP_BAR_STYLE == "Stylized Bar" then
						temperatureBarSegments.layout.content:add(createStylizedTempMarker(temp, minTemp, maxTemp, totalWidth, barHeight))
					else
						temperatureBarSegments.layout.content:add(createTempMarker(temp, minTemp, maxTemp, totalWidth, barHeight, borderOffset))
					end
				end
				temperatureBarSegments:update()
			else
				temperatureBarSegments = nil
			end

			
			G_rowWidgets.m_temp = ui.create{
				name = "m_temp",
				type = ui.TYPE.Widget,
				template = TEMP_BAR_STYLE ~= "Stylized Bar" and borderTemplate or nil,
				thicknessMult = thicknessMult,
				minThicknessByIconSize = minThicknessByIconSize,
				props = {
					size = v2(totalWidth, barHeight),
				},
				order = "zzzneeds-temp",
				content = ui.content {
					TEMP_BAR_STYLE == "Stylized Bar" and {
						name = "bg",
						type = ui.TYPE.Image,
						props = {
							resource = getTexture("textures/SunsDusk/background.png"),
							tileH = false,
							tileV = false,
							relativeSize  = v2(1,1),
							alpha = 1,
						}
					} or {},
					temperatureBarTarget,
					temperatureBar,
					temperatureBarSegments or {},
					temperatureBarArrow,
				}
			}
		end
		---------------------------------------------------------- Update Bar ----------------------------------------------------------
		if arrow then
			temperatureBarArrow.props.resource = getTexture("textures/SunsDusk/"..arrow..".png")
			temperatureBarArrow.props.color = arrowColor
			temperatureBarArrow.props.size = v2(arrowSize,arrowSize)
			temperatureBarArrow.props.position = arrowPosition
			temperatureBarArrow.props.anchor = arrowAnchor
			temperatureBarArrow.props.alpha = 1
		else
			temperatureBarArrow.props.alpha = 0
		end
		
		temperatureBar.props.resource = bar.texture
		temperatureBar.props.size  = bar.size
		temperatureBar.props.position = bar.position
		temperatureBar.props.alpha = bar.alpha
		
		temperatureBarTarget.props.resource = bartarget.texture
		temperatureBarTarget.props.size  = bartarget.size
		temperatureBarTarget.props.position = bartarget.position
		temperatureBarTarget.props.alpha = bartarget.alpha
		--print(bartarget.position, bartarget.size)
		--if lastbartargetsize ~=bartarget.size or lastbarsize ~=bar.size then
		--	lastbartargetsize =bartarget.size 
		--	lastbarsize =bar.size
			G_rowWidgets.m_temp:update()
		--	print("upd temp", bartarget.size, bar.size)
		--end
		---------------------------------------------------------- Wetness Bar ----------------------------------------------------------
		if TEMP_WETNESS_BAR then
			
			-- Initialize widget if it doesn't exist
			if not G_rowWidgets.m_wetness then
				wetnessBarHorizontal = {
					type = ui.TYPE.Image,
					props = {
						resource = getTexture('white'),
						color = util.color.hex("0a5e8f"), 
						--size = v2(0, 2),
						relativeSize = v2(saveData.m_temp.water.wetness * (TEMP_BAR_STYLE == "Stylized Bar" and 0.93 or 1),1),
						relativePosition = v2(0.5,0),
						position = v2(0,0),
						anchor = v2(0.5,0),
						--color = morrowindGold,
						--position = v2(markerPos, 0),
						tileH = true,
						tileV = false,
						alpha = 1,
					}
				}
				G_rowWidgets.m_wetness = ui.create{
					name = "m_wetness",
					type = ui.TYPE.Widget,
					--template = TEMP_BAR_STYLE ~= "Stylized Bar" and borderTemplate or nil,
					thicknessMult = 0.02,
					minThicknessByIconSize = 0.1,
					props = {
						size = v2(0, 0),
					},
					order = "zzzneeds-wetness",
					content = ui.content {
						wetnessBarHorizontal
					}
				}
				G_rowWidgets.m_wetness:update()
				wetnessWidgetLastSize = saveData.m_temp.water.wetness
				G_rowsNeedUpdate = true
			end
			local shouldUpdate = false
			if G_wetnessChange > 0 then
				--local currentTime = core.getRealTime()
				--local pulseSpeed = 2 -- Adjust this value: higher = faster pulsing
				--local intensity = math.max(0.2,math.sin(currentTime * pulseSpeed) + 1) / 2 -- Oscillates between 0 and 1
				--
				--wetnessBarHorizontal.props.color = util.color.rgb(0.055 + (0.745 * intensity), 0.529 + (0.371 * intensity), 0.8 + (0.2 * intensity))
				wetnessWidgetPulsing = true
				--shouldUpdate = true
			elseif wetnessWidgetPulsing then
				wetnessBarHorizontal.props.color = util.color.hex("0a5e8f")
				wetnessWidgetPulsing = false
				shouldUpdate = true
			end
			if math.abs(wetnessWidgetLastSize - saveData.m_temp.water.wetness) > 0.01 then
				wetnessWidgetLastSize = saveData.m_temp.water.wetness
				if TEMP_BAR_STYLE == "Stylized Bar" then
					wetnessBarHorizontal.props.relativeSize = v2(wetnessWidgetLastSize*0.93,1)
				else
					wetnessBarHorizontal.props.relativeSize = v2(wetnessWidgetLastSize,1)
				end
				shouldUpdate = true
			end
			if shouldUpdate then
				G_rowWidgets.m_wetness:update()
			end
		end
		addTooltip(G_rowWidgets.m_temp.layout, G_temperatureWidgetTooltip)
	end
end

local function pulsateWetnessWidget()
	if wetnessWidgetPulsing then
		local currentTime = core.getRealTime()
		local pulseSpeed = 2 -- Adjust this value: higher = faster pulsing
		local intensity = math.max(0.2,math.sin(currentTime * pulseSpeed) + 1) / 2 -- Oscillates between 0 and 1
		if wetnessBarHorizontal then
			wetnessBarHorizontal.props.color = util.color.rgb(0.055 + (0.745 * intensity), 0.529 + (0.371 * intensity), 0.8 + (0.2 * intensity))	
			G_rowWidgets.m_wetness:update()
		elseif wetnessBarVertical then
			wetnessBarVertical.props.color = util.color.rgb(0.055 + (0.745 * intensity), 0.529 + (0.371 * intensity), 0.8 + (0.2 * intensity))	
			G_columnWidgets.m_tempThermometer:update()
		
		else
			wetnessWidgetPulsing = false
		end
	end
end
table.insert(G_onFrameJobs, pulsateWetnessWidget)


table.insert(G_refreshWidgetJobs, updateTemperatureWidget)

---------------------------------------------------------------------------------------------------------------------------------- PULSATING WATER ------------------------------------------------------------------------------------------------------------------------------------------------------