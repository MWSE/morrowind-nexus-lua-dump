-- PLEASE NOTE: 
-- this mod will permanently remove the vanilla "restock" flag from any vendor's items in your savegame (any vendor you visit)


--- CONFIG:

INGREDIENT_RESTOCKING_MODE = 2
-- 1: only restock ingredients from the vanilla restock pool
-- 2: additionally restock some random ingredients (do both, but only half each)
-- 3: fully randomize the ingredient restocking (100% of the random ingredients, 1/8 of the vanilla restocking of ingredients)

INGREDIENT_SPAWN_SPEED = 0.75 
-- just an arbitrary multiplier for the additional ingredient restocking speed (mode 2 and 3)

INGREDIENT_MAX_STOCK = 3 
-- (in days, does not affect how much you get per day) (only affects the additional ingredient restocking, so mode 2 and 3)




PRINT_DEBUG_INFORMATION = false

local acti = require("openmw.interfaces").Activation
local types = require('openmw.types')
local core = require('openmw.core')
local world = require('openmw.world')
local storage = require('openmw.storage')
local modData = storage.globalSection('thatRestockMod')
modData:setLifeTime(storage.LIFE_TIME.Persistent)
if not modData:get("restockDB") then
	modData:set("restockDB", {})
end

scriptVersion = 1

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
		scriptVersion = 1
		merchants = {}
        return
    end
    if data.version > scriptVersion then
        error('Required update to a new version of the script')
    end
	merchants = data.merchants
end

function dbg(...)
if PRINT_DEBUG_INFORMATION then
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
    if orig_type == 'table' then
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
		return
	end
	dbg("initializing "..npcRecordId)
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
						or "vendor"
			merchant.generatedAlchemyMerchant = {qty = countIngredients,  class = class}
			dbg("found new ingredient vendor: ".. npcRecordId.." ("..class..")")
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
		dbg("checking stock")
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
	dbg("Vanilla restocking supplies at "..npcRecordId.." (mode "..INGREDIENT_RESTOCKING_MODE..")")
	if vanillaRestockPct == 1 then
		dbg("lastVanillaRestock: >1 day ago")
	else
		dbg("lastVanillaRestock: "..math.floor(vanillaRestockPct*10000)/10000 .." days ago")
	end
	
	for item,amount in pairs(merchant.vanillaRestocks) do
		if ingredientMultipliers[item] then
			if INGREDIENT_RESTOCKING_MODE == 2 then
				amount = math.ceil(amount/2)
			elseif INGREDIENT_RESTOCKING_MODE == 3 then
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
			if INGREDIENT_RESTOCKING_MODE == 2 then
				amount = math.ceil(amount/2)
			elseif INGREDIENT_RESTOCKING_MODE == 3 then
				amount = math.ceil(amount/8)
			end
		end
		dbg(item.." x "..amount.." ("..((merchant.currentStock[item] or 0)-(vanillaRestocked[item] or 0) )..(vanillaRestocked[item] and "+"..vanillaRestocked[item] or "")..")")
	end
	
	merchant.lastVanillaRestock = now
end

function additionalIngredients(npc,player)
	local npcRecordId = npc.recordId
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
			dbg("lastIngredientRestockRestock: >1 day ago")
		else
			dbg("lastIngredientRestockRestock: "..math.floor((now-merchant.lastIngredientRestock)*10000)/10000 .." days ago")
		end
		if merchant.lastIngredientRestock < now-0.05 then
			dbg ("Restocking additional Ingredients")
			dbg (npcRecordId.." ("..merchantClass.." = "..categoryAmounts[merchantClass]..") qty= "..(dbEntry.qty or "??")..(merchant.generatedAlchemyMerchant and " (generated)" or ""))
			merchant.lastIngredientRestock = math.max(merchant.lastIngredientRestock,now-1)
			local merchantIngredCount = 0
			dbg("current ingredients: (minus vanilla restock)")
			for itemId,count in pairs(merchant.currentStock) do
				if ingredientMultipliers[itemId] then
					if merchant.vanillaRestocks and merchant.vanillaRestocks[itemId] then
						local vanillaRestock = merchant.vanillaRestocks[itemId]
						if INGREDIENT_RESTOCKING_MODE == 2 then
							vanillaRestock = math.ceil(vanillaRestock/2)
						elseif INGREDIENT_RESTOCKING_MODE == 3 then
							vanillaRestock = math.ceil(vanillaRestock/8)
						end
						merchantIngredCount = merchantIngredCount + math.max(0,count - vanillaRestock)
						dbg(itemId.." x "..count.." - "..vanillaRestock)
					else
						merchantIngredCount = merchantIngredCount + count
						dbg(itemId.." x "..count)
					end
				end
			end
			local targetIngredients = categoryAmounts[merchantClass]/2 + (dbEntry.qty and math.min(dbEntry.qty,120)/5 or categoryAmounts[merchantClass]/3)
			targetIngredients = targetIngredients * INGREDIENT_SPAWN_SPEED * INGREDIENT_MAX_STOCK
			if INGREDIENT_RESTOCKING_MODE == 2 and merchant.vanillaRestocks then
				--for a,b in pairs(merchant.vanillaRestocks) do
				--	vanillaIngredients = vanillaIngredients + b
				--end
				--targetIngredients = targetIngredients + vanillaIngredients
				targetIngredients = targetIngredients / 2
			end
			local refreshBudget = math.max(0,math.min((now-merchant.lastIngredientRestock)*targetIngredients/INGREDIENT_MAX_STOCK, targetIngredients-merchantIngredCount ))
			local vanillaIngredients = 0
			--refreshBudget = math.max(refreshBudget/2, refreshBudget-vanillaIngredients)
			dbg("= "..merchantIngredCount)
			dbg("max ingredients: "..targetIngredients)
			dbg("budget: "..refreshBudget)
			if refreshBudget > 0 then
				local budgetUsed = 0
				for i=1,15 do
					local randomIngred = ingredientCategories[merchantClass][math.random(1,#ingredientCategories[merchantClass])]
					if khajiit[merchantRefId] and math.random(1,#ingredientCategories[merchantClass])<=2 then
						randomIngred = "ingred_moon_sugar_01"
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
				dbg((math.min(now+0.3,merchant.lastIngredientRestock + budgetUsed/(targetIngredients/INGREDIENT_MAX_STOCK))) .." = ".. merchant.lastIngredientRestock .." + "..budgetUsed.." / "..(targetIngredients/INGREDIENT_MAX_STOCK))
				merchant.lastIngredientRestock = math.min(now+0.3,merchant.lastIngredientRestock + budgetUsed/(targetIngredients/INGREDIENT_MAX_STOCK))
			end
		end
	end
end

local function activateNPC(npc, player)

player:sendEvent("Restock_showMessage","hi")
	if types.Actor.isDead(npc) then
		return
	end
	local npcRecordId = npc.recordId
	local npcRecord = types.NPC.record(npcRecordId)
	if not npcRecord or not npcRecord.servicesOffered.Barter then
		return
	end
	
		dbg("---------------")
	initMerchant(npc)
	
		dbg("---------------")
	checkCurrentStock(npc,player)
	
		dbg("---------------")
	vanillaRestock(npc)
	
		dbg("---------------")
	if INGREDIENT_RESTOCKING_MODE >= 2 then
		additionalIngredients(npc,player)
	end
	merchants[npcRecordId].currentStock = nil
end

acti.addHandlerForType(types.NPC, activateNPC)


ingredientMultipliers = { --gold values:
["ingred_alit_hide_01"]=1, -- 5
["ingred_bc_ampoule_pod"]=1, -- 2
["ingred_ash_salts_01"]=0.8, -- 25
["ingred_ash_yam_01"]=1, -- 1
["ingred_bittergreen_petals_01"]=1, -- 5
["ingred_black_anther_01"]=1, -- 2
["ingred_black_lichen_01"]=1, -- 2
["ingred_bloat_01"]=1, -- 5
["ingred_bonemeal_01"]=1, -- 2
["ingred_bread_01"]=1, -- 1
["ingred_bc_bungler's_bane"]=1, -- 1
["ingred_chokeweed_01"]=1, -- 1
["ingred_bc_coda_flower"]=1, -- 23
["ingred_comberry_01"]=1, -- 2
["ingred_corkbulb_root_01"]=1, -- 5
["ingred_corprus_weepings_01"]=1, -- 50
["ingred_crab_meat_01"]=1, -- 1
["ingred_daedra_skin_01"]=0.1, -- 200
["ingred_daedras_heart_01"]=0.1, -- 200
["ingred_diamond_01"]=0.2, -- 250
["ingred_dreugh_wax_01"]=0.6, -- 100
["ingred_ectoplasm_01"]=1, -- 10
["ingred_emerald_01"]=0.2, -- 150
["ingred_fire_petal_01"]=1, -- 2
["ingred_fire_salts_01"]=0.4, -- 100
["ingred_frost_salts_01"]=0.4, -- 75
["ingred_ghoul_heart_01"]=0.2, -- 150
["ingred_gold_kanet_01"]=1, -- 5
["ingred_gravedust_01"]=1, -- 1
["ingred_green_lichen_01"]=1, -- 1
["ingred_guar_hide_01"]=1, -- 5
["ingred_hackle-lo_leaf_01"]=1, -- 30
["ingred_heather_01"]=1, -- 1
["ingred_hound_meat_01"]=1, -- 2
["ingred_bc_hypha_facia"]=1, -- 1
["ingred_kagouti_hide_01"]=1, -- 2
["ingred_kresh_fiber_01"]=1, -- 1
["ingred_kwama_cuttle_01"]=1, -- 2
["food_kwama_egg_02"]=1, -- 2
["ingred_russula_01"]=1, -- 1
["ingred_marshmerrow_01"]=1, -- 1
["ingred_moon_sugar_01"]=0.5, -- 50
["ingred_muck_01"]=1, -- 1
["ingred_netch_leather_01"]=1, -- 1
["ingred_pearl_01"]=0.3, -- 100
["ingred_racer_plumes_01"]=1, -- 20
["ingred_rat_meat_01"]=1, -- 1
["ingred_raw_ebony_01"]=0.2, -- 200
["ingred_raw_glass_01"]=0.2, -- 200
["ingred_red_lichen_01"]=1, -- 25
["ingred_resin_01"]=1, -- 10
["ingred_roobrush_01"]=1, -- 1
["ingred_ruby_01"]=0.2, -- 200
["ingred_saltrice_01"]=1.3, -- 1
["ingred_scales_01"]=1, -- 2
["ingred_scamp_skin_01"]=1, -- 10
["ingred_scathecraw_01"]=1, -- 2
["ingred_scrap_metal_01"]=0.6, -- 20
["ingred_scrib_jelly_01"]=1, -- 10
["ingred_scrib_jerky_01"]=1, -- 5
["ingred_scuttle_01"]=0.9, -- 10
["ingred_shalk_resin_01"]=0.7, -- 50
["ingred_sload_soap_01"]=0.7, -- 50
["food_kwama_egg_01"]=1, -- 1
["ingred_bc_spore_pod"]=1, -- 1
["ingred_stoneflower_petals_01"]=1, -- 1
["ingred_trama_root_01"]=1, -- 10
["ingred_vampire_dust_01"]=0.4, -- 500
["ingred_coprinus_01"]=1, -- 1
["ingred_void_salts_01"]=0.4, -- 100
["ingred_wickwheat_01"]=1, -- 1
["ingred_willow_anther_01"]=1, -- 10
}

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
["healer"] = 10,
["priest"] = 10,
["wisewoman"] = 15
}
ingredientCategories ={
["trader"] = {"ingred_alit_hide_01","ingred_bloat_01","ingred_daedra_skin_01","ingred_diamond_01","ingred_emerald_01","ingred_ghoul_heart_01","ingred_gravedust_01","ingred_guar_hide_01","ingred_kagouti_hide_01","ingred_netch_leather_01","ingred_pearl_01","ingred_raw_ebony_01","ingred_raw_glass_01","ingred_red_lichen_01","ingred_resin_01","ingred_ruby_01","ingred_scrap_metal_01","ingred_sload_soap_01"},
["publican"] = {"ingred_bread_01","ingred_crab_meat_01","ingred_hound_meat_01","food_kwama_egg_02","ingred_rat_meat_01","ingred_saltrice_01","ingred_scrib_jerky_01","ingred_scuttle_01","food_kwama_egg_01"},
["thief"] = {"ingred_diamond_01","ingred_emerald_01","ingred_pearl_01","ingred_raw_ebony_01","ingred_raw_glass_01","ingred_ruby_01"},
["alchemist"] = {},
}

for a,b in pairs(ingredientMultipliers) do
	if a~="ingred_bread_01" and a~="ingred_moon_sugar_01" then
		table.insert(ingredientCategories["alchemist"],a)
	end
end
ingredientCategories["apothecary"] = ingredientCategories["alchemist"]
ingredientCategories["healer"] = ingredientCategories["alchemist"]
ingredientCategories["priest"] = ingredientCategories["healer"]
ingredientCategories["wisewoman"] = ingredientCategories["healer"]

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
["brathus dals"] = {num= 1, qty= 15, ll= 10+8, class= "trader"},
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
["gadela andus"] = {num= 4, qty= 16, ll= 10+39, class= "trader"},
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

khajiit = 
{
["abanji"]=true,
["adanja"]=true,
["addhiranirr"]=true,
["adharanji"]=true,
["affri"]=true,
["ahdahni"]=true,
["ahdni"]=true,
["ahdri"]=true,
["ahjara"]=true,
["ahnarra"]=true,
["ahnassi"]=true,
["ahndahra"]=true,
["ahndahra"]=true,
["ahnia"]=true,
["ahnisa"]=true,
["ahzini"]=true,
["aina"]=true,
["ajira"]=true,
["anjari"]=true,
["arabhi"]=true,
["aravi"]=true,
["ashidasha"]=true,
["baadargo"]=true,
["bahdahna"]=true,
["bahdrashi"]=true,
["baissa"]=true,
["bhusari"]=true,
["cattle"]=true,
["chirranirr"]=true,
["dahleena"]=true,
["dahnara"]=true,
["dro'barri"]=true,
["dro'qanar"]=true,
["dro'sakhar"]=true,
["dro'shavir"]=true,
["dro'tasarr"]=true,
["dro'zah"]=true,
["dro'zaymar"]=true,
["dro'zharim"]=true,
["drofarahn"]=true,
["dro'zhirr"]=true,
["ekapi"]=true,
["habasi"]=true,
["harassa"]=true,
["idhassi"]=true,
["inerri"]=true,
["inorra"]=true,
["j'dato"]=true,
["j'dhannar"]=true,
["j'hanir"]=true,
["j'jarsha"]=true,
["j'jazha"]=true,
["j'kara"]=true,
["j'raksa"]=true,
["j'rasha"]=true,
["j'saddha"]=true,
["j'zamha"]=true,
["j'zhirr"]=true,
["j_saddha"]=true,
["jo'ren-dar"]=true,
["jo'thri-dar"]=true,
["jobasha"]=true,
["jodhur"]=true,
["joshur"]=true,
["kaasha"]=true,
["khamuzi"]=true,
["khazura"]=true,
["khinjarsi"]=true,
["kiseena"]=true,
["kishni"]=true,
["kisimba"]=true,
["kisisa"]=true,
["m'aiq"]=true,
["m'nashi"]=true,
["m'shan"]=true,
["ma'dara"]=true,
["ma'jidarr"]=true,
["ma'khar"]=true,
["ma'zahn"]=true,
["nisaba"]=true,
["pretty kitty"]=true,
["qa'dar"]=true,
["ra'karim"]=true,
["ra'kothre"]=true,
["ra'mhirr"]=true,
["ra'sava"]=true,
["ra'tesh"]=true,
["ra'virr"]=true,
["ra'zahr"]=true,
["ra'zhid"]=true,
["rabinna"]=true,
["ri'darsha"]=true,
["ri'dumiwa"]=true,
["ri'shajirr"]=true,
["ri'vassa"]=true,
["ri'zaadha"]=true,
["s'bakha"]=true,
["s'radirr"]=true,
["s'rava"]=true,
["s'raverr"]=true,
["s'renji"]=true,
["s'vandra"]=true,
["s'virr"]=true,
["shaba"]=true,
["shivani"]=true,
["sholani"]=true,
["shotherra"]=true,
["shunari eye-fly"]=true,
["sugar-lips habasi"]=true,
["todd_khajiit"]=true,
["thengil"]=true,
["tsabhi"]=true,
["tsajadhi"]=true,
["tsalani"]=true,
["tsani"]=true,
["tsiya"]=true,
["tsrazami"]=true,
["ubaasi"]=true,
["udarra"]=true,
["unjara"]=true,
["urjorad"]=true,
["vanjirra"]=true,
["wadarkhu"]=true,
["zahraji"]=true
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