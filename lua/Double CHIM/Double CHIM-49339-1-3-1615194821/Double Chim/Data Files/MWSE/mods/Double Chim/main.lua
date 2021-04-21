local cf = mwse.loadConfig("DoubleChim", {lwkey = {keyCode = 42}, dwmkey = {keyCode = 29}})		local L = {}	local T = timer
local p, mp, ad, p1, p3, D, ic, MB, Sim		 local Matr = tes3matrix33.new()	Matr:toRotationX(math.rad(180))		local W = {}	local AS = {[0]=1, [2]=0, [3]=0, [4]=0, [5]=1, [6]=1, [7]=1}
local ING = {["Enchant_right"] = true, ["Enchant_left"] = true}		local OBT = {[tes3.objectType.light] = true, [tes3.objectType.lockpick] = true, [tes3.objectType.probe] = true}

L.Cul = function(x) W.w1.appCulled = x	W.w3.appCulled = x	W.wl1.appCulled = not x		W.wl3.appCulled = not x		W.wr1.appCulled = not x		W.wr3.appCulled = not x	end
L.GetConEn = function(arm, en) local E = arm == 1 and "ER" or "EL"	if en and en.castType == 3 then W[E] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}}
	for i, ef in ipairs(en.effects) do W[E][i].id = ef.id	W[E][i].min = ef.min	W[E][i].max = ef.max	W[E][i].radius = ef.radius	W[E][i].duration = 36000	W[E][i].attribute = ef.attribute	W[E][i].skill = ef.skill end	
else W[E] = nil end end
L.ClearEn = function() local si	if D.DWER then si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.DWER}	if si then si.state = 6 end D.DWER = nil end
if D.DWEL then si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.DWEL}	if si then si.state = 6 end D.DWEL = nil end end
local function playItemSound(e) if e.item == W.WR or e.item == W.WL then if W.snd then W.snd = nil return false else W.snd = nil end end end
local function spellResist(e) if e.target == p and e.source.objectType == tes3.objectType.enchantment and e.source.castType == 3 and e.sourceInstance.item.objectType == tes3.objectType.weapon then e.resistedPercent = 100 end end
local function magicCasted(e) if e.caster == p and e.source.icon == "" then local name = e.source.name
	if name == "Enchant_right" then D.DWER = e.sourceInstance.serialNumber elseif name == "Enchant_left" then D.DWEL = e.sourceInstance.serialNumber end
end	end
local function weaponReadied(e) if e.reference == p then if e.weaponStack then 	L.Cul(true) else L.DWMOD(false) end end end
local function weaponUnreadied(e) if e.reference == p then	L.Cul(false) end end


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer 	ad = mp.actionData		D = p.data	p1 = mp.firstPersonReference.sceneNode	p3 = p.sceneNode	W = {}	Sim = nil	L.ClearEn()
	W.l1 = p1:getObjectByName("Bip01 L Hand")		W.l3 = p3:getObjectByName("Bip01 L Hand")		W.r1 = p1:getObjectByName("Bip01 R Hand")		W.r3 = p3:getObjectByName("Bip01 R Hand")
	W.w1 = p1:getObjectByName("Weapon Bone")		W.w3 = p3:getObjectByName("Weapon Bone")
	event.unregister("playItemSound", playItemSound)	event.unregister("spellResist", spellResist)	event.unregister("magicCasted", magicCasted)	event.unregister("weaponReadied", weaponReadied)	event.unregister("weaponUnreadied", weaponUnreadied)
	local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
	if w and w.isOneHanded then	W.wr1 = tes3.loadMesh(w.mesh):clone()	W.wr1.translation = W.w1.translation:copy()		W.wr1.rotation = W.w1.rotation:copy()	W.wr3 = W.wr1:clone()
	W.WR = w	W.DR = wd	W.DR.data.DW = 1	L.GetConEn(1, w.enchantment) end
end		event.register("loaded", loaded)


L.DWMOD = function(st) if st then 
	if not W.DWM then if W.WR and W.WL and p.object.inventory:contains(W.WR, W.DR) and W.DR.condition > 0 and p.object.inventory:contains(W.WL, W.DL) and W.DL.condition > 0 then
		local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object		mp:unequip{armorSlot = 8}	mp:unequip{type = tes3.objectType.light}	L.ClearEn()
--		tes3.playAnimation{reference = p, mesh = "xbase_anim_dw.nif"}
--		p1 = mp.firstPersonReference.sceneNode		W.l1 = p1:getObjectByName("Bip01 L Hand")		W.r1 = p1:getObjectByName("Bip01 R Hand")		W.w1 = p1:getObjectByName("Weapon Bone")
		
		W.l1:attachChild(W.wl1)		W.wl1:updateNodeEffects()	W.l3:attachChild(W.wl3)		W.wl3:updateNodeEffects()	W.r1:attachChild(W.wr1)		W.wr1:updateNodeEffects()	W.r3:attachChild(W.wr3)		W.wr3:updateNodeEffects()
		L.Cul(true)		W.DWM = true	tes3.messageBox("Double weapons! %s and %s", W.WR, W.WL)
		event.register("playItemSound", playItemSound)	event.register("spellResist", spellResist)	event.register("magicCasted", magicCasted)	event.register("weaponReadied", weaponReadied)	event.register("weaponUnreadied", weaponUnreadied)
		if W.ER then tes3.applyMagicSource{reference = p, name = "Enchant_right", effects = W.ER} end		if W.EL then tes3.applyMagicSource{reference = p, name = "Enchant_left", effects = W.EL} end
		if W.ER and w == W.WR and wd == W.DR then mp:equip{item = W.WL, itemData = W.DL} elseif W.EL and w == W.WL and wd == W.DL or (w ~= W.WR and w ~= W.WL) then mp:equip{item = W.WR, itemData = W.DR} end
	else tes3.messageBox("Weapons not prepared! %s and %s", W.WR, W.WL)		W.WL = nil	 W.DL = nil	end end
elseif W.DWM then L.ClearEn()
--	tes3.playAnimation{reference = p, mesh = "xbase_anim.nif"}
--	p1 = mp.firstPersonReference.sceneNode		W.l1 = p1:getObjectByName("Bip01 L Hand")		W.r1 = p1:getObjectByName("Bip01 R Hand")		W.w1 = p1:getObjectByName("Weapon Bone")
	
	W.l1:detachChild(W.wl1)		W.l3:detachChild(W.wl3)		W.r1:detachChild(W.wr1)		W.r3:detachChild(W.wr3)		L.Cul(false)	W.DWM = false	tes3.messageBox("DW mod off")
	event.unregister("playItemSound", playItemSound)	event.unregister("spellResist", spellResist)	event.unregister("magicCasted", magicCasted)	event.unregister("weaponReadied", weaponReadied)	event.unregister("weaponUnreadied", weaponUnreadied)
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
--elseif e.button == 2 then	local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
	--local o = (w == W.WL and w ~= W.WR and "L") or (w == W.WR and w ~= W.WL and "R") or (w == W.WR and w == W.WL and "D") or "Error"		local od = (wd == W.DL and "L") or (wd == W.DR and "R") or "Error"
	--tes3.messageBox("w = %s (%s)  data = %s (%s)  mesh = %s", o, w, od, wd and wd.data.DW, mp.firstPersonReference.object.mesh)
	--MB[1] = 0	ad.animationAttackState = 0
end end		event.register("mouseButtonDown", mouseButtonDown)


local function equipped(e) if e.reference == p then	local o = e.item	if o.objectType == tes3.objectType.weapon then local od = e.itemData
	if o.isOneHanded then if not ((o == W.WL and od == W.DL) or (o == W.WR and od == W.DR)) then	L.DWMOD(false)
		if ic:isKeyDown(cf.lwkey.keyCode) then
			W.wl1 = tes3.loadMesh(o.mesh):clone()	W.wl1.translation = W.w1.translation:copy()		W.wl1.translation.z = W.wl1.translation.z*-1	W.wl1.rotation = W.w1.rotation:copy() * Matr	W.wl3 = W.wl1:clone()
			W.WL = o	W.DL = od	W.DL.data.DW = 2	L.GetConEn(2, o.enchantment)	tes3.messageBox("Left weapon remembered: %s", o.name)	if W.WR then L.DWMOD(true) end
		else
			W.wr1 = tes3.loadMesh(o.mesh):clone()	W.wr1.translation = W.w1.translation:copy()		W.wr1.rotation = W.w1.rotation:copy()	W.wr3 = W.wr1:clone()
			W.WR = o	W.DR = od	W.DR.data.DW = 1	L.GetConEn(1, o.enchantment)	if W.WL then L.DWMOD(true) end
		end
	end else L.DWMOD(false) end
elseif (o.objectType == tes3.objectType.armor and o.slot == 8 or OBT[o.objectType]) then L.DWMOD(false) end end end		event.register("equipped", equipped)

local function keyDown(e) if not tes3ui.menuMode() and e.keyCode == cf.dwmkey.keyCode then if e.isAltDown then W.WL = nil W.DL = nil else L.DWMOD(not W.DWM) end end end	event.register("keyDown", keyDown)


local function sim(e) if W.DWM then
	tes3.messageBox("as = %s  swing = %.2f   dir = %s   MB = %s", ad.animationAttackState, ad.attackSwing, ad.attackDirection, MB[1])
end end	--event.register("simulate", sim)

local function onAttack(e) local a = e.mobile	local ar = e.reference	local t = e.targetMobile	local tr = e.targetReference	local ad = a.actionData
local w = a.readiedWeapon	local wd = w and w.variables	w = w and w.object 	local wt = w and w.type or -1	local fiz = ad.physicalDamage
local sw = ad.attackSwing	 local dir = ad.attackDirection		local as = ad.animationAttackState	local ag = ad.currentAnimationGroup
if ar == p then	local ob = (w == W.WL and w ~= W.WR and "L") or (w == W.WR and w ~= W.WL and "R") or (w == W.WR and w == W.WL and "D") or "Error"	
	local dat = (wd == W.DL and "L") or (wd == W.DR and "R") or "Error"
	tes3.messageBox("%s  dir = %s  sw = %.2f   w = %s  dat = %s", (dir == 1 and (ob == "L" or ob == "D") and dat == "L") or (dir ~= 1 and (ob == "R" or ob == "D") and dat == "R"), dir, sw, ob, dat)
end end		--event.register("attack", onAttack)

local function mouseButtonUp(e) if W.DWM and not tes3ui.menuMode() and e.button == 0 and ad.animationAttackState == 2 then	local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
	--event.register("simulate", simulate)
	--if T.timeLeft then T:cancel() end
end end		--event.register("mouseButtonUp", mouseButtonUp)

--local function equip(e) if e.reference == p then	local it = e.item	if it.objectType == tes3.objectType.weapon then local ida = e.itemData	if ida and ida.condition <= 0 then
--if it == W.WL and ida == W.DL then W.WL = nil	 W.DL = nil		L.DWMOD(false) elseif it == W.WR and ida == W.DR then W.WR = nil	 W.DR = nil		L.DWMOD(false) end end end end end
--for _, st in pairs(p.object.inventory) do if st.object.objectType == tes3.objectType.weapon and st.variables and st.variables[1].condition > 0 and st.variables[1].data.DW then end end
--if not T.timeLeft then T = timer.start{duration = 0.1, iterations = -1, callback = function() end} end


local function registerModConfig()	local tpl = mwse.mcm.createTemplate("DoubleChim")	tpl:saveOnClose("DoubleChim", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
	p0:createKeyBinder{variable = var{id = "lwkey", table = cf}, label = "Press this key when equip weapon to remember it for left hand"}
	p0:createKeyBinder{variable = var{id = "dwmkey", table = cf}, label = "Switch to dual-weapon mode. Press this button while holding ALT to forget the left weapon"}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)	ic = tes3.worldController.inputController		MB = ic.mouseState.buttons 
	--tes3.findGMST("sMagicPCResisted").value = ""
end		event.register("initialized", initialized)