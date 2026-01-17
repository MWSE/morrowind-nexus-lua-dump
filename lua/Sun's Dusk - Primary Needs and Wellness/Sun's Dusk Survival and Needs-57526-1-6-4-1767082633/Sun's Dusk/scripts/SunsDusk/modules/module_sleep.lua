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

-- Well rested overlay reference
local wellRestedIcon = nil
local lastWellRestedTier = nil

-- Returns bed quality rank: nil = floor, 1.5 = bedroll/stolen, 2.9 = owned/tent
-- TODO: implement actual bed detection logic
local function getBedRank()
	if not G_currentBed then return nil end
	-- placeholder: return 2.9 for any bed
	if G_currentBed.recordId == "sd_campingobject_bedrolltent" or G_currentBed.recordId == "campingGear_bedroll" then
		return 2.9
	elseif G_currentBed.recordId == "sd_campingobject_bedroll" then
		return 2
	elseif G_currentBed.owner.recordId then
		return 1.5
	elseif G_currentBed.owner.factionId and types.NPC.getFactionRank(self, G_currentBed.owner.factionId) == 0 then
		return 1.5
	elseif G_currentBed.owner.factionId and types.NPC.getFactionRank(self, G_currentBed.owner.factionId) < G_currentBed.owner.factionRank then
		return 1.5
	end
	return 2.9
end

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
	wellRestedIcon = nil
	
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
	lastWellRestedTier = nil
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
	if not sleepData then return end

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
		local wellRestedColor
		if skinData.stages > 1 then
			tirednessTexture = getTexture(skinData.base.."sleep_"..currentTirednessLevel..skinData.extension)
			local tint = 0.35-currentTirednessLevel * 0.07
			local hue = tint / 1.05
			wellRestedColor = util.color.rgb(hsvToRgb(hue, 1.0, 1.0))
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
			
			wellRestedIcon = {
				name = "wellrested_icon",
				type = ui.TYPE.Image,
				props = {
					resource = getTexture("textures/SunsDusk/well_rested.png"),
					color = wellRestedColor or S_COLOR,
					tileH = false,
					tileV = false,
					relativeSize = v2(0.4, 0.4),
					relativePosition = v2(0.6, 0),
					alpha = sleepData.wellRestedPool > 0 and 1 or 0,
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
					wellRestedIcon,
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
		
		-- Update well rested icon visibility
		local wellRestedVisible = sleepData.wellRestedPool > 0 and math.min(1, 0.3 + sleepData.wellRestedPool*2*0.7)*currentAlpha or 0
		if lastWellRestedTier ~= wellRestedVisible then
			wellRestedIcon.props.alpha = wellRestedVisible
			lastWellRestedTier = wellRestedVisible
			needsUpdate = true
		end
		wellRestedIcon.props.color = wellRestedColor
		
		local tooltipStr = math.floor(sleepData.tiredness*100).."%\n"
		if sleepData.longLastingDuration then
			tooltipStr = tooltipStr.."Well fed: "..formatTimeLeft(sleepData.longLastingDuration).."\n"
		end
		if sleepData.wellRestedPool > 0 then
			local avgBedRank = sleepData.wellRestedBedRankWeighted / sleepData.wellRestedPool
			local tierName = math.floor(avgBedRank) >= 2 and "Well Rested" or "Rested"
			local minutesRemaining = sleepData.wellRestedPool * HOURS_PER_RESTED_STATE * 6 * 60 / 1.5
			tooltipStr = tooltipStr..tierName..": "..formatTimeLeft(minutesRemaining).." (+"..f1(avgBedRank * 5).."%)\n"
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
		wellRestedIcon = nil
		if G_columnWidgets.m_sleep then
			G_columnWidgets.m_sleep = nil
			G_columnsNeedUpdate = true
		end
		lastTirednessLevel = nil
		lastTirednessValue = nil
		lastTirednessAlpha = nil
		lastWellRestedTier = nil
	end
end

table.insert(G_refreshWidgetJobs, updateWidget)


--only used for the print (for now?)
local combinedPersonalities = {
    [1] = "M ",   -- M + space
    [2] = "M ",
    [3] = "M ",
    [4] = "M ",
    [5] = "M ",
    [6] = "M ",
    [7] = "  ",   -- space + space
    [8] = "  ",
    [9] = " N",   -- space + N
    [10] = " N",
    [11] = " N",
    [12] = " N",
    [13] = " N",
    [14] = " N",
    [15] = " N",
    [16] = " N",
    [17] = " N",
    [18] = " N",
    [19] = " N",
    [20] = "M ",  -- M + space
    [21] = "M ",
    [22] = "M ",
    [23] = "M ",
    [24] = "M ",
}


-- executed every hour (debug print only, cycle updated in minute function)
local function module_sleep_hour(clockHour)
	if not sleepData then return end
	for i,v in pairs(sleepData.sleepingCycle) do --for index, value
		if i == clockHour then
			if i < 10 then
				log(4, tostring(combinedPersonalities[i]).."  ".."["..i.."]".. " =  ".. tostring(v))
			else
				log(4, tostring(combinedPersonalities[i]).." ".."["..i.."]".. " =  ".. tostring(v))
			end
		else
			if i < 10 then
				log(4, tostring(combinedPersonalities[i]).."   "..i.. "  =  ".. tostring(v))
			else
				log(4, tostring(combinedPersonalities[i]).."  "..i.. "  =  ".. tostring(v))
			end
		end
	end
end

table.insert(G_perHourJobs, module_sleep_hour)

-- Returns a graduated score (0 to 1.25) based on how close value is to threshold
-- @param value: the value to check
-- @param operator: comparison operator string (">" or "<")
-- @param threshold: the threshold to compare against
-- @return: 1.0-1.25 if exceeding threshold (bonus), 0.8-1.0 if slightly below, down to 0 if 0.4+ below
local function getGraduatedScore(value, operator, threshold)
	-- Calculate how far we are from passing the threshold
	-- Positive diff = failing, negative diff = exceeding
	local diff
	if operator == ">" then
		diff = threshold - value  -- for >= checks: higher value is better
	elseif operator == "<" then
		diff = value - threshold  -- for <= checks: lower value is better
	else
		error("Invalid operator: " .. tostring(operator) .. ". Use '>=' or '<='")
	end
	
	if diff <= 0 then
		-- Exceeding threshold: award bonus up to 25%
		-- 0.625 multiplier means you hit max bonus (+0.25) at 0.4 past threshold
		return 1.0 + math.min(0.25, (-diff) * 0.625)
	elseif diff >= 0.4 then
		-- Too far below threshold: no score
		return 0
	else
		-- Graduated falloff zone (0 to 0.4 below threshold)
		-- Exponential decay: 0.1 below → ~0.8, 0.2 below → ~0.4, 0.3 below → ~0.2
		return math.min(1.0, 1.6 * math.pow(0.5, diff / 0.1))
	end
end

-- Same as getGraduatedScore but applies a penalty when failing the threshold
-- @param value: the value to check
-- @param operator: comparison operator string (">" or "<")
-- @param threshold: the threshold to compare against
-- @param penalty: penalty multiplier applied when failing
-- @return: same as getGraduatedScore when passing, but blends in negative penalty when failing
local function getGraduatedScoreWithPenalty(value, operator, threshold, penalty)
	local diff
	if operator == ">" then
		diff = threshold - value
	elseif operator == "<" then
		diff = value - threshold
	else
		error("Invalid operator: " .. tostring(operator) .. ". Use '>=' or '<='")
	end
	
	if diff <= 0 then
		-- Exceeding threshold: same bonus as non-penalty version
		return 1.0 + math.min(0.25, (-diff) * 0.625)
	elseif diff >= 0.4 then
		-- Completely failing: full penalty
		return -penalty
	else
		-- Partial fail zone: blend between partial score and partial penalty
		-- As passScore decreases (more failing), penalty portion increases
		-- Example with penalty=3, diff=0.1: passScore=0.8, result = 0.8 - 0.2*3 = 0.2
		-- Example with penalty=3, diff=0.2: passScore=0.4, result = 0.4 - 0.6*3 = -1.4
		local passScore = math.min(1.0, 1.6 * math.pow(0.5, diff / 0.1))
		return passScore - (1 - passScore) * penalty
	end
end



local function module_sleep_minute(clockHour, minute, minutesPassed)
	if not sleepData then return end
	--if not sleepData then return end
	local tirednessPrior = sleepData.tiredness
	if G_isLongTravel then
		if sleepData.currentSleepingProfile ~= "insomniac" then
			sleepData.tiredness = 0.2
		end
		sleepData.wellRestedPool = 0
		sleepData.wellRestedBedRankWeighted = 0
	elseif G_isSleeping then
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
		
		-- Well rested: accumulate or drain based on bed quality
		local bedRank = getBedRank() -- returns nil, 1.5 or 2.9
		local theoreticalRecovery = 2/HOURS_PER_RESTED_STATE/6/60*minutesPassed
		if bedRank then
			-- Ranked bed: add to well rested pool (up to 30% bonus for sleeping in your cycle)
			local cycleBonus = 1 + 0.3 * sleepData.sleepingCycle[clockHour]
			bedRank = bedRank * cycleBonus
			local contribution = theoreticalRecovery * cycleBonus
			local oldPool = sleepData.wellRestedPool
			sleepData.wellRestedPool = math.min(0.5, sleepData.wellRestedPool + contribution)
			local actualContribution = sleepData.wellRestedPool - oldPool
			sleepData.wellRestedBedRankWeighted = sleepData.wellRestedBedRankWeighted + (actualContribution * bedRank) -- never exceeds 1.45 ?
		else
			 
			-- Floor sleep: drain at half rate
			local drainAmount = 0.5/HOURS_PER_RESTED_STATE/6/60*minutesPassed
			local newPool = math.max(0, sleepData.wellRestedPool - drainAmount)
			local ratio = sleepData.wellRestedPool > 0 and (newPool / sleepData.wellRestedPool) or 0
			sleepData.wellRestedPool = newPool
			sleepData.wellRestedBedRankWeighted = sleepData.wellRestedBedRankWeighted * ratio
		end
	else
		sleepData.tiredness = math.min(1, sleepData.tiredness + 1/HOURS_PER_RESTED_STATE/6/60*minutesPassed)
		log(5, tostring(minutesPassed).."m passed  ;  currently not sleeping at ...  "..clockHour..":00  ;  current tiredness is: "..f2(sleepData.tiredness).." ; gained  "..f2(sleepData.tiredness -tirednessPrior ))
		
		-- Well rested: drain at 1.5x awake rate
		local drainAmount = 1.5/HOURS_PER_RESTED_STATE/6/60*minutesPassed
		local newPool = math.max(0, sleepData.wellRestedPool - drainAmount)
		local ratio = sleepData.wellRestedPool > 0 and (newPool / sleepData.wellRestedPool) or 0
		sleepData.wellRestedPool = newPool
		sleepData.wellRestedBedRankWeighted = sleepData.wellRestedBedRankWeighted * ratio
	end
	
	-- Update sleeping cycle: distribute across hours based on time spent
	if minutesPassed > 0 then
		local cycleChangePerHour = 0.2
		local cycleDelta = G_isSleeping and cycleChangePerHour or -cycleChangePerHour
		
		local currentMinuteOfHour = minute % 60
		local remaining = minutesPassed
		local hour = clockHour
		local posInHour = currentMinuteOfHour
		
		-- If at minute 0, we haven't spent time in this hour yet
		if posInHour == 0 then
			hour = hour - 1
			if hour < 1 then hour = 24 end
			posInHour = 60
		end
		
		while remaining > 0 do
			local timeInThisHour = math.min(remaining, posInHour)
			local fraction = timeInThisHour / 60
			--print(hour .." gets ".. cycleDelta * fraction)
			sleepData.sleepingCycle[hour] = math.max(0, math.min(1, sleepData.sleepingCycle[hour] + cycleDelta * fraction))
			
			remaining = remaining - timeInThisHour
			hour = hour - 1
			if hour < 1 then hour = 24 end
			posInHour = 60
		end
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
			
			local awakeThreshold = 0.2
			local sleepThreshold = 0.8
			
			local wakeupPenalty = 3
			local stayupPenalty = 1
			
			if sleepData.currentSleepingProfile == "morninglark" then
				--log "easy morninglark"
				awakeThreshold = 0.3
				sleepThreshold = 0.7
				neededAwakeHoursInTimespan = 8
				neededSleepingHoursInTimespan = 6
				wakeupPenalty = 2
			end
			awakeThreshold = awakeThreshold +0.01
			sleepThreshold = sleepThreshold -0.01
			
			--sleeping?
			for hour = 20, 22 do
				sleepingHoursInTimespan = sleepingHoursInTimespan + getGraduatedScore(sleepData.sleepingCycle[hour], ">", sleepThreshold)
			end
			for hour = 23, 24 do
				sleepingHoursInTimespan = sleepingHoursInTimespan + getGraduatedScoreWithPenalty(sleepData.sleepingCycle[hour], ">", sleepThreshold, stayupPenalty)
			end
			for hour = 1, 6 do
				sleepingHoursInTimespan = sleepingHoursInTimespan + getGraduatedScore(sleepData.sleepingCycle[hour], ">", sleepThreshold)
			end
			
			--awake?
			for hour = 7, 8 do
				awakeHoursInTimespan = awakeHoursInTimespan + getGraduatedScore(sleepData.sleepingCycle[hour], "<", awakeThreshold)
			end
			for hour = 9, 11 do
				awakeHoursInTimespan = awakeHoursInTimespan + getGraduatedScoreWithPenalty(sleepData.sleepingCycle[hour], "<", awakeThreshold, wakeupPenalty)
			end
			for hour = 12, 19 do
				awakeHoursInTimespan = awakeHoursInTimespan + getGraduatedScore(sleepData.sleepingCycle[hour], "<", awakeThreshold)
			end
			if minute%60 == 0 or minutesPassed > 50 then
				log(3, "morninglark:  slept", f1dot(sleepingHoursInTimespan), "/", neededSleepingHoursInTimespan)
				log(3, "morninglark:  awake", f1dot(awakeHoursInTimespan), "/", neededAwakeHoursInTimespan)
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
			
			local awakeThreshold = 0.2
			local sleepThreshold = 0.8
			
			local wakeupPenalty = 3
			local stayupPenalty = 1

			if sleepData.currentSleepingProfile == "nightowl" then
				-- log "easy nightowl"
				awakeThreshold = 0.3
				sleepThreshold = 0.7
				neededAwakeHoursInTimespan = 8
				neededSleepingHoursInTimespan = 6
				wakeupPenalty = 2
			end
			
			awakeThreshold = awakeThreshold +0.01
			sleepThreshold = sleepThreshold -0.01
			
			--sleeping?
			for hour = 9, 11 do
				sleepingHoursInTimespan = sleepingHoursInTimespan + getGraduatedScore(sleepData.sleepingCycle[hour], ">", sleepThreshold)
			end
			for hour = 12, 13 do
				sleepingHoursInTimespan = sleepingHoursInTimespan + getGraduatedScoreWithPenalty(sleepData.sleepingCycle[hour], ">", sleepThreshold, stayupPenalty)
			end
			for hour = 14, 19 do
				sleepingHoursInTimespan = sleepingHoursInTimespan + getGraduatedScore(sleepData.sleepingCycle[hour], ">", sleepThreshold)
			end
			
			--awake?
			for hour = 20, 21 do
				awakeHoursInTimespan = awakeHoursInTimespan + getGraduatedScore(sleepData.sleepingCycle[hour], "<", awakeThreshold)
			end
			for hour = 22, 24 do
				awakeHoursInTimespan = awakeHoursInTimespan + getGraduatedScoreWithPenalty(sleepData.sleepingCycle[hour], "<", awakeThreshold, wakeupPenalty)
			end
			for hour = 1, 8 do
				awakeHoursInTimespan = awakeHoursInTimespan + getGraduatedScore(sleepData.sleepingCycle[hour], "<", awakeThreshold)
			end
			if minute%60 == 0 or minutesPassed > 50 then
				log(3, "nightowl:  slept",f1dot(sleepingHoursInTimespan), "/", neededSleepingHoursInTimespan)
				log(3, "nightowl:  awake",f1dot(awakeHoursInTimespan), "/", neededAwakeHoursInTimespan)
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
			if minute%60 == 0 or minutesPassed > 50 then
				log(3, "insomniac:  slept",f1dot(sleepScore), "/", sleepThreshold)
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
		if minute%60 == 0 or minutesPassed > 50 then
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


table.insert(G_perMinuteJobs, module_sleep_minute)


local function onLoad(originalData)
	if not NEEDS_TIREDNESS then return end
	if not saveData.m_sleep then
		saveData.m_sleep = {
			sleepingCycle = {0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5},
			tiredness = (1/6),
			recentCuddles = 0,
			wellRestedPool = 0,
			wellRestedBedRankWeighted = 0,
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
	if not sleepData.wellRestedPool then
		sleepData.wellRestedPool = 0
		sleepData.wellRestedBedRankWeighted = 0
	end
	-- 1/6 = 0% alpha ; 2/6 = 20% alpha ; 3/6 = 40% alpha ; 4/6 = 60% alpha ; 5/6 = 80% alpha ; 6/6 = 100% alpha
end

table.insert(G_onLoadJobs, onLoad)

table.insert(G_onLoadJobs, updateWidget)

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
table.insert(G_settingsChangedJobs, settingsChanged)

local function onConsume(item)
	if not sleepData then return end
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	if entry and entry.wakeValue and entry.wakeValue ~= 0 then 
		sleepData.tiredness = math.min(1, math.max(0, sleepData.tiredness - entry.wakeValue/200*WAKEVALUE_MULT)) -- would be 100 but i balanced spreadsheet around this
		
		if entry.wakeValue2 and entry.wakeValue2 > 0 then
			sleepData.longLastingMagnitude = entry.wakeValue2/360*WAKEVALUE_MULT
			sleepData.longLastingDuration = 360
		end
		
		
		local clockHour = math.floor((saveData.lastUpdate / 60 + G_clockOffset))%24
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
table.insert(G_onConsumeJobs, onConsume)



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

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if sleepData and sleepData.wellRestedPool > 0 then
		--print(1, skillId, table.concat(params, " "))
		--for a,b in pairs(params) do print(a,b) end
		local avgBedRank = sleepData.wellRestedBedRankWeighted / sleepData.wellRestedPool
		if avgBedRank >= 1 then
			params.skillGain = params.skillGain * (1 + avgBedRank * 0.05)
			--print(skillId, "x"..f2(1 + avgBedRank * 0.05))
		end
	end
end)