local cfg = mwse.loadConfig("4NM_ARMORER") or {minchance = 20, autokey = {keyCode = 56}}
local koef, chance
local A = {furn_anvil00 = true, furn_t_fireplace_01 = true, furn_de_forge_01 = true, furn_de_bellows_01 = true, Furn_S_forge = true}

local function improve(e) if e.item then	local cost = (2 * e.item.value)^0.5
	if chance - cost >= math.random(100) then	e.itemData.condition = e.item.maxCondition * (1 + koef)
		tes3.messageBox("You successfully improved %s  Chance = %.2f (%.2f - %.2f cost)", e.item.name, (chance - cost), chance, cost)		tes3.playSound{sound = "repair"}
	else	e.itemData.condition = e.item.maxCondition * (0.5 + koef * 4)
		tes3.messageBox("You failed to improve %s  Chance = %.2f (%.2f - %.2f cost)", e.item.name, (chance - cost), chance, cost)			tes3.playSound{sound = "repair fail"}
	end
end end

local function filt(e) if ((e.item.objectType == tes3.objectType.weapon and e.item.type ~= 11) or e.item.objectType == tes3.objectType.armor) and chance - (2 * e.item.value)^0.5 >= cfg.minchance then
	if not e.itemData then tes3.addItemData{to = tes3.player, item = e.item} end	if e.itemData then return e.itemData.condition >= e.item.maxCondition end
else return false end end

local function onEquip(e) if not tes3.mobilePlayer.inCombat and e.item.objectType == tes3.objectType.repairItem then	local anvil
	koef = math.min(tes3.mobilePlayer.armorer.current/2000 * e.item.quality, 0.1)
	for r in tes3.player.cell:iterateReferences(tes3.objectType.static) do if A[r.object.id] and tes3.player.position:distance(r.position) < 800 then anvil = true	break end end
	chance = math.min((tes3.mobilePlayer.armorer.current + tes3.mobilePlayer.luck.current/5 + tes3.mobilePlayer.agility.current/5) * e.item.quality/2, 150) + (anvil and math.min(tes3.mobilePlayer.armorer.current/2, 50) or 0)
	tes3.findGMST("fRepairAmountMult").value = anvil and 3 or 2
	if tes3.worldController.inputController:isKeyDown(cfg.autokey.keyCode) then tes3ui.showInventorySelectMenu{title = "Improve weapons and armor", noResultsText = "No items that you can improve", filter = filt, callback = improve}	return false
	else timer.start{duration = 0.1, callback = function() tes3ui.showInventorySelectMenu{title = "Improve weapons and armor", noResultsText = "No items that you can improve", filter = filt, callback = improve} end} end
end end

local function registerModConfig()	local template = mwse.mcm.createTemplate("4NM_ARMORER")		template:saveOnClose("4NM_ARMORER", cfg)		template:register()		local page = template:createPage()
	page:createSlider{label = "Minimum chance of success for upgrade offer", min = 0, max = 100, step = 1, jump = 5, variable = mwse.mcm.createTableVariable{id = "minchance", table = cfg}}
	page:createKeyBinder{label = "Hold this button while equipping the repair kit - repair menu will not appear, but there will only be an upgrade menu", variable = mwse.mcm.createTableVariable{id = "autokey", table = cfg}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)
	event.register("equip", onEquip)
end		event.register("initialized", initialized)