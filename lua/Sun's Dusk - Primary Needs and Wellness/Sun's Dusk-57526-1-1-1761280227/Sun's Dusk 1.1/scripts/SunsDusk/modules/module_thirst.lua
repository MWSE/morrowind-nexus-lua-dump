local thirstData




local function buildSeveritySuffix()
	local suffix = ""
	if saveData.countCompanions >= 1 then
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
		types.Actor.spells(self):remove(buff)
	else
		log(2, "[SunsDusk] Skipping removal of missing spell:", buff)
	end
end


local function alphaFromValue(x)
	if HUD_ALPHA == "Smooth" then
		-- params
		local k = 6	   -- exponential sharpness
		local p = 4	   -- trig sharpness
		local alpha = 0.5 -- 0..1 (only used for the weighted blend)
		
		-- per-step bookkeeping
		local step = math.floor(x * 6)
		local t = x * 6 - step			   -- progress in [0,1] within the step
		local base = step / 5
		local nextStep = math.min((step + 1) / 5, 1)
		
		-- components
		local a = (math.exp(k * t) - 1) / (math.exp(k) - 1)				 -- exp-in(k)
		local b = (math.sin((math.pi/2) * t))^p							  -- trig(p)
		
		-- weighted average
		local e_lin = (1 - alpha) * a + alpha * b
	
		local y = math.min(base + (nextStep - base) * e_lin, 1)
		
		--perceptualBias
		local a = (math.exp(6 * t) - 1) / (math.exp(6) - 1)		   -- exp-in k=6
		local bTrig = (math.sin((math.pi/2) * t))^4					-- trig p=4
		
		-- choose a blend you liked (linear alpha=0.5 shown here)
		local e = 0.5 * a + 0.5 * bTrig
		
		-- perceptual remap (pick ONE)
		local gamma = 1.7
		e = e ^ gamma					 -- Option A: gamma
		
		-- OR:
		-- e = bias(0.7, e)			   -- Option B: bias
		
		-- finalize
		local y = math.min(base + (nextStep - base) * e, 1)
		return y
	else
		local step = math.floor( x * 6)
		return math.min(step / 5, 1)
	end
end

local function alphaFromValue06666(x)
	if HUD_ALPHA == "Smooth" then
		-- parameters
		local k = 6		-- exponential sharpness
		local p = 4		-- trig sharpness
		local alpha = 0.5  -- blend weight
		local gamma = 1.7  -- perceptual correction
		local xMax = 0.6666  -- full brightness reached here

		-- clamp and rescale so [0, 0.6666] -> [0, 1]
		local scaledX = math.min(x / xMax, 1)

		-- define 4 plateaus (3 steps, final = 1)
		local stepCount = 4
		local step = math.floor(scaledX * stepCount)
		local t = scaledX * stepCount - step
		local base = step / (stepCount - 1)
		local nextStep = math.min((step + 1) / (stepCount - 1), 1)

		-- easing components
		local a = (math.exp(k * t) - 1) / (math.exp(k) - 1)
		local b = (math.sin((math.pi / 2) * t)) ^ p

		-- blend easing
		local e = (1 - alpha) * a + alpha * b
		e = e ^ gamma  -- perceptual tweak

		-- interpolate step levels
		local y = math.min(base + (nextStep - base) * e, 1)

		return y
	else
		local stepCount = 4
		local step = math.floor(x * stepCount)
		return math.min(step / (stepCount - 1), 1)
	end
end

local function getThirstAlpha()
	local thirst = math.max(0,math.min(1,thirstData.thirst))
	if NEEDS_THIRST_BUFFS then -- this setting prevents thirst from going above 0.666666
		return alphaFromValue06666(thirst)
	end
	return alphaFromValue(thirst)
end

local function updateWidget()
	if not NEEDS_THIRST then return end

	uiWidgets.m_thirst = {
	}
	
	if true then
		local skinData = iconPacks.thirst[T_SKIN]
		local thirstTexture
		if skinData.stages > 1 then
			local thirstLevel = math.max(0, math.floor(thirstData.thirst * skinData.stages - 0.00001))
			thirstTexture = getTexture(skinData.base.."thirst_"..thirstLevel..skinData.extension)
		else
			thirstTexture =  getTexture(skinData.base.."thirst"..skinData.extension)
		end
		
		local widget = {
			type = ui.TYPE.Widget,
			props = {
				size = v2(HUD_ICON_SIZE,HUD_ICON_SIZE),
			},
			order = "needs-thirst",
			content = ui.content {
				T_BACKGROUND ~= "No Background" and { -- Damage Bar r.2.lag
					name = "thirst_background",
					type = ui.TYPE.Image,
					props = {
						resource = T_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or thirstTexture,
						color = T_BACKGROUND == "Classic" and T_BACKGROUND_COLOR or util.color.rgb(0,0,0),
						tileH = false,
						tileV = false,
						relativeSize  = v2(1,1),
						relativePosition = T_BACKGROUND == "Shadow" and v2(0.04,0.027) or nil,
						alpha = T_BACKGROUND == "Classic" and (HUD_ALPHA == "Static" and 1 or getThirstAlpha()^2) or 0.5,
					}
				} or {},
				{
					name = "thirst_icon",
					type = ui.TYPE.Image,
					props = {
						resource = thirstTexture,
						color =  T_COLOR,
						tileH = false,
						tileV = false,
						relativeSize  = v2(1,1),
						alpha = HUD_ALPHA == "Static" and 1 or getThirstAlpha(),
					}
				}
			}
		}
		table.insert(uiWidgets.m_thirst, widget)
		local tooltipStr = math.floor(thirstData.thirst*100).."%\n"
		if thirstData.longLastingDuration then
			tooltipStr = tooltipStr.."Well fed: "..formatTimeLeft(thirstData.longLastingDuration).."\n"
		end
		tooltipStr = tooltipStr..(tooltips[thirstData.currentThirstBuff] or "ERROR: "..tostring(thirstData.currentThirstBuff))
		addTooltip(widget,tooltipStr)
	end
end

table.insert(refreshWidgetJobs, updateWidget)

local function module_thirst_minute(clockHour, minute, minutesPassed)
	if not NEEDS_THIRST then return end

	local baseStep = (isSleeping and 0.5 or 1) / HOURS_PER_THIRST_STATE / 6 / 60
	local raceConsumptionMult = 1
	
	if NEEDS_RACES_THIRST then
		-- consumption
		if saveData.playerInfo.isDunmer then raceConsumptionMult = 0.8 end
		if saveData.playerInfo.isRedguard or saveData.playerInfo.isFarmingTool then raceConsumptionMult = 0.7 end
		if saveData.playerInfo.isAltmer then raceConsumptionMult = 1.2 end
		--restoration
		if saveData.playerInfo.isFarmingTool then
			local restore = 0
			if isInRain then
				restore = restore + ARGONIAN_RAIN_RESTORE_PER_MIN * minutesPassed
			end
			if isInWater > 0 then
				restore = restore + ARGONIAN_SWIM_RESTORE_PER_MIN * minutesPassed * isInWater
			end
			if restore > 0 then
				thirstData.thirst = math.max(0, thirstData.thirst - restore)
			end
		end
	end
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

	if NEEDS_THIRST_BUFFS then -- prevent thirst from going above 0.5 (thirstLevel 3 starts at 0.5 or so)
		thirstData.thirst = math.min(1-3/6-0.0001, thirstData.thirst)
	end

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

	local buff = "sd_thirst_" .. thirstData.thirstLevel .. suffix
	thirstData.currentThirstBuff = buff
	types.Actor.spells(self):add(buff)
	
	
	if DEATH_BY_DEHYDRATION and thirstData.thirst >=0.99 then
		types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - math.min(7, 0.5 * minutesPassed)
		ambient.playSound("Health Damage", {volume =0.5})
		SDVignetteAlpha = 0.5
		SDVignette.layout.props.alpha = SDVignetteAlpha
		SDVignette:update()
	end
	updateWidget()
end

table.insert(perMinuteJobs, module_thirst_minute)

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

table.insert(onLoadJobs, onLoad)

table.insert(onLoadJobs, updateWidget) --after all onload jobs, also update widget

local function settingsChanged(sectionName, setting, oldValue)
	if setting == "NEEDS_THIRST" then
		if oldValue == false then
			onLoad()
		else
			removeBuffs()
			saveData.m_thirst = nil
			uiWidgets.m_thirst = nil
		end
	end
end
table.insert(settingsChangedJobs, settingsChanged)

-- ─── water consumption: Bosmer +20% water restore when enabled ───
local function onConsume(item)
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	if entry and entry.drinkValue then
		log(3, "item ID:  "..item.recordId.."  ;  item name: "..tostring(entry.localizedName).."  ;  drink value:  "..entry.drinkValue)
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
		if NEEDS_RACES_THIRST and saveData.playerInfo.isBosmer then
			if item.type.record(item).name:lower():find("water") then
				drinkValue = drinkValue * 1.2
			end
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

table.insert(onConsumeJobs, onConsume)

local function onConsumedWater(liquid)
	if liquid ~= "water" then return end
	local drinkValue = 0.1
	if NEEDS_RACES_THIRST then
		if saveData.playerInfo.isBosmer then
			drinkValue = drinkValue * 1.2
		end
	end
	if NEEDS_THIRST_VW == "Immortal" then
		drinkValue = drinkValue * 0.1
	end
	thirstData.thirst = math.max(0, thirstData.thirst - drinkValue)
	module_thirst_minute(nil, nil, 0)

	if ATRONACH_WATER_MULT ~= "Full" then --and types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.StuntedMagicka).magnitude > 0 then
		if ATRONACH_WATER_MULT == "Half" then
			onFrameJobs.checkDispellWaterAtronach = function()
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
					onFrameJobs.checkDispellWaterAtronach = nil
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
end

table.insert(onConsumedWaterJobs, onConsumedWater)

local function cellChanged(lastCell)
	if self.cell then
		core.sendGlobalEvent("SunsDusk_WaterBottles_convertMiscInCell", {
			player = self,
		})
	end
end

table.insert(onLoadJobs, cellChanged)
table.insert(cellChangedJobs, cellChanged)


local function onFrame(dt)
	if self.controls.jump and isInWater < 0.6 then
		core.sendGlobalEvent("SunsDusk_WaterBottles_spillWater", self) -- only one argument, and must be serializable (gameobject is)
	end
end

table.insert(onFrameJobs, onFrame)


-- ──────────────────────────────────────────────────────────────────────────── Refill ───────────────────────────────────────────────────────────────────────────────────

input.registerTriggerHandler('Activate', async:callback(function()
	
	if not NEEDS_THIRST_REFILL or not NEEDS_THIRST then return end
	if raycastResult.hitObject then
		if raycastResult.hitObject.recordId:find('well') and types.Static.objectIsInstance(raycastResult.hitObject) then 
			log(3, "activated well ... refilling now", raycastResult.hitObject.recordId)
			core.sendGlobalEvent("SunsDusk_WaterBottles_refillBottlesWell", self)
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
	if raycastResult.hitObject and raycastResult.hitObject.recordId:find('well') and types.Static.objectIsInstance(raycastResult.hitObject) then
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
table.insert(raycastChangedJobs, raycastChanged)
table.insert(refreshWidgetJobs, raycastChanged)


local function refillSwimming(dt)
	if isInWater > 0.6 and NEEDS_THIRST_REFILL then
		core.sendGlobalEvent("SunsDusk_WaterBottles_refillSpillables", self)
	end
end

table.insert(onFrameJobsSluggish, refillSwimming)


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

table.insert(landedSpellHitJobs, landedSpellHit)

local function spilledWater(ml)
	ui.showMessage("spilled "..ml.." Ml")
	ambient.playSoundFile("sound/Fx/FOOT/splsh.wav")
	ambient.playSoundFile("sound/sunsdusk/water-splash-05-2-by-jazzy.junggle.net.ogg")
end

eventHandlers.SunsDusk_spilledWater = spilledWater


local function refilledBottlesWell(message)
	ui.showMessage(message)
	ambient.playSound("item potion up")
end

eventHandlers.SunsDusk_refilledBottlesWell = refilledBottlesWell



