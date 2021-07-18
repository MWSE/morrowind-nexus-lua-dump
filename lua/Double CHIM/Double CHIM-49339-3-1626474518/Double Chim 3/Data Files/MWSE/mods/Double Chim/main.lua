local cf = mwse.loadConfig("DoubleChim", {m = true, ekey = {keyCode = 42}, dwmkey = {keyCode = 29}})		local L = {}
local p, mp, ad, p1, p3, D, ic, MB, Sim		local W = {}	local AS = {[0]=1, [2]=0, [3]=0, [4]=0, [5]=1, [6]=1, [7]=1}
local ING = {["Enchant_right"] = true, ["Enchant_left"] = true}		L.DWOBT = {[tes3.objectType.light] = true, [tes3.objectType.lockpick] = true, [tes3.objectType.probe] = true}

L.M180 = tes3matrix33.new()		L.M180:toRotationX(math.rad(180))
L.Cul = function(x) W.w1.appCulled = x	W.w3.appCulled = x	W.wl1.appCulled = not x		W.wl3.appCulled = not x		W.wr1.appCulled = not x		W.wr3.appCulled = not x	end
L.GetConEn = function(arm, en) local E = arm == 1 and "ER" or "EL"	if en and en.castType == 3 then W[E] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}}
	for i, ef in ipairs(en.effects) do W[E][i].id = ef.id	W[E][i].min = ef.min	W[E][i].max = ef.max	W[E][i].radius = ef.radius	W[E][i].duration = 36000	W[E][i].attribute = ef.attribute	W[E][i].skill = ef.skill end	
else W[E] = nil end end
L.DWNEW = function(o, od, left)	if left then
	W.wl1 = tes3.loadMesh(o.mesh):clone()	W.wl1.translation = W.w1.translation:copy()		W.wl1.translation.z = W.wl1.translation.z*-1	W.wl1.rotation = W.w1.rotation:copy() * L.M180	W.wl3 = W.wl1:clone()
	W.WL = o	W.DL = od	W.DL.tempData.DW = 2	L.GetConEn(2, o.enchantment)	if cf.m then tes3.messageBox("Left weapon remembered: %s", o.name)	end		if W.WR then L.DWMOD(true) end
else W.wr1 = tes3.loadMesh(o.mesh):clone()	W.wr1.translation = W.w1.translation:copy()		W.wr1.rotation = W.w1.rotation:copy()	W.wr3 = W.wr1:clone()
	W.WR = o	W.DR = od	W.DR.tempData.DW = 1	L.GetConEn(1, o.enchantment)	if W.WL then L.DWMOD(true) end
end end
L.ClearEn = function() local si	if D.DWER then si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.DWER}	if si then si.state = 6 end D.DWER = nil end
if D.DWEL then si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.DWEL}	if si then si.state = 6 end D.DWEL = nil end end
local function playItemSound(e) if e.item == W.WR or e.item == W.WL then if W.snd then W.snd = nil return false else W.snd = nil end end end
local function spellResist(e) if e.target == p and e.source.objectType == tes3.objectType.enchantment and e.source.castType == 3 and e.sourceInstance.item.objectType == tes3.objectType.weapon then e.resistedPercent = 100 end end
local function weaponReadied(e) if e.reference == p then if e.weaponStack then 	L.Cul(true) else L.DWMOD(false) end end end
local function weaponUnreadied(e) if e.reference == p then	L.Cul(false) end end


local function SAVE(e) if W.DWM then D.DW = {IDR = W.WR.id, IDL = W.WL.id, CondR = W.DR.condition, CondL = W.DL.condition} end end		event.register("save", SAVE)

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer 	ad = mp.actionData		D = p.data		p1 = tes3.player1stPerson.sceneNode		p3 = p.sceneNode	W = {}	Sim = nil	L.ClearEn()
W.l1 = p1:getObjectByName("Bip01 L Hand")		W.l3 = p3:getObjectByName("Bip01 L Hand")		W.r1 = p1:getObjectByName("Bip01 R Hand")		W.r3 = p3:getObjectByName("Bip01 R Hand")
W.w1 = p1:getObjectByName("Weapon Bone")		W.w3 = p3:getObjectByName("Weapon Bone")
event.unregister("playItemSound", playItemSound, {priority = 10000})	event.unregister("spellResist", spellResist)	event.unregister("weaponReadied", weaponReadied)	event.unregister("weaponUnreadied", weaponUnreadied)
local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
if w then	if D.DW then
	if w.id == D.DW.IDR and wd.condition == D.DW.CondR then L.DWNEW(w, wd, false)		local ob = tes3.getObject(D.DW.IDL)
		for i, ida in pairs(p.object.inventory:findItemStack(ob).variables) do if ida.condition == D.DW.CondL and ida ~= W.DR then L.DWNEW(ob, ida, true)	break end end
	--	for _, st in pairs(p.object.inventory) do if st.object.id == D.DW.IDL and st.variables and st.variables[1].condition == D.DW.CondL and st.variables[1] ~= W.DR then L.DWNEW(st.object, st.variables[1], true)	break end end
	elseif w.id == D.DW.IDL and wd.condition == D.DW.CondL then L.DWNEW(w, wd, true)	local ob = tes3.getObject(D.DW.IDR)
		for i, ida in pairs(p.object.inventory:findItemStack(ob).variables) do if ida.condition == D.DW.CondR and ida ~= W.DL then L.DWNEW(ob, ida, false)	break end end
	--	for _, st in pairs(p.object.inventory) do if st.object.id == D.DW.IDR and st.variables and st.variables[1].condition == D.DW.CondR and st.variables[1] ~= W.DL then L.DWNEW(st.object, st.variables[1], false)	break end end
	end
	D.DW = nil
elseif w.type < 9 and w.isOneHanded then L.DWNEW(w, wd, false) end end
end		event.register("loaded", loaded)


L.DWMOD = function(st) if st then 
	if not W.DWM then if W.WR and W.WL and p.object.inventory:contains(W.WR, W.DR) and W.DR.condition > 0 and p.object.inventory:contains(W.WL, W.DL) and W.DL.condition > 0 then
		tes3.loadAnimation{reference = mp.firstPersonReference, file = "dw_merged.nif"}
		p1 = tes3.player1stPerson.sceneNode		W.l1 = p1:getObjectByName("Bip01 L Hand")	W.r1 = p1:getObjectByName("Bip01 R Hand")	W.w1 = p1:getObjectByName("Weapon Bone")
		local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object		mp:unequip{armorSlot = 8}	mp:unequip{type = tes3.objectType.light}	L.ClearEn()
		W.l1:attachChild(W.wl1)		W.wl1:updateNodeEffects()	W.l3:attachChild(W.wl3)		W.wl3:updateNodeEffects()	W.r1:attachChild(W.wr1)		W.wr1:updateNodeEffects()	W.r3:attachChild(W.wr3)		W.wr3:updateNodeEffects()
		L.Cul(true)		W.DWM = true	if cf.m then tes3.messageBox("Double weapons! %s and %s", W.WR, W.WL) end
		event.register("playItemSound", playItemSound, {priority = 10000})	event.register("spellResist", spellResist)	event.register("weaponReadied", weaponReadied)	event.register("weaponUnreadied", weaponUnreadied)
		if W.ER then D.DWER = (tes3.applyMagicSource{reference = p, name = "Enchant_right", effects = W.ER}).serialNumber end
		if W.EL then D.DWEL = (tes3.applyMagicSource{reference = p, name = "Enchant_left", effects = W.EL}).serialNumber end
		if W.ER and w == W.WR and wd == W.DR then mp:equip{item = W.WL, itemData = W.DL} elseif W.EL and w == W.WL and wd == W.DL or (w ~= W.WR and w ~= W.WL) then mp:equip{item = W.WR, itemData = W.DR} end
	else if cf.m then tes3.messageBox("Weapons not prepared! %s and %s", W.WR, W.WL) end		W.WL = nil	 W.DL = nil	end end
elseif W.DWM then L.ClearEn()		tes3.loadAnimation{reference = mp.firstPersonReference, file = nil}
	W.l1:detachChild(W.wl1)		W.l3:detachChild(W.wl3)		W.r1:detachChild(W.wr1)		W.r3:detachChild(W.wr3)		
	L.Cul(false)	W.DWM = false	if cf.m then tes3.messageBox("DW mod off") end
	event.unregister("playItemSound", playItemSound, {priority = 10000})	event.unregister("spellResist", spellResist)	event.unregister("weaponReadied", weaponReadied)	event.unregister("weaponUnreadied", weaponUnreadied)
end end


L.Swap = function(w, wd) if (mp.isMovingLeft or mp.isMovingRight) and not (mp.isMovingForward or mp.isMovingBack) then
	if w == W.WR and wd == W.DR then
		if p.object.inventory:contains(W.WL, W.DL) and W.DL.condition > 0 then
			ad.animationAttackState = 0		W.snd = 1	mp:equip{item = W.WL, itemData = W.DL}		ad.attackDirection = 0
		else L.DWMOD(false) W.WL = nil W.DL = nil end
	end
else
	if w == W.WL and wd == W.DL then
		if p.object.inventory:contains(W.WR, W.DR) and W.DR.condition > 0 then
			if mp.isRunning or mp.isWalking then MB[1] = 0 end		ad.animationAttackState = 0		W.snd = 1	mp:equip{item = W.WR, itemData = W.DR}
		else L.DWMOD(false) W.WR = nil W.DR = nil end
	end
end end


local function simulate(e) if W.DWM and mp.weaponDrawn and MB[1] == 128 then	if AS[ad.animationAttackState] == 1 then	local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
	L.Swap(w, wd)	event.unregister("simulate", simulate)		Sim = nil
end else event.unregister("simulate", simulate)	Sim = nil end end



local function mouseButtonDown(e) if W.DWM and not tes3ui.menuMode() and e.button == 0 and mp.weaponDrawn then	local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
	if w then if AS[ad.animationAttackState] == 1 then L.Swap(w, wd) elseif AS[ad.animationAttackState] == 0 and not Sim then event.register("simulate", simulate)	Sim = 1 end else L.DWMOD(false) end
end end		event.register("mouseButtonDown", mouseButtonDown)


local function equipped(e) if e.reference == p then	local o = e.item	if o.objectType == tes3.objectType.weapon then local od = e.itemData
	if o.type < 9 and o.isOneHanded then if not ((o == W.WL and od == W.DL) or (o == W.WR and od == W.DR)) then	L.DWMOD(false)		L.DWNEW(o, od, ic:isKeyDown(cf.ekey.keyCode)) end
	else L.DWMOD(false) end
elseif (o.objectType == tes3.objectType.armor and o.slot == 8 or L.DWOBT[o.objectType]) then L.DWMOD(false) end end end		event.register("equipped", equipped)

local function keyDown(e) if not tes3ui.menuMode() and e.keyCode == cf.dwmkey.keyCode then if e.isAltDown then W.WL = nil W.DL = nil else L.DWMOD(not W.DWM) end end end	event.register("keyDown", keyDown)


local function registerModConfig()	local tpl = mwse.mcm.createTemplate("DoubleChim")	tpl:saveOnClose("DoubleChim", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
	p0:createKeyBinder{variable = var{id = "ekey", table = cf}, label = "Press this key when equip weapon to remember it for left hand"}
	p0:createKeyBinder{variable = var{id = "dwmkey", table = cf}, label = "Switch to dual-weapon mode. Press this button while holding ALT to forget the left weapon"}
	p0:createYesNoButton{variable = var{id = "m", table = cf}, label = "Show messages"}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	ic = tes3.worldController.inputController		MB = ic.mouseState.buttons 
	tes3.findGMST("sMagicPCResisted").value = ""
end		event.register("initialized", initialized)