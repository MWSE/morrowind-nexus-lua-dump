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
	if not thirstData or not thirstData.currentThirstBuff then return end
	local buff = thirstData.currentThirstBuff
	if core.magic.spells.records[buff] then
		typesActorSpellsSelf:remove(buff)
	else
		log(2, "[SunsDusk] Skipping removal of missing spell:", buff)
	end
end

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
	local skinData = iconPacks.thirst[T_SKIN]
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
			order = "needs-thirst",
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
	tooltipStr = tooltipStr..(not thirstData.currentThirstBuff and "" or tooltips[thirstData.currentThirstBuff] or "ERROR: "..tostring(thirstData.currentThirstBuff))
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

local function module_thirst_minute(clockHour, minute, minutesPassed)
	if not NEEDS_THIRST then return end

	local baseStep = ((G_isSleeping or G_isTravelling) and 0.5 or 1) / HOURS_PER_THIRST_STATE / 6 / 60
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
			local restored = availableDuration * thirstData.longLastingMagnitude / 200
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
	
	--apply new buff
	removeBuffs()
	thirstData.currentThirstBuff = nil

	local suffix = buildSeveritySuffix()
	thirstData.thirstLevel = math.max(0, math.floor(thirstData.thirst * 6 - 0.00001))
	-- remove severitiy suffixes (_2 and _3) for positive buffs (level 0-2)
	-- note: no companion buffs on hardcore
	if thirstData.thirstLevel <= 3 and (suffix == "_2" or suffix == "_3") then
		suffix = ""
	end
	if NEEDS_THIRST_BUFFS_DEBUFFS == "Only buffs" and thirstData.thirstLevel <= 2 
	or NEEDS_THIRST_BUFFS_DEBUFFS == "Only debuffs" and thirstData.thirstLevel >= 3
	or NEEDS_THIRST_BUFFS_DEBUFFS == "Buffs and debuffs" then
		local buff = "sd_thirst_" .. thirstData.thirstLevel .. suffix
		thirstData.currentThirstBuff = buff
		G_addSpellWhenAwake(buff)
	end	
	
	if DEATH_BY_DEHYDRATION and not G_isTravelling and not G_isInJail then
		local volume = (thirstData.thirst-0.95)*20
		if volume > 0 then
			G_heartbeatFlags.thirst = volume
			G_vignetteFlags.thirst = 0.6*volume
			
			if thirstData.thirst >=0.99 then
				G_vignetteColorFlags.thirst = "default"
				if not debug.isGodMode() then
					types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - math.min(7, 0.5 * minutesPassed)
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

-- ─── water consumption: Bosmer +20% water restore when enabled ───
local function onConsume(item)
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	if not NEEDS_THIRST then return end
	if entry and entry.drinkValue and entry.drinkValue ~= 0 then
		local drinkValue = entry.drinkValue
		if NEEDS_THIRST_ALCOHOL_R and entry.consumeCategory == "alcohol" then
			drinkValue = drinkValue * -0.5
		end
		if drinkValue > 0 then
			drinkValue = drinkValue * DRINKVALUE_MULT
		end
		
		if NEEDS_RACES_THIRST and saveData.playerInfo.isBosmer then
			if entry.consumeCategory == "water" or item.type.record(item).name:lower():find("water") then
				drinkValue = drinkValue * 1.2
			end
		end
		if NEEDS_THIRST_VW == "Immortal" and not item.recordId:find("blood") and not item.type.record(item).name:find("blood") then
			drinkValue = drinkValue * 0.1
		end
		
		thirstData.thirst = math.min(1, math.max(0, thirstData.thirst - drinkValue / 200))
		
		if entry.drinkValue2 and entry.drinkValue2 > 0 then
			thirstData.longLastingMagnitude = drinkValue/entry.drinkValue*entry.drinkValue2/360*DRINKVALUE_MULT
			thirstData.longLastingDuration = 360
		end
		
		module_thirst_minute(nil, nil, 0)
	elseif types.Potion.objectIsInstance(item) then
		drinkValue = 0.2
		if saveData.playerInfo.isVampire > 0 and NEEDS_THIRST_VW == "Immortal" and not item.recordId:find("blood") and not item.type.record(item).name:find("blood") then
			drinkValue = drinkValue * 0.1
		end		
		if item.type.record(item).name:lower():sub(-8,-1) == "l water)" then
			drinkValue = 0
		end
		if NEEDS_THIRST_ALCOHOL_R and item.type.record(item).name:lower():find("sujamma") then
			drinkValue = drinkValue * -0.5
		end
		if NEEDS_THIRST_ALCOHOL_R and item.type.record(item).name:lower():find("flin") then --mazte
			drinkValue = drinkValue * -0.5
		end
		if NEEDS_THIRST_ALCOHOL_R and item.type.record(item).name:lower():find("mazte") then --mazte
			drinkValue = drinkValue * -0.5
		end
		if NEEDS_THIRST_ALCOHOL_R and item.type.record(item).name:lower():find("shein") then --mazte
			drinkValue = drinkValue * -0.5
		end
		if NEEDS_THIRST_ALCOHOL_R and item.type.record(item).name:lower():find("greef") then --mazte
			drinkValue = drinkValue * -0.5
		end
		if drinkValue > 0 then
			drinkValue = drinkValue * DRINKVALUE_MULT
		end
		thirstData.thirst = math.max(0, thirstData.thirst - drinkValue)
		
		core.sendGlobalEvent("SunsDusk_WaterBottles_downgradeWaterItem", {
			item = item,
			player = self,
		})
		module_thirst_minute(nil, nil, 0)
	end
end

table.insert(G_onConsumeJobs, onConsume)

local function onConsumedWater(liquid, remainingWater)
	if not NEEDS_THIRST then return end
	if liquid ~= "water" then return end
	-- Calculate efficiency (thirst reduction per unit of water)
	local efficiencyPerUnit = 0.3
	if NEEDS_RACES_THIRST then
		if saveData.playerInfo.isBosmer then
			efficiencyPerUnit = efficiencyPerUnit * 1.2
		end
	end
	if NEEDS_THIRST_VW == "Immortal" then
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
	
	if ATRONACH_WATER_MULT ~= "Full" then --and types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.StuntedMagicka).magnitude > 0 then
		if ATRONACH_WATER_MULT == "Half" then
			G_onFrameJobs.checkDispellWaterAtronach = function()
				local active = types.Actor.activeSpells(self)
				local hasWaterBuff= false
				for _, s in pairs(active) do
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
							active:remove(s.activeSpellId)
						end
					end
				end
				if not hasWaterBuff then
					G_onFrameJobs.checkDispellWaterAtronach = nil
				end
			end
		else
			local active = types.Actor.activeSpells(self)
			for _, s in pairs(active) do
				local name = (s.name or ""):lower()
				if name:find("water", 1, true) then
					local hasRestore = false
					for i, eff in ipairs(s.effects) do
						if eff.id == core.magic.EFFECT_TYPE.RestoreMagicka then
							hasRestore = true
						end
					end
					if hasRestore then
						active:remove(s.activeSpellId)
					end
				end
			end
		end
	end
	return remainingWater
end

table.insert(G_onConsumedWaterJobs, 0, onConsumedWater)

local function cellChanged(lastCell)
	if self.cell then
		core.sendGlobalEvent("SunsDusk_WaterBottles_convertMiscInCell", {
			player = self,
		})
	end
end

table.insert(G_onLoadJobs, cellChanged)
table.insert(G_cellChangedJobs, cellChanged)

local function onFrame(dt)
    if NEEDS_THIRST_SPILL_ON_JUMP and self.controls.jump and G_isInWater < 0.6 then
        core.sendGlobalEvent("SunsDusk_WaterBottles_spillWater", self)
    end
end

table.insert(G_onFrameJobs, onFrame)

-- ──────────────────────────────────────────────────────────────────────────── Refill ───────────────────────────────────────────────────────────────────────────────────

G_wellKeywords = { 
	"well", 		--wellbroken
	"fountain", 	-- T_De_SetInd_X_Fountain ; fountain_water
	"pool", 		--cavemud
	"trough", 
	-- "aquaduct", 
	"keg", 
	"ab_furn_barrel01water",
	"ab_furn_combucket02water", 
	"t_imp_furnr_basin_02_w", 
	"t_imp_furnr_basin_01", 
	"t_com_var_bucketwater_01", -- can now refill water in OAAB water barells full of water and TD basins with water ; stronghold no longer considered a well
}

if G_STARWIND_INSTALLED then
	table.insert(G_wellKeywords, "sw_ext_moist")
	table.insert(G_wellKeywords, "sw_bantha")
end
G_wellBlacklist = { "comkeg", "inkwell", "acid", "lava", "terrmineral", "stairwell", "smdwell", "fountainwall", "blood", "table", "rack" --[[comkegrack]] }

local function isWell(object)
	if G_raycastResultType ~= "Static" and G_raycastResultType ~= "Activator" then 
		return false
	end
	local dbEntry = dbStatics[object.recordId] and dbStatics[object.recordId].well
	if dbEntry ~= nil then
		return dbEntry and true
	end
	local id = object.recordId or ""
	for _, key in ipairs(G_wellKeywords) do
		if id:find(key, 1, true) then
			for _, key in ipairs(G_wellBlacklist) do
				if id:find(key, 1, true) then
					return false
				end
			end
			return true
		end
	end
	return false
end

input.registerTriggerHandler('Activate', async:callback(function()
	if not NEEDS_THIRST_REFILL or not NEEDS_THIRST then return end
	if G_raycastResult and G_raycastResult.hitObject and isWell(G_raycastResult.hitObject) then 
		log(3, "activated well ... refilling now", G_raycastResult.hitObject.recordId)
		core.sendGlobalEvent("SunsDusk_WaterBottles_refillBottlesWell", self)
		if thirstData.thirst > 0.001 then
			ambient.playSound("Drink")
			thirstData.thirst = 0
			module_thirst_minute(nil, nil, 0)
		elseif saveData.m_temp then --and saveData.m_temp.targetTemp > 20 then
			core.sendGlobalEvent("SunsDusk_WaterBottles_refillSpillables", self)
			ambient.playSoundFile("sound/Fx/FOOT/splsh.wav")
			--ambient.playSoundFile("sound/sunsdusk/water-splash-05-2-by-jazzy.junggle.net.ogg")
			saveData.m_temp.water.wetness = math.min(1, saveData.m_temp.water.wetness + 0.1)
			if saveData.m_temp.currentTemp > 10 then
				saveData.m_temp.currentTemp = math.max(10, saveData.m_temp.currentTemp - 4)
			end
		end
	end
end))

-- calculating anchor based on offcet from center
local function alignAxis(value)
	local center = 0.5
	local threshold = 0.01
	local dist = math.abs(value - center)
	local t = math.min(dist / threshold, 1)
	if value > center then
		return 0.5 - (t * 0.5)  -- Interpolate from 0.5 to 1
	else
		return 0.5 + (t * 0.5)  -- Interpolate from 0.5 to 0
	end
end
local function alignAnchor(pos)
	local alignedX = alignAxis(pos.x)
	local alignedY = alignAxis(pos.y)
	return v2(alignedX, alignedY)
end

local function raycastChanged()
	if not NEEDS_THIRST_REFILL or not NEEDS_THIRST then return end
	if G_raycastResultType and isWell(G_raycastResult.hitObject) then
		if wellTooltip then
			wellTooltip:destroy()
		end
		wellTooltip = ui.create({
			layer = 'Scene',
			name = "wellTooltip",
			type = ui.TYPE.Text,
			props = {
				text = "refill water",
				relativePosition = v2(TOOLTIP_RELATIVE_X/100,TOOLTIP_RELATIVE_Y/100),
				anchor = alignAnchor(v2(TOOLTIP_RELATIVE_X/100,TOOLTIP_RELATIVE_Y/100)),
				textColor = TOOLTIP_FONT_COLOR,
				textShadow = true,
				textSize = TOOLTIP_FONT_SIZE,
			}
		})
	elseif wellTooltip then
		wellTooltip:destroy()
		wellTooltip = nil
	end
end
table.insert(G_raycastChangedJobs, raycastChanged)
table.insert(G_refreshWidgetJobs, raycastChanged)


local function refillSwimming(dt)
	if G_isInWater > 0.6 and NEEDS_THIRST_REFILL then
		core.sendGlobalEvent("SunsDusk_WaterBottles_refillSpillables", self)
	end
end

--table.insert(G_onFrameJobsSluggish, refillSwimming)
table.insert(G_sluggishScheduler[5], refillSwimming)
G_onFrameJobsSluggish.refillSwimming=refillSwimming


local function landedSpellHit(target, spell)
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

-- after jumping
local function spilledWater(ml)
	if saveData.m_temp then
		if saveData.m_temp.currentTemp > 10 then
			local wetnessMod = 1 - saveData.m_temp.water.wetness
			saveData.m_temp.currentTemp = math.max(10, saveData.m_temp.currentTemp - ml/250 * wetnessMod)
		end
		saveData.m_temp.water.wetness = math.min(1, saveData.m_temp.water.wetness + ml/250*0.1)
		--module_temp_minute(24, 1, 0)
	end	
	ui.showMessage("You splash water on your face and drink from the open cups you carry. There is "..ml.." Ml less to drink in your inventory.")
	ambient.playSoundFile("sound/Fx/FOOT/splsh.wav")
	ambient.playSoundFile("sound/sunsdusk/water-splash-05-2-by-jazzy.junggle.net.ogg")
end

G_eventHandlers.SunsDusk_spilledWater = spilledWater


local function refilledBottlesWell(message)
	ui.showMessage(message)
	ambient.playSound("item potion up")
end

G_eventHandlers.SunsDusk_refilledBottlesWell = refilledBottlesWell