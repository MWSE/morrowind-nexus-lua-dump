local thirstData

-- Widget element references (created once, updated as needed)
local thirstIcon = nil
local thirstBackground = nil
local thirstWidget = nil

-- State tracking for conditional updates
local lastThirstLevel = nil
local lastThirstValue = nil
local lastTooltipStr = nil
local lastAlpha = nil
local lastIconSize = nil

local function buildSeveritySuffix()
	local suffix = ""
	if saveData.countCompanions >= 1 and NEEDS_THIRST_COMPANION then
		suffix = "_c"
	end
	if NEEDS_SEVERITY_THIRST == "Hard" then
		suffix = "_2"
	end
	if NEEDS_SEVERITY_THIRST == "Hardcore" then
		suffix = "_3"
	end
	return suffix
end

-- race + environment tuning
local ARGONIAN_RAIN_RESTORE_PER_MIN   = 0.002   -- ~0.12 per hour of rain
local ARGONIAN_SWIM_RESTORE_PER_MIN   = 0.006   -- ~0.36 per hour while in water

-- Argonian passive thirst restore remains the same in module_thirst_minute():
-- if NEEDS_RACES_THIRST and saveData.playerInfo.isFarmingTool then
--   if isRaining() then restore += ARGONIAN_RAIN_RESTORE_PER_MIN * minutesPassed end
--   if isPlayerInWater() then restore += ARGONIAN_SWIM_RESTORE_PER_MIN * minutesPassed end
-- end

-- == suppressing logs from this mod ==

local function removeBuffs()
	if not thirstData then return end
	if thirstData.currentThirstBuff then
		local buff = thirstData.currentThirstBuff
		if core.magic.spells.records[buff] then
			typesActorSpellsSelf:remove(buff)
		else
			log(2, "[SunsDusk] Skipping removal of missing spell:", buff)
		end
		thirstData.currentThirstBuff = nil
	end
end
table.insert(G_removeAbilitiesJobs, removeBuffs)

-- Destroy UI elements (for cleanup/reset)
function G_destroyThirstUi()
	thirstIcon = nil
	thirstBackground = nil
	if thirstWidget then
		thirstWidget:destroy()
		thirstWidget = nil
	end
	if G_columnWidgets and G_columnWidgets.m_thirst then
		G_columnWidgets.m_thirst:destroy()
		G_columnWidgets.m_thirst = nil
	end
	lastThirstLevel = nil
	lastThirstValue = nil
	lastAlpha = nil
	lastIconSize = nil
	G_columnsNeedUpdate = true
end
table.insert(G_destroyHudJobs, G_destroyThirstUi)

local function updateWidget()
	if not NEEDS_THIRST then return end

	-- Calculate current values
	local skinData = G_iconPacks.thirst[T_SKIN]
	local currentThirstLevel = math.max(0, math.floor(thirstData.thirst * skinData.stages - 0.00001))
	local currentAlpha = HUD_ALPHA == "Static" and 1 or getWidgetAlpha(thirstData.thirst)
	local bgAlpha = T_BACKGROUND == "Classic" and (HUD_ALPHA == "Static" and 1 or currentAlpha^2) or 0.5
	
	-- Determine texture
	local thirstTexture
	if skinData.stages > 1 then
		thirstTexture = getTexture(skinData.base.."thirst_"..currentThirstLevel..skinData.extension)
	else
		thirstTexture = getTexture(skinData.base.."thirst"..skinData.extension)
	end
	
	-- Initialize widget if it doesn't exist
	if not thirstWidget then
		-- Create sub-elements
		thirstBackground = T_BACKGROUND ~= "No Background" and {
			name = "thirst_background",
			type = ui.TYPE.Image,
			props = {
				resource = T_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or thirstTexture,
				color = T_BACKGROUND == "Classic" and T_BACKGROUND_COLOR or util.color.rgb(0,0,0),
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				relativePosition = T_BACKGROUND == "Shadow" and v2(0.04,0.027) or nil,
				alpha = bgAlpha,
			}
		} or {}
		
		thirstIcon = {
			name = "thirst_icon",
			type = ui.TYPE.Image,
			props = {
				resource = thirstTexture,
				color = T_COLOR,
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				alpha = currentAlpha,
			}
		}
		
		-- Create main widget
		thirstWidget = ui.create{
			name = "m_thirst",
			type = ui.TYPE.Widget,
			props = {
				size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE),
			},
			userData = {
				order = "needs-thirst",
			},
			content = ui.content {
				thirstBackground,
				thirstIcon,
			}
		}
		
		-- Store in G_columnWidgets
		if not G_columnWidgets then
			G_columnWidgets = {}
		end
		G_columnWidgets.m_thirst = thirstWidget
		
		-- Initialize tracking variables
		lastThirstLevel = currentThirstLevel
		lastThirstValue = thirstData.thirst
		lastAlpha = currentAlpha
		lastIconSize = HUD_ICON_SIZE
		
		G_columnsNeedUpdate = true
	end
	
	-- Check if we need to update
	local needsUpdate = false
	
	-- Update widget size if icon size changed
	if lastIconSize ~= HUD_ICON_SIZE then
		thirstWidget.layout.props.size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE)
		lastIconSize = HUD_ICON_SIZE
		needsUpdate = true
		G_columnsNeedUpdate = true
	end
	
	-- Update icon texture if thirst level changed
	if lastThirstLevel ~= currentThirstLevel then
		thirstIcon.props.resource = thirstTexture
		lastThirstLevel = currentThirstLevel
		needsUpdate = true
		
		-- Update background texture if not using Classic style
		if T_BACKGROUND ~= "No Background" and T_BACKGROUND ~= "Classic" and thirstBackground then
			thirstBackground.props.resource = thirstTexture
		end
	end
	
	-- Update alpha if it changed
	if lastAlpha ~= currentAlpha then
		thirstIcon.props.alpha = currentAlpha
		lastAlpha = currentAlpha
		needsUpdate = true
		
		-- Update background alpha if using Classic style
		if T_BACKGROUND == "Classic" and thirstBackground then
			thirstBackground.props.alpha = HUD_ALPHA == "Static" and 1 or currentAlpha^2
		end
	end
	
	local tooltipStr = math.floor(thirstData.thirst*100).."%\n"
	if thirstData.longLastingDuration then
		tooltipStr = tooltipStr.."Well fed: "..formatTimeLeft(thirstData.longLastingDuration).."\n"
	end
	tooltipStr = tooltipStr..(not thirstData.currentThirstBuff and "Loading..." or tooltips[thirstData.currentThirstBuff] or "Error: "..tostring(thirstData.currentThirstBuff))
	if lastTooltipStr ~= tooltipStr then
		lastTooltipStr = tooltipStr
		addTooltip(thirstWidget.layout, tooltipStr)
		needsUpdate = true
	end
	
	-- Only call update if something actually changed
	if needsUpdate then
		thirstWidget:update()
	end
end

table.insert(G_refreshWidgetJobs, updateWidget)

function module_thirst_minute(clockHour, minute, minutesPassed)
	if not NEEDS_THIRST then return end

	local baseStep = (G_isLongTravel and 0 or (G_isSleeping or G_isTravelling) and 0.6 or 1) / HOURS_PER_THIRST_STATE / 6 / 60
	local raceConsumptionMult = 1
	
	if NEEDS_RACES_THIRST then
		-- consumption
		if saveData.playerInfo.isDunmer then raceConsumptionMult = 0.8 end
		if saveData.playerInfo.isRedguard or saveData.playerInfo.isFarmingTool then raceConsumptionMult = 0.7 end
		if saveData.playerInfo.isAltmer then raceConsumptionMult = 1.2 end
		--restoration
		if saveData.playerInfo.isFarmingTool then
			local restore = 0
			if saveData.weatherInfo.isInRain then
				restore = restore + ARGONIAN_RAIN_RESTORE_PER_MIN * minutesPassed
			end
			if G_isInWater > 0 then
				restore = restore + ARGONIAN_SWIM_RESTORE_PER_MIN * minutesPassed * G_isInWater
			end
			if restore > 0 then
				thirstData.thirst = math.max(0, thirstData.thirst - restore)
			end
		end
	end
	if G_isInJail then
		thirstData.thirst = 0.5
	else
		if thirstData.longLastingDuration and minutesPassed > 0 then
			local availableDuration = math.min(thirstData.longLastingDuration, minutesPassed)
			local restored = availableDuration * thirstData.longLastingMagnitude
			thirstData.thirst = math.max(0, thirstData.thirst - restored)
			thirstData.longLastingDuration = thirstData.longLastingDuration - availableDuration
			if thirstData.longLastingDuration <= 0 then
				thirstData.longLastingDuration = nil
			end
		end
		thirstData.thirst = math.min(1, thirstData.thirst + baseStep * minutesPassed * raceConsumptionMult)
	end
	--if NEEDS_THIRST_BUFFS then -- prevent thirst from going above 0.5 (thirstLevel 3 starts at 0.5 or so)
	--	thirstData.thirst = math.min(1-3/6-0.0001, thirstData.thirst)
	--end
	
	local suffix = buildSeveritySuffix()
	thirstData.thirstLevel = math.max(0, math.floor(thirstData.thirst * 6 - 0.00001))
	-- remove severitiy suffixes (_2 and _3) for positive buffs (level 0-2)
	-- note: no companion buffs on hardcore
	if thirstData.thirstLevel <= 3 and (suffix == "_2" or suffix == "_3") then
		suffix = ""
	end

	-- compute desired thirst buff
	local newThirstBuff = nil
	if NEEDS_THIRST_BUFFS_DEBUFFS == "Only buffs" and thirstData.thirstLevel <= 2
	or NEEDS_THIRST_BUFFS_DEBUFFS == "Only debuffs" and thirstData.thirstLevel >= 3
	or NEEDS_THIRST_BUFFS_DEBUFFS == "Buffs and debuffs" then
		newThirstBuff = "sd_thirst_" .. thirstData.thirstLevel .. suffix
	end

	-- diff-apply thirst buff
	if newThirstBuff ~= thirstData.currentThirstBuff then
		local oldBuff = thirstData.currentThirstBuff
		if oldBuff and core.magic.spells.records[oldBuff] then
			typesActorSpellsSelf:remove(oldBuff)
		end
		thirstData.currentThirstBuff = nil
		if newThirstBuff and not G_preventAddingAnyBuffs then
			typesActorSpellsSelf:add(newThirstBuff)
			thirstData.currentThirstBuff = newThirstBuff
			log(3, "[SunsDusk:Thirst] Applied thirst buff:", newThirstBuff)
		end
	end
	
	if DEATH_BY_DEHYDRATION and not G_isTravelling and not G_isInJail then
		local volume = (thirstData.thirst-0.95)*20
		if volume > 0 then
			G_heartbeatFlags.thirst = volume
			G_vignetteFlags.thirst = 0.6*volume
			
			if thirstData.thirst >=0.99 then
				G_vignetteColorFlags.thirst = "default"
				if not debug.isGodMode() then
					typesPlayerStatsSelf.health.current = typesPlayerStatsSelf.health.current - math.min(7, 0.5 * minutesPassed)
				end
				G_flashVignette = 0.7
			end
		else
			G_heartbeatFlags.thirst = nil
			G_vignetteFlags.thirst  = nil
			G_vignetteColorFlags.thirst = nil
		end
	else
		G_heartbeatFlags.thirst = nil
		G_vignetteFlags.thirst  = nil
		G_vignetteColorFlags.thirst = nil
	end
	updateWidget()
end

table.insert(G_perMinuteJobs, module_thirst_minute)

-- force buff/widget refresh; ignores call when needId is set and not "thirst"
local function refreshNeeds(needId)
	if needId and needId ~= "thirst" then return end
	if not NEEDS_THIRST or not thirstData then return end
	module_thirst_minute(nil, nil, 0)
end
table.insert(G_refreshNeedsJobs, refreshNeeds)

local function onLoad(originalData)
	if not NEEDS_THIRST then return end
	if not saveData.m_thirst then
		saveData.m_thirst = {
			thirst = (1/6),
		}
	end
	thirstData = saveData.m_thirst
	-- migration:
	if not thirstData.thirstLevel then
		thirstData.thirstLevel = 1
	end	
end

table.insert(G_onLoadJobs, onLoad)

table.insert(G_onLoadJobs, updateWidget) --after all onload jobs, also update widget

local function settingsChanged(sectionName, setting, oldValue)
	if setting == "NEEDS_THIRST" then
		if oldValue == false then
			onLoad()
		else
			removeBuffs()
			saveData.m_thirst = nil
			G_destroyThirstUi()
			G_heartbeatFlags.thirst = nil
			G_vignetteFlags.thirst  = nil
			G_vignetteColorFlags.thirst = nil
		end
	elseif setting == "T_BACKGROUND" then
		G_destroyThirstUi()
	end
end
table.insert(G_settingsChangedJobs, settingsChanged)

local function removeRandomConsumableBuff(consumableName)
	local luck = typesPlayerStatsSelf.luck.modified
	local removedId
	for _, s in pairs(typesActorActiveSpellsSelf) do
		local name = (s.name or ""):lower()
		if name == consumableName:lower() then
			removedId = s.id
			typesActorActiveSpellsSelf:remove(s.activeSpellId)
			break
		end
	end
	local ret = true
	if removedId then
		local effects = {0}
		local buffName = "Dirty Water"
		if math.random() < 0.25 + typesPlayerStatsSelf.luck.modified/150 then
			effects = {1}
			buffName = "Lucky Water"
		else
			ret = false
		end
		typesActorActiveSpellsSelf:add({
			id = removedId,
			effects = effects,
			ignoreResistances = true,
			ignoreSpellAbsorption = true,
			ignoreReflect = true,
			name = buffName,
		})
	end
	-- true = don't nullify drink value
	return ret
end

-- --- water consumption: Bosmer +20% water restore when enabled ---

function G_getDrinkValue(item)
	
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	if not NEEDS_THIRST then return 0, nil, nil, not entry end
	local drinkValue
	local longLastingMagnitude
	local longLastingDuration
	local shouldSendDowngradeEvent = false
	local isVampire = saveData.playerInfo.isVampire > 0
	
	if entry and entry.drinkValue and entry.drinkValue ~= 0 then
		drinkValue = entry.drinkValue

		-- Alcohol penalty
		if NEEDS_THIRST_ALCOHOL_R and entry.consumeCategory == "alcohol" then
			drinkValue = drinkValue * -0.5
		end
		
		-- Apply drink value multiplier for positive values
		if drinkValue > 0 then
			drinkValue = drinkValue * DRINKVALUE_MULT
		end
		
		-- Bosmer racial bonus
		if NEEDS_RACES_THIRST and saveData.playerInfo.isBosmer then
			if entry.consumeCategory == "water" or item.type.record(item).name:lower():find("water") then
				drinkValue = drinkValue * 1.2
			end
		end
		
		-- Vampire penalty
		if isVampire and NEEDS_THIRST_VW == "Immortal" and not item.recordId:find("blood") and not item.type.record(item).name:find("blood") then
			drinkValue = drinkValue * 0.1
		end
		
		-- Long-lasting effects
		if entry.drinkValue2 and entry.drinkValue2 > 0 then
			longLastingMagnitude = drinkValue/entry.drinkValue*entry.drinkValue2/360*DRINKVALUE_MULT
			longLastingDuration = 360
		end
		
	elseif types.Potion.objectIsInstance(item) then
		drinkValue = 0.2
		
		-- Vampire penalty for non-blood potions
		if isVampire and NEEDS_THIRST_VW == "Immortal" and not item.recordId:find("blood") and not item.type.record(item).name:find("blood") then
			drinkValue = drinkValue * 0.1
		end
		
		local lowerName = item.type.record(item).name:lower()
		
		-- Special water types
		if lowerName:sub(-8,-1) == "l water)" then
			drinkValue = nil
		end
		if lowerName:sub(-12,-1) == "l saltwater)" then
			drinkValue = -0.2
		end
		if lowerName:sub(-19,-1) == "l suspicious water)" then
			if not removeRandomConsumableBuff(item.type.record(item).name) then
				drinkValue = nil
			end
		end
		if drinkValue then
			-- Alcohol penalties
			if NEEDS_THIRST_ALCOHOL_R then
				if lowerName:find("sujamma") or lowerName:find("flin") or lowerName:find("mazte") or 
				lowerName:find("shein") or lowerName:find("greef") then
					drinkValue = drinkValue * -0.5
				end
			end
			
			-- Stoneflower tea tiredness reduction
			if lowerName:find("stoneflower tea") and saveData.m_sleep then
				saveData.m_sleep.tiredness = math.max(0, saveData.m_sleep.tiredness - 0.02)
			end
			
			-- Apply drink value multiplier for positive values
			if drinkValue > 0 then
				drinkValue = drinkValue * DRINKVALUE_MULT
			end
		end
		shouldSendDowngradeEvent = true
	end
	
	return drinkValue, longLastingMagnitude, longLastingDuration, shouldSendDowngradeEvent
end

local function onConsume(item)
	local drinkValue, longLastingMagnitude, longLastingDuration, shouldSendDowngradeEvent = G_getDrinkValue(item)
	
	if thirstData and drinkValue then
		thirstData.thirst = math.min(1, math.max(0, thirstData.thirst - drinkValue))
		
		if longLastingDuration then
			thirstData.longLastingMagnitude = longLastingMagnitude
			thirstData.longLastingDuration = longLastingDuration
		end

		module_thirst_minute(nil, nil, 0)
	end
	if shouldSendDowngradeEvent then
		core.sendGlobalEvent("SunsDusk_WaterBottles_downgradeWaterItem", {
			item = item,
			player = self,
		})
	end
end

table.insert(G_onConsumeJobs, onConsume)


function G_getTheoreticalDrinkValue(item)
	if not NEEDS_THIRST then return 0 end
	
	-- First try to get the actual drink value
	local drinkValue, longLastingMagnitude, longLastingDuration = G_getDrinkValue(item)
	-- If we got a drink value, return it
	if drinkValue then
		return drinkValue, longLastingMagnitude, longLastingDuration
	end
	
	-- Otherwise, assume it's water and calculate theoretical value
	local theoreticalDrinkValue
	
	local lowerName = item.type.record(item).name:lower()
	
	-- Check if it's NOT ritual water (inverse of the original check)
	if lowerName:sub(-8,-1) == "l water)" then
		theoreticalDrinkValue = 0.2 -- Base water value
		-- Apply drink value multiplier
		theoreticalDrinkValue = theoreticalDrinkValue * DRINKVALUE_MULT
		
		-- Bosmer racial bonus for water
		if NEEDS_RACES_THIRST and saveData.playerInfo.isBosmer then
			theoreticalDrinkValue = theoreticalDrinkValue * 1.2
		end
		
		-- Vampire penalty for water
		if NEEDS_THIRST_VW == "Immortal" then
			theoreticalDrinkValue = theoreticalDrinkValue * 0.1
		end
	else
		-- It's ritual water, so drink value is 0
		theoreticalDrinkValue = 0
	end
	
	return theoreticalDrinkValue
end


local function onConsumedWater(liquid, remainingWater)
	if not NEEDS_THIRST then return end
	if liquid ~= "water" and liquid ~= "susWater" then return end
	-- Calculate efficiency (thirst reduction per unit of water)
	local efficiencyPerUnit = 0.3
	if NEEDS_RACES_THIRST then
		if saveData.playerInfo.isBosmer then
			efficiencyPerUnit = efficiencyPerUnit * 1.2
		end
	end
	if saveData.playerInfo.isVampire > 0 and NEEDS_THIRST_VW == "Immortal" then
		efficiencyPerUnit = efficiencyPerUnit * 0.1
	end
	-- Calculate how much water we need to drink to satisfy thirst
	local waterNeeded = thirstData.thirst / efficiencyPerUnit
	-- Actually consume water (capped by what's available)
	local waterConsumed = math.min(remainingWater, waterNeeded)
	-- Reduce thirst based on water consumed
	local drinkValue = efficiencyPerUnit * waterConsumed
	thirstData.thirst = math.max(0, thirstData.thirst - drinkValue)
	-- Return remaining water
	remainingWater = remainingWater - waterConsumed
	
	module_thirst_minute(nil, nil, 0)
	
	if ATRONACH_WATER_MULT ~= "Full" and (ATRONACH_WATER_MULT_AFFECTS_ALL or typesActorActiveEffectsSelf:getEffect(core.magic.EFFECT_TYPE.StuntedMagicka).magnitude > 0) then
		if ATRONACH_WATER_MULT == "Half" then
			G_onFrameJobs.checkDispellWaterAtronach = function()
				local hasWaterBuff= false
				for _, s in pairs(typesActorActiveSpellsSelf) do
					local name = (s.name or ""):lower()
					if name:find("water", 1, true) then
						local hasRestore = false
						for i, eff in ipairs(s.effects) do
							if eff.id == core.magic.EFFECT_TYPE.RestoreMagicka then
								if eff.durationLeft < 5 then
									hasRestore = true
								end
								hasWaterBuff = true
							end
						end
						if hasRestore then
							typesActorActiveSpellsSelf:remove(s.activeSpellId)
						end
					end
				end
				if not hasWaterBuff then
					G_onFrameJobs.checkDispellWaterAtronach = nil
				end
			end
		else
			for _, s in pairs(typesActorActiveSpellsSelf) do
				local name = (s.name or ""):lower()
				if name:find("water", 1, true) then
					local hasRestore = false
					for i, eff in ipairs(s.effects) do
						if eff.id == core.magic.EFFECT_TYPE.RestoreMagicka then
							hasRestore = true
						end
					end
					if hasRestore then
						typesActorActiveSpellsSelf:remove(s.activeSpellId)
					end
				end
			end
		end
	end
	return remainingWater
end

table.insert(G_onConsumedWaterJobs, 0, onConsumedWater)

local function landedSpellHit(target, spell)
	print( saveData.playerInfo.isVampire , NEEDS_THIRST_VW  )
	if saveData.playerInfo.isVampire > 0 and NEEDS_THIRST_VW ~= "Disable" then
		local totalMagnitude = 0
		for i,effect in pairs(spell.effects) do
			local effectRecord = core.magic.effects.records[effect.id]
			if effect.id == "absorbhealth" then
				totalMagnitude = totalMagnitude + effect.duration* (effect.maxMagnitude+effect.minMagnitude)/2
			end		
		end
		local restoredThirst = 0.04+totalMagnitude/750
		if NEEDS_THIRST_VW == "Supernatural" then
			restoredThirst = restoredThirst * 0.5
		end
		thirstData.thirst = math.max(0,thirstData.thirst - restoredThirst)
		module_thirst_minute(nil, nil, 0)
	end
end

table.insert(G_landedSpellHitJobs, landedSpellHit)