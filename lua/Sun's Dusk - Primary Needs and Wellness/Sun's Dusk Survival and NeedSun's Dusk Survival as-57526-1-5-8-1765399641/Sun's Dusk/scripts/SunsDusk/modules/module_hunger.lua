-- 0.50 exclusive: using absorb health as a vampire restores hunger // rend flesh for werewolves: using claws in combat restores hunger

-- diseases:
-- slaughterfish : ataxia ; greenspore
-- nix hound : dampworm ; rattles
-- cliff-racer : helljoint
-- alit : rockjoint
-- guar : rockjoint
-- rat : rust chancre ; witbane
-- dreugh : wither
-- kagouti : yellow tick

-- ─── helpers ───
commonDiseaseOnConsume = {
	"ataxia",
	"dampworm",
	"greenspore",
	"helljoint",
	"rattles",
	"rockjoint",
	"rust chancre",
	"witbane",
	"wither",
	"yellow tick",
}

local hungerData

-- Widget element references (created once, updated as needed)
local hungerIcon = nil
local hungerBackground = nil
local hungerWidget = nil
local profileIcon = nil
local profileBackground = nil
local profileWidget = nil

-- State tracking for conditional updates
local lastHungerLevel = nil
local lastHungerValue = nil
local lastHungerAlpha = nil
local lastFoodProfile = nil
local lastTooltipStr = nil

-- Destroy UI elements (for cleanup/reset)
function G_destroyHungerUi()
	hungerIcon = nil
	hungerBackground = nil
	profileIcon = nil
	profileBackground = nil
	
	if hungerWidget then
		hungerWidget:destroy()
		hungerWidget = nil
	end
	if profileWidget then
		profileWidget:destroy()
		profileWidget = nil
	end
	
	if G_columnWidgets then
		if G_columnWidgets.m_hunger then
			G_columnWidgets.m_hunger:destroy()
			G_columnWidgets.m_hunger = nil
		end
		if G_columnWidgets.m_hunger_profile then
			G_columnWidgets.m_hunger_profile:destroy()
			G_columnWidgets.m_hunger_profile = nil
		end
	end
	
	lastHungerLevel = nil
	lastHungerValue = nil
	lastHungerAlpha = nil
	lastFoodProfile = nil
	G_columnsNeedUpdate = true
end
table.insert(G_destroyHudJobs, G_destroyHungerUi)

local function buildSeveritySuffix()
	local suffix = ""
	if saveData.countCompanions >= 1 and NEEDS_HUNGER_COMPANION then
		suffix = "_c"
	end
	if NEEDS_SEVERITY_HUNGER == "Hard" then
		suffix = "_2"
	end
	if NEEDS_SEVERITY_HUNGER == "Hardcore" then
		suffix = "_3"
	end
	--if saveData.specialCompanion then
	--	suffix = "_n"
	--end
	return suffix
end

local function removeBuffs()
	if not hungerData then return end
	
	if hungerData.currentHungerBuff then
		local buff = hungerData.currentHungerBuff
		if core.magic.spells.records[buff] then
			typesActorSpellsSelf:remove(buff)
		else
			log(2, "[SunsDusk] Skipping removal of missing spell:", buff)
		end
	end
	if hungerData.currentFoodProfileBuff then
		local buff = hungerData.currentFoodProfileBuff
		if core.magic.spells.records[buff] then
			typesActorSpellsSelf:remove(buff)
		else
			log(2, "[SunsDusk] Skipping removal of missing spell:", buff)
		end
	end
end

local function updateWidget()
	if not NEEDS_HUNGER then return end

	-- Initialize G_columnWidgets if needed
	if not G_columnWidgets then
		G_columnWidgets = {}
	end

	local skinData = iconPacks.hunger[H_SKIN]
	
	-- ===== FOOD PROFILE WIDGET =====
	if hungerData.currentFoodProfile and H_SP_DISPLAY then
		local foodProfileTexture = getTexture(skinData.base.."hunger_"..hungerData.currentFoodProfile..skinData.extension)
		
		-- Initialize profile widget if it doesn't exist
		if not profileWidget then
			profileBackground = H_BACKGROUND ~= "No Background" and {
				name = "profile_background",
				type = ui.TYPE.Image,
				props = {
					resource = H_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or foodProfileTexture,
					color = H_BACKGROUND == "Classic" and H_BACKGROUND_COLOR or util.color.rgb(0,0,0),
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
					resource = foodProfileTexture,
					color = H_COLOR,
					tileH = false,
					tileV = false,
					relativeSize = v2(1,1),
					alpha = 1,
				}
			}
			
			profileWidget = ui.create{
				name = "m_hunger_profile",
				type = ui.TYPE.Widget,
				props = {
					size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE),
				},
				order = "profiles-hunger",
				content = ui.content {
					profileBackground,
					profileIcon,
				}
			}
			
			G_columnWidgets.m_hunger_profile = profileWidget
			lastFoodProfile = hungerData.currentFoodProfile
			G_columnsNeedUpdate = true
		end
		
		-- Update profile widget if food profile changed
		if lastFoodProfile ~= hungerData.currentFoodProfile then
			profileIcon.props.resource = foodProfileTexture
			if H_BACKGROUND ~= "No Background" and H_BACKGROUND ~= "Classic" and profileBackground then
				profileBackground.props.resource = foodProfileTexture
			end
			lastFoodProfile = hungerData.currentFoodProfile
			profileWidget:update()
		end
		
		-- Update tooltip
		local tooltipStr = tooltips[hungerData.currentFoodProfileBuff] or "ERROR: "..tostring(hungerData.currentFoodProfileBuff)
		addTooltip(profileWidget.layout, tooltipStr)
		
	elseif profileWidget then
		-- Remove profile widget if no longer needed
		profileWidget:destroy()
		profileWidget = nil
		profileIcon = nil
		profileBackground = nil
		if G_columnWidgets.m_hunger_profile then
			G_columnWidgets.m_hunger_profile = nil
			G_columnsNeedUpdate = true
		end
		lastFoodProfile = nil
	end
	
	-- ===== MAIN HUNGER WIDGET =====
	-- Calculate current values
	local currentHungerLevel = math.max(0, math.floor(hungerData.hunger * skinData.stages - 0.00001))
	local currentAlpha = HUD_ALPHA == "Static" and 1 or getWidgetAlpha(hungerData.hunger)
	local bgAlpha = H_BACKGROUND == "Classic" and (HUD_ALPHA == "Static" and 1 or currentAlpha^2) or 0.5
	
	-- Determine texture
	local hungerTexture
	if skinData.stages > 1 then
		hungerTexture = getTexture(skinData.base.."hunger_"..currentHungerLevel..skinData.extension)
	else
		hungerTexture = getTexture(skinData.base.."hunger"..skinData.extension)
	end
	
	-- Initialize widget if it doesn't exist
	if not hungerWidget then
		hungerBackground = H_BACKGROUND ~= "No Background" and {
			name = "hunger_background",
			type = ui.TYPE.Image,
			props = {
				resource = H_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or hungerTexture,
				color = H_BACKGROUND == "Classic" and H_BACKGROUND_COLOR or util.color.rgb(0,0,0),
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				relativePosition = H_BACKGROUND == "Shadow" and v2(0.04,0.027) or nil,
				alpha = bgAlpha,
			}
		} or {}
		
		hungerIcon = {
			name = "hunger_icon",
			type = ui.TYPE.Image,
			props = {
				resource = hungerTexture,
				color = H_COLOR,
				tileH = false,
				tileV = false,
				relativeSize = v2(1,1),
				alpha = currentAlpha,
			}
		}
		
		hungerWidget = ui.create{
			name = "m_hunger",
			type = ui.TYPE.Widget,
			props = {
				size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE),
			},
			order = "needs-hunger",
			content = ui.content {
				hungerBackground,
				hungerIcon,
			}
		}
		
		G_columnWidgets.m_hunger = hungerWidget
		
		-- Initialize tracking variables
		lastHungerLevel = currentHungerLevel
		lastHungerValue = hungerData.hunger
		lastHungerAlpha = currentAlpha
		
		G_columnsNeedUpdate = true
	end
	
	-- Check if we need to update
	local needsUpdate = false
	
	-- Update icon texture if hunger level changed
	if lastHungerLevel ~= currentHungerLevel then
		hungerIcon.props.resource = hungerTexture
		lastHungerLevel = currentHungerLevel
		needsUpdate = true
		
		-- Update background texture if not using Classic style
		if H_BACKGROUND ~= "No Background" and H_BACKGROUND ~= "Classic" and hungerBackground then
			hungerBackground.props.resource = hungerTexture
		end
	end
	
	-- Update alpha if it changed
	if lastHungerAlpha ~= currentAlpha then
		hungerIcon.props.alpha = currentAlpha
		lastHungerAlpha = currentAlpha
		needsUpdate = true
		
		-- Update background alpha if using Classic style
		if H_BACKGROUND == "Classic" and hungerBackground then
			hungerBackground.props.alpha = HUD_ALPHA == "Static" and 1 or currentAlpha^2
		end
	end
	
	local tooltipStr = math.floor(hungerData.hunger*100).."%\n"
	if hungerData.longLastingDuration then
		tooltipStr = tooltipStr.."Well fed: "..formatTimeLeft(hungerData.longLastingDuration).."\n"
	end
	tooltipStr = tooltipStr..(not hungerData.currentHungerBuff and "" or tooltips[hungerData.currentHungerBuff] or "ERROR: "..tostring(hungerData.currentHungerBuff))
	if lastTooltipStr ~= tooltipStr then
		lastTooltipStr = tooltipStr
		addTooltip(hungerWidget.layout, tooltipStr)
		needsUpdate = true
	end
	
	-- Only call update if something actually changed
	if needsUpdate then
		hungerWidget:update()
	end
end
table.insert(G_refreshWidgetJobs, updateWidget)

local function module_hunger_hour(clockHour)
	if not NEEDS_HUNGER then return end
	for i, entry in pairs(hungerData.foodProfiles) do
		if i ~= "Broken Pact" then
			hungerData.foodProfiles[i] = math.max(0, entry*0.95 - 0.03)
		end
	end
end
table.insert(G_perHourJobs, module_hunger_hour)

local function module_hunger_minute(clockHour, minute, minutesPassed)
	if not NEEDS_HUNGER then return end
	--if not hungerData then return end
	local hungerPrior = hungerData.hunger
	
	-- fast metabolism
	local raceConsumptionMult = 1
	if NEEDS_RACES_HUNGER then
		if saveData.playerInfo.isAltmer then
			raceConsumptionMult = raceConsumptionMult * 1.15
		elseif saveData.playerInfo.isRedguard then
			raceConsumptionMult = raceConsumptionMult * 1.1
		end
	end
	if G_isInJail then
		hungerData.hunger = 0.5
	else
		if G_isSleeping or G_isTravelling then
			-- hunger is always increasing
			hungerData.hunger = math.min(1, hungerData.hunger + 0.5/HOURS_PER_HUNGER_STATE/6/60*minutesPassed*raceConsumptionMult)
		else
			-- change sleeping cycle for current hour of being awake -0.2
			hungerData.hunger = math.min(1, hungerData.hunger + 1/HOURS_PER_HUNGER_STATE/6/60*minutesPassed*raceConsumptionMult)
		end
		if hungerData.longLastingDuration and minutesPassed > 0 then
			local availableDuration = math.min(hungerData.longLastingDuration, minutesPassed)
			restored = availableDuration * hungerData.longLastingMagnitude / 200
			hungerData.hunger = math.max(0, hungerData.hunger - restored)
			hungerData.longLastingDuration = hungerData.longLastingDuration - availableDuration
			if hungerData.longLastingDuration <= 0 then
				hungerData.longLastingDuration = nil
			end
		end
	end
	--if NEEDS_HUNGER_BUFFS then -- prevent hunger from going above 0.5 (hungerLevel 3 starts at 0.5 or so)
	--	hungerData.hunger = math.min(1-3/6-0.0001, hungerData.hunger)
	--end

	--apply new buff
	removeBuffs()
	hungerData.currentHungerBuff = nil
	hungerData.currentFoodProfile = nil
	hungerData.currentFoodProfileBuff = nil
	if NEEDS_HUNGER_NOURISHMENT then
		-- well nourished
		local foodProfile = nil
		local buff = nil
		
		local highestCategory = 0
		
		highestCategory = math.max(highestCategory, hungerData.foodProfiles["Very Small"])
		highestCategory = math.max(highestCategory, hungerData.foodProfiles["Light Meal"])
		highestCategory = math.max(highestCategory, hungerData.foodProfiles["Medium Meal"])
		highestCategory = math.max(highestCategory, hungerData.foodProfiles["Filling Meal"])
		highestCategory = math.max(highestCategory, hungerData.foodProfiles["Hearty Meal"])
		highestCategory = math.max(highestCategory, hungerData.foodProfiles["Raw Meat"])
		
		local countCategories = 0
		if hungerData.foodProfiles["Very Small"] > 1 then 
			countCategories = countCategories + 1
		end
		if hungerData.foodProfiles["Light Meal"] > 1 then 
			countCategories = countCategories + 1
		end
		if hungerData.foodProfiles["Medium Meal"] > 1 then 
			countCategories = countCategories + 1
		end
		if hungerData.foodProfiles["Filling Meal"] > 1 then 
			countCategories = countCategories + 1
		end
		if hungerData.foodProfiles["Hearty Meal"] > 1 then 
			countCategories = countCategories + 1
		end
		if hungerData.foodProfiles["Raw Meat"] > 1 then 
			countCategories = countCategories + 1
		end
		if countCategories >= 3 then
			foodProfile = "well_nourished"
			buff = "sd_h_sp_varied"
		end
		
		-- green pact
		if minute%60 == 0 then
			log(3, "Green Pact: "..hungerData.foodProfiles["Green Pact"]..">3, Vegan: "..hungerData.foodProfiles["Vegan"].."==0, Broken Pact: "..hungerData.foodProfiles["Broken Pact"].."m left" )
			log(3, "Well Nourished: "..countCategories..">3, Corprus: "..hungerData.foodProfiles["Corprus"]..">3 and >Highest Category: "..highestCategory )
		end
		if hungerData.foodProfiles["Vegan"] == 0 and hungerData.foodProfiles["Green Pact"] > 3 then
			foodProfile = "green_pact"
			buff = "sd_h_sp_greenpact"
		end
		
		-- corprus eater
		if hungerData.foodProfiles["Corprus"] > 3 and hungerData.foodProfiles["Corprus"] >= highestCategory then
			foodProfile = "corprus_eater"
			buff = "sd_h_sp_corprus"
		end
		
		-- Broken Pact
		if hungerData.foodProfiles["Broken Pact"] > 0 then
			hungerData.foodProfiles["Broken Pact"] = hungerData.foodProfiles["Broken Pact"] - minutesPassed
			foodProfile = "broken_pact"
			buff = "sd_h_sp_greenpact_2"
		end
		if buff then
			hungerData.currentFoodProfile = foodProfile
			hungerData.currentFoodProfileBuff = buff
			G_addSpellWhenAwake(buff)
		end
	end
	
	local suffix = buildSeveritySuffix()

	hungerData.hungerLevel = math.max(0, math.floor(hungerData.hunger * 6 - 0.00001))
	
	-- remove severitiy suffixes (_2 and _3) for positive buffs (level 0-2)
	-- note: no companion buffs on hardcore
	
	if hungerData.hungerLevel <= 3 and (suffix == "_2" or suffix == "_3") then
		suffix = ""
	end
	
	if NEEDS_HUNGER_BUFFS_DEBUFFS == "Only buffs" and hungerData.hungerLevel <= 2 
	or NEEDS_HUNGER_BUFFS_DEBUFFS == "Only debuffs" and hungerData.hungerLevel >= 3 
	or NEEDS_HUNGER_BUFFS_DEBUFFS == "Buffs and debuffs" then
		local buff = "sd_hunger_"..hungerData.hungerLevel..suffix
		hungerData.currentHungerBuff = buff
		G_addSpellWhenAwake(buff)
	end
	
	if DEATH_BY_STARVATION and not G_isTravelling and not G_isInJail then
		local volume = (hungerData.hunger-0.95)*20
		if volume > 0 then
			G_heartbeatFlags.hunger = volume
			G_vignetteFlags.hunger = 0.6*volume
			
			if hungerData.hunger >=0.99 then
				G_vignetteColorFlags.hunger = "default"
				if not debug.isGodMode() then
					types.Actor.stats.dynamic.health(self).current = types.Actor.stats.dynamic.health(self).current - math.min(7, 0.5 * minutesPassed)
				end
				G_flashVignette = 0.7
			end
		else
			G_heartbeatFlags.hunger = nil
			G_vignetteFlags.hunger  = nil
			G_vignetteColorFlags.hunger = nil
		end
	else
		G_heartbeatFlags.hunger = nil
		G_vignetteFlags.hunger  = nil
		G_vignetteColorFlags.hunger = nil
	end

	updateWidget()
end
table.insert(G_perMinuteJobs, module_hunger_minute)

local function onLoad(originalData)
	if not NEEDS_HUNGER then return end
	if not saveData.m_hunger then
		saveData.m_hunger = {
			hunger = (1/6),
		}
	end
	hungerData = saveData.m_hunger
	-- migration:
	if not hungerData.hungerLevel then
		hungerData.hungerLevel = 1
	end
	if not hungerData.hungerLevel then
		hungerData.hungerLevel = 1
	end
	if not hungerData.foodProfiles then
		hungerData.foodProfiles = {
			["Very Small"] = 0,
			["Light Meal"] = 0,
			["Medium Meal"] = 0,
			["Filling Meal"] = 0,
			["Hearty Meal"] = 0,
			["Beverage"] = 0,
			["Alcohol"] = 0,
			["Raw Meat"] = 0,
			["Corprus"] = 0,
			["Human"] = 0,
			["Green Pact"] = 0,
			["Vegan"] = 0,
			["Broken Pact"] = 0,
		}
	end
end

table.insert(G_onLoadJobs, onLoad)
table.insert(G_onLoadJobs, updateWidget) --after all onload jobs, also update widget

local function settingsChanged(sectionName, setting, oldValue)
	if setting == "NEEDS_HUNGER" then
		if oldValue == false then
			onLoad()
		else
			removeBuffs()
			saveData.m_hunger = nil
			G_destroyHungerUi()
			G_heartbeatFlags.hunger = nil
			G_vignetteFlags.hunger  = nil
			G_vignetteColorFlags.hunger = nil
		end
	elseif setting == "H_BACKGROUND" then
		G_destroyHungerUi()
	end
end
table.insert(G_settingsChangedJobs, settingsChanged)

local function onConsume(item)
	if not NEEDS_HUNGER then return end
	local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
	if not entry or not entry.foodValue or entry.foodValue == 0 then
		-- Ingredients still give a tiny restore, unchanged
		if types.Ingredient.objectIsInstance(item) then
			hungerData.hunger = math.max(0, hungerData.hunger - 0.1)
			module_hunger_minute(24, 1, 0)
			hungerData.foodProfiles["Light Meal"] = hungerData.foodProfiles["Light Meal"] + 1
		end
		return
	end
	-- todo:
	-- fast metabolism
	-- altmer + 15%
	-- redguard + 10%

	local foodValue = tonumber(entry.foodValue) or 0
	local category = entry.consumeCategory
	local isRawMeat = category == "raw meat"

	-- 1) disease chance multiplier for raw meat
	local foodDiseaseChance = RAW_MEAT_DISEASE_CHANCE / 100
	local toxicityChance = 1
	local restore = foodValue / 200.0
	
	if NEEDS_RACES_HUNGER then
		-- BEASTS
		if saveData.playerInfo.isBeast then
			if isRawMeat then
				foodDiseaseChance = 0
				restore = restore * (200 / 150)
			end
		end
		-- ORCS
		if saveData.playerInfo.isOrc then
			foodDiseaseChance = 0
			toxicityChance = 0
		end
		-- ALTMER
		if saveData.playerInfo.isAltmer then
			foodDiseaseChance = foodDiseaseChance * 1.25
			if isRawMeat then
				restore = restore * 0.75
			end
			if entry.isCookedMeal then
				restore = restore * 1.25
			end
		end
		-- SIMPERIAL
		if saveData.playerInfo.isImperial then
			foodDiseaseChance = foodDiseaseChance * 1.15
			if isRawMeat then
				restore = restore * 0.85
			end
			if entry.isCookedMeal then
				restore = restore * 1.15
			end
		end
		
		-- BOSMER
		if saveData.playerInfo.isBosmer then
			foodDiseaseChance = 0
			if entry.isGreenPact then
				restore = restore * 1.25
			else
				restore = restore * 0.5
			end
		end
		
	end
	if saveData.playerInfo.isVampire > 0 then
		foodDiseaseChance = 0
		if NEEDS_HUNGER_VW ~= "Disable" then
			if isRawMeat or category == "human" then
				if NEEDS_HUNGER_VW == "Immortal" then
					restore = restore * 1.5
				else --Supernatural
					restore = restore * 1.2
				end
			elseif NEEDS_HUNGER_VW == "Immortal" then
				restore = restore * 0
			end
		end
	end
	if saveData.playerInfo.isWerewolf > 0 then
		foodDiseaseChance = 0
		if NEEDS_HUNGER_VW ~= "Disable" then
			if entry.isGreenPact then
				if NEEDS_HUNGER_VW == "Immortal" then
					restore = restore * 1.5
				else --Supernatural
					restore = restore * 1.2
				end
			elseif NEEDS_HUNGER_VW == "Immortal" then
				restore = restore * 0
			end
		end
	end

	-- apply once
	if restore > 0 then
		hungerData.hunger = math.min(1, math.max(0, hungerData.hunger - restore*FOODVALUE_MULT))
		if entry.foodValue2 and entry.foodValue2 > 0 then
			hungerData.longLastingMagnitude = (restore*200/entry.foodValue)*entry.foodValue2/360*FOODVALUE_MULT
			hungerData.longLastingDuration = 360
		end
	end
	
	local gotDebuff = 0
	
	-- 3) disease roll for raw meat
	if RAW_MEAT_DISEASE_CHANCE > 0 and isRawMeat and foodDiseaseChance > 0 then
		if math.random() < foodDiseaseChance then
			hungerData.longLastingMagnitude = nil
			hungerData.longLastingDuration = nil
			typesActorSpellsSelf:add(commonDiseaseOnConsume[math.random(1, #commonDiseaseOnConsume)])
			gotDebuff = 0.5
		end
	end

	-- 4) food poisoning
	if NEEDS_HUNGER_TOXICITY and entry.isToxic then
		local suffix = buildSeveritySuffix()
		if math.random() < toxicityChance then
			if entry.foodValue2 then
				hungerData.longLastingMagnitude = nil
				hungerData.longLastingDuration = nil
			end
			hungerData.longLastingMagnitude = nil
			hungerData.longLastingDuration = nil
			types.Actor.activeSpells(self):add({
				id = "sd_h_sp_foodpoisoning" .. suffix,
				effects = { 0, 1 },
				ignoreResistances = true,
				ignoreSpellAbsorption = true,
				ignoreReflect = true
			})
			gotDebuff = 2
		end
	end
	
	if entry.consumeCategory and hungerData.foodProfiles[entry.consumeCategory] then
		if gotDebuff > 0 then
			hungerData.foodProfiles[entry.consumeCategory] = math.max(0, hungerData.foodProfiles[entry.consumeCategory] - gotDebuff)
		else
			hungerData.foodProfiles[entry.consumeCategory] = hungerData.foodProfiles[entry.consumeCategory] + (entry.isCookedMeal and 2 or 1)
		end
	end
	if entry.isGreenPact then
		hungerData.foodProfiles["Green Pact"] = hungerData.foodProfiles["Green Pact"] + 1
	else
		if hungerData.currentFoodProfile == "green_pact" then
			hungerData.foodProfiles["Broken Pact"] = 1440
			log(3, "Broke Green pact", item)
		end
		hungerData.foodProfiles["Vegan"] = hungerData.foodProfiles["Vegan"] + 1
	end
	
	module_hunger_minute(24, 1, 0)
end
table.insert(G_onConsumeJobs, onConsume)

-- ─── Vampire Feed Hook ───
-- External call: SD_Hunger_ApplyRestoreFraction(frac)
-- frac in [0..1], reduces hunger by that fraction and refreshes buffs/UI.
local function landedHit(target, attack)
	if saveData.playerInfo.isInWerewolfForm and NEEDS_HUNGER_VW ~= "Disable" and attack.successful and math.random() < 0.4 and attack.sourceType == I.Combat.ATTACK_SOURCE_TYPES.Melee  then
		ambient.playSoundFile("sound/sunsdusk/Swallowing_water_by_180242.ogg",{volume = 1.5})
		hungerData.foodProfiles["Raw Meat"] = hungerData.foodProfiles["Raw Meat"] + 0.4
		hungerData.foodProfiles["Green Pact"] = hungerData.foodProfiles["Green Pact"] + 0.4
		local restoredHunger = 0.1 * attack.strength
		if NEEDS_HUNGER_VW == "Supernatural" then
			restoredHunger = restoredHunger * 2/3
		end
		hungerData.hunger = math.max(0,hungerData.hunger - restoredHunger)
	end
end

table.insert(G_landedHitJobs, landedHit)

local function landedSpellHit(target, spell)
	if saveData.playerInfo.isVampire > 0 and NEEDS_HUNGER_VW ~= "Disable" then
		local totalMagnitude = 0
		for i,effect in pairs(spell.effects) do
			local effectRecord = core.magic.effects.records[effect.id]
			if effect.id == "absorbhealth" then
				totalMagnitude = totalMagnitude + effect.duration* (effect.maxMagnitude+effect.minMagnitude)/2
			end
		end
		local restoredHunger = 0.02+totalMagnitude/1500
		if NEEDS_HUNGER_VW == "Supernatural" then
			restoredHunger = restoredHunger * 2/3
		end
		hungerData.hunger = math.max(0,hungerData.hunger - restoredHunger)
		module_hunger_minute(24, 1, 0)
	end
end

table.insert(G_landedSpellHitJobs, landedSpellHit)