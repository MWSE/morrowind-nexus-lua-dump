-- PLEASE NOTE: 
-- this mod will permanently remove the vanilla "restock" flag from any vendor's items in your savegame (any vendor you visit)

-- the CONFIG is now ingame in the script settings


local acti = require("openmw.interfaces").Activation
local types = require('openmw.types')
local core = require('openmw.core')
local world = require('openmw.world')
local storage = require('openmw.storage')
local modData = storage.globalSection('thatRestockMod')
local common = {MOD_ID="Restocking"}
local globalSettings = storage.globalSection('SettingsGlobalRestocking')

modData:setLifeTime(storage.LIFE_TIME.Persistent)
if not modData:get("restockDB") then
	modData:set("restockDB", {})
end

--version 1.3
scriptVersion = 1.2


local I = require("openmw.interfaces")
local settings = {
    {
        key = "INGREDIENT_RESTOCKING_MODE",
        name = "Ingredient Restocking Mode",
        description = "Vanilla: Only restock ingredients the merchant would naturally restock\nFully Randomized: Only restock 1/8 of the vanilla ingredients, but spawn an appropiate amount of ingredients that fit the merchant\nHalf-half: Do both, but 50% each",
        default = "Half-Half", 
        renderer = "select",
        argument = {
            disabled = false,
            l10n = "LocalizationContext", 
            items = {"Vanilla", "Half-Half", "Fully Randomized"},
        },
    },
	{
        key = "INGREDIENT_SPAWN_SPEED",
        name = "Restocking Speed For Randomized Ingredients",
        description = "",
        default = 0.75, 
        renderer = "number",
		min = 0,
    },
	{
        key = "INGREDIENT_MAX_STOCK",
        name = "Max Stock For Randomized Ingredients In Days",
        description = "You'll still only get up to 24 hours worth of ingredients at once\nThis increases the max stock so they will restock some more, even if you don't buy something",
        default = 1.5, 
        renderer = "number",
		--integer = true,
		min = 0.1,
    },
	{
		key = "PRINT_DEBUG_INFORMATION",
		renderer = "checkbox",
		name = "Print debug informations to the console (F10)",
		description = "In case you're curious how the sausage is made",
		default = false,
	}
}

if core.contentFiles.has("tr_mainland.esm") or core.contentFiles.has("TR_Factions.esp") then
table.insert(settings,
	{
		key = "TAMRIEL_REBUILT_INGREDIENTS_ONLY_SOLD_IN_TAMRIEL",
		renderer = "checkbox",
		name = "Tamriel Rebuilt Ingredients Only Sold In Tamriel",
		description = "Only spawn random tamriel ingredients when you trade with a merchant from that mod",
		default = true,
	}
)
end
I.Settings.registerGroup {
    key = "SettingsGlobalRestocking",
    page = "Restocking",
    l10n = "Restocking",
    name = "Restocking",
	description = "",
    permanentStorage = true,
    settings = settings
}



local function onSave()
    return {
        version = scriptVersion,
		merchants = merchants,
    }
end


local function onLoad(data)
    if not data then
		dbg("--------------------------------")
		dbg("initializing restock mod")
		dbg("--------------------------------")
		merchants = {}
		local globalDB = modData:getCopy("restockDB")
		for a,b in pairs(globalDB) do
			if b.generatedAlchemyMerchant then
				if b.generatedAlchemyMerchant.class == "vendor" then
					b.generatedAlchemyMerchant.class = "trader"
					dbg("update: fixed (global DB)",a)
				end
			end
		end
		modData:set("restockDB",globalDB)
        return
    end
	if not merchants then
		merchants = {}
	end
	if data.version == 1 then
		for a,b in pairs(data.merchants) do
			if b.generatedAlchemyMerchant then
				if b.generatedAlchemyMerchant.class == "vendor" then
					b.generatedAlchemyMerchant.class = "trader"
					dbg("update: fixed",a)
				end
			end
		end
		local globalDB =  modData:getCopy("restockDB")
		for a,b in pairs(globalDB) do
			if b.generatedAlchemyMerchant then
				if b.generatedAlchemyMerchant.class == "vendor" then
					b.generatedAlchemyMerchant.class = "trader"
					dbg("update: fixed (global DB)",a)
				end
			end
		end
		modData:set("restockDB",globalDB)
	end
    if data.version > scriptVersion then
        for _,player in pairs(world.players) do
			player:sendEvent("Restock_showMessage", "Version too old, Restock mod disabled")
		end
		disableMod = true
    end
	merchants = data.merchants
end

function dbg(...)
if globalSettings:get("PRINT_DEBUG_INFORMATION") then
print(...)
end
end



function tableSize(t)
	local i=0
	for _ in pairs(t) do
		i=i+1
	end
	return i
end

function tableFind(t,kw)
	for a,b in pairs(t) do
		if b==kw then
			return true
		end
	end
	return false
end

function randomIndex(t)
	local i=math.ceil(math.random()*tableSize(t))
	for index in pairs(t) do
		i=i-1
		if i==0 then
			return index
		end
	end
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function initMerchant(npc)
	local npcRecordId = npc.recordId
	if merchants[npcRecordId] then
		if merchants[npcRecordId].dataVersion then
			dbg("--")
			return
		else
			if npc.contentFile == "tr_mainland.esm" or npc.contentFile == "TR_Factions.esp" then
				dbg("refreshing "..npcRecordId.." because the database entry is old and this is a TR npc")
			else
				merchants[npcRecordId].dataVersion = 1
				dbg("--")
				return
			end
		end
	end
	dbg("--initializing "..npcRecordId)
	local npcRecord = types.NPC.record(npcRecordId)
	merchants[npcRecordId] = {}
	local merchant = merchants[npcRecordId]
	local now = world.getGameTime() / (24*60*60)
	local globalDB =  modData:getCopy("restockDB")
	merchant.lastVanillaRestock = now
	merchant.lastIngredientRestock = now
	merchant.generatedAlchemyMerchant = false
	merchant.vanillaRestocks = {}
	merchant.currentStock = {}
	merchant.dataVersion = 1
	local vanillaRestockCount =0
	for _,itemStack in pairs(types.NPC.inventory(npc):getAll()) do
		local itemId = itemStack.recordId
		local itemCount = itemStack.count
		merchant.currentStock[itemId] = itemCount
		if types.Item.isRestocking(itemStack) then
			vanillaRestockCount = vanillaRestockCount + itemCount
			merchant.vanillaRestocks[itemId] = (merchant.vanillaRestocks[itemId] or 0)+itemCount
			itemStack:remove()
			local tempItem = world.createObject(itemId, itemCount)
			tempItem:moveInto(types.NPC.inventory(npc))
		end
	end
	for _,cont in pairs(npc.cell:getAll(types.Container)) do
		if cont.owner.recordId == npcRecordId then
			if not types.Container.inventory(cont):isResolved() then
				types.Container.inventory(cont):resolve()
			end
			for _,itemStack in pairs(types.Container.inventory(cont):getAll()) do
				local itemId = itemStack.recordId
				local itemCount = itemStack.count
				merchant.currentStock[itemId] = (merchant.currentStock[itemId] or 0) + itemCount
				if types.Item.isRestocking(itemStack) then
					vanillaRestockCount = vanillaRestockCount + itemCount
					merchant.vanillaRestocks[itemId] = (merchant.vanillaRestocks[itemId] or 0)+itemCount
					itemStack:remove()
					local tempItem = world.createObject(itemId, itemCount)
					tempItem:moveInto(types.Container.inventory(cont))
				end
			end
		end
	end
	--is this an alchemyMerchant ?
	local countIngredients = 0
	if not alchemyMerchants[npcRecordId:lower()] then
		for itemId,itemCount in pairs(merchant.currentStock) do
			if ingredientMultipliers[itemId] then
				countIngredients = countIngredients + itemCount
			end
		end
		if countIngredients >2 then
			local class = categoryAmounts[npcRecord.class:lower()] and npcRecord.class:lower() 
						or classMap[npcRecord.class:lower()] and classMap[npcRecord.class:lower()]
						or "trader"
			merchant.generatedAlchemyMerchant = {qty = countIngredients,  class = class}
			dbg("found new ingredient vendor: ".. npcRecordId.." ("..class.." / qty: "..countIngredients..")")
		else
			dbg("".. npcRecordId.." ("..npcRecord.class..") won't be a new ingredient vendor :(")
		end
	end
	if globalDB[npcRecordId] then
		if globalDB[npcRecordId].vanillaRestockCount > vanillaRestockCount then
			dbg("loading fallback vanilla restocks ("..globalDB[npcRecordId].vanillaRestockCount.." > "..vanillaRestockCount..")")
			merchant.vanillaRestocks = deepcopy(globalDB[npcRecordId].vanillaRestocks)
			vanillaRestockCount = globalDB[npcRecordId].vanillaRestockCount
		end
		if not alchemyMerchants[npcRecordId:lower()] then
			if globalDB[npcRecordId].generatedAlchemyMerchant and globalDB[npcRecordId].generatedAlchemyMerchant.qty > countIngredients then
				dbg("loading fallback generatedAlchemyMerchant ("..globalDB[npcRecordId].generatedAlchemyMerchant.." > "..countIngredients..")")
				merchant.generatedAlchemyMerchant = deepcopy(globalDB[npcRecordId].generatedAlchemyMerchant)
			end
		end
	end
	globalDB[npcRecordId] = {}
	globalDB[npcRecordId].vanillaRestockCount = vanillaRestockCount
	globalDB[npcRecordId].vanillaRestocks = deepcopy(merchant.vanillaRestocks)
	globalDB[npcRecordId].generatedAlchemyMerchant = deepcopy(merchant.generatedAlchemyMerchant)
	modData:set("restockDB",globalDB)
	
end

function checkCurrentStock(npc,player)
	local npcRecordId = npc.recordId
	local merchant = merchants[npcRecordId]
	if not merchant.currentStock then
		dbg("--checking stock")
		merchant.currentStock = {}
		for _,itemStack in pairs(types.NPC.inventory(npc):getAll()) do
			local itemId = itemStack.recordId
			local itemCount = itemStack.count
			merchant.currentStock[itemId] = itemCount
			if types.Item.isRestocking(itemStack) then
				dbg("WARNING: "..itemId.." somehow returned to restocking?")
				player:sendEvent("Restock_showMessage","WARNING: "..itemId.." somehow returned to restocking?")
				player:sendEvent("Restock_showMessage","Please report this occurance to the mod author")
				itemStack:remove()
				local tempItem = world.createObject(itemId, itemCount)
				tempItem:moveInto(types.NPC.inventory(npc))
			end
		end
		for _,cont in pairs(npc.cell:getAll(types.Container)) do
			if cont.owner.recordId == npcRecordId then
				for _,itemStack in pairs(types.Container.inventory(cont):getAll()) do
					local itemId = itemStack.recordId
					local itemCount = itemStack.count
					merchant.currentStock[itemId] = (merchant.currentStock[itemId] or 0) + itemCount
					if types.Item.isRestocking(itemStack) then
						dbg("WARNING: "..itemId.." somehow returned to restocking?")
						player:sendEvent("Restock_showMessage","WARNING: "..itemId.." somehow returned to restocking?")
						player:sendEvent("Restock_showMessage","Please report this occurance to the mod author")
						itemStack:remove()
						local tempItem = world.createObject(itemId, itemCount)
						tempItem:moveInto(types.NPC.inventory(npc))
					end
				end
			end
		end
	else
		dbg("--")
	end
end

function vanillaRestock(npc)
	local npcRecordId = npc.recordId
	local npcRecord = types.NPC.record(npcRecordId)
	local merchant = merchants[npcRecordId]
	local now = world.getGameTime() / (24*60*60)
	local lastVanillaRestock = merchant.lastVanillaRestock
	local vanillaRestockPct = math.min(1, now-merchant.lastVanillaRestock)
	local vanillaRestocked = {}
	dbg("--Vanilla restocks at "..npcRecordId.." (mode "..globalSettings:get("INGREDIENT_RESTOCKING_MODE")..")")
	if vanillaRestockPct == 1 then
		dbg("lastVanillaRestock: >1 day ago")
	else
		dbg("lastVanillaRestock: "..math.ceil(vanillaRestockPct*1000)/1000 .." days ago")
	end
	
	for item,amount in pairs(merchant.vanillaRestocks) do
		if ingredientMultipliers[item] then
			if globalSettings:get("INGREDIENT_RESTOCKING_MODE") == "Half-Half" then
				amount = math.ceil(amount/2)
			elseif globalSettings:get("INGREDIENT_RESTOCKING_MODE") == "Fully Randomized" then
				amount = math.ceil(amount/8)
			end
		end
		local restockBudget = vanillaRestockPct * amount
		if math.random() < restockBudget-math.floor(restockBudget) then
			restockBudget = restockBudget + 1
		end
		restockBudget = math.max(0, math.floor(restockBudget) - (merchant.currentStock[item] or 0))
		if restockBudget > 0 then
			local tempItem = world.createObject(item,restockBudget)
			vanillaRestocked[item] = restockBudget
			tempItem:moveInto(types.NPC.inventory(npc))
			merchant.currentStock[item] = (merchant.currentStock[item] or 0) + restockBudget
		end
	end
	for item,amount in pairs(merchant.vanillaRestocks) do
		if ingredientMultipliers[item] then
			if globalSettings:get("INGREDIENT_RESTOCKING_MODE") == "Half-Half" then
				amount = math.ceil(amount/2)
			elseif globalSettings:get("INGREDIENT_RESTOCKING_MODE") == "Fully Randomized" then
				amount = math.ceil(amount/8)
			end
		end
		dbg(item.." x "..amount.." ("..((merchant.currentStock[item] or 0)-(vanillaRestocked[item] or 0) )..(vanillaRestocked[item] and "+"..vanillaRestocked[item] or "")..")")
	end
	
	merchant.lastVanillaRestock = now
end

function additionalIngredients(npc,player)
	local npcRecordId = npc.recordId
	local npcRecord = types.NPC.record(npcRecordId)
	local merchant = merchants[npcRecordId]
	if alchemyMerchants[npcRecordId:lower()] or merchant.generatedAlchemyMerchant then
		local dbEntry= alchemyMerchants[npcRecordId:lower()] or merchant.generatedAlchemyMerchant
		local merchantClass = dbEntry.class
		
		local now = world.getGameTime() / (24*60*60)
		if merchant.lastIngredientRestock > now+0.35 then --no idea if anything could cause that
			dbg("WARNING, INGREDIENT RESTOCK TIME LIED IN THE FUTURE")
			player:sendEvent("Restock_showMessage","WARNING, INGREDIENT RESTOCK TIME LIED IN THE FUTURE")
			player:sendEvent("Restock_showMessage","PLEASE REPORT THIS OCCURANCE TO THE MOD AUTHOR")
			merchant.lastIngredientRestock = now-1
		end
		if merchant.lastIngredientRestock <= now-1 then
			dbg("--Additional Ingredients / lastRestock: >1 day ago")
		else
			dbg("--Additional Ingredients / lastRestock: "..math.ceil((now-merchant.lastIngredientRestock)*1000)/1000 .." days ago")
		end
		if merchant.lastIngredientRestock < now-0.05 then
			dbg (npcRecordId.." ("..merchantClass.." = "..categoryAmounts[merchantClass]..") qty= "..(dbEntry.qty or "??")..(merchant.generatedAlchemyMerchant and " (generated)" or ""))
			merchant.lastIngredientRestock = math.max(merchant.lastIngredientRestock,now-1)
			local merchantIngredCount = 0
			dbg("current ingredients: (minus vanilla restock)")
			for itemId,count in pairs(merchant.currentStock) do
				if ingredientMultipliers[itemId] then
					if merchant.vanillaRestocks and merchant.vanillaRestocks[itemId] then
						local vanillaRestock = merchant.vanillaRestocks[itemId]
						if globalSettings:get("INGREDIENT_RESTOCKING_MODE") == "Half-Half" then
							vanillaRestock = math.ceil(vanillaRestock/2)
						elseif globalSettings:get("INGREDIENT_RESTOCKING_MODE") == "Fully Randomized" then
							vanillaRestock = math.ceil(vanillaRestock/8)
						end
						merchantIngredCount = merchantIngredCount + math.max(0,count - vanillaRestock)
						dbg(itemId..": "..count.." - "..vanillaRestock)
					else
						merchantIngredCount = merchantIngredCount + count
						dbg(itemId..": "..count)
					end
				end
			end
			local targetIngredients = categoryAmounts[merchantClass]/2 + (dbEntry.qty and math.min(dbEntry.qty,120)/3 or categoryAmounts[merchantClass]/3)
			targetIngredients = targetIngredients * globalSettings:get("INGREDIENT_SPAWN_SPEED") * globalSettings:get("INGREDIENT_MAX_STOCK")
			if globalSettings:get("INGREDIENT_RESTOCKING_MODE") == "Half-Half" and merchant.vanillaRestocks then
				--for a,b in pairs(merchant.vanillaRestocks) do
				--	vanillaIngredients = vanillaIngredients + b
				--end
				--targetIngredients = targetIngredients + vanillaIngredients
				targetIngredients = targetIngredients / 2
			end
			local refreshBudget = math.max(0,math.min((now-merchant.lastIngredientRestock)*targetIngredients/globalSettings:get("INGREDIENT_MAX_STOCK"), targetIngredients-merchantIngredCount ))
			local vanillaIngredients = 0
			--refreshBudget = math.max(refreshBudget/2, refreshBudget-vanillaIngredients)
			dbg("= "..merchantIngredCount)
			dbg("max ingredients: "..targetIngredients)
			dbg("budget: "..refreshBudget)
			if refreshBudget > 0 then
				if npc.contentFile == "tr_mainland.esm" or npc.contentFile == "TR_Factions.esp" or not globalSettings:get("TAMRIEL_REBUILT_INGREDIENTS_ONLY_SOLD_IN_TAMRIEL") then
					dbg("using TR ingredient table")
				end
				local budgetUsed = 0
				for i=1,40 do
					local ingredientTable = ingredientCategories
					if npc.contentFile == "tr_mainland.esm" or npc.contentFile == "TR_Factions.esp" or not globalSettings:get("TAMRIEL_REBUILT_INGREDIENTS_ONLY_SOLD_IN_TAMRIEL") then
						ingredientTable = TR_ingredientCategories
					end
					local randomIngred = ingredientTable[merchantClass][math.random(1,#ingredientTable[merchantClass])]
					if npcRecord.race == "khajiit" and (math.random(1,#ingredientTable[merchantClass])<=2 or math.random()<0.1) then
						randomIngred =  ingredientTable["contraband"][math.random(1,#ingredientTable["contraband"])]
					end
					local randomCount = math.ceil(math.random()*5*ingredientMultipliers[randomIngred])
					randomCount = math.min((merchant.currentStock[randomIngred] or 0) + randomCount, math.ceil(ingredientMultipliers[randomIngred]*25))-(merchant.currentStock[randomIngred] or 0)
					if randomCount >=1 then
						local tempItem = world.createObject(randomIngred,randomCount)
						tempItem:moveInto(types.NPC.inventory(npc))
						merchant.currentStock[randomIngred] = (merchant.currentStock[randomIngred] or 0) + randomCount
					end
					budgetUsed = budgetUsed + randomCount
					dbg("inserted: "..randomIngred.." x "..randomCount)
					--dbg("budgetUsed: "..budgetUsed)
					if budgetUsed >= refreshBudget then
						break
					end
				end
				dbg("new timestamp: "..(math.floor(math.min(now+0.3,merchant.lastIngredientRestock + budgetUsed/(targetIngredients/globalSettings:get("INGREDIENT_MAX_STOCK")))*1000)/1000) .." = ".. math.floor(merchant.lastIngredientRestock*1000)/1000 .." + "..budgetUsed.." / "..math.floor((targetIngredients/globalSettings:get("INGREDIENT_MAX_STOCK"))*1000)/1000)
				merchant.lastIngredientRestock = math.min(now+0.3,merchant.lastIngredientRestock + budgetUsed/(targetIngredients/globalSettings:get("INGREDIENT_MAX_STOCK")))
			end
		end
	end
end

local function activateNPC(npc, player)
	if types.Actor.isDead(npc) then
		return
	end
	local npcRecordId = npc.recordId
	local npcRecord = types.NPC.record(npcRecordId)
	if not npcRecord or not npcRecord.servicesOffered.Barter then
		return
	end
	if disableMod then
		player:sendEvent("Restock_showMessage", "Version too old, Restock mod disabled")
		return
	end
		
	--if types.NPC.races.record(npcRecord.race).isBeast then
	--	local tempItem = world.createObject("ingred_moon_sugar_01",1)
	--	tempItem:moveInto(types.NPC.inventory(npc))
	--end
		--dbg("--------------")
	initMerchant(npc)
	
		--dbg("---------------")
	checkCurrentStock(npc,player)
	
		--dbg("---------------")
	vanillaRestock(npc)
	
		--dbg("---------------")
	if globalSettings:get("INGREDIENT_RESTOCKING_MODE") ~= "Vanilla" then
		additionalIngredients(npc,player)
	end
	merchants[npcRecordId].currentStock = nil
end

acti.addHandlerForType(types.NPC, activateNPC)

ingredientBlacklist = {
	"uniq",
	"corprusmeat",
	"human",
	"_UNI",
	"UNI_",
	"_uni",
	"uni_",
	"cursed",
	"innocent_heart",
	"udyrfrykte_heart",
	"ingred_scrib_jelly_02", --meteor slime
	"ingred_raw_glass_tinos", --Raw Glass (tinos?)
	"poison_goop00", --Poison
	"ingred_guar_hide_marsus", --Marsus' Guar Hide
	"ingred_guar_hide_girith", --Girith's Guar Hide
	"ingred_treated_bittergreen_uniq", --Treated Bittergreen Petals
	
	--TR:
	"tr_m",
	"tr_i",
	
	--MR:
	"mr_crab_meat_poisoned",
	
	
}

gemNames = {
	"amethyst",
	"diamond",
	"emerald",
	"garnet",
	"pearl",
	"ruby",
	"sapphire",
	
	--TR:
	"jade_01",
	"opal_01",
	"aquamarine_01",
	"topaz_01",
	"spinel_01",
	"turquoise_01",
	"spellstone_01",
	"agate_",
	"amber_01",
	"ametrine_01",
	"bloodstone_01",
	"citrine_01",
	"foolsgold_01",
	"icecrystal_01",
	"jet_01",
	"khajiiteye_01",
	"lodestone_01",
	"malouchite_01",
	"moonstone_01",
	"onyx_01",
	"peridot_01",
	"rosequartz_01",
	"smokyquartz_01",
	
	--MR:
	"mr_topaz",
	
}

tradegoodNames = {
	"hide",
	"leather",
	"pelt",
	"raw_",
	"metal",
	"ingred_bloat_01",
	"ingred_daedra_skin_01",
	"ingred_ghoul_heart_01",
	"ingred_gravedust_01",
	"_ore", --adamantium_ore is very rare
	
	--TR:
	"t_ingmine",
	"t_ingdye",
	"silk_01", --also spidersilk + dridreasilk
	"wool_01",
	
}
contrabandNames = {
	"moon_sugar",
}

ingredientMultipliers = {}

ingredientCategories ={
	["food"] = {},
	["tradegoods"] = {},
	["expensive"] = {},
	["contraband"] = {},
	["uncategorized"] = {},
	["ignored"] = {},
}
TR_prefixes={
"t_ingcrea",
"t_ingflor",
"t_ingmine",
"t_ingfood",
"t_ingdye",
"t_ingspice",
"tr_m",
"tr_i",
}
TR_ingredientCategories ={
	["food"] = {},
	["tradegoods"] = {},
	["expensive"] = {},
	["contraband"] = {},
	["uncategorized"] = {},
	["ignored"] = {},
}

for i, rec in pairs(types.Ingredient.records) do
	local isOkay = true
	for _, keyWord in pairs(ingredientBlacklist) do
		if rec.id:find(keyWord) then
			isOkay = false
		end
	end
	if isOkay and rec.mwscript=="" then
		local isFood = false
		for a,b in pairs(rec.effects) do
			if b.id == "restorefatigue" then
				isFood = true
			end
		end
		if rec.id:find("food") then
			isFood = true
		end
		if rec.value >=35 then
			isFood = false
		end
		if rec.id:find("t_ingfood") then
			isFood = true
		end
		if rec.id:find("sweetroll") then
			isFood = true
		end
		if rec.id:find("mr_marshmerrow_boiled ") then
			isFood = true
		end
		if rec.id:find("t_ingflor") then
			isFood = false
		end
		if rec.id:find("powder") then
			isFood = false
		end
		if rec.id:find("choke") then
			isFood = false
		end
		
		local isGem = false
		for _, keyWord in pairs(gemNames) do
			if rec.id:find(keyWord) and not isFood then
				isGem =true
			end			
		end
		if rec.value <50 then
			isGem = false
		end
		
		local isTradegood = false
		for _, keyWord in pairs(tradegoodNames) do
			if rec.id:find(keyWord) and not isFood and not isGem then
				isTradegood =true
			end			
		end
		
		local isContraband = false
		for _, keyWord in pairs(contrabandNames) do
			if rec.id:find(keyWord) then
				isContraband = true
				isTradegood = false
				isGem = false
				isFood = false
			end			
		end
		

		if rec.value >= 40 then
			ingredientMultipliers[rec.id] = math.max(0.1,0.5-((rec.value-40)/300))
		elseif rec.value >= 20 then
			ingredientMultipliers[rec.id] = 0.58-0.08*((rec.value-20)/20)
		elseif rec.value >= 10 then
			ingredientMultipliers[rec.id] = 0.67-0.09*((rec.value-10)/10)
		elseif rec.value >= 5 then
			ingredientMultipliers[rec.id] = 0.76-0.09*((rec.value-5)/5)
		elseif rec.value >= 2 then
			ingredientMultipliers[rec.id] = 0.85-0.09*((rec.value-2)/3)
		else
			ingredientMultipliers[rec.id] = 1
		end
		if rec.id:find("spice_") then
			ingredientMultipliers[rec.id] = ingredientMultipliers[rec.id] *0.7
		elseif isFood then
			ingredientMultipliers[rec.id] = ingredientMultipliers[rec.id] *1.2
		end
		local isTR = false
		for a,b in pairs(TR_prefixes) do
			if rec.id:find(b) == 1 then
				isTR = true
			end
		end
		if isTR then
			if rec.id:find("spice_") then
				table.insert(TR_ingredientCategories.food,rec.id)
				table.insert(TR_ingredientCategories.tradegoods,rec.id)
			elseif isFood then
				table.insert(TR_ingredientCategories.food,rec.id)
			elseif isGem then
				table.insert(TR_ingredientCategories.expensive,rec.id)
			elseif isTradegood then
				table.insert(TR_ingredientCategories.tradegoods,rec.id)
			elseif isContraband then
				table.insert(TR_ingredientCategories.contraband,rec.id)
			else
				table.insert(TR_ingredientCategories.uncategorized,rec.id)
			end
		else
			if rec.id:find("spice_") then
				table.insert(ingredientCategories.food,rec.id)
				table.insert(TR_ingredientCategories.food,rec.id)
				table.insert(ingredientCategories.tradegoods,rec.id)
				table.insert(TR_ingredientCategories.tradegoods,rec.id)
			elseif isFood then
				table.insert(ingredientCategories.food,rec.id)
				table.insert(TR_ingredientCategories.food,rec.id)
			elseif isGem then
				table.insert(ingredientCategories.expensive,rec.id)
				table.insert(TR_ingredientCategories.expensive,rec.id)
			elseif isTradegood then
				table.insert(ingredientCategories.tradegoods,rec.id)
				table.insert(TR_ingredientCategories.tradegoods,rec.id)
			elseif isContraband then
				table.insert(ingredientCategories.contraband,rec.id)
				table.insert(TR_ingredientCategories.contraband,rec.id)
			else
				table.insert(ingredientCategories.uncategorized,rec.id)
				table.insert(TR_ingredientCategories.uncategorized,rec.id)
			end
		end
	else
		local isTR = false
		for a,b in pairs(TR_prefixes) do
			if rec.id:find(b) == 1 then
				isTR = true
			end
		end
		if isTR then
			table.insert(TR_ingredientCategories.ignored,rec.id) --UNUSED
		else
			table.insert(ingredientCategories.ignored,rec.id) --UNUSED
			table.insert(TR_ingredientCategories.ignored,rec.id) --UNUSED
		end
	end
end

for catName,cat in pairs(TR_ingredientCategories) do
	dbg("")
	dbg(catName..":")
	for _,itemName in pairs(cat) do
		--local mult = math.floor(100*ingredientMultipliers[itemName])/100
		if tableFind(ingredientCategories[catName],itemName) then
			dbg(itemName)
		else
			dbg("TR",itemName)
		end
		if catName ~= "ignored" then
		local randomCount = math.ceil(math.random()*5*ingredientMultipliers[itemName])
		end
	end
end

ingredientCategories.alchemist = {}
ingredientCategories.publican = {}
for _,ing in pairs(ingredientCategories.food) do
	table.insert(ingredientCategories.publican, ing)
	table.insert(ingredientCategories.alchemist, ing)
end
--("food -> publican")
ingredientCategories.trader = {}
for _,ing in pairs(ingredientCategories.tradegoods) do
	table.insert(ingredientCategories.trader, ing)
	table.insert(ingredientCategories.alchemist, ing)
end
--("tradegoods -> trader")
ingredientCategories.thief = {}
for _,ing in pairs(ingredientCategories.expensive) do
	table.insert(ingredientCategories.thief, ing)
	table.insert(ingredientCategories.trader, ing)
	table.insert(ingredientCategories.alchemist, ing)
end
--("expensive -> thief")
--("expensive -> trader")
for _,ing in pairs(ingredientCategories.uncategorized) do
	table.insert(ingredientCategories.alchemist, ing)
	table.insert(ingredientCategories.alchemist, ing)
end
--("everything except contraband -> alchemist")

ingredientCategories["apothecary"] = ingredientCategories["alchemist"]
ingredientCategories["healer"] = ingredientCategories["alchemist"]
ingredientCategories["priest"] = ingredientCategories["alchemist"]
ingredientCategories["wisewoman"] = ingredientCategories["alchemist"]

--TR:
TR_ingredientCategories.alchemist = {}
TR_ingredientCategories.publican = {}
for _,ing in pairs(TR_ingredientCategories.food) do
	table.insert(TR_ingredientCategories.publican, ing)
	table.insert(TR_ingredientCategories.alchemist, ing)
end
--("food -> publican")
TR_ingredientCategories.trader = {}
for _,ing in pairs(TR_ingredientCategories.tradegoods) do
	table.insert(TR_ingredientCategories.trader, ing)
	table.insert(TR_ingredientCategories.alchemist, ing)
end
--("tradegoods -> trader")
TR_ingredientCategories.thief = {}
for _,ing in pairs(TR_ingredientCategories.expensive) do
	table.insert(TR_ingredientCategories.thief, ing)
	table.insert(TR_ingredientCategories.trader, ing)
	table.insert(TR_ingredientCategories.alchemist, ing)
end
--("expensive -> thief")
--("expensive -> trader")
for _,ing in pairs(TR_ingredientCategories.uncategorized) do
	table.insert(TR_ingredientCategories.alchemist, ing)
	table.insert(TR_ingredientCategories.alchemist, ing)
end
--("everything except contraband -> alchemist")
TR_ingredientCategories["apothecary"] = TR_ingredientCategories["alchemist"]
TR_ingredientCategories["healer"] = TR_ingredientCategories["alchemist"]
TR_ingredientCategories["priest"] = TR_ingredientCategories["alchemist"]
TR_ingredientCategories["wisewoman"] = TR_ingredientCategories["alchemist"]

classMap = {
	["alchemist service"] = "alchemist",
	["apothecary service"] = "apothecary",
	["crusader"] = "priest",
	["healer service"] = "healer",
	["monk"] = "priest",
	["monk service"] = "priest",
	["priest service"] = "priest",
	["thief service"] = "thief",
	["wise woman"] = "wisewoman",
	["wise woman service"] = "wisewoman",
	["witch"] = "apothcary",
}

categoryAmounts = {
["trader"]= 8,
["publican"]=25,
["thief"]=3,
["alchemist"] = 35,
["apothecary"] = 25,
["healer"] = 15,
["priest"] = 10,
["wisewoman"] = 15
}

-- database in case you're installing the mod mid-game and have already bought all ingredients (just in case)
alchemyMerchants = 
{
["bildren areleth"] = {num= 7+18+3, qty= 55+43+6, ll= 19, class= "apothecary"},
["milar maryon"] = {num= 8, qty= 70, class= "healer"},
["clagius clanler"] = {num= 1, qty= 3, ll= 30, class= "trader"},
["mororurg"] = {num= 17, qty= 33, class= "alchemist"},
["jolda"] = {num= 10+8, qty= 62+8, class= "apothecary"},
["tivam sadri"] = {num= 9, qty= 71, class= "priest"},
["eldrilu dalen"] = {num= 9, qty= 65, ll= 36, class= "priest"},
["folvys andalor"] = {num= 9, qty= 73, class= "healer"},
["brathus dals"] = {num= 1, qty= 15, ll= 10+8, class= "publican"},
["mamaea"] = {ll= 36, class= "healer"},
["massarapal"] = {ll= 36, class= "trader"},
["elynu saren"] = {num= 2, qty= 12, ll= 28, class= "priest"},
["manse andus"] = {num= 4, qty= 17, ll= 10+6, class= "publican"},
["brarayni sarys"] = {num= 11+21, qty= 61+28, class= "alchemist"},
["bervaso thenim"] = {num= 8, qty= 15, ll= 106, class= "apothecary"},
["bacola closcius"] = {ll= 12, class= "publican"},
["fara"] = {num= 1+1, qty= 20+2, ll= 10+11, class= "publican"},
["thaeril"] = {num= 2, qty= 12, ll= 10+13, class= "publican"},
["threvul serethi"] = {num= 8+1+1, qty= 60+20+6, ll= 68, class= "healer"},
["drarayne girith"] = {num= 3, qty= 12, ll= 10+14, class= "trader"},
["gils drelas"] = {num= 12+10, qty= 68+14, class= "alchemist"},
["danoso andrano"] = {num= 10+2, qty= 83+8, ll= 5, class= "apothecary"},
["tusamircil"] = {num= 10, qty= 85, class= "alchemist"},
["craeita jullalian"] = {num= 14+13, qty= 50+16, ll= 35, class= "alchemist"},
["cienne sintieve"] = {num= 11+13, qty= 83+24, class= "alchemist"},
["j'rasha"] = {num= 7+7, qty= 33+9, ll= 109, class= "healer"},
["gindas ildram"] = {num= 6, qty= 235, ll= 58, class= "trader"},
["scelian plebo"] = {num= 11+11, qty= 82+12, ll= 35, class= "healer"},
["meder nulen"] = {num= 1, qty= 10, ll= 39, class= "trader"},
["ralds oril"] = {num= 4+2, qty= 4+3, ll= 38, class= "trader"},
["addut-lamanu"] = {ll= 46, class= "healer"},
["lloros sarano"] = {num= 4, qty= 22, ll= 17, class= "priest"},
["eris telas"] = {ll= 10, class= "apothecary"},
["nalis gals"] = {ll= 10, class= "trader"},
["perien aurelie"] = {ll= 10, class= "trader"},
["abelle chriditte"] = {ll= 11, class= "alchemist"},
["selkirnemus"] = {ll= 12, class= "trader"},
["moroni uvelas"] = {num= 1, qty= 1, ll= 9, class= "trader"},
["shulki ashunbabi"] = {num= 4, qty= 19, class= "trader"},
["ravoso aryon"] = {num= 8, qty= 8, class= "trader"},
["thongar"] = {num= 1, qty= 1, ll= 45, class= "trader"},
["burcanius varo"] = {num= 1, qty= 6, ll= 10+34, class= "trader"},
["raril giral"] = {num= 4, qty= 5, ll= 10+28, class= "publican"},
["nibani maesa"] = {num= 4, qty= 6, ll= 41, class= "wisewoman"},
["manirai"] = {num= 5, qty= 9, ll= 39, class= "wisewoman"},
["malpenix blonia"] = {num= 6, qty= 8, ll= 38, class= "trader"},
["drelasa ramothran"] = {ll= 15+14, class= "publican"},
["ulumpha gra-sharob"] = {num= 4, qty= 30, class= "healer"},
["fenas madach"] = {num= 7, qty= 73, ll= 120, class= "thief"},
["heifnir"] = {num= 6, qty= 9, ll= 40, class= "trader"},
["jeanne"] = {ll= 51, class= "trader"},
["ygfa"] = {num= 5+2, qty= 24+4, ll= 10, class= "healer"},
["fryfnhild"] = {num= 3, qty= 18, ll= 44, class= "trader"},
["mandur omalen"] = {num= 7, qty= 24, ll= 38, class= "trader"},
["elegal"] = {ll= 16, class= "trader"},
["nivos drivam"] = {num= 6, qty= 16, class= "trader"},
["tiras sadus"] = {num= 4, qty= 5, ll= 51, class= "trader"},
["banor seran"] = {num= 3, qty= 38, ll= 10+32, class= "publican"},
["gadela andus"] = {num= 4, qty= 16, ll= 10+39, class= "publican"},
["somutis vunnis"] = {num= 6, qty= 30, class= "priest"},
["guls llervu"] = {num= 6, qty= 30, ll= 4, class= "priest"},
["pierlette rostorard"] = {num= 12+14, qty= 85+28, ll= 103, class= "apothecary"},
["daynali dren"] = {num= 15+9, qty= 122+9, ll= 32, class= "alchemist"},
["sedris omalen"] = {num= 5, qty= 38, class= "priest"},
["galore salvi"] = {ll= 20+14, class= "publican"},
["llorayna sethan"] = {num= 1, qty= 2, ll= 20+11, class= "publican"},
["benunius agrudilius"] = {num= 3+1, qty= 8+2, ll= 10+49, class= "publican"},
["tussi"] = {num= 1, qty= 30, ll= 51, class= "healer"},
["relms gilvilo"] = {num= 7, qty= 31, class= "priest"},
["fadase selvayn"] = {num= 5, qty= 6, ll= 10, class= "trader"},
["berwen"] = {num= 5+2, qty= 19+9, ll= 52, class= "trader"},
["peragon"] = {num= 7, qty= 32, class= "apothecary"},
["ashur-dan"] = {ll= 68, class= "trader"},
["garas seloth"] = {num= 7+14+2, qty= 26+20+20, ll= 7, class= "alchemist"},
["ababael timsar-dadisun"] = {ll= 69, class= "trader"},
["nalcarya of white haven"] = {num= 19+18, qty= 127+24, class= "alchemist"},
["goldyn belaram"] = {num= 7, qty= 24, ll= 51, class= "trader"},
["dulnea ralaal"] = {num= 4, qty= 59, ll= 12+31, class= "publican"},
["llarara omayn"] = {num= 7, qty= 35, class= "priest"},
["telis salvani"] = {num= 7, qty= 35, class= "healer"},
["sinnammu mirpal"] = {num= 9, qty= 43, ll= 41, class= "wisewoman"},
["zanmulk sammalamus"] = {num= 5+1, qty= 50+4, class= "healer"},
["galuro belan"] = {num= 6+16, qty= 28+24, ll= 14, class= "apothecary"},
["kurapli"] = {num= 1, qty= 30, ll= 58, class= "trader"},
["lanabi"] = {num= 1, qty= 30, ll= 58, class= "trader"},
["ernand thierry"] = {num= 7+11, qty= 35+15, class= "alchemist"},
["arnand liric"] = {num= 6, qty= 45, class= "healer"},
["tyermaillin"] = {ll= 22, class= "healer"},
["irgola"] = {num= 1, qty= 1, ll= 19, class= "trader"},
["sorosi radobar"] = {num= 1, qty= 7, ll= 5+15, class= "publican"},
["verick gemain"] = {num= 8, qty= 21, ll= 56, class= "trader"},
["rolasa oren"] = {num= 5, qty= 5, ll= 68, class= "alchemist"},
["sedam omalen"] = {ll= 77, class= "trader"},
["salen ravel"] = {num= 5+3+2, qty= 35+8+24, ll= 43, class= "priest"},
["shenk"] = {num= 7, qty= 24, ll= 12+50, class= "publican"},
["aunius autrus"] = {num= 7, qty= 45, class= "priest"},
["mehra drora"] = {num= 7+1, qty= 46+1, class= "priest"},
["agning"] = {num= 1, qty= 5, ll= 21, class= "publican"},
["gadayn andarys"] = {num= 1, qty= 8, ll= 77, class= "trader"},
["dulian"] = {num= 7+1, qty= 50+1, class= "priest"},
["chaplain ogrul"] = {num= 6, qty= 60, class= "healer"},
["andilu drothan"] = {num= 7+3, qty= 34+8, ll= 44, class= "alchemist"},
["vaval selas"] = {num= 7+1, qty= 35+2, ll= 49, class= "healer"},
["manara othan"] = {num= 4, qty= 9, ll= 10+73, class= "publican"},
["daynes redothril"] = {ll= 26, class= "trader"},
["arangaer"] = {num= 2, qty= 3, ll= 22, class= "alchemist"},
["anarenen"] = {num= 8+11, qty= 48+13, class= "alchemist"},
["cocistian quaspus"] = {num= 7+5, qty= 52+5, ll= 19, class= "apothecary"},
["llathyno hlaalu"] = {num= 9, qty= 45, class= "priest"},
["dralval andrano"] = {num= 9+5, qty= 45+5, class= "apothecary"},
["ajira"] = {num= 9+6, qty= 45+7, class= "alchemist"},
["andil"] = {num= 7, qty= 60, class= "apothecary"},
["ganalyn saram"] = {num= 7+20, qty= 35+35, ll= 21, class= "alchemist"},
["hinald"] = {ll= 27, class= "thief"},
["hjotra the peacock"] = {num= 5, qty= 20, ll= 14, class= "trader"},
["aurane frernis"] = {num= 8+24, qty= 38+31, ll= 14, class= "apothecary"},
["ibarnadad assirnarari"] = {num= 19+6, qty= 45+18, ll= 54, class= "apothecary"},
["irna maryon"] = {num= 9+4, qty= 51+7, class= "apothecary"},
["sernsi drelas"] = {num= 8, qty= 50, ll= 65, class= "trader"},
["mevel fererus"] = {ll= 29, class= "trader"},
["vasesius viciulus"] = {num= 4, qty= 4, ll= 6+18, class= "trader"},
["anis seloth"] = {num= 26+19+1, qty= 190+42+4, ll= 41, class= "alchemist"},
["felara andrethi"] = {num= 8+7, qty= 64+18, class= "healer"},
["orns omaren"] = {num= 1, qty= 10, ll= 98, class= "trader"},
["boderi farano"] = {ll= 10+2, class= "publican"},
["trasteve"] = {num= 1, qty= 1, ll= 30, class= "trader"},
["ery"] = {num= 2, qty= 2, ll= 10, class= "publican"},
["arrille"] = {num= 3, qty= 15, ll= 10, class= "trader"},
["ashumanu eraishah"] = {num= 3, qty= 7, ll= 10, class= "trader"},
["balen andrano"] = {ll= 3, class= "trader"},
["ra'virr"] = {ll= 3, class= "trader"},
["syloria siruliulus"] = {ll= 7, class= "trader"},
["lalatia larian"] = {num= 1, qty= 1, class= "priest"},
["mebestian ence"] = {num= 1, qty= 1, ll= 3, class= "trader"},
["helviane desele"] = {num= 1+1, qty= 1+6, class= "publican"},
["tendris vedran"] = {num= 3, qty= 4, class= "apothecary"},

--tribunal
["crito olcinius"]={ class="priest"},
["fonari indaren"]={ class="apothecary"},
["galsa andrano"]={ class="healer"},
["hession"]={ class="publican"},
["laurina maria"]={ class="healer"},
["mehra helas"]={ class="healer"},
["nerile andaren"]={ class="healer"},
["ra'tesh"]={ class="trader"},
["roner arano"]={ class="trader"},
["sunel hlas"]={ class="trader"},
["ten-tongues_weerhat"]={ class="trader"},
["ungeleb"]={ class="alchemist"},

--solstheim
["alcedonia amnis"]={ class="publican"},
["bronrod_the_roarer"]={ class="healer"},
["mirisa"]={ class="priest"},
["sathyn andrano"]={ class="trader"},
}


return {    
	engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
    },
	eventHandlers = {
		AlchRestock_takeAll = takeAll,
		AlchRestock_takeBook = takeBook,
	}
}