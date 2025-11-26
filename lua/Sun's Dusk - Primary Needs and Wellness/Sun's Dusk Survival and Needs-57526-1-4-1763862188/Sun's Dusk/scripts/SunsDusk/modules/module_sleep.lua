
--gmsts
local fRestMagicMult	 = core.getGMST("fRestMagicMult")
local fFatigueReturnBase = core.getGMST("fFatigueReturnBase")
local fFatigueReturnMult = core.getGMST("fFatigueReturnMult")
local fEndFatigueMult	= core.getGMST("fEndFatigueMult")
local fEncumbranceStrMult = core.getGMST("fEncumbranceStrMult")

local sleepData

-- Widget element references (created once, updated as needed)
local tirednessIcon = nil
local tirednessBackground = nil
local tirednessWidget = nil
local profileIcon = nil
local profileBackground = nil
local profileWidget = nil

-- State tracking for conditional updates
local lastTirednessLevel = nil
local lastTirednessValue = nil
local lastTirednessAlpha = nil
local lastSleepingProfile = nil

local function removeBuffs()
	if not sleepData then return end
	if sleepData.currentTirednessBuff and core.magic.spells.records[sleepData.currentTirednessBuff] then 
		log(5, "removing", sleepData.currentTirednessBuff, core.magic.spells.records[sleepData.currentTirednessBuff])
		typesActorSpellsSelf:remove(sleepData.currentTirednessBuff) 
	end
	if sleepData.currentSleepingProfileBuff and core.magic.spells.records[sleepData.currentSleepingProfileBuff] then 
		log(5, "removing", sleepData.currentSleepingProfileBuff, core.magic.spells.records[sleepData.currentSleepingProfileBuff])
		typesActorSpellsSelf:remove(sleepData.currentSleepingProfileBuff) 
	end
	
-- sleeping 8 hours during your sleep personality takes you from exhausted -> well-rested--message boxes: morning->night, no longer morning person ... enjoy night time // night->morning, no longer enjoy the darkness ... you are a morning person // night or morning -> insomniac, after days of little sleep, you find yourself not [whatever]

-- mwscript check for Dagoth Ur nightmares
-- going to sleep hungry and/or thirsty reduces sleep quality
-- sleeping for more than 12 hrs per day reduces sleep quality
end

-- Destroy UI elements (for cleanup/reset)
function G_destroySleepUi()
	tirednessIcon = nil
	tirednessBackground = nil
	profileIcon = nil
	profileBackground = nil
	
	if tirednessWidget then
		tirednessWidget:destroy()
		tirednessWidget = nil
	end
	if profileWidget then
		profileWidget:destroy()
		profileWidget = nil
	end
	
	if G_columnWidgets then
		if G_columnWidgets.m_sleep then
			G_columnWidgets.m_sleep:destroy()
			G_columnWidgets.m_sleep = nil
		end
		if G_columnWidgets.m_sleep_profile then
			G_columnWidgets.m_sleep_profile:destroy()
			G_columnWidgets.m_sleep_profile = nil
		end
	end
	
	lastTirednessLevel = nil
	lastTirednessValue = nil
	lastTirednessAlpha = nil
	lastSleepingProfile = nil
	G_columnsNeedUpdate = true
end
table.insert(G_destroyHudJobs, G_destroySleepUi)



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




local function updateWidget()
	if not NEEDS_TIREDNESS then return end

	-- Initialize G_columnWidgets if needed
	if not G_columnWidgets then
		G_columnWidgets = {}
	end

	local skinData = iconPacks.sleep[S_SKIN]
	
	-- ===== SLEEPING PROFILE WIDGET =====
	if sleepData.currentSleepingProfile and S_SP_DISPLAY then
		local sleepProfileTexture = getTexture(skinData.base.."sleep_"..sleepData.currentSleepingProfile..skinData.extension)
		local profileOrder = sleepData.currentSleepingProfile == "insomniac" and "needs-sleep" or "profiles-sleep"
		
		-- Initialize profile widget if it doesn't exist
		if not profileWidget then
			profileBackground = S_BACKGROUND ~= "No Background" and {
				name = "profile_background",
				type = ui.TYPE.Image,
				props = {
					resource = S_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or sleepProfileTexture,
					color = S_BACKGROUND == "Classic" and S_BACKGROUND_COLOR or util.color.rgb(0,0,0),
					tileH = false,
					tileV = false,
					relativeSize = v2(1,1),
					relativePosition = S_BACKGROUND == "Shadow" and v2(0.04,0.027) or nil,
					alpha = 1,
				}
			} or {}
			
			profileIcon = {
				name = "profile_icon",
				type = ui.TYPE.Image,
				props = {
					resource = sleepProfileTexture,
					color = S_COLOR,
					tileH = false,
					tileV = false,
					relativeSize = v2(1,1),
					alpha = 1,
				}
			}
			
			profileWidget = ui.create{
				name = "m_sleep_profile",
				type = ui.TYPE.Widget,
				props = {
					size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE),
				},
				order = profileOrder,
				content = ui.content {
					profileBackground,
					profileIcon,
				}
			}
			
			G_columnWidgets.m_sleep_profile = profileWidget
			lastSleepingProfile = sleepData.currentSleepingProfile
			G_columnsNeedUpdate = true
		end
		
		-- Update profile widget if sleeping profile changed
		local needsProfileUpdate = false
		if lastSleepingProfile ~= sleepData.currentSleepingProfile then
			profileIcon.props.resource = sleepProfileTexture
			if S_BACKGROUND ~= "No Background" and S_BACKGROUND ~= "Classic" and profileBackground then
				profileBackground.props.resource = sleepProfileTexture
			end
			-- Update order if changed (insomniac vs normal)
			if profileWidget.layout.order ~= profileOrder then
				profileWidget.layout.order = profileOrder
				G_columnsNeedUpdate = true
			end
			lastSleepingProfile = sleepData.currentSleepingProfile
			needsProfileUpdate = true
		end
		
		-- Update tooltip
		local tooltipStr = tooltips[sleepData.currentSleepingProfileBuff] or "ERROR: "..tostring(sleepData.currentSleepingProfileBuff)
		addTooltip(profileWidget.layout, tooltipStr)
		
		if needsProfileUpdate then
			profileWidget:update()
		end
		
	elseif profileWidget then
		-- Remove profile widget if no longer needed
		profileWidget:destroy()
		profileWidget = nil
		profileIcon = nil
		profileBackground = nil
		if G_columnWidgets.m_sleep_profile then
			G_columnWidgets.m_sleep_profile = nil
			G_columnsNeedUpdate = true
		end
		lastSleepingProfile = nil
	end
	
	-- ===== MAIN TIREDNESS WIDGET =====
	-- Only show tiredness widget if not insomniac
	if sleepData.currentSleepingProfile ~= "insomniac" then
		-- Calculate current values
		local currentTirednessLevel = math.max(0, math.floor(sleepData.tiredness * skinData.stages - 0.00001))
		local currentAlpha = HUD_ALPHA == "Static" and 1 or getWidgetAlpha(sleepData.tiredness)
		local bgAlpha = S_BACKGROUND == "Classic" and (HUD_ALPHA == "Static" and 1 or currentAlpha^2) or 0.5
		
		-- Determine texture
		local tirednessTexture
		if skinData.stages > 1 then
			tirednessTexture = getTexture(skinData.base.."sleep_"..currentTirednessLevel..skinData.extension)
		else
			tirednessTexture = getTexture(skinData.base.."sleep"..skinData.extension)
		end
		
		-- Initialize widget if it doesn't exist
		if not tirednessWidget then
			tirednessBackground = S_BACKGROUND ~= "No Background" and {
				name = "tiredness_background",
				type = ui.TYPE.Image,
				props = {
					resource = S_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or tirednessTexture,
					color = S_BACKGROUND == "Classic" and S_BACKGROUND_COLOR or util.color.rgb(0,0,0),
					tileH = false,
					tileV = false,
					relativeSize = v2(1,1),
					relativePosition = S_BACKGROUND == "Shadow" and v2(0.04,0.027) or nil,
					alpha = bgAlpha,
				}
			} or {}
			
			tirednessIcon = {
				name = "tiredness_icon",
				type = ui.TYPE.Image,
				props = {
					resource = tirednessTexture,
					color = S_COLOR,
					tileH = false,
					tileV = false,
					relativeSize = v2(1,1),
					alpha = currentAlpha,
				}
			}
			
			tirednessWidget = ui.create{
				name = "m_sleep",
				type = ui.TYPE.Widget,
				props = {
					size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE),
				},
				order = "needs-sleep",
				content = ui.content {
					tirednessBackground,
					tirednessIcon,
				}
			}
			
			G_columnWidgets.m_sleep = tirednessWidget
			
			-- Initialize tracking variables
			lastTirednessLevel = currentTirednessLevel
			lastTirednessValue = sleepData.tiredness
			lastTirednessAlpha = currentAlpha
			
			G_columnsNeedUpdate = true
		end
		
		-- Check if we need to update
		local needsUpdate = false
		
		-- Update icon texture if tiredness level changed
		if lastTirednessLevel ~= currentTirednessLevel then
			tirednessIcon.props.resource = tirednessTexture
			lastTirednessLevel = currentTirednessLevel
			needsUpdate = true
			
			-- Update background texture if not using Classic style
			if S_BACKGROUND ~= "No Background" and S_BACKGROUND ~= "Classic" and tirednessBackground then
				tirednessBackground.props.resource = tirednessTexture
			end
		end
		
		-- Update alpha if it changed
		if lastTirednessAlpha ~= currentAlpha then
			tirednessIcon.props.alpha = currentAlpha
			lastTirednessAlpha = currentAlpha
			needsUpdate = true
			
			-- Update background alpha if using Classic style
			if S_BACKGROUND == "Classic" and tirednessBackground then
				tirednessBackground.props.alpha = HUD_ALPHA == "Static" and 1 or currentAlpha^2
			end
		end
		
		local tooltipStr = math.floor(sleepData.tiredness*100).."%\n"
		if sleepData.longLastingDuration then
			tooltipStr = tooltipStr.."Well fed: "..formatTimeLeft(sleepData.longLastingDuration).."\n"
		end
		tooltipStr = tooltipStr..(not sleepData.currentTirednessBuff and "" or tooltips[sleepData.currentTirednessBuff] or "ERROR: "..tostring(sleepData.currentTirednessBuff))
		if lastTooltipStr ~= tooltipStr then
			lastTooltipStr = tooltipStr
			addTooltip(tirednessWidget.layout, tooltipStr)
			needsUpdate = true
		end
		
		-- Only call update if something actually changed
		if needsUpdate then
			tirednessWidget:update()
		end
		
	elseif tirednessWidget then
		-- Remove tiredness widget if player is now insomniac
		tirednessWidget:destroy()
		tirednessWidget = nil
		tirednessIcon = nil
		tirednessBackground = nil
		if G_columnWidgets.m_sleep then
			G_columnWidgets.m_sleep = nil
			G_columnsNeedUpdate = true
		end
		lastTirednessLevel = nil
		lastTirednessValue = nil
		lastTirednessAlpha = nil
	end
end

table.insert(G_refreshWidgetJobs, updateWidget)

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
	
	
	--if NEEDS_TIREDNESS_BUFFS then -- prevent tiredness from going above 0.5 (tirednesslevel 3 starts at 0.5 or so)
	--	sleepData.tiredness = math.min(1-3/6-0.0001, sleepData.tiredness)
	--end

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
				G_addSpellWhenAwake("sd_t_sp_morninglark")
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
				G_addSpellWhenAwake("sd_t_sp_nightowl")
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
				G_addSpellWhenAwake("sd_t_sp_insomniac")
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
		if saveData.countCompanions >= 1 and NEEDS_TIREDNESS_COMPANION then
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
		
		if NEEDS_TIREDNESS_BUFFS_DEBUFFS == "Only buffs" and sleepData.tirednessLevel <= 2 
		or NEEDS_TIREDNESS_BUFFS_DEBUFFS == "Only debuffs" and sleepData.tirednessLevel >= 3 
		or NEEDS_TIREDNESS_BUFFS_DEBUFFS == "Buffs and debuffs" then
			local buff = "sd_tiredness_"..sleepData.tirednessLevel..suffix
			sleepData.currentTirednessBuff = buff
			G_addSpellWhenAwake(buff)
		end
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
			G_destroySleepUi()
		end
	elseif setting == "S_BACKGROUND" then
		G_destroySleepUi()
	end
end
table.insert(settingsChangedJobs, settingsChanged)

local function onConsume(item)
	if not NEEDS_TIREDNESS then return end
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	if entry and entry.wakeValue and entry.wakeValue ~= 0 then 
 		log(3, "item ID:  "..item.recordId.."  ;  item name: "..tostring(item.type.record(item).name).."  ;  wake value:  "..entry.wakeValue.."  ;  wake value2:  "..tostring(entry.wakeValue2))
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