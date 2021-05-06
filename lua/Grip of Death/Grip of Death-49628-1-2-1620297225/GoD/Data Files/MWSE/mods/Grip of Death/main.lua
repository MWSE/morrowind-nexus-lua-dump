local cf = mwse.loadConfig("Grip of Death", {gripkey = {keyCode = 56}})			local L = {}		L.AltW = {2, 1, 4, 3, 3, 1, 8, 7}	local AltWCD

local function equip(e) if e.reference == tes3.player and e.item.objectType == tes3.objectType.weapon and tes3.worldController.inputController:isKeyDown(cf.gripkey.keyCode) and not AltWCD then
local o = e.item	local ida = e.itemData	local wg = o.weight
if L.AltW[o.type] and wg > 0 and o ~= AltW then		local New
	if o.id:sub(1,2) == "4_" and tes3.getObject(o.id:sub(3)) then New = tes3.getObject(o.id:sub(3)) else	local nid = "4_" .. o.id		local K = o.isOneHanded and 1.25 or 0.8
		New = tes3.getObject(nid) or tes3.createObject{objectType = tes3.objectType.weapon, id = nid, name = o.name, type = L.AltW[o.type], mesh = o.mesh, icon = o.icon, enchantment = o.enchantment, weight = o.weight,
		materialFlags = o.flags, value = o.value, maxCondition = o.maxCondition, enchantCapacity = o.enchantCapacity, ignoresNormalWeaponResistance = o.ignoresNormalWeaponResistance, reach = o.reach,
		speed = o.isOneHanded and math.min(o.speed + ((wg < 12 and 0) or ((wg < 14 or wg > 24) and 0.1) or 0.2), 2) or math.max(o.speed - ((wg < 11 and 0) or (wg < 13 and 0.1) or (wg < 15 and 0.2) or 0.25), 0.4),
		chopMin = o.chopMin*K, chopMax = o.chopMax*K, slashMin = o.slashMin*K, slashMax = o.slashMax*K, thrustMin = o.thrustMin*K, thrustMax = o.thrustMax*K}
	end
	tes3.addItem{reference = tes3.player, item = New}		--itemData = ida
	if ida then local DAT = tes3.addItemData{to = tes3.player, item = New}	DAT.condition = ida.condition		if ida.charge then DAT.charge = ida.charge end end
	AltWCD = true	tes3.mobilePlayer:equip{item = New}
	timer.delayOneFrame(function() tes3.removeItem{reference = tes3.player, item = o, playSound = false}	AltWCD = nil end, timer.real)
	return false
end
end end		event.register("equip", equip)


local function SpearSword(e)	local w = tes3.mobilePlayer.readiedWeapon	local wid = w and w.object.id
	if w and wid:sub(1,2) == "4_" then local Old = tes3.getObject(wid:sub(3))	if Old and Old.type == 6 then e.progress = 0	tes3.mobilePlayer:exerciseSkill(7, 1) end end
end		event.register("exerciseSkill", SpearSword, {filter = 5})

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Grip of Death")	tpl:saveOnClose("Grip of Death", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
	p0:createKeyBinder{variable = var{id = "gripkey", table = cf}, label = "Press this key when equip weapon to change it grip"}
end		event.register("modConfigReady", registerModConfig)