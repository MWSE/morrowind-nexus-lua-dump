--[[
inspired from HotFusion's Economy Adjuster
http://mw.modhistory.com/download-98-11202
 and Wakim's game settings
http://mw.modhistory.com/download-90-13337
, no need of a separate .esp, and no need of extra dialog greetings
/abot
--]]

-- begin configurable parameters
local defaultConfig = {
upgradeTrainerNPCsSkills = true,
upgradeMerchantNPCsSkills = true,
persistentSkillsUpgrades = true, -- merchants/trainers skills upgrade type false = on the fly, true = persistent
atLeastPlayerLevel = false, -- if actor level < player level, use player level instead
skillLevelBase = 0, -- base value added to upgraded mercantile and speechcraft (default: 0)
skillLevelMultiplier = 3, -- multiplier for upgraded mercantile and speechcraft (suggested: 3, HotFusion's default: 5)
fBargainOfferBase = 40, -- NPC buy/sell price percent (game default: 50, suggested: 40)
creatureBargainLevel = 10, -- If greater than 0, fBargainOfferBase and max(creature bargain level, creature level) affect creature prices (game default: 0, suggested: 10)
harderMerchantsBuyingPrices = 1, -- Harder Barter like merchants buying prices reduction 0 Disabled .. 4 Very High
fBargainOfferMulti = -5, -- repeated bargain request modifier (game default: -4, suggested: -5)
fBribe10Mod = 20, -- NPC Disposition raise % on successful 10 gold bribe (game default: 35, suggested: 20)
fBribe100Mod = 40, -- NPC Disposition raise % on successful 100 gold bribe (game default: 75, suggested: 40)
fBribe1000Mod = 60, -- NPC Disposition raise % on successful 1000 gold bribe (game default: 150, suggested: 60)
iBarterSuccessDisposition = 1, -- NPC Disposition raise on successfull barter (game default: 1, suggested: 0)
fDispBargainSuccessMod_X100 = 1, -- NPC disposition raise / 100 when player sells under price (game default: 100, suggested: 1)
logLevel = 0, -- 0 = off, 1 = log, 2 = message, 3 = log + message, 4 = messagebox, 5 = log + messagebox
}
-- end configurable parameters

local author = 'abot'
local modName = 'Smart Merchants'
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig) ---or defaultConfig
---assert(config)

local bit = require('bit')

local function dm(s)
	---local dbug = math.floor(tes3.getGlobal('ab01debug'))
	local dbug = config.logLevel
	s = string.format("%s: %s", modPrefix, s)
	if dbug then
		if bit.band(dbug, 4) == 4 then
			tes3.messageBox({ message = s, buttons = {'OK'} })
		elseif bit.band(dbug, 2) == 2 then
			tes3.messageBox(s)
		end
		if bit.band(dbug, 1) == 1 then
			mwse.log(s)
		end
	end
end

local function applyConfig()
	if not config then
		return
	end
	local fBargainOfferBase = tes3.findGMST(tes3.gmst.fBargainOfferBase)
	if not fBargainOfferBase then
		return
	end
	fBargainOfferBase.value = config.fBargainOfferBase
	tes3.findGMST(tes3.gmst.fBargainOfferMulti).value = config.fBargainOfferMulti
	tes3.findGMST(tes3.gmst.fBribe10Mod).value = config.fBribe10Mod
	tes3.findGMST(tes3.gmst.fBribe100Mod).value = config.fBribe100Mod
	tes3.findGMST(tes3.gmst.fBribe1000Mod).value = config.fBribe1000Mod
	tes3.findGMST(tes3.gmst.iBarterSuccessDisposition).value = config.iBarterSuccessDisposition
	tes3.findGMST(tes3.gmst.fDispBargainSuccessMod).value = config.fDispBargainSuccessMod_X100 / 100
	dm("GMST changes applied")
end

local function logConfig(options)
	mwse.log(json.encode(config, options))
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	---dm("modConfigReady")
	local template = mwse.mcm.createTemplate(mcmName)

	---template:saveOnClose(configName, config)
	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
		applyConfig()
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Preferences",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.2
			self.elements.sideToSideBlock.children[2].widthProportional = 0.8
		end
	}

	-- Feature Toggles
	local toggles = preferences:createCategory{label="Feature Toggles"}

	local mercantileFix = tes3.hasCodePatchFeature(tes3.codePatchFeature.mercantileFix)
	if not mercantileFix then
		local mcpDesc = [[Morrowind Code Patch "Mercantile fix" description:
Merchants should no longer pay less for an item with increasing mercantile skill.
The issue was that prices merchants pay, were capped by the price the merchant sells the same item at.
The sell price was dipping too low, causing the buy price to go down too. It is now uncapped.
It does show the underlying barter mechanics aren't balanced well.
To avoid exploitable situations with the barter system all price modifiers (differences from base price) are reduced by 50%%.
Zero value items are no longer buyable or sellable for 1 septim.]]
		toggles:createInfo({
			text = 'Warning: Morrowind Code Patch option "Mercantile fix" is not detected, it is highly suggested to enable it.',
			description = mcpDesc
		})
		toggles:createHyperlink{
			text = "Morrowind Code Patch",
			exec = 'start https://www.nexusmods.com/morrowind/mods/19510',
			description = mcpDesc
		}
		toggles:createHyperlink{
			text = "Morrowind Code Patch Beta Update",
			exec = 'start https://www.nexusmods.com/morrowind/mods/26348',
			description = mcpDesc
		}
	end

	toggles:createOnOffButton{
		label = "Upgrade trainer NPCs skills",
		description = "HotFusion's inspired mercantile and speechcraft increase with best skills",
		variable = createConfigVariable("upgradeTrainerNPCsSkills")
	}
	toggles:createOnOffButton{
		label = "Upgrade merchant NPCs skills",
		description = "HotFusion's inspired mercantile and speechcraft increase with level",
		variable = createConfigVariable("upgradeMerchantNPCsSkills")
	}
	toggles:createOnOffButton{
		label = "Persistent merchants/trainers skills upgrades",
		description = [[Toggle merchants/trainers skill upgrades to be persistent
(base value changes) or on-the-fly (valid while in current dialog only).
On the fly changes may cause a slight delay as the game resets them when closing the dialog menu.]],
		variable = createConfigVariable("persistentSkillsUpgrades")
	}
	toggles:createOnOffButton{
		label = "If actor level < player level, use player level instead",
		description = "Can make even low level trainers/merchants harsh",
		variable = createConfigVariable("atLeastPlayerLevel")
	}

	-- Feature Controls
	local controls = preferences:createCategory{label="Feature Controls"}
	controls:createSlider{
		label = "Level based skill base",
		description = [[Base added to upgraded NPC mercantile and speechcraft (default: 0)
An extra starting base you can add to upgraded NPC mercantile and speechcraft
skillLevel = (NPClevel * config.skillLevelMultiplier) + config.skillLevelBase]],
		variable = createConfigVariable("skillLevelBase")
		,min = 0
	}
	controls:createSlider{
		label = "Level based skill multiplier",
		description = [[Multiplier for upgraded NPC mercantile and speechcraft (suggested: 3, HotFusion's default: 5)
skillLevel = (NPClevel * config.skillLevelMultiplier) + config.skillLevelBase]],
		variable = createConfigVariable("skillLevelMultiplier")
		,min = 0, max = 10, step = 1, jump = 1
	}
	controls:createSlider{
		label = "NPC buy/sell price percent",
		description = "fBargainOfferBase GMST (game default: 50, suggested: 40)",
		variable = createConfigVariable("fBargainOfferBase")
		,min = 1
	}
	controls:createSlider{
		label = "Creature bargain level",
		description = [[Game default: 0, suggested: 10.
If greater than 0, fBargainOfferBase and max(creature bargain level, creature level) affect prices when selling to creatures (e.g. creeper).]],
		variable = createConfigVariable("creatureBargainLevel")
		,min = 0, max = 200
	}

	controls:createDropdown{
		label = "Harder Barter like merchants buying prices reduction:",
		description = "Default: 0. Disabled. When enabled, greatly reduces merchants buying prices for expensive items."
		.."\n if unitPrice = totalPrice / units > 10 then"
		.."\n1. Low - Squared root base 10 logarithmic --> totalPrice / sqrt(base 10 logarithm(unitPrice))"
		.."\n2. Medium - Squared root natural logarithmic --> totalPrice / sqrt(natural logarithm(unitPrice))"
		.."\n3. High - Base 10 logarithmic --> totalPrice / base 10 logarithm(unitPrice)"
		.."\n4. Very High - Natural logarithmic --> totalPrice / natural logarithm(unitPrice)",
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Low - Squared root base 10 logarithmic", value = 1 },
			{ label = "2. Medium - Squared root natural logarithmic", value = 2 },
			{ label = "3. High - Base 10 logarithmic", value = 3 },
			{ label = "4. Very High - Natural logarithmic", value = 4 },
		},
		variable = createConfigVariable("harderMerchantsBuyingPrices")
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Log", value = 1 },
			{ label = "2. Message", value = 2 },
			{ label = "3. Log + message", value = 3 },
			{ label = "4. MessageBox", value = 4 },
			{ label = "5. Log + MessageBox", value = 5 },
		},
		variable = createConfigVariable("logLevel"),
		description = [[
Debug logging level. Default: 0. Off.
]]
	}

	controls:createSlider{
		label = "NPC repeated bargain modifier",
		description = "fBargainOfferMulti GMST (game default: -4, suggested: -5)\n(the more you insist and fail, the more they dislike you)",
		variable = createConfigVariable("fBargainOfferMulti")
		,min = -20, max = 0
	}
	controls:createSlider{
		label = "NPC Disposition raise percent on successful 10 gold bribe",
		description = "fBribe10Mod GMST (game default: 35, suggested: 20)",
		variable = createConfigVariable("fBribe10Mod")
		,min = 0
	}
	controls:createSlider{
		label = "NPC Disposition raise percent on successful 100 gold bribe",
		description = "fBribe100Mod GMST (game default: 75, suggested: 40)",
		variable = createConfigVariable("fBribe100Mod")
		,min = 0

	}
	controls:createSlider{
		label = "NPC Disposition raise percent on successful 1000 gold bribe",
		description = "fBribe1000Mod GMST (game default: 150, suggested: 60)",
		variable = createConfigVariable("fBribe1000Mod")
		,min = 0, max = 200
	}
	controls:createSlider{
		label = "NPC Disposition raise on successful barter",
		description = "iBarterSuccessDisposition GMST (game default: 1, suggested: 0)",
		variable = createConfigVariable("iBarterSuccessDisposition")
		,min = 0, max = 10, step = 1, jump = 1
	}
	controls:createSlider{
		label = "NPC disposition raise / 100 when player sells under price",
		description = "fDispBargainSuccessMod GMST X 100 (game default: 100, suggested: 1)",
		variable = createConfigVariable("fDispBargainSuccessMod_X100")
		,min = 0, max = 200
	}

	mwse.mcm.register(template)

	logConfig()

end
event.register('modConfigReady', modConfigReady)


--[[
https://mwse.readthedocs.io/en/latest/lua/api/tes3/setStatistic.html
tes3.setStatistic

Sets a statistic on a given actor. This should be used instead of manually setting values on the game structures,
to ensure that events and GUI elements are properly handled.
Either skill, attribute, or name must be provided.
Parameters

Accepts parameters through a table with the given keys:
attribute (number) Optional. The attribute to set.
base (number) Optional. If set, the base value will be set.
current (number) Optional. If set, the current value will be set.
limit (boolean) Default: false. If set, the attribute won’t rise above 100 or fall below 0.
name (string) Optional. A generic name of an attribute to set.
reference (tes3mobileActor, tes3reference, string)
skill (number) Optional. The skill to set.
value (number) Optional. If set, both the base and current value will be set.
--]]

local function adjustMerchantSkills(mobile)

	---mwse.log("%s adjustMerchantSkills", modPrefix)
	if not (mobile.actorType == 1) then -- 0 = creature, 1 = NPC, 2 = player
		return
	end

	local actorRef = mobile.reference
	assert(actorRef)

	assert(actorRef.object)
	local level = actorRef.object.level -- note that mwscripting SetLevel gets/sets the BASE object level
	assert(level)
	---dm(string.format("actor '%s' level %s", actorRef.id, level))

	-- if actor level < player level, use player level instead
	if config.atLeastPlayerLevel then
		local playerLevel = tes3.mobilePlayer.object.level
		if level < playerLevel then
			level = playerLevel
			---dm("actor level < player level, using player level instead")
		end
	end

	local mercantile = mobile.mercantile.current
	---assert(mercantile)
	---mwse.log("actorRef.id = %s, level = %s, mercantile = %s", actorRef.id, level, mercantile)

	local speechcraft = mobile.speechcraft.current
	---assert(speechcraft)
	---mwse.log("actorRef.id = %s, level = %s, speechcraft = %s", actorRef.id, level, speechcraft)

	local skillLevel = (level * config.skillLevelMultiplier) + config.skillLevelBase
	if skillLevel > 255 then
		skillLevel = 255
	end

	if mercantile < skillLevel then
		if config.persistentSkillsUpgrades then
			tes3.setStatistic({reference = actorRef, skill = tes3.skill.mercantile, value = skillLevel})
		else
			tes3.setStatistic({reference = actorRef, skill = tes3.skill.mercantile, current = skillLevel})
		end
		dm(string.format("actor '%s' mercantile set to %s", actorRef.id, skillLevel))
	end

	if speechcraft < skillLevel then
		if config.persistentSkillsUpgrades then
			tes3.setStatistic({reference = actorRef, skill = tes3.skill.speechcraft, value = skillLevel})
		else
			tes3.setStatistic({reference = actorRef, skill = tes3.skill.speechcraft, current = skillLevel})
		end
		dm(string.format("actor '%s' speechcraft set to %s", actorRef.id, skillLevel))
	end
end

local function adjustTrainerSkills(mobile)

	dm("adjustTrainerSkills")
	if not (mobile.actorType == 1) then -- 0 = creature, 1 = NPC, 2 = player
		return
	end

	local actorRef = mobile.reference
	assert(actorRef)

	local level = actorRef.object.level -- SetLevel gets/sets the base object level
	assert(level)
	---dm(string.format("actorRef.id = %s, level = %s", actorRef.id, level))

	local mercantile = mobile.mercantile.current
	assert(mercantile)
	---dm(string.format("actorRef.id = %s, level = %s, mercantile = %s", actorRef.id, level, mercantile))

	local speechcraft = mobile.speechcraft.current
	assert(speechcraft)
	---dm(string.format("actorRef.id = %s, level = %s, speechcraft = %s", actorRef.id, level, speechcraft))

	local skill1 = 0
	local skill2 = 0
	local skill3 = 0
	local skillNew
	for _, v in pairs(mobile.skills) do
		skillNew = v.current
		if skillNew >= skill1 then
			skill3 = skill2
			skill2 = skill1
			skill1 = skillNew
		elseif skillNew >= skill2 then
			skill3 = skill2
			skill2 = skillNew
		elseif skillNew >= skill3 then
			skill3 = skillNew
		end
		---dm(string.format("skillNew id %s, current=%s\n", i, skillNew))
	end
	local skillLevel = (level * config.skillLevelMultiplier) + config.skillLevelBase
	-- skill3 is the 3rd highest skill of the NPC. We will set mercantile and speechcraft to max(skillLevel, skill3 - 1)

	skillNew = skill3 - 1

	if skillNew > 255 then
		skillNew = 255
	end

	dm(string.format("skillLevel = %s, skillNew = %s\n", skillLevel, skillNew))

	if mercantile < skillLevel then
		if mercantile < skillNew then
			if config.persistentSkillsUpgrades then
				tes3.setStatistic({reference = actorRef, skill = tes3.skill.mercantile, value  = skillNew})
			else
				tes3.setStatistic({reference = actorRef, skill = tes3.skill.mercantile, current = skillNew})
			end
			dm(string.format("actor '%s' mercantile set to %s", actorRef.id, skillNew))
		end
	end

	if speechcraft < skillLevel then
		if speechcraft < skillNew then
			if config.persistentSkillsUpgrades then
				tes3.setStatistic({reference = actorRef, skill = tes3.skill.speechcraft, value = skillNew})
			else
				tes3.setStatistic({reference = actorRef, skill = tes3.skill.speechcraft, current = skillNew})
			end
			dm(string.format("actor '%s' speechcraft set to %s", actorRef.id, skillNew))
		end
	end
end

local function uiActivatedMerchant(e)
	if config.upgradeMerchantNPCsSkills then
		if e.newlyCreated then
			local mobile = tes3ui.getServiceActor()
			if mobile then
				---local ref = mobile.reference
				---assert(ref)
				---dm(string.format("uiActivated mobile = %s", modPrefix, ref.id))
				adjustMerchantSkills(mobile)
			end
		end
	end
end

local function uiActivatedTrainer(e)
	if config.upgradeTrainerNPCsSkills then
		if e.newlyCreated then
			local mobile = tes3ui.getServiceActor()
			if mobile then
				---local ref = mobile.reference
				---assert(ref)
				---dm(string.format("uiActivated mobile = %s", modPrefix, ref.id))
				adjustTrainerSkills(mobile)
			end
		end
	end
end

local function calcBarterPrice(e)
	-- e.buying boolean. Read-only. If true, the player is buying, otherwise the player is selling
	if e.buying then
		return
	end
	local priceChanged = false
	local price = e.price
	local h = config.harderMerchantsBuyingPrices
	if h then
		if h > 0 then
			local x = e.basePrice / e.count
			if x > 10 then
				if h == 1 then
					price = price / math.sqrt(math.log10(x))
				elseif h == 2 then
					price = price / math.sqrt(math.log(x))
				elseif h == 3 then
					price = price / math.log10(x)
				elseif h == 4 then
					price = price / math.log(x)
				end
				price = math.floor(price + 0.5)
				priceChanged = true
---mwse.log("basePrice = %s, count = %s, price = %s, priceafter = %s", e.basePrice, e.count, e.price, price)
			end
		end
	end
--[[
log (m * n) = log m + log n
log (m/n) = log m − log n
price = price / log10(baseprice/count)
price = price / log10(baseprice) - log10(count)
]]
	if config.creatureBargainLevel then
		if config.creatureBargainLevel > 0 then
			local mobile = e.mobile
			assert(mobile)
			local actorType = mobile.actorType
			assert(actorType)
			if actorType == 0 then -- creature
				local actorRef = mobile.reference
				assert(actorRef)
				local level = math.max(actorRef.object.level, config.creatureBargainLevel)
				assert(level)
				local kPerc = config.fBargainOfferBase / 100
				local kLevel = (level / 100) + 1
				price = price * kPerc / kLevel
				price = math.floor(price + 0.5)
				priceChanged = true
			end
		end
	end
	if priceChanged then
		e.price = price
	end
end

local function loaded()
	applyConfig()
end

local function initialized()
	event.register('uiActivated', uiActivatedTrainer, { filter = 'MenuServiceTraining' })
	event.register('uiActivated', uiActivatedMerchant, { filter = 'MenuBarter' })
	event.register('calcBarterPrice', calcBarterPrice)
	event.register('loaded', loaded)
	dm("initialized")
end
event.register('initialized', initialized)

--[[

calcBarterPrice

This event is raised when an item price is being determined when bartering.
Event Data
buying: boolean. Read-only. If true, the player is buying, otherwise the player is selling.
mobile: tes3mobileActor. Read-only. The mobile actor for who is selling or buying. May not always be available.
item: tes3item. Read-only. The item, if any, that is being bartered.
itemData: tes3itemData. Read-only. The item data for the bartered item.
price: number. The price of the item. This can be modified, but ensure that the buy/sell price is matched or there will be odd behavior.
count: number. Read-only. The number of items being bartered.
reference: tes3reference. Read-only. A shortcut to the mobile’s reference. May not always be available.
basePrice: number. Read-only. The base price of the item, before any event modifications.

"fBribe10Mod" 35 Dictates amount that NPC Disposition will raise on a successful 10 Gold Bribe –
Don’t believe it’s in straight disposition points – Could be percentages - (Other
factors like race, sex, opposing faction etc. reduce this amount significantly)
"1151" "fBribe100Mod" 75 Dictates amount that NPC Disposition will raise on a successful 100 Gold Bribe.
See above.
"1152" "fBribe1000Mod" 150 Dictates amount that NPC Disposition will raise on a successful 1000 Gold Bribe.
See above.
"1082" "iBarterSuccessDisposition" 1
"1083" "iBarterFailDisposition" -1
If you barter with a merchant successfully, your disposition with that merchant
increases by one and falls by 1 if you fail a barter attempt.
"1133" "fDispBargainSuccessMod" 1
"1134" "fDispBargainFailMod" -1
I don't remember if these work the same as the previous barter disposition values, or
if these are multipliers. These effect the long term disposition of the merchant


from https://wiki.openmw.org/index.php?title=Research:Trading_and_Services
all prices are negative when player is buying, positive when player is selling

accept if playerOffer <= merchantOffer (same for buy and sell)
if npc is a creature: reject (no haggle)

a = abs(merchantOffer)
b = abs(playerOffer)
if buying: d = int(100 * (a - b) / a)
if selling: d = int(100 * (b - a) / b)

clampedDisposition = clamp int(npcDisposition) to [0..100]
dispositionTerm = fDispositionMod * (clampedDisposition - 50)
pcTerm = (dispositionTerm + pcMercantile + 0.1 * pcLuck + 0.2 * pcPersonality) * pcFatigueTerm
npcTerm = (npcMercantile + 0.1 * npcLuck + 0.2 * npcPersonality) * npcFatigueTerm
x = fBargainOfferMulti * d + fBargainOfferBase
if buying: x += abs(int(pcTerm - npcTerm))
if selling: x += abs(int(npcTerm - pcTerm))

roll 100, if roll <= x then trade is accepted
adjust npc temporary disposition by iBarterSuccessDisposition or iBarterFailDisposition

--]]
