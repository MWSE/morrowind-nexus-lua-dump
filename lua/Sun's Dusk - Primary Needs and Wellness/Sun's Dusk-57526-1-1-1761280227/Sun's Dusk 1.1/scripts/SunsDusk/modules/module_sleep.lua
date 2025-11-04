
--gmsts
local fRestMagicMult     = core.getGMST("fRestMagicMult")
local fFatigueReturnBase = core.getGMST("fFatigueReturnBase")
local fFatigueReturnMult = core.getGMST("fFatigueReturnMult")
local fEndFatigueMult    = core.getGMST("fEndFatigueMult")
local fEncumbranceStrMult = core.getGMST("fEncumbranceStrMult")

local sleepData


local function removeBuffs()
	if not sleepData then return end
	if sleepData.currentTirednessBuff and core.magic.spells.records[sleepData.currentTirednessBuff] then 
		log(5, "removing", sleepData.currentTirednessBuff, core.magic.spells.records[sleepData.currentTirednessBuff])
		types.Actor.spells(self):remove(sleepData.currentTirednessBuff) 
	end
	if sleepData.currentSleepingProfileBuff and core.magic.spells.records[sleepData.currentSleepingProfileBuff] then 
		log(5, "removing", sleepData.currentSleepingProfileBuff, core.magic.spells.records[sleepData.currentSleepingProfileBuff])
		types.Actor.spells(self):remove(sleepData.currentSleepingProfileBuff) 
	end
	
-- sleeping 8 hours during your sleep personality takes you from exhausted -> well-rested--message boxes: morning->night, no longer morning person ... enjoy night time // night->morning, no longer enjoy the darkness ... you are a morning person // night or morning -> insomniac, after days of little sleep, you find yourself not [whatever]

-- mwscript check for Dagoth Ur nightmares
-- going to sleep hungry and/or thirsty reduces sleep quality
-- sleeping for more than 12 hrs per day reduces sleep quality
end

--dehardcoded regen formulas
local function getRestorationPerHourOfSleep()
	local endurance = types.Actor.stats.attributes.endurance(self).modified --const float endurance = stats.getAttribute(ESM::Attribute::Endurance).getModified();
	local health = 0.1 * endurance --const float health = 0.1f * endurance;
	local magicka = fRestMagicMult * types.Actor.stats.attributes.intelligence(self).modified --const float magicka = fRestMagicMult * stats.getAttribute(ESM::Attribute::Intelligence).getModified();
	local strength = types.NPC.stats.attributes.strength(self).modified
	local encumbrance = types.Actor.getEncumbrance(self) --float encumbrance = getEncumbrance(ptr);
	local capacity = strength * fEncumbranceStrMult --float capacity = getCapacity(ptr);
	local normalizedEncumbrance = 0
	if encumbrance > 0 and capacity > 0 then
		normalizedEncumbrance = encumbrance / capacity
	elseif encumbrance > 0 and capacity == 0 then
		normalizedEncumbrance = 1.0
	end
	normalizedEncumbrance = math.min(1, normalizedEncumbrance)
	local x = (fFatigueReturnBase + fFatigueReturnMult * (1 - normalizedEncumbrance)) * (fEndFatigueMult * endurance); --const float x = (fFatigueReturnBase + fFatigueReturnMult * (1 - normalizedEncumbrance)) * (fEndFatigueMult * endurance);
	local fatigue = 3600 * x
	magicka = magicka * (1 - types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.StuntedMagicka).magnitude)
	--log(types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.StuntedMagicka).magnitude)
	
	return health, fatigue, magicka
end

local function alphaFromValue(x)
	if HUD_ALPHA == "Smooth" then
		-- params
		local k = 6       -- exponential sharpness
		local p = 4       -- trig sharpness
		local alpha = 0.5 -- 0..1 (only used for the weighted blend)
		
		-- per-step bookkeeping
		local step = math.floor(x * 6)
		local t = x * 6 - step               -- progress in [0,1] within the step
		local base = step / 5
		local nextStep = math.min((step + 1) / 5, 1)
		
		-- components
		local a = (math.exp(k * t) - 1) / (math.exp(k) - 1)                 -- exp-in(k)
		local b = (math.sin((math.pi/2) * t))^p                              -- trig(p)
		
		-- weighted average
		local e_lin = (1 - alpha) * a + alpha * b
	
		local y = math.min(base + (nextStep - base) * e_lin, 1)
		
		--perceptualBias
		local a = (math.exp(6 * t) - 1) / (math.exp(6) - 1)           -- exp-in k=6
		local bTrig = (math.sin((math.pi/2) * t))^4                    -- trig p=4
		
		-- choose a blend you liked (linear alpha=0.5 shown here)
		local e = 0.5 * a + 0.5 * bTrig
		
		-- perceptual remap (pick ONE)
		local gamma = 1.7
		e = e ^ gamma                     -- Option A: gamma
		
		-- OR:
		-- e = bias(0.7, e)               -- Option B: bias
		
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
		local k = 6        -- exponential sharpness
		local p = 4        -- trig sharpness
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

local function getTirednessAlpha()
	local tiredness = math.max(0,math.min(1,sleepData.tiredness))
	if NEEDS_TIREDNESS_BUFFS then -- this setting prevents tiredness from going above 0.666666
		return alphaFromValue06666(tiredness)
	end
	return alphaFromValue(tiredness)
--alphaFromValue(math.max(0,math.min(1, NEEDS_TIREDNESS_BUFFS and sleepData.tiredness*1.66 or sleepData.tiredness))) -- instead of times 1.666 call different alphaFromValue functions
end

local function updateWidget()
	if not NEEDS_TIREDNESS then return end

	uiWidgets.m_sleep = {
	}
	
	
	
	if sleepData.currentSleepingProfile and S_SP_DISPLAY then
		local skinData = iconPacks.sleep[S_SKIN]
		local sleepProfileTexture = getTexture(skinData.base.."sleep_"..sleepData.currentSleepingProfile..skinData.extension)
		
		local widget = {
			type = ui.TYPE.Widget,
			props = {
				size = v2(HUD_ICON_SIZE,HUD_ICON_SIZE),
			},
			order = sleepData.currentSleepingProfile == "insomniac" and "needs-sleep" or "profiles-sleep",
			content = ui.content {
				S_BACKGROUND ~= "No Background" and {
					name = "profile_background",
					type = ui.TYPE.Image,
					props = {
						resource = S_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or sleepProfileTexture,
						color =  S_BACKGROUND == "Classic" and S_BACKGROUND_COLOR or util.color.rgb(0,0,0),
						tileH = false,
						tileV = false,
						relativeSize  = v2(1,1),
						relativePosition = S_BACKGROUND == "Shadow" and v2(0.04,0.027) or nil,
						alpha = 1,
					}
				} or {},	
				{
					name = "profile_icon",
					type = ui.TYPE.Image,
					props = {
						resource = sleepProfileTexture,
						color =  S_COLOR,						
						tileH = false,
						tileV = false,
						relativeSize  = v2(1,1),
						alpha = 1,
					}
				}
			}
		}
		table.insert(uiWidgets.m_sleep, widget)
		addTooltip(widget, tooltips[sleepData.currentSleepingProfileBuff] or "ERROR: "..tostring(sleepData.currentSleepingProfileBuff))
	end
	if sleepData.currentSleepingProfile ~= "insomniac" then
		local tirednessTexture
		local skinData = iconPacks.sleep[S_SKIN]
		if skinData.stages > 1 then
			local tirednessLevel = math.max(0, math.floor(sleepData.tiredness * skinData.stages - 0.00001))
			tirednessTexture = getTexture(skinData.base.."sleep_"..tirednessLevel..skinData.extension)
		else
			tirednessTexture =  getTexture(skinData.base.."sleep"..skinData.extension)
		end
		local widget = {
			type = ui.TYPE.Widget,
			props = {
				size = v2(HUD_ICON_SIZE,HUD_ICON_SIZE),
			},
			order = "needs-sleep",
			content = ui.content {
				S_BACKGROUND ~= "No Background" and { -- Damage Bar r.2.lag
					name = "tiredness_background",
					type = ui.TYPE.Image,
					props = {
						resource = S_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or tirednessTexture,
						color = S_BACKGROUND == "Classic" and S_BACKGROUND_COLOR or util.color.rgb(0,0,0),
						tileH = false,
						tileV = false,
						relativeSize  = v2(1,1),
						relativePosition = S_BACKGROUND == "Shadow" and v2(0.04,0.027) or nil,
						alpha = S_BACKGROUND == "Classic" and (HUD_ALPHA == "Static" and 1 or getTirednessAlpha()^2) or 0.5,
					}
				} or {},
				{
					name = "tiredness_icon",
					type = ui.TYPE.Image,
					props = {
						resource = tirednessTexture,
						color =  S_COLOR,
						tileH = false,
						tileV = false,
						relativeSize  = v2(1,1),
						alpha = HUD_ALPHA == "Static" and 1 or getTirednessAlpha(),
					}
				}
			}
		}
		table.insert(uiWidgets.m_sleep, widget)
		local tooltipStr = math.floor(sleepData.tiredness*100).."%\n"
		if sleepData.longLastingDuration then
			tooltipStr = tooltipStr.."Well fed: "..formatTimeLeft(sleepData.longLastingDuration).."\n"
		end
		tooltipStr = tooltipStr..(tooltips[sleepData.currentTirednessBuff] or "ERROR: "..tostring(sleepData.currentTirednessBuff))
		addTooltip(widget,tooltipStr)
	end
end

table.insert(refreshWidgetJobs, updateWidget)

-- executed every hour
local function module_sleep_hour(clockHour)
	if not NEEDS_TIREDNESS then return end
	if isSleeping then
		sleepData.sleepingCycle[clockHour] = math.max(0,math.min(1, sleepData.sleepingCycle[clockHour] + 0.2))
	else
		sleepData.sleepingCycle[clockHour] = math.max(0,math.min(1, sleepData.sleepingCycle[clockHour] - 0.2))
	end
	for i,v in pairs(sleepData.sleepingCycle) do --for index, value
		if i == clockHour then
			log(3, "["..i.."]", "=", v)
		else
			log(3, i, "=", v)
		end
	end
end

table.insert(perHourJobs, module_sleep_hour)

local function module_sleep_minute(clockHour, minute, minutesPassed)
	if not NEEDS_TIREDNESS then return end
	--if not sleepData then return end
	local tirednessPrior = sleepData.tiredness
	if isSleeping then
		-- change sleeping cycle for current hour of sleeping + 0.2
		sleepData.tiredness = math.max(0, sleepData.tiredness - 2/HOURS_PER_RESTED_STATE/6/60*minutesPassed)
		log(5, tostring(minutesPassed).."m passed  ;  currently sleeping at ...  "..clockHour..":00  ;  current tiredness  is: "..f2(sleepData.tiredness) .." ; lost  "..f2(tirednessPrior - sleepData.tiredness).." ; sleepingCycle: "..sleepData.sleepingCycle[clockHour])
		local health, fatigue, magicka = getRestorationPerHourOfSleep() --fatigue regen is extremely high, ignore that
		health = health / 60
		fatigue = fatigue / 60
		magicka = magicka / 60
		local oldHealth  = types.Actor.stats.dynamic.health(self).current
		local oldMagicka = types.Actor.stats.dynamic.magicka(self).current
		
		local newHealth  = oldHealth + health * (sleepData.sleepingCycle[clockHour])
		local newMagicka = oldMagicka + magicka * (sleepData.sleepingCycle[clockHour])
		--local newHealth  = oldHealth  - health  --testing
		--local newMagicka = oldMagicka - magicka --testing
		
		local maxHealth  = types.Actor.stats.dynamic.health(self).base 
		local maxMagicka = types.Actor.stats.dynamic.magicka(self).base
		
		types.Actor.stats.dynamic.health(self).current =  math.max(oldHealth, math.min(maxHealth,  newHealth ))
		types.Actor.stats.dynamic.magicka(self).current = math.max(oldMagicka, math.min(maxMagicka, newMagicka))

		log(5, "+".. newHealth-oldHealth .." Health")
		log(5, "+".. newMagicka-oldMagicka .." Magicka")
	else
		-- change sleeping cycle for current hour of being awake -0.2
		sleepData.tiredness = math.min(1, sleepData.tiredness + 1/HOURS_PER_RESTED_STATE/6/60*minutesPassed)
		log(5, tostring(minutesPassed).."m passed  ;  currently not sleeping at ...  "..clockHour..":00  ;  current tiredness is: "..f2(sleepData.tiredness).." ; gained  "..f2(sleepData.tiredness -tirednessPrior ))
	
	end
	if sleepData.longLastingDuration and minutesPassed > 0 then
		local availableDuration = math.min(sleepData.longLastingDuration, minutesPassed)
		local restored = availableDuration * sleepData.longLastingMagnitude / 200
		sleepData.tiredness = math.max(0, sleepData.tiredness - restored)
		sleepData.longLastingDuration = sleepData.longLastingDuration - availableDuration
		if sleepData.longLastingDuration <= 0 then
			sleepData.longLastingDuration = nil
		end
	end
	
	
	if NEEDS_TIREDNESS_BUFFS then -- prevent tiredness from going above 0.5 (tirednesslevel 3 starts at 0.5 or so)
		sleepData.tiredness = math.min(1-3/6-0.0001, sleepData.tiredness)
	end

	--apply new buff
	removeBuffs()
	sleepData.currentTirednessBuff = nil
	sleepData.currentSleepingProfileBuff = nil
	
	local isInsomniac = false
	if SLEEP_PERSONALITY then
		-- sleep personality differences
		-- morning: sleep from 8p-10p and wake up between 4a-6a for x days of a week
		-- night: sleep from 10a-12p and wake up between 6p-8p for x days of a week
		-- insomniac: sleep less than 4 hours per day for x days of a week -- removes penalties
		
		--morning person
		do
			local awakeHoursInTimespan = 0
			local neededAwakeHoursInTimespan = 10
			
			local sleepingHoursInTimespan = 0
			local neededSleepingHoursInTimespan = 8
			
			local awakeThreshold = 0.41
			local sleepThreshold = 0.59
			
			local wakeupPenalty = 3
			
			if sleepData.currentSleepingProfile == "morninglark" then
				--log "easy morninglark"
				awakeThreshold = 0.42
				sleepThreshold = 0.58
				neededAwakeHoursInTimespan = 8
				neededSleepingHoursInTimespan = 6
				wakeupPenalty = 2
			end
			awakeThreshold = awakeThreshold +0.01
			sleepThreshold = sleepThreshold -0.01
				
			--sleeping?
			for hour = 20, 24 do
				if sleepData.sleepingCycle[hour] >= sleepThreshold then
					sleepingHoursInTimespan = sleepingHoursInTimespan + 1
				end
			end
			for hour = 1, 6 do
				if sleepData.sleepingCycle[hour] >= sleepThreshold then
					sleepingHoursInTimespan = sleepingHoursInTimespan + 1
				end
			end
			
			--awake?
			for hour = 7, 9 do
				if sleepData.sleepingCycle[hour] <= awakeThreshold then
					awakeHoursInTimespan = awakeHoursInTimespan + 1
				else
					awakeHoursInTimespan = awakeHoursInTimespan - wakeupPenalty
				end
			end
			for hour = 10, 19 do
				if sleepData.sleepingCycle[hour] <= awakeThreshold then
					awakeHoursInTimespan = awakeHoursInTimespan + 1
				end
			end
			if minute%60 == 0 then
				log(3, "morninglark:  slept",sleepingHoursInTimespan, "/", neededSleepingHoursInTimespan)
				log(3, "morninglark:  awake",awakeHoursInTimespan, "/", neededAwakeHoursInTimespan)
			end
			if sleepingHoursInTimespan >= neededSleepingHoursInTimespan and awakeHoursInTimespan >= neededAwakeHoursInTimespan then
				types.Actor.spells(self):add("sd_t_sp_morninglark")
				sleepData.currentSleepingProfileBuff = "sd_t_sp_morninglark"
				sleepData.currentSleepingProfile = "morninglark"
				goto continue
			end
		end
		
		-- night person
		do
			local awakeHoursInTimespan = 0
			local neededAwakeHoursInTimespan = 10
			
			local sleepingHoursInTimespan = 0
			local neededSleepingHoursInTimespan = 8
			
			local awakeThreshold = 0.41
			local sleepThreshold = 0.59
			
			local wakeupPenalty = 3
			
			if sleepData.currentSleepingProfile == "nightowl" then
				-- log "easy nightowl"
				awakeThreshold = 0.42
				sleepThreshold = 0.58
				neededAwakeHoursInTimespan = 8
				neededSleepingHoursInTimespan = 6
				wakeupPenalty = 2
			end
			
			awakeThreshold = awakeThreshold +0.01
			sleepThreshold = sleepThreshold -0.01
			
			--sleeping?
			for hour = 9, 19 do
				if sleepData.sleepingCycle[hour] >= sleepThreshold then
					sleepingHoursInTimespan = sleepingHoursInTimespan + 1
				end
			end
			
			--awake?
			for hour = 20, 22 do
				if sleepData.sleepingCycle[hour] <= awakeThreshold then
					awakeHoursInTimespan = awakeHoursInTimespan + 1
				else
					awakeHoursInTimespan = awakeHoursInTimespan - wakeupPenalty
				end
			end
			for hour = 23, 24 do
				if sleepData.sleepingCycle[hour] <= awakeThreshold then
					awakeHoursInTimespan = awakeHoursInTimespan + 1
				end
			end
			for hour = 1, 8 do
				if sleepData.sleepingCycle[hour] <= awakeThreshold then
					awakeHoursInTimespan = awakeHoursInTimespan + 1
				end
			end
			if minute%60 == 0 then
				log(3, "nightowl:  slept",sleepingHoursInTimespan, "/", neededSleepingHoursInTimespan)
				log(3, "nightowl:  awake",awakeHoursInTimespan, "/", neededAwakeHoursInTimespan)
			end
			if sleepingHoursInTimespan >= neededSleepingHoursInTimespan and awakeHoursInTimespan >= neededAwakeHoursInTimespan then
				types.Actor.spells(self):add("sd_t_sp_nightowl")
				sleepData.currentSleepingProfileBuff = "sd_t_sp_nightowl"
				sleepData.currentSleepingProfile = "nightowl"
				goto continue
			end
		end
		
		-- insomniac
		do
			local sleepScore = 0
			local sleepThreshold = 3
			
			if sleepData.currentSleepingProfile == "insomniac" then
				-- log "easy insomniac"
				sleepThreshold = 5
			end
			
			--sleeping avg?
			for hour = 1, 24 do
				sleepScore = sleepScore + sleepData.sleepingCycle[hour]
			end
			if minute%60 == 0 then
				log(3, "insomniac:  slept",sleepScore, "/", sleepThreshold)
			end
			if sleepScore < sleepThreshold then
				types.Actor.spells(self):add("sd_t_sp_insomniac")
				sleepData.currentSleepingProfileBuff = "sd_t_sp_insomniac"
				isInsomniac = true
				sleepData.currentSleepingProfile = "insomniac"
				goto continue
			end
		end
		-- nothing applied:
		sleepData.currentSleepingProfile = nil
		
		::continue::
		if minute%60 == 0 then
			log(5, "set sleep profile", sleepData.currentSleepingProfile)
		end
		---------------------
	else
		sleepData.currentSleepingProfile = nil
	end
	if not isInsomniac then

		local suffix = ""
		if saveData.countCompanions >= 1 then
			suffix = "_c"
		end
		if NEEDS_SEVERITY_TIREDNESS == "Hard" then
			suffix = "_2"
		end
		if NEEDS_SEVERITY_TIREDNESS == "Hardcore" then
			suffix = "_3"
		end
		--if saveData.specialCompanion then
		--	suffix = "_n"
		--end
		
		sleepData.tirednessLevel = math.max(0, math.floor(sleepData.tiredness * 6 - 0.00001))
		
		-- remove severitiy suffixes (_2 and _3) for positive buffs (level 0-2)
		-- note: no companion buffs on hardcore
		

		
		if sleepData.tirednessLevel <= 3 and (suffix == "_2" or suffix == "_3") then
			suffix = ""
		end
		
		local buff = "sd_tiredness_"..sleepData.tirednessLevel..suffix
		sleepData.currentTirednessBuff = buff
		types.Actor.spells(self):add(buff)

	end
	updateWidget()
end


table.insert(perMinuteJobs, module_sleep_minute)


local function onLoad(originalData)
	if not NEEDS_TIREDNESS then return end
	if not saveData.m_sleep then
		saveData.m_sleep = {
			sleepingCycle = {0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5},
			tiredness = (1/6),
			recentCuddles = 0
			--currentTirednessBuff = nil,
			--currentSleepingProfileBuff = nil,
			--currentSleepingProfile = nil
		}
	end
	sleepData = saveData.m_sleep
	
	-- migration:
	if not sleepData.tirednessLevel then
		sleepData.tirednessLevel = 1
	end
	-- 1/6 = 0% alpha ; 2/6 = 20% alpha ; 3/6 = 40% alpha ; 4/6 = 60% alpha ; 5/6 = 80% alpha ; 6/6 = 100% alpha
end

table.insert(onLoadJobs, onLoad)

table.insert(onLoadJobs, updateWidget)

local function settingsChanged(sectionName, setting, oldValue)
	if setting == "NEEDS_TIREDNESS" then
		if oldValue == false then
			onLoad()
		else
			removeBuffs()
			saveData.m_sleep = nil
			uiWidgets.m_sleep = nil
		end
	end
end
table.insert(settingsChangedJobs, settingsChanged)

local function onConsume(item)
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	if entry and entry.wakeValue then 
 		log(3, "item ID:  "..item.recordId.."  ;  item name: "..tostring(entry.localizedName).."  ;  wake value:  "..entry.wakeValue.."  ;  wake value2:  "..tostring(entry.wakeValue2))
		sleepData.tiredness = math.min(1, math.max(0, sleepData.tiredness - entry.wakeValue/200*WAKEVALUE_MULT)) -- would be 100 but i balanced spreadsheet around this
		
		if entry.wakeValue2 and entry.wakeValue2 > 0 then
			sleepData.longLastingMagnitude = entry.wakeValue2/360*WAKEVALUE_MULT
			sleepData.longLastingDuration = 360
		end
		
		
		local clockHour = math.floor((saveData.lastUpdate / 60 + CLOCK_OFFSET))%24
		if clockHour == 0 then 
			clockHour = 24
		end
		module_sleep_minute(clockHour, 1, 0)
 	end
--		core.sendGlobalEvent("SunsDusk_WaterBottles_downgradeWaterItem", {
--			item = item,
--			player = self,
--		})
end
table.insert(onConsumeJobs, onConsume)



--[[
demo:
0.8
1
1
1
1 awake -0.2 = 0.8
1 sleep +0.2 = 1
0 sleep +0.2 = 0.2
0 sleep +0.2 = 0.2
0 sleep +0.2 = 0.2
0 sleep +0.2 = 0.2
0 sleep +0.2 = 0.2
0 sleep +0.2 = 0.2
0 awake -0.2 = 0
0 awake -0.2 = 0
0 ...
1
1
0
0
0
0.88
0.88
0.88
0.88
]]