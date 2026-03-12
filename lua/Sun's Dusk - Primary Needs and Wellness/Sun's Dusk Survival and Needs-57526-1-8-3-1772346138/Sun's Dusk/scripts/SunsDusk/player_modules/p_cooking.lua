local cookingData
local makeCookingButton = require("scripts.SunsDusk.lib.ui_makeCookingButton")
local cookingRecipes = require("scripts.SunsDusk.lib.cooking_recipes")
local SkillFramework = I.SkillFramework
local skillId = "SunsDusk_Cooking"
local cookingStat

local textSize = 24
local listHeight = 570
local totalWidth = 800
local listWidth = 300
local descriptionWidth = 500
local listSize = 19
local scrollbarHeight = math.floor(listHeight/30)*30

local cookingUiSettingsSection = storage.playerSection("SunsDuskCookingUi")
local isInDialogue = false
local cookingWithInnkeeper = false
local innkeeperIngredients = {}
local lastCookingLevel = 0

local controllerColumn = 1 -- 1,2,3
local controllerListIndex = 1
local controllerRightIndex = 1 -- 1=cook, 2=minus, 3=plus
local controllerFocusedClickbox = nil
local controllerActive = false -- becomes true on first dpad/arrow press
local controllerActivateHeld = false
local cookingHeldDirection = nil -- direction string currently held for repeat
local cookingHeldTimestamp = 0   -- when the held direction can next repeat



G_cookingRecipes = {
	["sd_book_cook_food_egg"] = true,
	["sd_book_cook_food_egg_g"] = true,
	["sd_book_cook_food_f"] = true,
	["sd_book_cook_food_f_g_h"] = true,
	["sd_book_cook_food_f_g_salt"] = true,
	["sd_book_cook_food_f_salt"] = true,
	["sd_book_cook_food_fruit"] = true,
	["sd_book_cook_food_fruit_g_h"] = true,
	["sd_book_cook_food_g"] = true,
	["sd_book_cook_food_g_salt"] = true,
	["sd_book_cook_food_g_spice"] = true,
	["sd_book_cook_food_m"] = true,
	["sd_book_cook_food_m_f"] = true,
	["sd_book_cook_food_m_fruit"] = true,
	["sd_book_cook_food_m_g"] = true,
	["sd_book_cook_food_m_meat"] = true,
	["sd_book_cook_food_m_salt"] = true,
	["sd_book_cook_food_m_soup"] = true,
	["sd_book_cook_food_m_spice"] = true,
	["sd_book_cook_food_meat"] = true,
	["sd_book_cook_food_meat_g_h"] = true,
	["sd_book_cook_food_meat_salt"] = true,
	["sd_book_cook_food_meat_soup"] = true,
	["sd_book_cook_food_meat_spice"] = true,
}

local function loadUiSettings()
	local layerId = ui.layers.indexOf("Modal")
	local G_hudLayerSize = ui.layers[layerId].size
	
	-- Setup storage
	totalWidth = math.max(100,math.min(G_hudLayerSize.x*0.9, cookingUiSettingsSection:get("WIDGET_WIDTH") or totalWidth))
	listHeight = math.max(100,math.min(math.floor(G_hudLayerSize.y*0.8), cookingUiSettingsSection:get("LIST_HEIGHT") or listHeight))
	listWidth = math.floor(totalWidth/8*3)
	descriptionWidth = math.floor(totalWidth/8*5)
	listSize = math.floor(listHeight/30)
	scrollbarHeight = math.floor(listHeight/30)*30
end

loadUiSettings()

local availableIngredients = {}
local selectedIngredients = {} -- Table to track multiple selections
local mealPreviewElements = {} -- UI elements in right column
local mealCount = 1
local fWortChanceValue = core.getGMST("fWortChanceValue")
cookingLevelModified = 0
alchemyLevel = 0
local waterAmount, waterItems
local containerCounts = { bowls = 0, plates = 0 }
local INNKEEPER_MEAL_COST = 25

local function countContainers()
	local bowls = 0
	local plates = 0
	local icon = nil
	for _, item in ipairs(typesActorInventorySelf:getAll(types.Miscellaneous)) do
		if item:isValid() and item.count > 0 then
			local foodwareType = getFoodwareType(item)
			if foodwareType == "bowl" then
				bowls = bowls + item.count
				icon = icon or types.Miscellaneous.record(item).icon
			elseif foodwareType == "plate" then
				plates = plates + item.count
				icon = icon or types.Miscellaneous.record(item).icon
			end
		end
	end
	containerCounts.bowls = bowls
	containerCounts.plates = plates
	containerCounts.icon = icon
	return bowls, plates, icon
end

local function getPlayerGold()
	local gold = 0
	local goldItem = typesActorInventorySelf:find("gold_001")
	if goldItem then
		gold = goldItem.count
	end
	return gold
end

local scrollbarBackground
local scrollbarThumb
local currentScrollbarWidth = 0

local currentIndex = 1
local MAX_INGREDIENTS = 3
local scrollbarWidth = 10
local seperatorWidth = 30
local marginWidth = 3

local getMagicEffectName
local calculateMaxMeals
local generateIngredientTooltip
local countMatchingEffects
local getMatchHighlightAlpha
local updateAllButtonHighlights
local populateButtonEffectIcons
local getIngredientEffects
local calculateMealStat
local createMealPreview
local createStatText
local updateMealPreview
local clearSelection
local confirmCooking
local addIngredientButton
local toggleIngredientSelection
local rebuildList
local updateScrollbar

local borderFile = "thin"
local borderOffset = 3
local controllerTooltipTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), 1, {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture{ path = 'black' },
		relativeSize = v2(1,1),
		alpha = 0.93,
	}
}).borders

-- ──────────────────────────────────────────────────────────────────────────────── IMMERSIVE MODE CONFIGURATION ────────────────────────────────────────────────────────────────────────────────



-- Racial multiplier lookup table
local RACIAL_MULTIPLIERS = {
	isBreton = 1.5,
	isAltmer = 1.3,
	isOrc = 1.35,
	isDunmer = 1.25,
	isImperial = 1.2,
	isBeast = 0.7,
}

-- Ingredient class modifiers (Mult = multiplier, Mod = flat additive)
local CLASS_MODS = {
	salts = { chanceMult = 1.5, drinkValueMult = 0.8 },  -- +50% effect chance, -20% thirst (you get thirsty)
	spices = { foodValueMult = 1.25, magnitudeMult = 1.15 },  -- +25% food value, +15% magnitude
	egg = { foodValueMult = 1.2 },  -- +20% hunger
	bread = { drinkValueMult = 1.2 },  -- +20% thirst
}

-- IMMERSIVE MODE
-- Helper function to apply effect-specific magnitude scaling
local function applyEffectScaling(magnitude, effectId)
	local id = tostring(effectId or "")
	if id:find("fortify", 1, true) then
		return magnitude * 1.5
	elseif id:find("restore", 1, true) then
		return magnitude * 1.2
	elseif id:find("resist", 1, true) then
		return magnitude * 2.0
	elseif id:find("detect", 1, true) or id:find("night", 1, true) then
		return magnitude * 0.8
	end
	return magnitude
end

-- Effect priority categories (higher priority = more likely to appear)
-- should only be priority for alcheffect1 as this is the effect weight
local effectPriorities = {
	-- Instant cures (highest priority)
	curecommondisease = 1000,
	cureblightdisease = 999,
	curepoison = 998,
	cureparalyzation = 997,
	
	-- Restoration (high priority)
	restorehealth = 950,
	restorefatigue = 925,
	restoremagicka = 975,	
	
	-- Elemental resistances (high priority)
	resistfire = 800,
	resistfrost = 799,
	resistshock = 788,
	resistmagicka = 750,
	
	-- Disease resistances
	-- resistcommondisease = 750,
	-- resistblightdisease = 750,
	-- resistcorprusdisease = 750,
	
	-- Utility buffs (medium-high priority)
	waterwalking = 749,
	waterbreathing = 725,
	swiftswim = 700,
	
	-- Detection and sensory
	nighteye = 650,
	detectanimal = 625,
	detectenchantment = 600,
	-- detectkey = 600,
	
	-- Mobility
	-- jump = 550,
	feather = 595,
	-- slowfall = 550,
	
	-- Shields
	shield = 550,
	fireshield = 575,
	lightningshield = 565,
	frostshield = 555,
	sanctuary = 500,
	
	-- Fortify effects (medium-low priority)
	fortifyhealth = 300,
	-- fortifymagicka = 300,
	-- fortifyfatigue = 300,
	fortifyattribute = 400,
	-- fortifyskill = 250,
	fortifyattack = 401,
	-- fortifymaximummagicka = 200,
	
	-- Chameleon/Invisibility
	chameleon = 575,
	invisibility = 500,
	
	-- Offensive (lowest priority for food)
	-- firedamage = 50,
	-- frostdamage = 50,
	-- shockdamage = 50,
	-- poison = 50,
}


-- ──────────────────────────────────────────────────────────────────────────────── ARCANE MODE CONFIGURATION ────────────────────────────────────────────────────────────────────────────────
local dailyBuffMultipliers = {
	
	levitate = 0, -- special code + special generated potion?
	
	waterbreathing = 4,
	waterwalking = 2,
	slowfall = 2,
	invisibility = 0,
	restoreattribute = 3,
	restoreskill = 3,
	
	swiftswim = 28,
	light = 0,
	nighteye = 25,
	detectanimal = 50,
	detectenchantment = 40,
	detectkey = 40,
	telekinesis = 0, -- broken
	
	chameleon = 16,
	jump = 21,
	feather = 40,
	burden = 20,
	
	shield = 25,
	fireshield = 25,
	lightningshield = 25,
	frostshield = 25,
	sanctuary = 15,
	
	spellabsorption = 16,
	reflect = 16,
	resistfire = 25,
	resistfrost = 25,
	resistshock = 25,
	resistmagicka = 25,
	resistpoison = 25,
	resistnormalweapons = 11,
	resistparalysis = 25,
	
	resistcommondisease = 40,
	resistblightdisease = 40,
	resistcorprusdisease = 40,
	
	fortifyattribute = 28,
	fortifyhealth = 28,
	fortifymagicka = 28,
	fortifyfatigue = 50,
	fortifyskill = 28,
	fortifymaximummagicka = 5,
	fortifyattack = 15,
	
	absorbattribute = 2.5,
	absorbhealth = 2.5,
	absorbmagicka = 2.5,
	absorbfatigue = 2.5,
	absorbskill = 2.5,
	
	restorehealth = 1.5,
	restoremagicka = 0.3,
	restorefatigue = 1.5,
	
	firedamage = 0.8,
	shockdamage = 0.6,
	frostdamage = 0.8,
	poison = 0.3,
	sundamage = 5,
	
	drainattribute = 15,
	drainskill = 15,
	
	-- just confusing:
	drainhealth = 0,
	drainmagicka = 0,
	drainfatigue = 0,
	
	damagefatigue = 0.5,
	
	weaknesstofire = 4.2,
	weaknesstofrost = 4.2,
	weaknesstoshock = 4.2,
	weaknesstomagicka = 4.2,
	weaknesstocommondisease = 7,
	weaknesstoblightdisease = 2.8,
	weaknesstocorprusdisease = 2.8,
	weaknesstopoison = 5.6,
	weaknesstonormalweapons = 2.8,
	
	blind = 10,
	sound = 10,
	paralyze = 0,
	silence = 0,
	dispel = 0,
	
	curecommondisease = 0,
	cureblightdisease = 0,
	curecorprusdisease = 0,
	curepoison = 0,
	cureparalyzation = 0,
	removecurse = 0,
}

local noDuration = {
["almsiviintervention"] = "AlmsiviIntervention",
["cureblightdisease"] = "CureBlightDisease",
["cureparalyzation"] = "CureParalyzation",
["mark"] = "Mark",
["corprus"] = "Corprus",
["curecommondisease"] = "CureCommonDisease",
["recall"] = "Recall",
["removecurse"] = "RemoveCurse",
["divineintervention"] = "DivineIntervention",
["curecorprusdisease"] = "CureCorprus",
["curepoison"] = "CurePoison",
["vampirism"] = "Vampirism",
["open"] = "Open",
["lock"] = "Lock",
["dispel"] = "Dispel",
}


-- ──────────────────────────────────────────────────────────────────────────────── EFFECT HELPERS ────────────────────────────────────────────────────────────────────────────────
local function isEffectVisible(ingredient, effect)
	return COOKING_MODE == "Immersive" or math.max(cookingLevelModified, alchemyLevel) >= effect.vanillaIndex*fWortChanceValue or ingredient and cookingData.discoveredEffects[ingredient.recordId] and cookingData.discoveredEffects[ingredient.recordId][effect.vanillaIndex]
end


-- comes from sd_g.lua
function getMagicEffectName(effectId)
	-- magic effect from the API
	local effect = core.magic.effects.records[effectId]
	--local gm = core.getGMST("sEffect"..effectId)
	--print(effectId,effectId,gm,gm)
	-- If the effect exists, return its name
	if effect then
		return shortEffects[effect.id] --effect.name
	end
	return "Unknown Effect"
end

-- Calculate the cost of ingredients bought from innkeeper for a given meal count
-- innkeeperCount is used first, so player pays for those at ingredient value
local function calculateIngredientCost(forMealCount)
	local totalCost = 0
	for idx, _ in pairs(selectedIngredients) do
		local ingredient = availableIngredients[idx]
		if ingredient and ingredient.innkeeperCount > 0 then
			-- Player buys min(forMealCount, innkeeperCount) from innkeeper
			local boughtFromInnkeeper = math.min(forMealCount, ingredient.innkeeperCount)
			totalCost = totalCost + boughtFromInnkeeper * (ingredient.value or 0)
		end
	end
	return totalCost
end

function calculateMaxMeals()
	local maxMeals = 999
	for idx, _ in pairs(selectedIngredients) do
		local ingredient = availableIngredients[idx]
		if ingredient then
			local itemCount = ingredient.count + ingredient.innkeeperCount
			maxMeals = math.min(maxMeals, itemCount)
		end
	end
	maxMeals = maxMeals < 999 and maxMeals or 0
	
	if cookingWithInnkeeper then
		-- Limit by gold: service fee + ingredient costs
		local playerGold = getPlayerGold()
		-- Binary search for max affordable meals
		local lo, hi = 0, maxMeals
		while lo < hi do
			local mid = math.ceil((lo + hi) / 2)
			local totalCost = INNKEEPER_MEAL_COST * mid + calculateIngredientCost(mid)
			if totalCost <= playerGold then
				lo = mid
			else
				hi = mid - 1
			end
		end
		maxMeals = lo
	else
		maxMeals = math.min(maxMeals, math.floor(waterAmount/(COOKING_WATER_MULT*250)))

		-- Limit by available containers (bowls + plates)
		local totalContainers = containerCounts.bowls + containerCounts.plates
		if totalContainers > 0 then
			maxMeals = math.min(maxMeals, totalContainers)
		elseif maxMeals > 0 then
			-- No containers available, can't cook
			maxMeals = 0
		end
	end
	
	return maxMeals	
end

-- Calculate how many effects match between an ingredient and all selected ingredients
function countMatchingEffects(ingredientIndex)
	if not availableIngredients[ingredientIndex] then return 0 end
	
	local ingredient = availableIngredients[ingredientIndex]
	--local record = types.Ingredient.record(ingredient.recordId)
	--if not record then return 0 end
	
	local ingredientEffects = getIngredientEffects(ingredient)
	if #ingredientEffects == 0 then return 0 end
	
	-- Get all unique effect IDs from this ingredient
	local ingredientEffectIds = {}
	for _, effect in ipairs(ingredientEffects) do
		if isEffectVisible(ingredient, effect) then
			ingredientEffectIds[effect.uniqueId] = 0
		end
	end
	
	-- Count matches with selected ingredients
	local matchCount = 0
	for selectedIdx, _ in pairs(selectedIngredients) do
		local selectedIngredient = availableIngredients[selectedIdx]
		if selectedIngredient then
			for _, effect in ipairs(getIngredientEffects(selectedIngredient)) do
				
				if isEffectVisible(selectedIngredient, effect) and ingredientEffectIds[effect.uniqueId]  then
					--ingredientEffectIds[effect.uniqueId] = ingredientEffectIds[effect.uniqueId] + 1
					matchCount = matchCount + 1
				end
			end
		end
	end
	
	--for _, count in pairs(ingredientEffectIds) do
	--	matchCount = matchCount + math.min(2,count)
	--end
	return matchCount
end

-- Get the actual matching effects (not just the count)
function getMatchingEffects(ingredientIndex)
	if not availableIngredients[ingredientIndex] then return {} end
	
	local ingredient = availableIngredients[ingredientIndex]
	local ingredientEffects = getIngredientEffects(ingredient)
	if #ingredientEffects == 0 then return {} end
	
	local matchingEffects = {}
	local addedEffects = {} -- Track which effects we've already added to avoid duplicates
	
	-- Check each effect against selected ingredients
	for _, effect in ipairs(ingredientEffects) do
		if isEffectVisible(ingredient, effect) then
			for selectedIdx, _ in pairs(selectedIngredients) do
				local selectedIngredient = availableIngredients[selectedIdx]
				if selectedIngredient and selectedIngredient.recordId~= ingredient.recordId then
					for _, selectedEffect in ipairs(getIngredientEffects(selectedIngredient)) do
						if isEffectVisible(selectedIngredient, selectedEffect) and effect.uniqueId == selectedEffect.uniqueId and not addedEffects[effect.uniqueId] then
							table.insert(matchingEffects, effect)
							addedEffects[effect.uniqueId] = true
							break
						end
					end
				end
				if addedEffects[effect.uniqueId] then break end
			end
		end
	end
	
	return matchingEffects
end

-- ──────────────────────────────────────────────────────────────────────────────── UI HELPERS ────────────────────────────────────────────────────────────────────────────────

-- Get highlight intensity (alpha) based on number of matching effects
function getMatchHighlightAlpha(matchCount)
	if matchCount == 0 then
		return 0 -- No highlight
	elseif matchCount == 1 then
		return 0.055 -- Faint
	elseif matchCount == 2 then
		return 0.11 -- Medium
	elseif matchCount >= 3 then
		return 0.145 -- Strong
	end
end

function generateIngredientTooltip(ingredient)
	local flex = {
		type = ui.TYPE.Flex,
		name = 'tooltipFlex',
		props = {
			autoSize = true,
		},
		content = ui.content {
		}
	}
	
	local textSize = 16
	-- Add ingredient rank if available
	if ingredient.data and ingredient.data.ingredientRank and COOKING_MODE == "Immersive" then
		local effectFlex ={
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
			},
			content = ui.content({})
		}
		flex.content:add(effectFlex)
		effectFlex.content:add{ props = { size = v2(1, 1) * 5 } }
		effectFlex.content:add {
			type = ui.TYPE.Text,
			props = {
				text = "Item Quality: " .. ingredient.data.ingredientRank,
				textSize = textSize,
				textColor = G_morrowindGold,
				textAlignH = ui.ALIGNMENT.Center,
			},
		}
		flex.content:add{ props = { size = v2(1, 1) * 3 } }
	else
		flex.content:add{ props = { size = v2(1, 1) * 4 } }
	end
	for i, effect in pairs(getIngredientEffects(ingredient)) do
		if isEffectVisible(ingredient, effect) then
			local effectFlex ={
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
				},
				content = ui.content({})
			}
			flex.content:add(effectFlex)
			effectFlex.content:add{ props = { size = v2(1, 1) * 5 } }
	
			effectFlex.content:add {
				type = ui.TYPE.Image,
				props = {
					resource = getTexture(effect.icon),
					tileH = false,
					tileV = false,
					size = v2(textSize,textSize),
					alpha = 0.7,
				}
			}
			effectFlex.content:add { 
				type = ui.TYPE.Text,
				props = {
					text = " "..effect.text.." ",
					textSize = textSize,
					textColor = G_morrowindGold,
					textAlignH = ui.ALIGNMENT.Center,
				},
			}
		else
			flex.content:add { 
				type = ui.TYPE.Text,
				props = {
					text = " ? ",
					textSize = textSize,
					textColor = G_morrowindGold,
					textAlignH = ui.ALIGNMENT.Center,
				},
			}
		end
		flex.content:add{ props = { size = v2(1, 1)*2 } }
	end
	if ingredient.data and ingredient.data.ingredientRank and COOKING_MODE ~= "Immersive" then
		local effectFlex ={
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
			},
			content = ui.content({})
		}
		flex.content:add(effectFlex)
		effectFlex.content:add{ props = { size = v2(1, 1) * 5 } }
		effectFlex.content:add {
			type = ui.TYPE.Text,
			props = {
				text = "Rank " .. ingredient.data.ingredientRank.." ",
				textSize = textSize,
				textColor = G_morrowindGold,
				textAlignH = ui.ALIGNMENT.Center,
			},
		}
	else
	end
		flex.content:add{ props = { size = v2(1, 1) * 4 } }
	
	return flex
end

-- Update all visible button highlights
function updateAllButtonHighlights()
	-- Update all visible buttons in the list
	for _, buttonBox in ipairs(flex_V_H_V2.layout.content) do
		-- Check if this is a button with an ingredient index
		for _, child in ipairs(buttonBox.layout.content) do
			if child.name == 'clickbox' and child.userData and child.userData.ingredientIndex then
				local i = child.userData.ingredientIndex
				local matchCount = countMatchingEffects(i)
				local highlightAlpha = getMatchHighlightAlpha(matchCount)
				
				-- Update the button's highlight alpha
				child.userData.highlightAlpha = highlightAlpha
				
				-- Check if this button is selected
				local isSelected = false
				for _, selectedData in pairs(selectedIngredients) do
					if selectedData.button and selectedData.button.clickbox == child then
						isSelected = true
						break
					end
				end
				
				-- Update effect icons using the stored button object
				--if child.userData.buttonObject and not isSelected then
					local matchingEffects = getMatchingEffects(i)
					populateButtonEffectIcons(child.userData.buttonObject, matchingEffects)
				--end
				
				-- Re-apply color with new highlight
				if child.userData.applyColor then
					child.userData.applyColor(child)
				end
				
				break
			end
		end
	end
end

-- Populate a button's right icon container with effect icons
-- Icons are arranged top to bottom, right to left (fill rightmost column first)
function populateButtonEffectIcons(button, matchingEffects)
	if not button or not button.rightIconContainer then return end
	
	-- Clear existing content
	button.rightIconContainer.layout.content = ui.content{}
	
	if #matchingEffects == 0 then
		button.rightIconContainer:update()
		return
	end
	
	-- Configuration for 2x2 grid layout using relative positioning
	local maxVisibleIcons = 4 -- Maximum visible icons (game limit)
	local displayCount = math.min(#matchingEffects, maxVisibleIcons)
	
	-- Relative icon size (approximately 14px in a 36x30 container)
	local iconRelativeSize = v2(0.5, 0.5)

	
	-- Place icons: fill right column first (top to bottom), then left column
	for idx = 1, displayCount do
		local effect = matchingEffects[idx]
		
		-- Calculate grid position (rightmost column first, top to bottom)
		local row = (idx - 1) % 2
		local col = math.floor((idx - 1) / 2)
		button.rightIconContainer.layout.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(effect.icon),
				relativeSize = iconRelativeSize,
				relativePosition = v2(1-col*0.5,row*0.5),
				anchor = v2(1, 0),
				alpha = 0.8,
			},
		}
	end
	
	-- Add "+X" indicator if there are more effects
	if #matchingEffects > maxVisibleIcons then
		local remainingCount = #matchingEffects - maxVisibleIcons
		button.rightIconContainer.layout.content:add{
			type = ui.TYPE.Text,
			props = {
				text = "+" .. remainingCount,
				textColor = G_morrowindGold,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = 10,
				relativePosition = v2(0, 0.5),
				anchor = v2(1, 0.5),
				position = v2(-2, 0),
				textAlignV = ui.ALIGNMENT.Center,
				textAlignH = ui.ALIGNMENT.End,
			},
		}
	end
	
	button.rightIconContainer:update()
end
local function fillCookingUi()
	if #SDCookingUI.layout.content > 0 then
		auxUi.deepDestroy(flex_V)
		table.remove(SDCookingUI.layout.content, 1)
	end
	local borderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture{ path = 'black' },
			relativeSize = v2(1,1),
			alpha = 0.8,
		}
	}).borders
	--SDCookingUI.layout.content = ui.content{}
	flex_V = ui.create{
		type = ui.TYPE.Flex,
		name = "mainFlexV",
		props = { horizontal = false },
		content = ui.content{},
	}
	table.insert(SDCookingUI.layout.content, 1, flex_V)
	
	-- ================================================ TOP BAR ================================================
	local topBar = {
		type = ui.TYPE.Widget,
		props = {
			size = v2(descriptionWidth + listWidth + marginWidth*4 + seperatorWidth, textSize*1.4),
		},
		content = ui.content {}
	}
	flex_V.layout.content:add(topBar)
	
	local topBarBackground = {
		type = ui.TYPE.Image,
		props = {
			resource = getTexture('white'),
			alpha = 0,
			color = G_morrowindGold,
			relativeSize = v2(1,1),
		},
	}
	topBar.content:add(topBarBackground)
	
	-- Drag & Drop Events for Top Bar
	topBar.events = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				if not elem.userData then
					elem.userData = {}
				end
				elem.userData.isDragging = true
				elem.userData.dragStartPosition = data.position
				elem.userData.windowStartPosition = SDCookingUI.layout.props.position or v2(0, 0)
			end
			topBarBackground.props.alpha = 0.2
			SDCookingUI:update()
			flex_V:update()
		end),
		
		mouseRelease = async:callback(function(data, elem)
			if elem.userData then
				elem.userData.isDragging = false
			end
			topBarBackground.props.alpha = 0.1
			SDCookingUI:update()
			flex_V:update()
		end),
		
		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local deltaX = data.position.x - elem.userData.dragStartPosition.x
				local deltaY = data.position.y - elem.userData.dragStartPosition.y
				local newPosition = v2(
					elem.userData.windowStartPosition.x + deltaX,
					elem.userData.windowStartPosition.y + deltaY
				)
				windowPos = newPosition
				SDCookingUI.layout.props.position = newPosition
				SDCookingUI:update()
				flex_V:update()
			end
		end),
		
		focusGain = async:callback(function(_, elem)
			topBarBackground.props.alpha = 0.1
			if SDCookingUI then
				SDCookingUI:update()
				flex_V:update()
			end
		end),
		
		focusLoss = async:callback(function(_, elem)
			if elem.userData then
				elem.userData.isDragging = false
			end
			topBarBackground.props.alpha = 0
			if SDCookingUI then
				SDCookingUI:update()
				flex_V:update()
			end
		end)
	}
	topBar.content:add{
		name = 'text',
		type = ui.TYPE.Text,
		props = {
			text = "Cooking",
			textColor = G_morrowindGold,
			textShadow = true,
			textShadowColor = util.color.rgb(0,0,0),
			textSize = textSize,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			position = v2(marginWidth,0),
			relativePosition = v2(0,0.5),
			anchor = v2(0,0.5),
		},
	}
	
	-- NPC CLASS ID (if cooking with innkeeper and skill setting enabled)
	if INNKEEPER_COOKING_SKILLS and cookingWithInnkeeper then
		local npcClassId = cookingWithInnkeeper.type.record(cookingWithInnkeeper).class
		if npcClassId then
			local class = types.NPC.classes.records[ npcClassId]
			if class then
				
				topBar.content:add {
					name = 'npcClassId',
					type = ui.TYPE.Text,
					props = {
						text = class.name..":",
						textColor = G_morrowindGold,
						textShadow = true,
						textShadowColor = util.color.rgb(0,0,0),
						textSize = textSize*0.8,
						textAlignH = ui.ALIGNMENT.Center,
						textAlignV = ui.ALIGNMENT.Center,
						position = v2(-textSize*3.4, 0),
						relativePosition = v2(0.5, 0.5),
						anchor = v2(1, 0.5),
					},
				}
			end
		end
	end
	
	-- CURRENT LEVEL WIDGET 
	local progressBar = 
	{
		template = borderTemplate,
		type = ui.TYPE.Widget,
		props = {
			size = v2(textSize*6, textSize),
			anchor = v2(0.5,0.5),
			relativePosition = v2(0.5, 0.5),
		},
		content = ui.content {}
	}
	topBar.content:add(progressBar)
	progressBar.content:add {
		type = ui.TYPE.Image,
		props = {
			resource = background,
			tileH = false,
			tileV = false,
			relativeSize  = v2(1,1),
			relativePosition = v2(0,0),
			alpha = 0.3,
		}
	}
	
	local displayedProgress = cookingData.level%1
	if INNKEEPER_COOKING_SKILLS and cookingWithInnkeeper then
		displayedProgress = (cookingData.NPCSkills[getId(cookingWithInnkeeper)] or 0) % 1
	end
	progressBar.content:add {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = 'white' },
			tileH = false,
			tileV = false,
			relativeSize  = v2(displayedProgress,1),
			relativePosition = v2(0,0),
			alpha = 0.8,
			color = G_morrowindBlue,
		}
	}
	progressBar.content:add { 
		type = ui.TYPE.Text,
		--template = quickLootText,
		props = {
			text = "Level "..math.floor(cookingLevelModified),
			textSize = textSize*0.8,--itemFontSize*textSizeMult,
			--size = v2(0,textSize),
			relativeSize  = v2(0,1),
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5,0.5),
			textAlignH = ui.ALIGNMENT.Center,
			textColor = G_morrowindLight,
		},
	}
	
	--progressBar.content:add {
	--	template = borderTemplate,
	--	props = {
	--		relativeSize  = v2(1,1),
	--		alpha = 0.5,
	--	}
	--}
	
	-- CLOSE BUTTON
	xButton = makeButton(nil, {size = v2(textSize*1, textSize*1)}, function() 
		if SDCookingUI then
			if mouseTooltip then
				mouseTooltip:destroy()
				mouseTooltip = nil
			end
			SDCookingUI:destroy()
			SDCookingUI = nil
			cookingWithInnkeeper = false
			I.UI.setMode()
		end
		I.UI.setMode()
	end,nil, nil,getTexture("textures/SunsDusk/menu_icon_close.png"))
	xButton.image.props.color = G_morrowindGold
	xButton.box.layout.props.relativePosition = v2(1,0.5)
	xButton.box.layout.props.position = v2(-marginWidth*2,0)
	xButton.box.layout.props.anchor = v2(1,0.5)
	topBar.content:add(xButton.box)
	
	
	-- ================================================ UI LAYOUT ================================================
	
	flex_V_H = {
		type = ui.TYPE.Flex,
		name = "horizontalFlex",
		props = { horizontal = true },
		content = ui.content{},
	}
	flex_V.layout.content:add(flex_V_H)
	flex_V.layout.content:add{ props = { size = v2(1,1)*marginWidth } }
	
	-- Scrollbar column
	flex_V_H_V1 = ui.create{
		type = ui.TYPE.Widget,
		props = {
			size = v2(20,scrollbarHeight),
			--relativeSize = v2(0,1),
		},
		content = ui.content {}
	}
	flex_V_H.content:add(flex_V_H_V1)
	
	-- List column (no border, no template)
	flex_V_H_V2 = ui.create{
		type = ui.TYPE.Flex,
		name = "listColumn",
		props = {
			horizontal = false,
			size = v2(listWidth,scrollbarHeight),
			autoSize = false,
		},
		content = ui.content{},
	}
	flex_V_H.content:add(flex_V_H_V2)
	
	-- Spacer
	flex_V_H.content:add{ props = { size = v2(1,1)* math.floor(seperatorWidth/2-2) } }
	
	-- Vertical separator line
	flex_V_H.content:add{
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = 'white' },
			size = v2(2, listHeight-textSize*1.4),
			color = G_morrowindGold,
			alpha = 0.4,
		},
	}
	
	-- Spacer
	flex_V_H.content:add{ props = { size = v2(1,1)* math.floor(seperatorWidth/2-2) } }
	
	-- Right column (Meal Preview)
	flex_V_H_V3 = ui.create{
		type = ui.TYPE.Flex,
		name = "rightColumn",
		props = {
			horizontal = false,
			size = v2(descriptionWidth,listHeight),
			autoSize = false,
		},
		content = ui.content{},
	}
	flex_V_H.content:add(flex_V_H_V3)
	flex_V.layout.content:add{ props = { size = v2(1,1)*marginWidth } }
	
	-- ================================================ SCROLLBAR ================================================
	
	scrollbarBackground = {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = 'white' },
			relativePosition = v2(0,0),
			relativeSize = v2(1,1),
			alpha = 0.625,
			color = util.color.rgb(0,0,0),
		},
	}
	
	scrollbarThumb = {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = 'white' },
			relativePosition = v2(0,0),
			relativeSize = v2(1,0),
			alpha = 0.4,
			color = G_morrowindGold,
		},
	}
	
	scrollbarBackground.events = {
		mousePress = async:callback(function(data, elem)
			local totalItems = #availableIngredients
			if totalItems <= listSize then return end
			local scrollAmount = 10
		
			local scrollContainerHeight = scrollbarHeight
			local thumbHeight = scrollbarThumb.props.relativeSize.y * scrollContainerHeight
			local currentThumbY = scrollbarThumb.props.relativePosition.y * scrollContainerHeight
			local clickY = data.offset.y
		
			local pageAmount = scrollAmount
			local newIndex
		
			if clickY < currentThumbY then
				newIndex = math.max(1, currentIndex - pageAmount)
			else
				-- Fixed: added +1 to allow reaching the last item
				newIndex = math.min(totalItems - listSize + 1, currentIndex + pageAmount)
			end
		
			rebuildList(newIndex)
		end),
	
		focusGain = async:callback(function(_, elem)
			elem.props.alpha = 0.1
			elem.props.color = G_morrowindGold
			flex_V_H_V1:update()
		end),
	
		focusLoss = async:callback(function(_, elem)
			elem.props.alpha = 0.625
			elem.props.color = util.color.rgb(0, 0, 0)
			flex_V_H_V1:update()
		end),
	}

	scrollbarThumb.events = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				if not elem.userData then elem.userData = {} end
				elem.userData.isDragging = true
				elem.userData.dragStartY = data.position.y
				elem.userData.dragStartThumbY = elem.props.relativePosition.y * scrollbarHeight
			end
		end),
	
		mouseRelease = async:callback(function(_, elem)
			if elem.userData then
				elem.userData.isDragging = false
			end
		end),
	
		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local totalItems = #availableIngredients
				if totalItems <= listSize then return end
	
				local scrollContainerHeight = scrollbarHeight
				local thumbHeight = elem.props.relativeSize.y * scrollContainerHeight
				local availableScrollDistance = scrollContainerHeight - thumbHeight
				if availableScrollDistance <= 0 then return end
	
				local deltaY = data.position.y - elem.userData.dragStartY
				local newThumbY = math.max(0, math.min(
					availableScrollDistance,
					elem.userData.dragStartThumbY + deltaY
				))
	
				elem.props.relativePosition = v2(0, newThumbY / scrollContainerHeight)
	
				local newScrollPosition = newThumbY / availableScrollDistance
				-- Fixed: added +1 to allow reaching the last item
				local maxScrollIndex = math.max(1, totalItems - listSize + 1)
				local newIndex = math.floor(newScrollPosition * (maxScrollIndex - 1) + 0.5) + 1
	
				rebuildList(newIndex)
			end
		end),
	
		focusGain = async:callback(function(_, elem)
			elem.props.alpha = 0.8
			flex_V_H_V1:update()
		end),
	
		focusLoss = async:callback(function(_, elem)
			elem.props.alpha = 0.4
			flex_V_H_V1:update()
		end),
	}
	flex_V_H_V1.layout.content:add(scrollbarBackground)
	flex_V_H_V1.layout.content:add(scrollbarThumb)
	
	-- ================================================ DESCRIPTION ================================================
	createMealPreview()
	
	-- ================================================ LIST POPULATION ================================================
	-- Match the working player.lua: create listSize items (items 1 through listSize)
	for i=currentIndex, math.min(#availableIngredients, currentIndex+listSize-1) do
		addIngredientButton(i)
	end

	flex_V.layout.content:add{ props = { size = v2(1,1)*marginWidth } }
	
	-- done
	updateScrollbar()
	updateMealPreview()
end

-- ──────────────────────────────────────────────────────────────────────────────── UI CREATION ────────────────────────────────────────────────────────────────────────────────
function makeCookingUi()
	waterAmount, waterItems = checkWaterInventory()
	countContainers()
	mealCount = 1
	availableIngredients = {}
	selectedIngredients = {}
	updateCookingLevel()
	innkeeperIngredients = {}
	controllerColumn = 1
	controllerListIndex = 1
	controllerRightIndex = 2
	controllerFocusedClickbox = nil
	controllerActive = false
	controllerActivateHeld = false
	cookingHeldDirection = nil
	if cookingWithInnkeeper then
		for _, item in pairs(types.Actor.inventory(cookingWithInnkeeper):getAll(types.Ingredient)) do
			innkeeperIngredients[item.recordId] = item.count
		end
		local innkeeperRecordId = cookingWithInnkeeper.recordId
		for _, container in pairs(nearby.containers) do
			if container.owner.recordId == innkeeperRecordId then
				for _, item in pairs(types.Container.inventory(container):getAll(types.Ingredient)) do
					innkeeperIngredients[item.recordId] = (innkeeperIngredients[item.recordId] or 0) + item.count
				end
			end
		end
		for _, item in pairs(nearby.items) do
			if types.Ingredient.objectIsInstance(item) and item.owner.recordId == innkeeperRecordId then
				innkeeperIngredients[item.recordId] = (innkeeperIngredients[item.recordId] or 0) + item.count
			end
		end
	end
	-- ================================================ INGREDIENT FILTERING AND SORTING ================================================
	-- Populate with actual ingredient data from dbConsumables
	do	
		local checkedIngredients = {}
		for _, item in pairs(typesActorInventorySelf:getAll(types.Ingredient)) do
			local recordId = item.recordId
			if dbConsumables[recordId] then
				local data = dbConsumables[recordId]
				if COOKING_MODE == "Immersive" then
					if not data.ingredientClass or data.ingredientClass == "monster" or data.ingredientClass == "dubious" or not data.ingredientRank or not data.alchEffect1 then
						-- Skip this ingredient - missing required fields for Immersive cooking
						goto continue
					end
				end
				local record = item.type.record(item)
				
				local ing = {
					recordId = recordId,
					data = dbConsumables[recordId],
					name = record.name,
					count = item.count,
					innkeeperCount = innkeeperIngredients[recordId] or 0,
					value = math.ceil(record.value/2),
				}
				checkedIngredients[recordId] = true
				ing.effects, ing.harmfulEffects, ing.beneficialEffects = getIngredientEffects(ing)
				table.insert(availableIngredients, ing)
				::continue::			
			end
		end
		
		-- add innkeeper ingredients to the list
		for recordId, count in pairs(innkeeperIngredients) do
			if not checkedIngredients[recordId] and dbConsumables[recordId] then
				local data = dbConsumables[recordId]
				
				if COOKING_MODE == "Immersive" then
					if not data.ingredientClass or data.ingredientClass == "monster" or data.ingredientClass == "dubious" or not data.ingredientRank or not data.alchEffect1 then
						-- Skip this ingredient - missing required fields for Immersive cooking
						goto continue
					end
				end
				local record = types.Ingredient.record(recordId)
				local ing = {
					recordId = recordId,
					data = dbConsumables[recordId],
					name = record.name,
					count = 0,
					innkeeperCount = count,
					value = math.ceil(record.value/2),
				}
				ing.effects, ing.harmfulEffects, ing.beneficialEffects = getIngredientEffects(ing)
				table.insert(availableIngredients, ing)
				::continue::			
			end
		end
		
		
		-- IMMERSIVE MODE: Sort by ingredient class, then by rank within class
		if COOKING_MODE == "Immersive" then
			-- Define sort order for ingredient classes
			local classOrder = {
				egg = 1,
				greens = 2,
				fruit = 3,			
				mushroom = 4,
				fish = 5,			
				meat = 6,
				spices = 7,
				salts = 8,
				bread = 9,			
			}
			
			table.sort(availableIngredients, function(a, b)
				local aClass = a.data.ingredientClass or ""
				local bClass = b.data.ingredientClass or ""
				local aOrder = classOrder[aClass] or 999
				local bOrder = classOrder[bClass] or 999
				
				-- First sort by class
				if aOrder ~= bOrder then
					return aOrder < bOrder
				end
				
				-- Within same class, sort by rank (low to high)
				local aRank = a.data.ingredientRank or 1
				local bRank = b.data.ingredientRank or 1
				if aRank ~= bRank then
					return aRank < bRank
				end
				
				-- Finally by name if everything else is equal
				return a.name < b.name
			end)
		else
			-- ARCANE MODE: Sort by beneficial effects, then by harmful effects
			table.sort(availableIngredients, function(a,b) 
				if a.beneficialEffects == b.beneficialEffects then
					return a.harmfulEffects < b.harmfulEffects
				end
				return a.beneficialEffects > b.beneficialEffects
			end)
		end
	end
	
	-- ================================================ WINDOW CREATION ================================================
	
	local borderTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture{ path = 'black' },
			relativeSize = v2(1,1),
			alpha = 0.8,
		}
	}).borders

	SDCookingUI = ui.create{
		type = ui.TYPE.Widget,
		layer = 'Modal',
		name = "SDCookingUI",
		template = windowTemplate,
		props = {
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
			autoSize = false,
			size = v2(descriptionWidth + listWidth + marginWidth*4 + seperatorWidth, listHeight + textSize*1.4),
		},
		content = ui.content {},
	}
	fillCookingUi()
	local dragButton
	dragButton = ui.create{
		type = ui.TYPE.Image,
		props = {
			resource = getTexture("textures/SunsDusk/resize.png"),
			size = v2(16,16),
			color = G_morrowindGold,
			relativePosition = v2(1,1),
			position = v2(-2,-2),
			anchor = v2(1,1),
			alpha = 0.8,
		},
		events = {
			mousePress = async:callback(function(data, elem)
				if data.button == 1 then
					if not elem.userData then elem.userData = {} end
					elem.userData.isDragging = true
					elem.userData.dragStart = data.position
					elem.userData.totalWidthStart = totalWidth
					elem.userData.listHeightStart = listHeight
				end
			end),
		
			mouseRelease = async:callback(function(_, elem)
				if elem.userData then
					elem.userData.isDragging = false
				end
			end),
		
			mouseMove = async:callback(function(data, elem)
				if elem.userData and elem.userData.isDragging then
					local delta = data.position - elem.userData.dragStart
					
					cookingUiSettingsSection:set("WIDGET_WIDTH", elem.userData.totalWidthStart + delta.x*2)
					cookingUiSettingsSection:set("LIST_HEIGHT", elem.userData.listHeightStart + delta.y*2)
					
					loadUiSettings()
					
					SDCookingUI.layout.props.size = v2(descriptionWidth + listWidth + marginWidth*4 + seperatorWidth, listHeight + textSize*1.4)
					fillCookingUi()
					SDCookingUI:update()
				end
			end),
		
			focusGain = async:callback(function(_, elem)
				elem.props.alpha = 0.8
				dragButton:update()
			end),
		
			focusLoss = async:callback(function(_, elem)
				elem.props.alpha = 0.4
				dragButton:update()
			end),
		}
	}
	
	SDCookingUI.layout.content:add(dragButton)
	
end

-- ──────────────────────────────────────────────────────────────────────────────── MEAL PREVIEW FUNCTIONS ────────────────────────────────────────────────────────────────────────────────

local function applyEffectBonuses(magnitude, effectId, statMods)
	-- Apply effect-specific bonuses
	if effectId:find("resist") then
		magnitude = magnitude * statMods.resistanceMult
	elseif effectId:find("water") or effectId == "swiftswim" then
		magnitude = magnitude * statMods.waterEffectMult
	elseif effectId == "restorehealth" or effectId == "fortifyhealth" then
		magnitude = magnitude * statMods.healthEffectMult
	end
	return magnitude
end
-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ GET INGREDIENT EFFECTS												  │
-- ╰──────────────────────────────────────────────────────────────────────╯

function getIngredientEffects(ingredient)
	local record = types.Ingredient.record(ingredient.recordId)
	local effects = {}
	local harmfulEffects, beneficialEffects = 0, 0

	if not record then return effects end
	

	if COOKING_MODE == "Immersive" then
		-- Immersive mode uses Primary Effect, Secondary Effect, and Third Effect from spreadsheet data
		local data = ingredient.data
		if not data then return effects end
		
		local racialMult = 1
		for race, mult in pairs(RACIAL_MULTIPLIERS) do
			if saveData.playerInfo[race] then
				racialMult = mult
			end
		end
		local ingredientRank = data.ingredientRank or 1
		
		-- Process up to 3 alchemy effects
		local alchEffects = {
			{ id = data.alchEffect1, slot = 1 },
			{ id = data.alchEffect2, slot = 2 },
			{ id = data.alchEffect3, slot = 3 },
		}
		
		for _, alchEffect in ipairs(alchEffects) do
			if alchEffect.id and alchEffect.id ~= "" then
				local effectId = alchEffect.id:lower()
				
				-- Find the corresponding game effect
				local gameEffect = core.magic.effects.records[effectId]
				if gameEffect then
					-- Calculate chance for this effect
					-- Primary effect always succeeds, secondary effects based on skill/rank
					local chance = 0
					
					if alchEffect.slot == 1 then 
						chance = 1.0
					else
						local skillFactor = math.min(cookingLevelModified / 100, 1.0)
						local rankFactor = ingredientRank / 3  -- 0.33..1.0 for ranks 1..3
					
						if alchEffect.slot == 2 then
							local baseChance = 0.42 + (skillFactor * 0.42)  -- 0.42..0.84
							chance = baseChance * racialMult * (0.85 + rankFactor * 0.5)  -- rank helps more
							chance = math.min(math.max(chance, 0.20), 0.97)  -- min 20%, cap 97%
					
						elseif alchEffect.slot == 3 then
							local baseChance = 0.18 + (skillFactor * 0.34)  -- 0.18..0.52
							if cookingLevelModified >= 80 or racialMult >= 1.3 then
								baseChance = baseChance + 0.12  -- softer bonus than before
							end
							chance = baseChance * racialMult * (0.75 + rankFactor * 0.55)
							chance = math.min(math.max(chance, 0.15), 0.90)  -- min 15%, cap 90%
						end
					end
					
					-- Build effect display text
					local text = getMagicEffectName(effectId)
					local uniqueId = effectId
					
					-- Add skill/attribute suffix if applicable
					for _, recEffect in pairs(record.effects) do
						if recEffect.id == effectId then
							if recEffect.affectedSkill then
								text = text .. shortSkills[recEffect.affectedSkill]
								uniqueId = uniqueId .. "-" .. recEffect.affectedSkill
							elseif recEffect.affectedAttribute then
								text = text .. shortAttributes[recEffect.affectedAttribute]
								uniqueId = uniqueId .. "-" .. recEffect.affectedAttribute
							end
							break
						end
					end
					
					-- Find matched skill/attribute on this ingredient's record
					local matchedSkill, matchedAttr = nil, nil
					for _, recEffect in pairs(record.effects) do
						if recEffect.id == effectId then
							matchedSkill = recEffect.affectedSkill
							matchedAttr = recEffect.affectedAttribute
							break
						end
					end
					
					-- Get effect priority (default to 100 if not in table)
					local basePriority = effectPriorities[effectId] or 100
					
					local levelMagnitudeMult = 0.1 + cookingLevelModified / 500
					
					table.insert(effects, {
						id = effectId,
						text = text,
						uniqueId = "sd-" .. uniqueId,
						skillId = matchedSkill,
						attributeId = matchedAttr,
						icon = gameEffect.icon,
						magnitude = levelMagnitudeMult,  -- now scales to level
						chance = chance,
						slot = alchEffect.slot,
						priority = basePriority,
					})
				end
			end
		end
		
	else  -- Arcane cooking mode
		for i, effect in pairs(record.effects) do
			local text = getMagicEffectName(effect.id)
			local uniqueId = effect.id
			
			if effect.affectedSkill then
				text = text .. shortSkills[effect.affectedSkill]
				uniqueId = uniqueId .. "_" .. effect.affectedSkill
			elseif effect.affectedAttribute then
				text = text .. shortAttributes[effect.affectedAttribute]
				uniqueId = uniqueId .. "_" .. effect.affectedAttribute
			end
			
			if dailyBuffMultipliers[effect.id] and dailyBuffMultipliers[effect.id] > 0 then
				local magnitude
				local isHarmful = effect.effect.harmful
				local levelMult = 0.5 + cookingLevelModified / 25
				local strength = dailyBuffMultipliers[effect.id] * 0.06
				
				if isHarmful then
					harmfulEffects = harmfulEffects + 1
					magnitude = (ingredient.data.ingredientRank or 1) ^ 0.4 * 2 * strength / (2 + levelMult)
				else
					beneficialEffects = beneficialEffects + 1
					magnitude = (ingredient.data.ingredientRank or 1) ^ 0.5 * levelMult * strength
				end
				
				table.insert(effects, {
					id = effect.id,
					text = text,
					uniqueId = "sd_" .. uniqueId,
					skillId = effect.affectedSkill,
					attributeId = effect.affectedAttribute,
					icon = effect.effect.icon,
					magnitude = magnitude,
					score = (ingredient.data.ingredientRank or 1) ^ 0.5,
					vanillaIndex = i,
					count = 1,
				})
			end
		end
	end
	
	return effects, harmfulEffects, beneficialEffects
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ ENHANCED calculateMealStats FUNCTION								  │
-- │ Implements ingredient synergies, special combinations, and bonuses	  │
-- ╰──────────────────────────────────────────────────────────────────────╯

function calculateMealStats()
	local stats = {
		consumeCategory = "Hearty Meal",
		foodValue = 0,
		foodValue2 = 0,
		drinkValue = 0.04,
		drinkValue2 = 0,
		wakeValue = 0,
		wakeValue2 = 0,
		warmthValue = 5,
		warmthValue2 = 5,
		isToxic = false,
		isGreenPact = true,
		isCookedMeal = true,
		totalRarity = 0,
		dynamicEffects = {},
		selectedCount = 0,
		consumedIngredients = {},
		durationSuffix = 1,
		count = mealCount,
		forcedFoodware = nil,  -- set when cooking with innkeeper to override container selection
		innkeeper = cookingWithInnkeeper,
		-- Recipe fields (set later based on ingredients)
		recipeName = nil,
		recipeIcon = nil,
		recipeItemId = nil,
		recipeMesh = nil,
		--longLasting = true,
	}
	
	
	-- Get sorted indices
	local sortedIndices = {}
	for idx, _ in pairs(selectedIngredients) do
		table.insert(sortedIndices, idx)
		stats.selectedCount = stats.selectedCount + 1
	end
	
	if stats.selectedCount == 0 then
		return stats
	end
	
	table.sort(sortedIndices)
	
	local statMods = {
		magnitudeMult = 1.0,
		magnitudeMod = 0,
		chanceMult = 1.0,
		chanceMod = 0,
		foodValueMult = 1.0,
		foodValueMod = 0,
		drinkValueMult = 1.0,
		drinkValueMod = 0,
		wakeValueMult = 1.0,
		wakeValueMod = 0,
		healthEffectMult = 1.0,
		resistanceMult = 1.0,
		waterEffectMult = 1.0,
		xpMult = 1.0,
	}
	
	-- Find matching recipe based on selected ingredients
	local ingredientsList = {}
	for _, idx in ipairs(sortedIndices) do
		local ingredient = availableIngredients[idx]
		if ingredient then
			table.insert(ingredientsList, ingredient)
		end
	end
	
	local recipe = cookingRecipes.findMatchingRecipe(ingredientsList, stats.isGreenPact)
	stats.recipeId = recipe.id
	stats.recipeName = recipe.name
	stats.recipeIcon = recipe.icon
	stats.isSoup = recipe.isSoup or false
	if recipe.mods and (not recipe.book or cookingData.readRecipes[recipe.book]) then
		log(3, "[Immersive Cooking] Special combination: " .. recipe.name .. " (known)")
		for key, value in pairs(recipe.mods) do
			if key:match("Mult$") then
				statMods[key] = statMods[key] * value
			else
				statMods[key] = statMods[key] + value
			end
		end
	else
		log(3, "[Immersive Cooking] Special combination: " .. recipe.name .. " (recipe unknown)")
	end
	
	-- elemental salt cooling
	for idx, _ in pairs(selectedIngredients) do
		local ingredient = availableIngredients[idx]
		if ingredient then
			if ingredient.recordId == "ingred_frost_salts_01" then
				stats.warmthValue = math.min(stats.warmthValue, 0) - 5
				stats.warmthValue2 = math.min(stats.warmthValue2, 0) - 5
			elseif ingredient.recordId == "ingred_fire_salts_01" then
				stats.warmthValue = math.max(stats.warmthValue, 5) + 5
				stats.warmthValue2 = math.max(stats.warmthValue2, 5) + 5
			end
		end
	end
	
	
	-- ═══════════════════════════════════════════════════════════════════════
	-- IMMERSIVE COOKING MODE
	-- ═══════════════════════════════════════════════════════════════════════
	if COOKING_MODE == "Immersive" then
		stats.shortBuff = true
		
		
		-- ── Calculate total ingredient rank and buff tier ──
		-- Sum of ingredient ranks determines buff tier
		-- These thresholds can be adjusted for balance
		local totalRank = 0
		for idx, _ in pairs(selectedIngredients) do
			local ingredient = availableIngredients[idx]
			if ingredient and ingredient.data then
				totalRank = totalRank + (ingredient.data.ingredientRank or 1)
			end
		end
		
		local buffRank = 1
		
		if totalRank <= 2 then
			buffRank = 1  -- Weakest buff
		elseif totalRank <= 4 then
			buffRank = 1.5  -- Weak buff +0.5
		elseif totalRank <= 6 then
			buffRank = 2.05  -- Mid buff +0.55
		elseif totalRank <= 9 then
			buffRank = 2.65  -- Good buff +0.6
		else
			buffRank = 3.3  -- Max buff +0.65
		end
			
		
		stats.buffRank = buffRank
		
		local levelDurationBonus = 0.2 + cookingLevelModified / 15
		local rankDurationBonus = totalRank * 0.2
		local durationRank = levelDurationBonus + rankDurationBonus
		stats.durationSuffix = math.min(4, math.max(1, math.floor(durationRank + 0.5)))  -- Duration uses buff rank (30 seconds * rank)
		stats.totalRarity = totalRank  -- Store for display
		
		-- ── Count ingredients by class ──
		local classCounts = {
			egg = 0,
			bread = 0,
			greens = 0,
			mushroom = 0,
			salts = 0,
			meat = 0,
			fish = 0,
			spices = 0,
			fruit = 0,
		}
		
		for idx, _ in pairs(selectedIngredients) do
			local ingredient = availableIngredients[idx]
			if ingredient and ingredient.data then
				local class = ingredient.data.ingredientClass
				if class and classCounts[class] then
					classCounts[class] = classCounts[class] + 1
				end
			end
		end
		
		-- ── Apply ingredient class modifiers ──
		for class, mods in pairs(CLASS_MODS) do
			if classCounts[class] and classCounts[class] > 0 then
				for key, value in pairs(mods) do
					if key:match("Mult$") then
						statMods[key] = statMods[key] * value
					else
						statMods[key] = statMods[key] + value
					end
				end
				
				-- Log modifier application
				if class == "salts" then
					log(3, "[Immersive Cooking] Salt bonus: +50% effect chance, -20% thirst")
				elseif class == "spices" then
					log(3, "[Immersive Cooking] Spice bonus: +25% food, +15% magnitude")
				end
			end
		end
		
		-- Quality ingredients (fish, greens, meat) increase XP
		local qualityCount = classCounts.fish + classCounts.greens + classCounts.meat
		if qualityCount > 0 then
			statMods.xpMult = statMods.xpMult * (1 + qualityCount * 0.15)
		end
		
		stats.xpMultiplier = statMods.xpMult
		
		-- ═══════════════════════════════════════════════════════════════════════
		-- Track effect counts across ALL ingredients for matching bonus
		-- ═══════════════════════════════════════════════════════════════════════
		local effectCounts = {}  -- effectId -> count of ingredients with this effect
		
		-- Count all effects across ingredients
		for _, idx in ipairs(sortedIndices) do
			local ingredient = availableIngredients[idx]
			if ingredient then
				local ingredientEffects = getIngredientEffects(ingredient)
				local seenInThisIngredient = {}
				for _, effect in pairs(ingredientEffects) do
					if not seenInThisIngredient[effect.id] then
						effectCounts[effect.id] = (effectCounts[effect.id] or 0) + 1
						seenInThisIngredient[effect.id] = true
					end
				end
			end
		end
		
		-- Count unique effects for diversity penalty
		local uniqueEffects = 0
		for _ in pairs(effectCounts) do
			uniqueEffects = uniqueEffects + 1
		end
		
		-- Calculate diversity penalty: more unique effects = harder to get secondary effects
		-- No penalty for 1-3 unique effects, starts penalizing at 4+
		local diversityPenalty = uniqueEffects <= 3 and 1.0 or (1.0 / (uniqueEffects - 2))
		log(3, string.format("[Immersive Cooking] Unique effects: %d, Diversity penalty: %.2f", 
			uniqueEffects, diversityPenalty))
		
		-- ═══════════════════════════════════════════════════════════════════════
		-- Process each selected ingredient
		-- ═══════════════════════════════════════════════════════════════════════
		for _, idx in ipairs(sortedIndices) do
			local ingredient = availableIngredients[idx]
			if ingredient and ingredient.data then
				stats.consumedIngredients[ingredient.recordId] = (stats.consumedIngredients[ingredient.recordId] or 0) + mealCount
				
				-- Accumulate base values
				stats.foodValue = stats.foodValue + (ingredient.data.foodValue or 0)
				stats.drinkValue = stats.drinkValue + (ingredient.data.drinkValue or 0)
				stats.wakeValue = stats.wakeValue + (ingredient.data.wakeValue or 0)
				stats.totalRarity = stats.totalRarity + (ingredient.data.ingredientRank or 1)
				
				if not ingredient.data.isGreenPact then
					stats.isGreenPact = false
				end
				
				-- ── Process effects with chance rolls ──
				for _, effect in pairs(getIngredientEffects(ingredient)) do
					local effectKey = effect.uniqueId .. stats.durationSuffix
					
					-- Initialize effect entry if not exists
					if not stats.dynamicEffects[effectKey] then
						stats.dynamicEffects[effectKey] = {
							id = effect.id,
							text = effect.text,
							uniqueId = effect.uniqueId,
							skillId = effect.skillId,
							attributeId = effect.attributeId,
							icon = effect.icon,
							magnitude = 0,
							potentialContributors = 0,
							successfulContributors = 0,  -- Track count of successful rolls
							slot = effect.slot,
							priority = effect.priority,
						}
					else
						-- Keep the lowest (best) slot
						stats.dynamicEffects[effectKey].slot = math.min(stats.dynamicEffects[effectKey].slot, effect.slot)
					end
				
					-- Track how many ingredients can provide this effect (for display)
					stats.dynamicEffects[effectKey].potentialContributors = stats.dynamicEffects[effectKey].potentialContributors + 1
					
					-- Roll for effect inclusion based on chance
					local includeEffect = false
					local finalChance = 1.0  -- Default for slot 1
					
					if effect.slot == 1 then
						-- Primary effect always included
						includeEffect = true
					else
						-- Apply base chance with bonuses
						local adjustedChance = effect.chance * statMods.chanceMult + statMods.chanceMod
						
						-- Matching effect bonus: +20% per additional matching ingredient
						local matchCount = effectCounts[effect.id] or 1
						local matchBonus = (matchCount - 1) * 0.20
						adjustedChance = adjustedChance * (1 + matchBonus)
						
						-- Apply diversity penalty
						adjustedChance = adjustedChance * diversityPenalty
						
						-- Store for display
						finalChance = adjustedChance
						
						-- Roll for inclusion
						includeEffect = math.random() < adjustedChance
					end
					
					-- Store the chance value for ALL effects (for preview display)
					stats.dynamicEffects[effectKey].chance = finalChance
					
					if includeEffect then
						-- Calculate magnitude with bonuses
						local magnitude = effect.magnitude * statMods.magnitudeMult + statMods.magnitudeMod
						magnitude = applyEffectBonuses(magnitude, effect.id, statMods)
						
						stats.dynamicEffects[effectKey].magnitude = stats.dynamicEffects[effectKey].magnitude + magnitude
						
						-- Increment successful contributor count
						stats.dynamicEffects[effectKey].successfulContributors = stats.dynamicEffects[effectKey].successfulContributors + 1
					end
				end
			end
		end
		
		-- ═══════════════════════════════════════════════════════════════════════
		-- PITY ROLL: Ensure at least one secondary effect for 3+ ingredient meals
		-- If both secondaries failed, re-roll the better one with advantage
		-- ═══════════════════════════════════════════════════════════════════════
		local slots = {
			[2] = { landed = false, bestChance = 0, bestEffect = nil },
			[3] = { landed = false, bestChance = 0, bestEffect = nil }
		}
		
		-- Collect which secondary effects landed and track best fallback chances
		for _, effect in pairs(stats.dynamicEffects) do
			local slot = slots[effect.slot]
			if slot then
				local hasLanded = (effect.successfulContributors or 0) > 0
				local chance = effect.chance or 0
				
				slot.landed = slot.landed or hasLanded
				if chance > slot.bestChance then
					slot.bestChance = chance
					slot.bestEffect = effect
				end
			end
		end
		
		-- Advantage reroll if both slots failed with 3+ ingredients
		if stats.selectedCount >= 3 and not slots[2].landed and not slots[3].landed then
			-- Pick the slot with higher chance to reroll
			local slotToReroll = slots[2].bestChance >= slots[3].bestChance and slots[2] or slots[3]
			
			-- Advantage: 1.15x multiplier, capped at 98%, rolled twice
			-- Formula: 1 - (1 - p)^2 (two tries)
			local advantageChance = 1 - (1 - math.min(0.98, slotToReroll.bestChance * 1.15))^2
			
			if math.random() < advantageChance and slotToReroll.bestEffect then
				slotToReroll.bestEffect.successfulContributors = 1
			end
		end
		
		-- ═══════════════════════════════════════════════════════════════════════
		-- Calculate final magnitudes based on buff rank
		-- ═══════════════════════════════════════════════════════════════════════
		for effectKey, effect in pairs(stats.dynamicEffects) do
			-- Base magnitude determined by effect slot and buff rank
			local baseMagnitude = effect.slot == 1 and (10 * buffRank) or (5 * buffRank)
			baseMagnitude = baseMagnitude * COOKING_MAGNITUDE_MULT * effect.magnitude
			-- Primary effects: 10/20/30/40
			-- Secondary effects: 5/10/15/20
			
			-- ── PREVIEW CALCULATION ──
			-- Calculate preview magnitude (for UI display before rolling)
			-- This shows what the magnitude would be if all potential contributors succeed
			local previewMagnitude = baseMagnitude * math.max(1, effect.potentialContributors)
			previewMagnitude = applyEffectScaling(previewMagnitude, effect.id)
			previewMagnitude = previewMagnitude * statMods.magnitudeMult + statMods.magnitudeMod
			previewMagnitude = applyEffectBonuses(previewMagnitude, effect.id, statMods)
			previewMagnitude = math.max(5, math.min(75, math.floor(previewMagnitude / 5) * 5))

			stats.dynamicEffects[effectKey].previewMagnitude = previewMagnitude
			
			-- ── ACTUAL CALCULATION ──
			-- Skip effects where no ingredients passed their roll
			if (effect.successfulContributors or 0) > 0 then
				local finalMagnitude = baseMagnitude * math.max(1, effect.potentialContributors)
				finalMagnitude = applyEffectScaling(finalMagnitude, effect.id)
				finalMagnitude = finalMagnitude * statMods.magnitudeMult + statMods.magnitudeMod
				finalMagnitude = applyEffectBonuses(finalMagnitude, effect.id, statMods)
				finalMagnitude = math.max(5, math.min(75, math.floor(finalMagnitude / 5) * 5))
				
				stats.dynamicEffects[effectKey].magnitude = finalMagnitude
				--print(string.format("DEBUG %s: slot=%d potC=%d sucC=%d baseMag=%d final=%d",
				--	effect.text,
				--	effect.slot,
				--	effect.potentialContributors,
				--	effect.successfulContributors,
				--	baseMagnitude,
				--	finalMagnitude
				--))
				log(4, string.format(
					"[Effect Magnitude] %s: rank=%d base=%d contributors=%d final=%d",
					effect.text,
					buffRank,
					baseMagnitude,
					effect.successfulContributors,
					finalMagnitude
				))
			end
		end
		
		-- ── Apply food/drink/wake modifiers ──
		stats.foodValue = stats.foodValue * statMods.foodValueMult + statMods.foodValueMod
		stats.drinkValue = stats.drinkValue * statMods.drinkValueMult + statMods.drinkValueMod
		stats.wakeValue = stats.wakeValue * statMods.wakeValueMult + statMods.wakeValueMod
		
		--stats.foodValue2 = (stats.foodValue2 + stats.foodValue / 7) * (0.8 + cookingLevelModified / 50)
		--stats.drinkValue2 = (stats.drinkValue2 + stats.drinkValue / 7) * (0.8 + cookingLevelModified / 50)
		--stats.wakeValue2 = (stats.wakeValue2 + stats.wakeValue / 3) * (0.8 + cookingLevelModified / 50)
		
		
		-- Apply cooking level modifiers to food/drink/wake values
		stats.foodValue = stats.foodValue * (0.8 + cookingLevelModified / 100)
		stats.drinkValue = stats.drinkValue * (0.8 + cookingLevelModified / 100)
		stats.wakeValue = stats.wakeValue * (0.8 + cookingLevelModified / 100)
		

		
		-- Special rules for single ingredient meals
		if stats.selectedCount == 1 then
			local ingredient = availableIngredients[sortedIndices[1]]
			if ingredient and ingredient.data then
				if ingredient.data.consumeCategory == "Very Small" then
					stats.foodValue = stats.foodValue * 2.0
					log(3, "[Immersive Cooking] Single tiny ingredient: +100% food value")
				end
			end
		end
		
	-- ═══════════════════════════════════════════════════════════════════════
	-- ARCANE COOKING MODE
	-- ═══════════════════════════════════════════════════════════════════════
	else
		if COOKING_MODE == "Arcane Cooking (24 Hours)" then
			stats.durationSuffix = 2
		end
		stats.drinkValue2 = 0.04
		
		for _, idx in ipairs(sortedIndices) do
			local ingredient = availableIngredients[idx]
			if ingredient and ingredient.data then
				stats.consumedIngredients[ingredient.recordId] = 
					(stats.consumedIngredients[ingredient.recordId] or 0) + mealCount
				
				stats.foodValue = stats.foodValue + (ingredient.data.foodValue or 0) / 2
				stats.drinkValue = stats.drinkValue + (ingredient.data.drinkValue or 0) / 2
				stats.wakeValue = stats.wakeValue + (ingredient.data.wakeValue or 0) / 2
				stats.totalRarity = stats.totalRarity + (ingredient.data.ingredientRank or 1)
				
				if ingredient.data.isToxic then
					stats.isToxic = true
				end
				if not ingredient.data.isGreenPact then
					stats.isGreenPact = false
				end

				for _, effect in pairs(getIngredientEffects(ingredient)) do
					local effectKey = effect.uniqueId .. stats.durationSuffix
					if not stats.dynamicEffects[effectKey] then
						stats.dynamicEffects[effectKey] = effect
						stats.dynamicEffects[effectKey].magnitude = stats.dynamicEffects[effectKey].magnitude * COOKING_MAGNITUDE_MULT * statMods.magnitudeMult
					else
						stats.dynamicEffects[effectKey].magnitude = stats.dynamicEffects[effectKey].magnitude + effect.magnitude * COOKING_MAGNITUDE_MULT * statMods.magnitudeMult
						stats.dynamicEffects[effectKey].score = stats.dynamicEffects[effectKey].score + effect.score
						stats.dynamicEffects[effectKey].vanillaIndex = math.min(stats.dynamicEffects[effectKey].vanillaIndex, effect.vanillaIndex)
						stats.dynamicEffects[effectKey].count = stats.dynamicEffects[effectKey].count + 1
					end
					stats.dynamicEffects[effectKey].visibleInPreview = stats.dynamicEffects[effectKey].visibleInPreview or isEffectVisible(ingredient, effect)
				end
			end
		end
		
		stats.foodValue2 = (stats.foodValue2 + stats.foodValue / 6.5) * (0.8 + cookingLevelModified / 50)
		stats.drinkValue2 = (stats.drinkValue2 + stats.drinkValue / 6.5) * (0.8 + cookingLevelModified / 50)
		stats.wakeValue2 = (stats.wakeValue2 + stats.wakeValue / 2.7) * (0.8 + cookingLevelModified / 50)
		
		stats.foodValue = stats.foodValue * (0.8 + cookingLevelModified / 100)
		stats.drinkValue = stats.drinkValue * (0.8 + cookingLevelModified / 100)
		stats.wakeValue = stats.wakeValue * (0.8 + cookingLevelModified / 100)
	end

	return stats
end

function createMealPreview()
	-- Preview title
	flex_V_H_V3.layout.content:add{
		name = 'previewTitle',
		type = ui.TYPE.Text,
		props = {
			text = "Meal Preview",
			textColor = G_morrowindGold,
			textShadow = true,
			textShadowColor = util.color.rgb(0,0,0),
			textSize = textSize,
			textAlignH = ui.ALIGNMENT.Center,
		},
	}
	
	flex_V_H_V3.layout.content:add{ props = { size = v2(1,1)*5 } }
	
	flex_V_H_V3_H1 = {
		type = ui.TYPE.Flex,
		name = "selectedIngredientsList",
		props = {
			horizontal = true,
			autoSize = true,
			align =ui.ALIGNMENT.Start,
			arrange =ui.ALIGNMENT.Start,
		},
		content = ui.content{},
	}
	flex_V_H_V3.layout.content:add(flex_V_H_V3_H1)
	
	--local flavorButton
	--flavorButton = makeButton(nil, {size = v2(100, 100)}, confirmCooking, darkenColor(G_morrowindGold, 0.4), flex_V_H_V3, getTexture("textures/SunsDusk/pot0.png"), nil, getTexture("textures/SunsDusk/pot4.png"))
	--mealPreviewElements.flavorImage = flavorButton.image
	--mealPreviewElements.cookButton = flavorButton
	--flex_V_H_V3_H1.content:add(flavorButton.box)
	
	-- Create vertical container for cooking button and meal count
	local cookingButtonContainer = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			autoSize = true,
			align = ui.ALIGNMENT.Center,
		},
		content = ui.content{},
	}
	flex_V_H_V3_H1.content:add(cookingButtonContainer)
	
	local flavorButton
	flavorButton = makeButton(nil, {size = v2(100, 100)}, confirmCooking, darkenColor(G_morrowindGold, 0.4), flex_V_H_V3, getTexture("textures/SunsDusk/pot0.png"), nil, getTexture("textures/SunsDusk/pot4.png"))
	mealPreviewElements.flavorImage = flavorButton.image
	mealPreviewElements.cookButton = flavorButton
	cookingButtonContainer.content:add(flavorButton.box)
	
	cookingButtonContainer.content:add{ props = { size = v2(1,1)*5 } }
	
	-- Meal count selector
	local mealCountContainer = {
		type = ui.TYPE.Container,
		props = {
			size = v2(100,25),
		},
		content = ui.content{},
	}
	cookingButtonContainer.content:add(mealCountContainer)
	
	-- Minus button
	local minusButton = makeButton("-", {size = v2(25, 25)}, function()
		if mealCount > 1 then
			local mod = 1
			if input.isShiftPressed() then
				mod = 5
			end
			if input.isCtrlPressed() then
				mealCount = 1
			else
				mealCount = math.max(1,mealCount - mod)
			end
			updateMealPreview()
		end
	end, G_morrowindGold, SDCookingUI)
	mealCountContainer.content:add(minusButton.box)
	
	
	-- Count text
	mealPreviewElements.mealCountText = {
		type = ui.TYPE.Text,
		props = {
			text = tostring(mealCount),
			textColor = G_morrowindGold,
			textShadow = true,
			textShadowColor = util.color.rgb(0,0,0),
			textSize = textSize*0.8,
			textAlignH = ui.ALIGNMENT.Center,
			size = v2(30, 25),
			position = v2(50, 0),
			anchor = v2(0.5,0),
		},
	}
	mealCountContainer.content:add(mealPreviewElements.mealCountText)
	
	
	-- Plus button
	local plusButton = makeButton("+", {size = v2(25, 25), position = v2(75,0)}, function()
		local maxMeals = calculateMaxMeals()
		if mealCount < maxMeals then
			local mod = 1
			if input.isShiftPressed() then
				mod = 5
			end
			
			if input.isCtrlPressed() then
				mealCount = maxMeals
			else
				mealCount = math.min(maxMeals, mealCount + mod)
			end
			updateMealPreview()
		end
	end, G_morrowindGold, SDCookingUI)
	mealCountContainer.content:add(plusButton.box)
	mealPreviewElements.minusButton = minusButton
	mealPreviewElements.plusButton = plusButton
	
	
	flex_V_H_V3_H1.content:add{ props = { size = v2(1,1)*10 } }
	-- Selected ingredients list container
	mealPreviewElements.ingredientsContainer = ui.create{
		type = ui.TYPE.Flex,
		name = "selectedIngredientsList",
		props = {
			horizontal = false,
			autoSize = true,
		},
		content = ui.content{},
	}
	--flex_V_H_V3.layout.content:add(mealPreviewElements.ingredientsContainer)
	flex_V_H_V3_H1.content:add(mealPreviewElements.ingredientsContainer)
	flex_V_H_V3.layout.content:add{ props = { size = v2(1,1)*10 } }
	
	-- Divider (above stats)
	flex_V_H_V3.layout.content:add{
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = 'white' },
			size = v2(descriptionWidth-marginWidth*8, 2),
			color = G_morrowindGold,
			alpha = 0.5,
		},
	}
	flex_V_H_V3.layout.content:add{ props = { size = v2(1,1)*10 } }
	
	-- Horizontal container for stats/warnings and effects
	local statsEffectsContainer = ui.create{
		type = ui.TYPE.Flex,
		name = "statsEffectsContainer",
		props = {
			horizontal = true,
			autoSize = true,
		},
		content = ui.content{},
	}
	flex_V_H_V3.layout.content:add(statsEffectsContainer)
	
	-- Left side: Stats and warnings
	local leftStatsContainer = ui.create{
		type = ui.TYPE.Flex,
		name = "leftStatsContainer",
		props = {
			horizontal = false,
			autoSize = true,
		},
		content = ui.content{},
	}
	statsEffectsContainer.layout.content:add(leftStatsContainer)
	
	-- Accumulated values section
	mealPreviewElements.statsContainer = ui.create{
		type = ui.TYPE.Flex,
		name = "statsContainer",
		props = {
			horizontal = false,
			autoSize = true,
		},
		content = ui.content{},
	}
	leftStatsContainer.layout.content:add(mealPreviewElements.statsContainer)
	
	-- Stats text elements
	mealPreviewElements.foodValueText = createStatText("Food: 0")
	mealPreviewElements.drinkValueText = createStatText("Drink: 0")
	mealPreviewElements.wakeValueText = createStatText("Wake: 0")
	mealPreviewElements.warmthValueText = createStatText("Warmth: 0")
	
	leftStatsContainer.layout.content:add{ props = { size = v2(1,1)*5 } }
	
	-- Warnings section (directly under stats, no divider)
	mealPreviewElements.warningsContainer = ui.create{
		type = ui.TYPE.Flex,
		name = "warningsContainer",
		props = {
			horizontal = false,
			autoSize = true,
		},
		content = ui.content{},
	}
	leftStatsContainer.layout.content:add(mealPreviewElements.warningsContainer)
	
	-- Container availability warnings (only when not cooking with innkeeper)
	if not cookingWithInnkeeper then
		local totalContainers = containerCounts.bowls + containerCounts.plates
		if totalContainers == 0 then
			mealPreviewElements.warningsContainer.layout.content:add{
				type = ui.TYPE.Text,
				props = {
					text = "No containers available!",
					textColor = util.color.rgb(1, 0.3, 0.3),
					textShadow = true,
					textSize = textSize * 0.7,
				},
			}
		elseif totalContainers < mealCount then
			mealPreviewElements.warningsContainer.layout.content:add{
				type = ui.TYPE.Text,
				props = {
					text = "Only " .. totalContainers .. " containers available",
					textColor = util.color.rgb(1, 0.8, 0.3),
					textShadow = true,
					textSize = textSize * 0.7,
				},
			}
		end
	end
	
	-- Spacer before vertical line
	--statsEffectsContainer.layout.content:add{ props = { size = v2(15,1) } }
	
	-- Vertical separator line
	statsEffectsContainer.layout.content:add{
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = 'white' },
			size = v2(2, 150),
			color = G_morrowindGold,
			alpha = 0.4,
		},
	}
	
	-- Spacer after vertical line
	statsEffectsContainer.layout.content:add{ props = { size = v2(5,1) } }
	
	-- Right side: Effects
	mealPreviewElements.effectsContainer = ui.create{
		type = ui.TYPE.Flex,
		name = "effectsContainer",
		props = {
			horizontal = false,
			autoSize = true,
		},
		content = ui.content{},
	}
	statsEffectsContainer.layout.content:add(mealPreviewElements.effectsContainer)
end

function createStatText(text)
	local textElement = {
		name = 'statText',
		type = ui.TYPE.Text,
		props = {
			text = text,
			textColor = G_lightText,
			textShadow = true,
			textShadowColor = util.color.rgb(0,0,0),
			textSize = textSize*0.7,
			textAlignH = ui.ALIGNMENT.Start,
			size = v2((descriptionWidth-marginWidth*5)/2, textSize*0.7),
			autoSize = false
		},
	}
	mealPreviewElements.statsContainer.layout.content:add(textElement)
	mealPreviewElements.statsContainer.layout.content:add{ props = { size = v2(1,1)*3 } }
	return textElement
end

function updateMealPreview()
	-- Clear ingredient list display
	mealPreviewElements.ingredientsContainer.layout.content = ui.content{}
	local ingredientRow = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			autoSize = true,
		},
		content = ui.content{},
	}
	-- Get calculated meal stats
	local mealStats = calculateMealStats()
	local selectedCount = mealStats.selectedCount
	-- Update meal count display and buttons
	if mealPreviewElements.mealCountText then
		local maxMeals = calculateMaxMeals()
		if input.isShiftPressed() then
			mealCount = maxMeals
		end
		if mealCount > maxMeals then
			mealCount = maxMeals
		elseif mealCount == 0 and maxMeals > 0 then
			mealCount = 1
		end
		mealPreviewElements.mealCountText.props.text = tostring(mealCount)
		
		-- Update button states
		if mealPreviewElements.minusButton then
			mealPreviewElements.minusButton.clickbox.userData.selected = (mealCount > 1)
			mealPreviewElements.minusButton.applyColor()
		end
		if mealPreviewElements.plusButton then
			mealPreviewElements.plusButton.clickbox.userData.selected = (mealCount < maxMeals)
			mealPreviewElements.plusButton.applyColor()
		end
	end
	
	if cookingWithInnkeeper then
		-- GOLD ROW (for innkeeper cooking)
		local playerGold = getPlayerGold()
		local ingredientCost = calculateIngredientCost(mealCount)
		local totalCost = INNKEEPER_MEAL_COST * mealCount + ingredientCost
		ingredientRow.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("icons/m/tx_gold_001.dds"),
				size = v2(16, 16),
			},
		}
		ingredientRow.content:add{ props = { size = v2(5,1) } }
		ingredientRow.content:add{
			name = 'ingredientItem',
			type = ui.TYPE.Text,
			props = {
				text = "Gold (" .. totalCost .. "g / " .. playerGold .. "g)",
				textColor = G_morrowindGold,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = textSize*0.7,
				textAlignH = ui.ALIGNMENT.Start,
			},
		}
		mealPreviewElements.ingredientsContainer.layout.content:add(ingredientRow)
		mealPreviewElements.ingredientsContainer.layout.content:add{ props = { size = v2(1,1)*2 } }
	else
		-- WATER ROW
		ingredientRow.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/SunsDusk/water.png"),
				size = v2(16, 16),
			},
		}
		ingredientRow.content:add{ props = { size = v2(5,1) } }
		
		local waterAmountStr
		if waterAmount >= 1000 then
			local liters = waterAmount / 1000
			local rounded = math.floor(liters / 0.5 + 0.5) * 0.5
			local str = string.format("%.1f", rounded)
			str = str:gsub("%.0$", "")  -- Remove .0
			waterAmountStr = str .. "L"
		else
			waterAmountStr = tostring(math.floor(waterAmount + 0.5)) .. " ml"
		end
		
		-- Add ingredient name
		ingredientRow.content:add{
			name = 'ingredientItem',
			type = ui.TYPE.Text,
			props = {
				text = "Water (".. COOKING_WATER_MULT*250 .."ml / ".. waterAmountStr ..")", 
				textColor = G_morrowindGold,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = textSize*0.7,
				textAlignH = ui.ALIGNMENT.Start,
			},
		}
		
		mealPreviewElements.ingredientsContainer.layout.content:add(ingredientRow)
		mealPreviewElements.ingredientsContainer.layout.content:add{ props = { size = v2(1,1)*2 } }
		
		-- FOODWARE ROW
		local totalFoodware = containerCounts.bowls + containerCounts.plates
		local foodwareRow = {
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = true,
			},
			content = ui.content{},
		}
		local foodwareIcon = containerCounts.icon or "icons/m/Misc_Com_Wood_Bowl_02.dds"
		foodwareRow.content:add{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture(foodwareIcon),
				size = v2(16, 16),
			},
		}
		foodwareRow.content:add{ props = { size = v2(5,1) } }
		foodwareRow.content:add{
			type = ui.TYPE.Text,
			props = {
				text = "Foodware [" .. totalFoodware .. "]",
				textColor = G_morrowindGold,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = textSize*0.7,
				textAlignH = ui.ALIGNMENT.Start,
			},
		}
		mealPreviewElements.ingredientsContainer.layout.content:add(foodwareRow)
		mealPreviewElements.ingredientsContainer.layout.content:add{ props = { size = v2(1,1)*2 } }
	end		
			

	
	-- Display selected ingredients
	local sortedIndices = {}
	for idx, _ in pairs(selectedIngredients) do
		table.insert(sortedIndices, idx)
	end
	table.sort(sortedIndices)
	local countIngredients = 0
	for _, idx in ipairs(sortedIndices) do
		local ingredient = availableIngredients[idx]
		if ingredient and ingredient.data then
			countIngredients = countIngredients + 1
			-- Create horizontal flex for icon + text
			local ingredientRow = {
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
					autoSize = true,
				},
				content = ui.content{},
			}
			
			-- Add icon
			local iconPath = types.Ingredient.record(ingredient.recordId).icon
			if iconPath then
				ingredientRow.content:add{
					type = ui.TYPE.Image,
					props = {
						resource = getTexture(iconPath),
						size = v2(16, 16),
					},
				}
				ingredientRow.content:add{ props = { size = v2(5,1) } }
			end
			
			-- Add ingredient name (with cost if cooking with innkeeper)
			local ingredientText = ingredient.name.." ["..(ingredient.data.ingredientRank or 1).."]"
			
			-- Show per-ingredient cost when cooking with innkeeper
			if cookingWithInnkeeper and ingredient.innkeeperCount > 0 then
				local boughtFromInnkeeper = math.min(mealCount, ingredient.innkeeperCount)
				local ingredientCost = boughtFromInnkeeper * (ingredient.value or 0)
				if ingredientCost > 0 then
					ingredientText = ingredientText .. " (" .. ingredientCost .. "g)"
				end
			end
			
			ingredientRow.content:add{
				name = 'ingredientItem',
				type = ui.TYPE.Text,
				props = {
					text = ingredientText,
					textColor = G_morrowindGold,
					textShadow = true,
					textShadowColor = util.color.rgb(0,0,0),
					textSize = textSize*0.7,
					textAlignH = ui.ALIGNMENT.Start,
				},
			}
			
			mealPreviewElements.ingredientsContainer.layout.content:add(ingredientRow)
			mealPreviewElements.ingredientsContainer.layout.content:add{ props = { size = v2(1,1)*2 } }
		end
	end
	
	-- Add clear button below ingredients if there are selected ingredients
	if selectedCount > 0 then
		mealPreviewElements.ingredientsContainer.layout.content:add{ props = { size = v2(1,1)*1 } }
		local clearButton = makeButton("Clear", {size = v2(70, 25)}, function()
			clearSelection()
		end, util.color.rgb(0.8, 0.2, 0.2), SDCookingUI)
		mealPreviewElements.ingredientsContainer.layout.content:add(clearButton.box)
		mealPreviewElements.clearButton = clearButton
	else
		mealPreviewElements.clearButton = nil
	end
	
	mealPreviewElements.flavorImage.props.resource = getTexture("textures/SunsDusk/pot"..countIngredients..".png")
	mealPreviewElements.cookButton.box :update()
	
	-- Update stat texts using calculated stats
	if mealStats.foodValue > 0 and mealStats.selectedCount > 0 then
		mealPreviewElements.foodValueText.props.text = string.format("Food Value: %i+%i", mealStats.foodValue*200, mealStats.foodValue2*200)
	else
		mealPreviewElements.foodValueText.props.text = ""
	end
	
	if mealStats.drinkValue > 0 and mealStats.selectedCount > 0 then
		mealPreviewElements.drinkValueText.props.text = string.format("Drink Value: %i+%i", mealStats.drinkValue*200, mealStats.drinkValue2*200)
	else
		mealPreviewElements.drinkValueText.props.text = ""
	end
	
	if mealStats.wakeValue > 0 and mealStats.selectedCount > 0 then
		mealPreviewElements.wakeValueText.props.text = string.format("Wake Value: %i+%i", mealStats.wakeValue*200, mealStats.wakeValue2*200)
	else
		mealPreviewElements.wakeValueText.props.text = ""
	end
	
	if (mealStats.warmthValue ~= 0 or mealStats.warmthValue2 ~= 0) and mealStats.selectedCount > 0 then
		mealPreviewElements.warmthValueText.props.text = string.format("Warmth Value: %s/%s", formatTemperatureModifier(mealStats.warmthValue), formatTemperatureModifier(mealStats.warmthValue2))
	else
		mealPreviewElements.warmthValueText.props.text = ""
	end
	
	-- Update warnings using calculated stats
	mealPreviewElements.warningsContainer.layout.content = ui.content{}
	
	if selectedCount > 0 then
		if mealStats.isToxic then
			mealPreviewElements.warningsContainer.layout.content:add{
				type = ui.TYPE.Text,
				props = {
					text = "Toxic",
					textColor = util.color.rgb(0.9, 0.2, 0.2),
					textShadow = true,
					textShadowColor = util.color.rgb(0,0,0),
					textSize = textSize*0.7,
					textAlignH = ui.ALIGNMENT.Start,
				},
			}
			mealPreviewElements.warningsContainer.layout.content:add{ props = { size = v2(1,1)*3 } }
		end
		
		if mealStats.isGreenPact then
			mealPreviewElements.warningsContainer.layout.content:add{
				type = ui.TYPE.Text,
				props = {
					text = "Green Pact",
					textColor = util.color.rgb(0.4, 0.8, 0.4),
					textShadow = true,
					textShadowColor = util.color.rgb(0,0,0),
					textSize = textSize*0.7,
					textAlignH = ui.ALIGNMENT.Start,
				},
			}
		end
	end
	
	-- Update effects using calculated stats
	mealPreviewElements.effectsContainer.layout.content = ui.content{}
	
	if selectedCount > 0 then
		-- Display effects from calculated stats
		local sortedList = {}
		for i, effect in pairs(mealStats.dynamicEffects) do
			table.insert(sortedList, effect)  -- Fix: insert the effect into sortedList
		end
		
		-- Sort based on COOKING_MODE
		table.sort(sortedList, function(a, b)
			if COOKING_MODE == "Immersive" then
				return (a.slot or 0) < (b.slot or 0)
			else
				return (a.score or 0) > (b.score or 0)  -- Higher scores first
			end
		end)
		
		for i, effect in ipairs(sortedList) do  -- Fix: iterate over sortedList with ipairs
			if COOKING_MODE ~= "Immersive" and not effect.visibleInPreview then
				mealPreviewElements.effectsContainer.layout.content:add{
					type = ui.TYPE.Text,
					props = {
						text = "?",
						textColor = G_lightText,
						textShadow = true,
						textShadowColor = util.color.rgb(0,0,0),
						textSize = textSize * 0.6,
						textAlignH = ui.ALIGNMENT.Start,
					},
				}
				
			elseif (effect.chance and effect.chance > 0) or effect.magnitude > 0 then
				local effectFlex = {
					type = ui.TYPE.Flex,
					props = {
						horizontal = true,
						autoSize = true,
					},
					content = ui.content{},
				}
				mealPreviewElements.effectsContainer.layout.content:add(effectFlex)
				
				effectFlex.content:add{
					type = ui.TYPE.Image,
					props = {
						resource = getTexture(effect.icon),
						tileH = false,
						tileV = false,
						size = v2(textSize*0.6, textSize*0.6),
						alpha = 0.7,
					},
				}
				effectFlex.content:add{ props = { size = v2(5,1) } }
				
				-- Build label first
				local effectText = tostring(effect.text or "")
				
				-- Calculate display magnitude
				-- For preview, show EXPECTED magnitude (if effect succeeds), not rolled magnitude
				local displayMag = 0
				if COOKING_MODE == "Immersive" and effect.potentialContributors and effect.potentialContributors > 0 then
					-- Use pre-calculated preview magnitude from calculateMealStats()
					displayMag = effect.previewMagnitude or 0
				else
					displayMag = tonumber(effect.magnitude) or 0
				end
				
				if COOKING_MODE == "Immersive" then
					effectText = effectText .. " " .. string.format("%i pts", displayMag)
				else
					effectText = effectText .. " " .. string.format("%.2f", displayMag)
				end
				
				if COOKING_MODE == "Immersive" and (effect.slot or 1) > 1 and effect.chance then
					local displayChance = math.floor(((tonumber(effect.chance) or 0) * 100) + 0.5)
					effectText = string.format("%s (%d%%)", effectText, displayChance)
				end
				
				effectFlex.content:add{
					type = ui.TYPE.Text,
					props = {
						text = effectText,
						textColor = G_lightText,
						textShadow = true,
						textShadowColor = util.color.rgb(0,0,0),
						textSize = textSize * 0.6,
						textAlignH = ui.ALIGNMENT.Start,
					},
				}

				mealPreviewElements.effectsContainer.layout.content:add{ props = { size = v2(1,1)*2 } }
			end
		end
		mealPreviewElements.effectsContainer.layout.content:add{
			type = ui.TYPE.Text,
			props = {
					text = COOKING_MODE == "Immersive" 
						and "for "..(mealStats.durationSuffix and mealStats.durationSuffix*30 or "???").." seconds (Rank "..(mealStats.durationSuffix or "?")..")" 
						or "for "..(24*mealStats.durationSuffix).." Minutes",
				textColor = G_lightText,
				textShadow = true,
				textShadowColor = util.color.rgb(0,0,0),
				textSize = textSize*0.6,
				textAlignH = ui.ALIGNMENT.Start,
			},
		}
	end
	
	-- Enable/disable cook button based on selection count
	if selectedCount >= 2 then
		mealPreviewElements.cookButton.clickbox.userData.selected = true
	else
		mealPreviewElements.cookButton.clickbox.userData.selected = false
	end
	mealPreviewElements.cookButton.applyColor()

	-- Update the UI
	mealPreviewElements.ingredientsContainer:update()
	mealPreviewElements.statsContainer:update()
	mealPreviewElements.warningsContainer:update()
	mealPreviewElements.effectsContainer:update()
	flex_V_H_V3:update()
end

function clearSelection()
	-- Deselect all buttons
	for idx, selectedData in pairs(selectedIngredients) do
		if selectedData.button then
			selectedData.button.clickbox.userData.selected = false
			selectedData.button.applyColor()
		end
	end
	selectedIngredients = {}
	updateMealPreview()
	updateAllButtonHighlights()
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Confirm Cooking													│
-- ╰────────────────────────────────────────────────────────────────────╯

local function findFoodPlacement(npc)
    if not npc or not npc:isValid() then return nil end
    
    local playerPos = self.position + v3(0, 0, 30)
    local npcPos = npc.position + v3(0, 0, 30)
    local toNpc = (npcPos - playerPos):normalize()
    
    -- Player -> NPC
    local playerHit = nearby.castRenderingRay(playerPos, npcPos, {
        collisionType = nearby.COLLISION_TYPE.World,
        ignore = self.object,
    })
    
    -- NPC -> Player
    local npcHit = nearby.castRenderingRay(npcPos, playerPos, {
        collisionType = nearby.COLLISION_TYPE.World,
        ignore = npc,
    })
    
    if not playerHit.hit or not npcHit.hit then return nil end
    local thickness = (npcHit.hitPos - playerHit.hitPos):length()
    if thickness < 20 then return nil end
    local right = toNpc:cross(v3(0, 0, 1)):normalize()
    local basePos = playerHit.hitPos + toNpc * 10
    local offsets = { 0, 10, -10 }  -- center, right, left
    
    for _, offset in ipairs(offsets) do
        local placeXY = basePos + right * offset
        local surfaceHit = nearby.castRenderingRay(
            placeXY + v3(0, 0, 120),
            placeXY - v3(0, 0, 10),
            { collisionType = nearby.COLLISION_TYPE.World }
        )
        if surfaceHit.hit and surfaceHit.hitPos.z > self.position.z + 35 then
            if types.Static.objectIsInstance(surfaceHit.hitObject) or types.Activator.objectIsInstance(surfaceHit.hitObject) then
                return surfaceHit.hitPos + v3(0, 0, 3)
            end
        end
    end
    
    return nil
end


function confirmCooking()
	local mealStats = calculateMealStats()
	if cookingWithInnkeeper and INNKEEPER_FOOD_PLACEMENT then
		local counterPos = findFoodPlacement(cookingWithInnkeeper)
		if counterPos then
			mealStats.placeAt = counterPos
			async:newUnsavableSimulationTimer(0.05, function()
				messageBox(1, "The innkeeper places your food on the counter")
			end)
		end
	end
	if mealStats.selectedCount < 2 then
		messageBox(2, "Select at least 2 ingredients to cook")
		return
	end
	if mealStats.count < 1 then
		if cookingWithInnkeeper then
			messageBox(2, "Not enough gold")
		else
			-- Determine exactly what's missing
			local hasWater = waterAmount >= (COOKING_WATER_MULT * 250)
			local totalContainers = containerCounts.bowls + containerCounts.plates
			if not hasWater and totalContainers == 0 then
				messageBox(2, "Not enough water or foodware")
			elseif not hasWater then
				messageBox(2, "Not enough water")
			else
				messageBox(2, "No foodware available")
			end
		end
		return
	end

	if COOKING_MODE ~= "Immersive" then
		-- Discover effects that appear on at least 2 ingredients
		for effectKey, effectData in pairs(mealStats.dynamicEffects) do
			if effectData.count and effectData.count >= 2 and effectData.vanillaIndex and effectData.vanillaIndex < 999 then
				-- Find which ingredients contributed this effect and mark as discovered
				for idx, _ in pairs(selectedIngredients) do
					local ingredient = availableIngredients[idx]
					if ingredient then
						local recordId = ingredient.recordId
						local ingredientEffects = getIngredientEffects(ingredient)
						
						-- Initialize ingredient's discovery table if needed
						if not cookingData.discoveredEffects[recordId] then
							cookingData.discoveredEffects[recordId] = {}
						end
						
						for _, effect in pairs(ingredientEffects) do
							-- Check if this effect matches and mark as discovered
							local thisEffectKey = effect.uniqueId .. mealStats.durationSuffix
							if thisEffectKey == effectKey and effect.vanillaIndex then
								if not isEffectVisible(ingredient, effect) then
									messageBox(4, "Discovered " ..effect.text.." in "..ingredient.name)
									cookingData.discoveredEffects[recordId][effect.vanillaIndex] = true
								end
							end
						end
					end
				end
			end
		end
	end
	local alchemyExp = 0
	
	local cookingMult = 1
	if saveData.playerInfo.majorSkills.alchemy then
		cookingMult = 1.2
	end
	if saveData.playerInfo.minorSkills.alchemy then
		cookingMult = 1.1
	end

	if INNKEEPER_COOKING_SKILLS and cookingWithInnkeeper then
		cookingData.NPCSkills[getId(cookingWithInnkeeper)] = cookingData.NPCSkills[getId(cookingWithInnkeeper)] or math.random(15,25)
		for i=1, mealStats.count do
			local levelDifficulty = 1 + cookingData.NPCSkills[getId(cookingWithInnkeeper)] / 15
			-- Update cooking level with XP multiplier
			local xpGain = 0.03 * mealStats.selectedCount + mealStats.totalRarity / 15
			if mealStats.xpMultiplier then
				xpGain = xpGain * mealStats.xpMultiplier
			end
			cookingData.NPCSkills[getId(cookingWithInnkeeper)] = cookingData.NPCSkills[getId(cookingWithInnkeeper)] + xpGain / levelDifficulty * cookingMult*0.9
		end
	else
		for i=1, mealStats.count do
			local levelDifficulty = 1 + cookingData.level / 15
			-- Update cooking level with XP multiplier
			local xpGain = 0.03 * mealStats.selectedCount + mealStats.totalRarity / 15
			if mealStats.xpMultiplier then
				xpGain = xpGain * mealStats.xpMultiplier
			end
			alchemyExp = alchemyExp + xpGain*4.5
			cookingData.level = cookingData.level + xpGain / levelDifficulty * cookingMult*0.8
		end
		updateCookingLevel()
		local expSteps = math.floor(mealStats.count/3)
		for i=1, expSteps do
			I.SkillProgression.skillUsed("alchemy", {skillGain = alchemyExp / expSteps, useType = I.SkillProgression.SKILL_USE_TYPES.Alchemy_CreatePotion , scale = nil})
		end
	end
	
	local message = "Cooking " .. mealStats.selectedCount .. " ingredients!"
	if mealStats.xpMultiplier and mealStats.xpMultiplier > 1.0 then
		message = message .. string.format(" [Bonus: %.0f%% XP]", (mealStats.xpMultiplier - 1) * 100)
	end
	messageBox(4, message)
	
	if cookingWithInnkeeper then
		local goldItem = typesActorInventorySelf:find("gold_001")
		if goldItem then
			-- Charge gold for innkeeper cooking: service fee + ingredient costs
			local ingredientCost = calculateIngredientCost(mealStats.count)
			local totalCost = INNKEEPER_MEAL_COST * mealStats.count + ingredientCost
			core.sendGlobalEvent("SunsDusk_removeItem", {
				self,
				goldItem,
				totalCost
			})
		end
		-- Set forced foodware so backend uses redware containers
		if mealStats.isSoup then
			mealStats.forcedFoodware = "misc_com_redware_bowl_01"
		else
			mealStats.forcedFoodware = "misc_com_redware_plate"
		end
	else
		-- Consume water
		if COOKING_WATER_MULT > 0 then
			core.sendGlobalEvent("SunsDusk_WaterBottles_consumeWater", {
				player = self,
				amountMl = 250*COOKING_WATER_MULT*mealStats.count
			})
		end
	end
	
	-- Send single event - backend handles batching, containers, and ingredients
	core.sendGlobalEvent("SunsDusk_createStew", {self, mealStats})
	
	-- Close the UI after cooking
	if SDCookingUI then
		if mouseTooltip then
			mouseTooltip:destroy()
			mouseTooltip = nil
		end
		SDCookingUI:destroy()
		SDCookingUI = nil
		cookingWithInnkeeper = false
		I.UI.setMode()
		--ambient.playSound("item potion up")
		ambient.playSoundFile("sound/sunsdusk/cooking.ogg", {volume = 1.0})
	end
end

-- ──────────────────────────────────────────────────────────────────────────────── INGREDIENT LIST FUNCTIONS ────────────────────────────────────────────────────────────────────────────────
function addIngredientButton(i)
	if i < 1 or i > #availableIngredients then return end
	
	local ingredient = availableIngredients[i]
	local itemCount = ingredient.count + ingredient.innkeeperCount
	local buttonLabel
	if itemCount > 1 then
		buttonLabel = ingredient.name .. " (" .. itemCount .. ")"
	else
		buttonLabel = ingredient.name
	end
	
	local iconPath = types.Ingredient.record(ingredient.recordId).icon
	
	-- Calculate matching effects for highlighting
	local matchCount = countMatchingEffects(i)
	local highlightAlpha = getMatchHighlightAlpha(matchCount)
	
	-- Get matching effects for icon display
	local matchingEffects = getMatchingEffects(i)
	
	-- Create button
	local button
	button = makeCookingButton(buttonLabel, {size = v2(listWidth,30)}, function()
		toggleIngredientSelection(i, button)
	end, G_morrowindGold, SDCookingUI, getTexture(iconPath), nil, nil, generateIngredientTooltip(ingredient) )
	
	-- Store the ingredient index, highlight alpha, AND the button object in the clickbox
	button.clickbox.userData.ingredientIndex = i
	button.clickbox.userData.highlightAlpha = highlightAlpha
	button.clickbox.userData.buttonObject = button
	
	-- Populate the right icon container with matching effect icons
	populateButtonEffectIcons(button, matchingEffects)
	
	-- Restore selection state if this ingredient was already selected
	if selectedIngredients[i] then
		button.clickbox.userData.selected = true
		selectedIngredients[i].button = button
	end
	
	-- Apply the initial color (including highlight)
	button.applyColor()
	
	flex_V_H_V2.layout.content:add(button.box)
	return button
end

function toggleIngredientSelection(index, button)
	if selectedIngredients[index] then
		-- Deselect
		selectedIngredients[index] = nil
		button.clickbox.userData.selected = false
	else
		-- Check if we've reached max ingredients
		local selectedCount = 0
		for _ in pairs(selectedIngredients) do selectedCount = selectedCount + 1 end
		
		if selectedCount >= MAX_INGREDIENTS then
			messageBox(4, "Maximum " .. MAX_INGREDIENTS .. " ingredients allowed")
			return
		end
		
		-- Select
		selectedIngredients[index] = {
			button = button,
			ingredient = availableIngredients[index]
		}
		button.clickbox.userData.selected = true
	end
	
	button.applyColor()
	updateMealPreview()
	updateAllButtonHighlights()
end

-- ──────────────────────────────────────────────────────────────────────────────── SCROLL & FRAME ────────────────────────────────────────────────────────────────────────────────
function updateScrollbar()
	local totalItems = #availableIngredients
	if totalItems <= listSize then
		scrollbarThumb.props.relativeSize = v2(1,0)
		scrollbarThumb.props.relativePosition = v2(0,0)
	else
		local thumbHeight = listSize / totalItems
		-- Use the working formula from player.lua
		local scrollPosition = (1 - thumbHeight) * (currentIndex - 1) / (totalItems - listSize)
		scrollbarThumb.props.relativeSize = v2(1, thumbHeight)
		scrollbarThumb.props.relativePosition = v2(0, scrollPosition)
	end
	flex_V_H_V1:update()
end

function rebuildList(newIndex)
	if newIndex < currentIndex then
		-- Scrolling up: remove from bottom, add to top
		for i = currentIndex - 1, newIndex, -1 do
			local tempDestroy = flex_V_H_V2.layout.content[#flex_V_H_V2.layout.content]
			table.remove(flex_V_H_V2.layout.content, #flex_V_H_V2.layout.content)
			if mouseTooltip then
				mouseTooltip:destroy()
				mouseTooltip = nil
			end
			tempDestroy:destroy()
			
			local button = addIngredientButton(i)
			if button then
				table.remove(flex_V_H_V2.layout.content, #flex_V_H_V2.layout.content)
				table.insert(flex_V_H_V2.layout.content, 1, button.box)
			end
		end
	elseif newIndex > currentIndex then
		-- Scrolling down: remove from top, add to bottom
		for i = currentIndex + 1, newIndex do
			local tempDestroy = flex_V_H_V2.layout.content[1]
			table.remove(flex_V_H_V2.layout.content, 1)
			if mouseTooltip then
				mouseTooltip:destroy()
				mouseTooltip = nil
			end
			tempDestroy:destroy()
			
			-- Use the correct index calculation matching player.lua
			local buttonIndex = i + listSize - 1
			addIngredientButton(buttonIndex)
		end
	end

	currentIndex = newIndex
	flex_V_H_V2:update()
	updateScrollbar()
	--updateAllButtonHighlights()
end

local function onMouseWheel(direction)
	if not SDCookingUI then return end
	direction = direction * 2
	local newIndex = math.max(1, math.min(#availableIngredients - listSize + 1, currentIndex - direction))
	rebuildList(newIndex)
end
table.insert(G_mousewheelJobs, onMouseWheel)

-- ──────────────────────────────────────────────────────────────────────────────── CONTROLLER / KEYBOARD NAVIGATION ────────────────────────────────────────────────────────────────────────────────

local function controllerClearFocus()
	if controllerFocusedClickbox then
		controllerFocusedClickbox.userData.focus = false
		controllerFocusedClickbox.userData.pressed = false
		if controllerFocusedClickbox.userData.applyColor then
			controllerFocusedClickbox.userData.applyColor(controllerFocusedClickbox)
		end
		controllerFocusedClickbox = nil
	end
	controllerActivateHeld = false
	if mouseTooltip then
		mouseTooltip:destroy()
		mouseTooltip = nil
	end
end

local function controllerSetFocus(clickbox)
	controllerClearFocus()
	if clickbox then
		controllerFocusedClickbox = clickbox
		clickbox.userData.focus = true
		if clickbox.userData.applyColor then
			clickbox.userData.applyColor(clickbox)
		end
	end
end

local function controllerGetListButton(ingredientIndex)
	if not flex_V_H_V2 then return nil end
	for _, buttonBox in ipairs(flex_V_H_V2.layout.content) do
		for _, child in ipairs(buttonBox.layout.content) do
			if child.name == 'clickbox' and child.userData and child.userData.ingredientIndex == ingredientIndex then
				return child, child.userData.buttonObject
			end
		end
	end
	return nil
end

local function controllerApplyListFocus()
	if #availableIngredients == 0 then return end
	controllerListIndex = math.max(1, math.min(#availableIngredients, controllerListIndex))
	-- ensure visible
	if controllerListIndex < currentIndex then
		rebuildList(controllerListIndex)
	elseif controllerListIndex > currentIndex + listSize - 1 then
		rebuildList(controllerListIndex - listSize + 1)
	end
	local clickbox = controllerGetListButton(controllerListIndex)
	if clickbox then
		controllerSetFocus(clickbox)
		-- Show tooltip to the right of the focused button
		local ingredient = availableIngredients[controllerListIndex]
		if ingredient then
			local tooltipContent = generateIngredientTooltip(ingredient)
			if mouseTooltip then
				mouseTooltip:destroy()
				mouseTooltip = nil
			end
			mouseTooltip = ui.create{
				type = ui.TYPE.Container,
				layer = 'Notification',
				name = "controllerTooltip",
				template = controllerTooltipTemplate,
				props = {
					anchor = v2(1, 0),
				},
				content = ui.content{tooltipContent}
			}
			local layerId = ui.layers.indexOf("Modal")
			local layerSize = ui.layers[layerId].size
			local windowSize = SDCookingUI.layout.props.size
			local windowOffset = SDCookingUI.layout.props.position or v2(0, 0)
			-- Window top-left: centered on layer + drag offset
			local wtlX = layerSize.x * 0.5 + windowOffset.x - windowSize.x * 0.5
			local wtlY = layerSize.y * 0.5 + windowOffset.y - windowSize.y * 0.5
			-- Button position within window
			local visualIndex = controllerListIndex - currentIndex
			local tooltipX = wtlX + 20
			local tooltipY = wtlY + textSize * 1.4 + marginWidth + visualIndex * 30
			mouseTooltip.layout.props.position = v2(tooltipX, tooltipY)
			mouseTooltip:update()
		end
	end
end

local function controllerApplyRightFocus()
	if not mealPreviewElements then return end
	local target
	if controllerColumn == 4 and mealPreviewElements.clearButton then
		target = mealPreviewElements.clearButton.clickbox
	elseif controllerRightIndex == 1 and mealPreviewElements.cookButton then
		target = mealPreviewElements.cookButton.clickbox
	elseif controllerRightIndex == 2 then
		if controllerColumn == 2 then
			target = mealPreviewElements.minusButton.clickbox
		elseif controllerColumn == 3 then
			target = mealPreviewElements.plusButton.clickbox
		end
	end
	if target then
		controllerSetFocus(target)
	end
end

local function controllerHandleInput(direction)
	if not SDCookingUI then return end
	controllerActive = true

	if direction == "close" then
		if controllerColumn == 1 then
			controllerColumn = 2
			controllerClearFocus()
			controllerApplyListFocus()
		else
			if mouseTooltip then
				mouseTooltip:destroy()
				mouseTooltip = nil
			end
			SDCookingUI:destroy()
			SDCookingUI = nil
			cookingWithInnkeeper = false
			I.UI.setMode()
		end
		return
	end

	if controllerColumn == 1 then
		if direction == "up" then
			if controllerListIndex == 1 then
				controllerListIndex = #availableIngredients
			else
				controllerListIndex = math.max(1, controllerListIndex - 1)
			end
			controllerApplyListFocus()
		elseif direction == "down" then
			if controllerListIndex == #availableIngredients then
				controllerListIndex = 1
			else
				controllerListIndex = math.min(#availableIngredients, controllerListIndex + 1)
			end
			controllerApplyListFocus()
		elseif direction == "right" then
			controllerColumn = 2
			controllerClearFocus()
			controllerApplyRightFocus()
		elseif direction == "activate" then
			-- Just show pressed visual, actual toggle happens on release
			if not controllerActivateHeld then
				controllerActivateHeld = true
				if controllerFocusedClickbox then
					controllerFocusedClickbox.userData.pressed = true
					if controllerFocusedClickbox.userData.applyColor then
						controllerFocusedClickbox.userData.applyColor(controllerFocusedClickbox)
					end
				end
			end
		end
	elseif controllerColumn > 1 then
		if direction == "up" then
			controllerRightIndex = math.max(1, controllerRightIndex - 1)
			controllerApplyRightFocus()
		elseif direction == "down" then
			controllerRightIndex = math.min(2, controllerRightIndex + 1)
			controllerApplyRightFocus()
		elseif direction == "right" then
			local maxCol = mealPreviewElements.clearButton and 4 or 3
			if controllerRightIndex == 1 then
				controllerColumn = math.min(maxCol,4)
			else
				controllerColumn = math.min(maxCol, controllerColumn + 1)
			end
			controllerApplyRightFocus()
		elseif direction == "left" then
			if controllerRightIndex == 1 and controllerColumn ~= 4 then -- from cooking button directly to list
				controllerColumn = 1
			else
				controllerColumn = math.max(1, controllerColumn - 1)
			end
			if controllerColumn == 1 then
				controllerClearFocus()
				controllerApplyListFocus()
			else
				controllerApplyRightFocus()
			end
		elseif direction == "activate" then
			-- Just show pressed visual, actual action happens on release
			if not controllerActivateHeld then
				controllerActivateHeld = true
				if controllerFocusedClickbox then
					controllerFocusedClickbox.userData.pressed = true
					if controllerFocusedClickbox.userData.applyColor then
						controllerFocusedClickbox.userData.applyColor(controllerFocusedClickbox)
					end
				end
			end
		end
	end
end

local function onControllerButtonPress(id)
	if not SDCookingUI then return end
	local dir
	if id == input.CONTROLLER_BUTTON.DPadUp then
		dir = "up"
	elseif id == input.CONTROLLER_BUTTON.DPadDown then
		dir = "down"
	elseif id == input.CONTROLLER_BUTTON.DPadLeft then
		dir = "left"
	elseif id == input.CONTROLLER_BUTTON.DPadRight then
		dir = "right"
	elseif id == input.CONTROLLER_BUTTON.A then
		dir = "activate"
	end
	if dir then
		controllerHandleInput(dir)
		if dir ~= "activate" then
			cookingHeldDirection = dir
			cookingHeldTimestamp = core.getRealTime() + 0.2
		end
	end
end
table.insert(G_controllerButtonPressJobs, onControllerButtonPress)

local function onCookingKeyPress(keyCode)
	if not SDCookingUI then return end
	local dir
	if keyCode == input.KEY.UpArrow then
		dir = "up"
	elseif keyCode == input.KEY.DownArrow then
		dir = "down"
	elseif keyCode == input.KEY.LeftArrow then
		dir = "left"
	elseif keyCode == input.KEY.RightArrow then
		dir = "right"
	elseif keyCode == input.KEY.Enter or keyCode == input.KEY.Space then
		dir = "activate"
	end
	if dir then
		controllerHandleInput(dir)
		if dir ~= "activate" then
			cookingHeldDirection = dir
			cookingHeldTimestamp = core.getRealTime() + 0.15
		end
	end
end
table.insert(G_keyPressJobs, onCookingKeyPress)

local function controllerHandleActivateRelease()
	if not SDCookingUI or not controllerActivateHeld then return end
	controllerActivateHeld = false
	-- Clear pressed visual
	if controllerFocusedClickbox then
		controllerFocusedClickbox.userData.pressed = false
		if controllerFocusedClickbox.userData.applyColor then
			controllerFocusedClickbox.userData.applyColor(controllerFocusedClickbox)
		end
	end
	-- Perform the action
	if controllerColumn == 1 then
		local clickbox, buttonObj = controllerGetListButton(controllerListIndex)
		if buttonObj then
			toggleIngredientSelection(controllerListIndex, buttonObj)
			controllerApplyListFocus()
		end
	elseif controllerRightIndex == 1 then
		confirmCooking()
	elseif controllerRightIndex == 2 then
		if controllerColumn == 2 then
			if mealCount > 1 then
				mealCount = mealCount - 1
				updateMealPreview()
			end
		elseif controllerColumn == 3 then
			local maxMeals = calculateMaxMeals()
			if mealCount < maxMeals then
				mealCount = mealCount + 1
				updateMealPreview()
			end
		elseif controllerColumn == 4 then
			clearSelection()
			controllerColumn = 1
			controllerClearFocus()
			controllerApplyListFocus()
		end
	end
end

local function onControllerButtonRelease(id)
	if not SDCookingUI then return end
	if id == input.CONTROLLER_BUTTON.A then
		controllerHandleActivateRelease()
	else
		cookingHeldDirection = nil
	end
end
table.insert(G_controllerButtonReleaseJobs, onControllerButtonRelease)

local function onCookingKeyRelease(keyCode)
	if not SDCookingUI then return end
	if keyCode == input.KEY.Enter or keyCode == input.KEY.Space then
		controllerHandleActivateRelease()
	else
		cookingHeldDirection = nil
	end
end
table.insert(G_keyReleaseJobs, onCookingKeyRelease)

G_onFrameJobs.cookingHeldRepeat = function()
	if not SDCookingUI or not cookingHeldDirection then return end
	local now = core.getRealTime()
	if now > cookingHeldTimestamp + 0.07 then
		controllerHandleInput(cookingHeldDirection)
		cookingHeldTimestamp = now
	end
end

-- ──────────────────────────────────────────────────────────────────────────────── ACTIVATION ────────────────────────────────────────────────────────────────────────────────
G_module_cooking_activators = {}
table.insert(G_module_cooking_activators, 'fire')
table.insert(G_module_cooking_activators, 'stove')
-- table.insert(G_module_cooking_activators, 'log')
-- table.insert(G_module_cooking_activators, 'table')
table.insert(G_module_cooking_activators, 'cook')
table.insert(G_module_cooking_activators, 'cauldron')
table.insert(G_module_cooking_activators, 'ember')
table.insert(G_module_cooking_activators, 'burn') -- SLF_CP_corpseBurned07_act
table.insert(G_module_cooking_activators, 'oven')
table.insert(G_module_cooking_activators, 'light_logpile')
table.insert(G_module_cooking_activators, 'furn_redoran_hearth_02')
table.insert(G_module_cooking_activators, 'grill')

G_module_cooking_blacklist = {}
table.insert(G_module_cooking_blacklist, 'firewat')
table.insert(G_module_cooking_blacklist, 'grille')

function G_isCookingActivator(object, objectType)
	if not object then return false end
	local recordId = object.recordId
	
	local refEntry, recordEntry = dbStatics[object.id], dbStatics[recordId]
	local dbEntry = refEntry and refEntry.cookingspot
	if refEntry == nil then
		dbEntry = recordEntry and recordEntry.cookingspot
	end
	
	if dbEntry ~= nil then
		return dbEntry and true
	end
	if not (objectType == "Static" or objectType == "Light" or objectType == "Activator") then
		return false
	end
	local recordId = object.recordId
	for _, searchString in pairs(G_module_cooking_blacklist) do
        if recordId:find(searchString) then
            return false
        end
    end
	for _, searchString in pairs(G_module_cooking_activators) do
        if recordId:find(searchString) then
            return true
        end
	end
	return false
end

-- ════════════════════════════════════════════════════════════════════════════════
-- World Interaction Registration
-- ════════════════════════════════════════════════════════════════════════════════

G_worldInteractions.cooking = {
	canInteract = function(object, objectType)
		if G_isCookingActivator(object, objectType) then
			return true
		end
		-- Also check for lit campfires (sd_wood_X_lit pattern)
		if object.recordId:match("^sd_wood_%d_lit$") then
			return true
		end
		return false
	end,
	getActions = function(object, objectType)
		local label = checkHasDirtyWater() and "Purify water" or "Cook"
		return {{
			label = label,
			preferred = "Activate",
			handler = function(obj)
				if not SDCookingUI then
					if checkHasDirtyWater() then
						core.sendGlobalEvent("SunsDusk_WaterBottles_purifyWater", {self})
					else
						makeCookingUi()
						I.UI.setMode("Interface", {windows = {}})
					end
				end
			end
		}}
	end
}

local function calculateRacialBonus()
	if not cookingData then return end -- player info is updating before init
	local bonus = 0
	if saveData.playerInfo.isBeast then
		bonus = bonus - 2
	end
	if saveData.playerInfo.isOrc then
		bonus = bonus + 7
	end
	-- if saveData.playerInfo.isBosmer then
	-- 	bonus = bonus - 5
	-- end
	if saveData.playerInfo.isAltmer then
		bonus = bonus + 5
	end
	if saveData.playerInfo.isImperial then
		bonus = bonus + 2
	end
	if saveData.playerInfo.isDunmer then
		bonus = bonus + 5
	end
	if saveData.playerInfo.isBreton then
		bonus = bonus + 10
	end	
	--if saveData.playerInfo.isRedguard then
	--	bonus = bonus + 
	--end
	--if saveData.playerInfo.isFarmingTool then
	--	bonus = bonus + 
	--end
	
	cookingData.racialBonus = math.floor(bonus)
end
table.insert(G_onPlayerInfoChangedJobs, calculateRacialBonus)

function updateCookingLevel()
	if math.floor(cookingData.level) > math.floor(lastCookingLevel) then
		ambient.playSound("skillraise")
		for i=math.floor(lastCookingLevel), math.floor(cookingData.level) do
			messageBox(1, "Cooking increased to ".. i)
		end
		lastCookingLevel = cookingData.level
	end
	alchemyLevel = typesPlayerStatsSelf.alchemy.modified + typesPlayerStatsSelf.intelligence.modified/10
	cookingData.alchemyBonus = alchemyLevel/10
	cookingData.shortBladeBonus = math.min(25, typesPlayerStatsSelf.shortblade.modified-5)/10
	cookingData.luckBonus = typesPlayerStatsSelf.luck.modified/20
	cookingLevelModified = math.floor(cookingData.level) + math.floor( cookingData.racialBonus + cookingData.alchemyBonus + cookingData.luckBonus + cookingData.shortBladeBonus)
	if cookingStat then
		cookingStat.base = math.floor(cookingData.level)
		cookingStat.modifier = math.floor( cookingData.alchemyBonus + cookingData.luckBonus + cookingData.shortBladeBonus) + cookingData.racialBonus
		cookingStat.progress = cookingData.level%1
	end
	
	if INNKEEPER_COOKING_SKILLS and cookingWithInnkeeper then
		cookingData.NPCSkills[getId(cookingWithInnkeeper)] = cookingData.NPCSkills[getId(cookingWithInnkeeper)] or math.random(15,25)
		cookingLevelModified = cookingData.NPCSkills[getId(cookingWithInnkeeper)]
	end
end


local function onLoad(event)

	if not saveData.m_cooking then
		saveData.m_cooking = {
			level = 5,
		}
	end
	cookingData = saveData.m_cooking
	lastCookingLevel = cookingData.level
	cookingData.discoveredEffects = cookingData.discoveredEffects or {}
	cookingData.NPCSkills = cookingData.NPCSkills or {}
	cookingData.readRecipes = cookingData.readRecipes or {}
	
	if SkillFramework then
		SkillFramework.registerSkill(skillId, {
			name = "Cooking",
			description = 
[[Cooking skill is measured by the ability to prepare dishes and draw out the beneficial properties of ingredients when combined over a fire. 
A Gourmet Chef can turn a handful of scraps into something worth savoring.]],
			icon = { fgr = "textures/SunsDusk/cupcake.png" },
			attribute = "intelligence",
			specialization = SkillFramework.SPECIALIZATION.Magic,
			skillGain = {
				[1] = 1.0,
			},
			startLevel = 5,
			maxLevel = 10000,
			statsWindowProps = {
				subsection = SkillFramework.STATS_WINDOW_SUBSECTIONS.Crafts
			}
		})
		cookingStat = SkillFramework.getSkillStat(skillId)
		if event == "onInit" then
			cookingData.level = cookingStat.base + cookingStat.progress
			lastCookingLevel = cookingData.level
		end
	elseif core.contentFiles.has("SkillFramework.omwscripts") then
		messageBox(1, "SkillFramework installed but not high enough in the load order")
	end
	calculateRacialBonus()
	updateCookingLevel()
end
	
table.insert(G_onLoadJobs, onLoad)

local function UiModeChanged(data)
	if SDCookingUI and not data.newMode then
		if mouseTooltip then
			mouseTooltip:destroy()
			mouseTooltip = nil
		end
		SDCookingUI:destroy()
		SDCookingUI = nil
		cookingWithInnkeeper = false
	end
	if data.newMode == "Dialogue" then
		isInDialogue = true
	else
		isInDialogue = false
	end
	if core.magic.spells.records["startcooking_dummy"] then
		typesActorSpellsSelf:remove("startcooking_dummy")
	end
	-- cook book exp
	if (data.newMode == "Book" or data.newMode == "Scroll") and data.arg.recordId then
		local recordId = data.arg.recordId
		if G_cookingRecipes[recordId] and not saveData.m_cooking.readRecipes[recordId] then
			saveData.m_cooking.readRecipes[recordId] = true
			local cookingMult = 1
			if saveData.playerInfo.majorSkills.alchemy then
				cookingMult = 1.2
			end
			if saveData.playerInfo.minorSkills.alchemy then
				cookingMult = 1.1
			end
			local levelDifficulty = 1 + cookingData.level / 15
			-- Update cooking level with XP multiplier
			local xpGain = 0.333
			local alchemyExp = xpGain*4.5
			cookingData.level = cookingData.level + xpGain / levelDifficulty * cookingMult*0.8
			I.SkillProgression.skillUsed("alchemy", {skillGain = alchemyExp, useType = I.SkillProgression.SKILL_USE_TYPES.Alchemy_CreatePotion , scale = nil})
			updateCookingLevel()
		end
	end
end

table.insert(G_UiModeChangedJobs, UiModeChanged)

local function onFrameCookingJobs()
	if isInDialogue then
		local hasDummySpell = false
		for _, spell in pairs(typesActorSpellsSelf) do
			if spell.id == "startcooking_dummy" then
				hasDummySpell = true
			end
		end
		if hasDummySpell then
			typesActorSpellsSelf:remove("startcooking_dummy")
			if G_currentDialogueNPC and not SDCookingUI then
				cookingWithInnkeeper = G_currentDialogueNPC
				makeCookingUi()
				I.UI.setMode("Interface", {windows = {}})
			end
		end
	end
end

--table.insert(G_onFrameJobsSluggish,onFrameCookingJobs)
table.insert(G_sluggishScheduler[5], onFrameCookingJobs)
G_onFrameJobsSluggish.onFrameCookingJobs = onFrameCookingJobs

local function onConsume(item)
	local recordId = item.recordId
	
	-- Check if this is a cooked meal by sending event to global script
	-- The global script will check stewRegistry and return container if needed
	core.sendGlobalEvent("SunsDusk_returnContainer", {
		player = self,
		item = item
	})
	
	-- Remove duplicate active spell effects (existing stew buff replacement logic)
	local record = item.type.record(item)
	local allowedEffects = {}
	for _, effect in pairs(record.effects) do
		local uid = effect.id.."-"..tostring(effect.effect.hasMagnitude and effect.magnitudeMax).."-"..(effect.affectedAttribute or effect.affectedSkill or "")	
		allowedEffects[uid] = 1
	end
	
	for _, s in pairs(typesActorActiveSpellsSelf) do
		local isActiveMeal = G_stewNames[s.name or ""]
		if isActiveMeal then
			local remove = false
			for _, effect in ipairs(s.effects) do
				if (effect.durationLeft or 1) < (effect.duration or 1)-0.1 then
					remove = true
				else
					local effectPrototype = core.magic.effects.records[effect.id]
					local uid = effect.id.."-"..tostring(effectPrototype.hasMagnitude and effect.maxMagnitude).."-"..(effect.affectedAttribute or effect.affectedSkill or "")
					allowedEffects[uid] = (allowedEffects[uid] or 0) - 1
					if allowedEffects[uid] < 0 then
						remove = true
					end
				end
			end
			if remove then
				--local uid = effect.id.."-"..tostring(effectPrototype.hasMagnitude and effect.maxMagnitude).."-"..(effect.affectedAttribute or effect.affectedSkill or "")
				--print("removing",uid)
				typesActorActiveSpellsSelf:remove(s.activeSpellId)
			end
		end
	end
end

table.insert(G_onConsumeJobs, onConsume)