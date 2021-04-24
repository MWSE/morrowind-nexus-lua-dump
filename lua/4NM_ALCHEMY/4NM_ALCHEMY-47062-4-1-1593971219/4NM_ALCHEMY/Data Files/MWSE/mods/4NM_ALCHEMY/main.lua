local cfg = mwse.loadConfig("4NM_ALCHEMY!") or {msg = true, eng = true, smart = true, lab = true, poisonkey = {keyCode = 25}, expkey = {keyCode = 56}}
local p, mp, D, L, P, B, E, BM, FR, PB, PBAR, drop, msg, eng	local TIM = timer	local mode = false	local CD = 0
local qualities = {"exclusive", "quality", "fresh", "standard", "cheap", "bargain"}		local nomag = {[39] = true, [45] = true, [46] = true, [69] = true, [70] = true, [72] = true, [73] = true}
local M = {["m\\misc_potion_bargain_01.nif"] = "w\\4nm_bottle1.nif", ["m\\misc_potion_cheap_01.nif"] = "w\\4nm_bottle2.nif", ["m\\misc_potion_fresh_01.nif"] = "w\\4nm_bottle3.nif",
["m\\misc_potion_standard_01.nif"] = "w\\4nm_bottle4.nif", ["m\\misc_potion_quality_01.nif"] = "w\\4nm_bottle5.nif", ["m\\misc_potion_exclusive_01.nif"] = "w\\4nm_bottle6.nif"}

local function onEquip(e) if e.reference == p and (e.item.objectType == tes3.objectType.alchemy or e.item.objectType == tes3.objectType.ingredient) and e.item.weight > 0 then
if e.item.objectType == tes3.objectType.alchemy and mode and M[e.item.mesh:lower()] then	local ispoison = true
	if cfg.smart then ispoison = nil		for i, eff in ipairs(e.item.effects) do if eff.object and eff.object.isHarmful then ispoison = true break end end end
	if ispoison then
		if tes3.worldController.inputController:isKeyDown(cfg.expkey.keyCode) then -- кидание бутылок
			if CD == 0 then CD = 1
				if mp.readiedWeapon and mp.readiedWeapon.object == B then mp:unequip{item = B} end
				timer.delayOneFrame(function() CD = 0
					local numdel = mwscript.getItemCount{reference = p, item = B}		if numdel > 0 then
						tes3.removeItem{reference = p, item = B, count = numdel}		tes3.addItem{reference = p, item = D.poisonbid, count = numdel}
						D.poisonbid = nil	if msg then if eng then tes3.messageBox("%d bottles extra unequipped", numdel) else tes3.messageBox("%d старых бутылок снято", numdel) end end
					end
					local num = mwscript.getItemCount{reference = p, item = e.item}	if num > 0 then
						for i, eff in ipairs(e.item.effects) do
							E.effects[i].id = eff.id	E.effects[i].radius = 5		E.effects[i].min = nomag[eff.id] and eff.min or eff.min/3		E.effects[i].max = nomag[eff.id] and eff.max or eff.max/3
							E.effects[i].duration = nomag[eff.id] and eff.duration/3 or eff.duration	E.effects[i].rangeType = 1		E.effects[i].attribute = eff.attribute		E.effects[i].skill = eff.skill
						end
						B.weight = e.item.weight	BM:detachChildAt(1)	BM:attachChild(tes3.loadMesh(M[e.item.mesh:lower()] or "w\\4nm_bottle1.nif"):clone(), true)
						D.poisonbid = e.item.id		tes3.removeItem{reference = p, item = e.item, count = num}		tes3.addItem{reference = p, item = B, count = num}
						mwscript.equip{reference = p, item = B}
						if msg then if eng then tes3.messageBox("%d bootles are ready!", num) else tes3.messageBox("%d бутылок готово к броску!", num) end end
					end
				end)
				return false
			else tes3.messageBox("Not so fast!") return false end
		else -- отравление оружия
			timer.delayOneFrame(function() if mwscript.getItemCount{reference = p, item = e.item} > 0 then
				for i, eff in ipairs(e.item.effects) do
					P.effects[i].id = eff.id	P.effects[i].min = nomag[eff.id] and eff.min or eff.min/5		P.effects[i].max = nomag[eff.id] and eff.max or eff.max/5
					P.effects[i].duration = nomag[eff.id] and eff.duration/5 or eff.duration		P.effects[i].attribute = eff.attribute		P.effects[i].skill = eff.skill
				end
				D.poison = 100 + mp.alchemy.current + mp.agility.current	PBAR.widget.current = D.poison		PBAR.visible = true
				tes3.removeItem{reference = p, item = e.item}
				if msg then if eng then tes3.messageBox("Poison is ready! Charges = %d", D.poison) else tes3.messageBox("Яд готов! объем = %d", D.poison) end end
			end end)
			return false
		end
	end
end

if D.potmcd then
	if msg then if eng then tes3.messageBox("Not so fast! I need at least %d seconds to swallow what is already in my mouth!", D.potmcd)
	else tes3.messageBox("Не так быстро! Мне надо еще хотя бы %d секунды чтобы проглотить то что уже у меня во рту!", D.potmcd) end end		return false
elseif D.potcd and D.potcd > L then
	if msg then if eng then tes3.messageBox("Belly already bursting! I can't take it anymore... I have to wait at least %d seconds before I can swallow something else", D.potcd - L)
	else tes3.messageBox("Пузо уже по швам трещит! Больше не могу... Надо подождать хотя бы %d секунд прежде, чем я смогу заглотить что-то еще", D.potcd - L) end end		return false
end
L = 50 + math.min(mp.endurance.current,100)/2		D.potmcd = 10 - math.min(mp.speed.current,100)/20		D.potcd = (D.potcd or 0) + 50 - mp.alchemy.current/10
if not TIM.timeLeft then TIM = timer.start{duration = 1, iterations = -1, callback = function() D.potcd = D.potcd - 1	if D.potmcd then D.potmcd = D.potmcd - 1	if D.potmcd <= 0 then D.potmcd = nil end end
	if D.potmcd and D.potmcd > D.potcd - L then PB.max = 5	PB.current = D.potmcd else PB.max = 30	PB.current = D.potcd - L	if PB.current <= 0 then FR.visible = false end end
	if D.potcd <= 0 then D.potcd = nil	TIM:cancel() end
end} end
PB.max = 5	PB.current = 5	FR.visible = true	if msg then if eng then tes3.messageBox("Om-nom-nom! Belly filled at %d / %d", D.potcd, L) else tes3.messageBox("Ням-ням! Пузо заполнилось на %d / %d", D.potcd, L) end end
end end


local function onUnequipped(e)
	if e.reference == p and e.item == B and CD == 0 then timer.delayOneFrame(function() local num = mwscript.getItemCount{reference = p, item = e.item} if num > 0 then
		tes3.removeItem{reference = p, item = e.item, count = num}
		tes3.addItem{reference = p, item = D.poisonbid, count = num}
		D.poisonbid = nil
		if msg then if eng then tes3.messageBox("%d bottles unequipped", num) else tes3.messageBox("%d бутылок снято", num) end end
	end end) end
end


local function onItemDropped(e) if e.reference.object == B then local num = e.reference.stackSize
	tes3.addItem{reference = p, item = D.poisonbid, count = num}
	e.reference:disable()	mwscript.setDelete{reference = e.reference}		if msg then if eng then tes3.messageBox("%d bottles unequipped", num) else tes3.messageBox("%d бутылок снято", num) end end
end end


local Curint, Curluck, Curalch, Flag, EF
local function onUiActivated(e)
	if mp.intelligence.current > mp.intelligence.base then Curint = mp.intelligence.current		mp.intelligence.current = mp.intelligence.base end
	if mp.luck.current > mp.luck.base then Curluck = mp.luck.current		mp.luck.current = mp.luck.base end
	if mp.alchemy.current > mp.alchemy.base then Curalch = mp.alchemy.current		mp.alchemy.current = mp.alchemy.base end
	if mode then EF = tes3.getDataHandler().nonDynamicData.magicEffects		for i=1, #EF do EF[i].isHarmful = not EF[i].isHarmful end	Flag = true end
	timer.delayOneFrame(function() if Curint then mp.intelligence.current = Curint	Curint = nil end	if Curluck then mp.luck.current = Curluck	Curluck = nil end
		if Curalch then mp.alchemy.current = Curalch		Curalch = nil end	if Flag then for i=1, #EF do EF[i].isHarmful = not EF[i].isHarmful end	Flag = nil end
	end)
end


local function onDamage(e) if e.source == "attack" and e.attackerReference == p and D.poison and e.attacker.readiedWeapon then
	if e.attacker.readiedWeapon.object.type < 9 then D.poison = D.poison - 100 + math.min(mp.agility.current, 100)/2		PBAR.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	PBAR.visible = false end end
	local chance = 50 + e.attacker.agility.current + e.attacker.luck.current/2 - e.mobile.agility.current - e.mobile.luck.current/2 - e.mobile.resistPoison/2
	if chance > math.random(100) then mwscript.equip{reference = e.reference, item = P}		if msg then tes3.messageBox("Poisoned! Chance = %.1f  Poison charges = %s", chance, (D.poison or 0)) end
	elseif msg then tes3.messageBox("Failure! Chance = %.1f  Poison charges = %s", chance, (D.poison or 0)) end 
end end

local function onProjectileExpire(e) if e.firingReference == p and e.mobile.objectType == 0 and D.poison then
	D.poison = D.poison - 100 + math.min(mp.agility.current, 100)/2		PBAR.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	PBAR.visible = false end
end end


local function onActivate(e) if e.activator == p and e.target.object.objectType == tes3.objectType.apparatus and tes3.worldController.inputController:isKeyDown(cfg.expkey.keyCode) then	local app = {}
	for r in p.cell:iterateReferences(tes3.objectType.apparatus) do
		if (not app[r.object.type] or app[r.object.type].quality < r.object.quality) and tes3.hasOwnershipAccess{target = r} and p.position:distance(r.position) < 800 then app[r.object.type] = r.object end
	end
	for i, ob in pairs(app) do tes3.addItem{reference = p, item = ob, playSound = false} end
	timer.delayOneFrame(function() local appar = app[0] or app[1] or app[2] or app[3]	if appar then
		mwscript.equip{reference = p, item = appar}		timer.delayOneFrame(function() for i, ob in pairs(app) do tes3.removeItem{reference = p, item = ob, playSound = false} end end)
	end end)
	return false
end end


local function onPotionBrewed(e) for _, q in pairs(qualities) do if e.object.icon:lower():find(q) then e.object.icon = "potions\\" .. q .. "_" .. e.object.effects[1].id .. ".dds"	break end end end

local function onKey(e) if mode then mode = false 	drop.visible = false	tes3.messageBox("Poison Mode disabled") else mode = true	drop.visible = true	tes3.messageBox("Poison Mode enabled") end end

local function onSave(e) if mwscript.getItemCount{reference = p, item = B} > 0 then tes3.messageBox("You cannot save the game with throwing bottles!") return false end end

local function onLoaded(e)	p = tes3.player		mp = tes3.mobilePlayer	D = tes3.player.data	msg = cfg.msg	eng = cfg.eng	L = 50 + math.min(mp.endurance.current,100)/2
P = tes3.getObject("4b_poison") or tes3alchemy.create{id = "4b_poison", name = "4b_poison", weight = 0.1, icon = "s\\b_tx_s_sun_dmg.dds"}
FR = tes3ui.findMenu(-526):findChild(-539).parent:createThinBorder{}	FR.visible = false	FR.autoHeight = true	FR.autoWidth = true		FR.paddingAllSides = 2	FR.borderAllSides = 2	FR.flowDirection = "top_to_bottom"
FR:createImage{path = "icons/potions_blocked.tga"}	local Pbar = FR:createFillBar{current = 30, max = 30}	Pbar.width = 32		Pbar.height = 6		PB = Pbar.widget	PB.showText = false		PB.fillColor = {0,255,255}

drop = tes3ui.findMenu(-526):findChild(-539).parent:createImage{path = "icons/poisondrop.tga"}	drop.visible = mode
PBAR = tes3ui.findMenu(-526):findChild(-547):createFillBar{current = D.poison or 0, max = 300}	PBAR.width = 36		PBAR.height = 7		PBAR.widget.showText = false	PBAR.widget.fillColor = {0,255,0}	PBAR.visible = not not D.poison

if D.potcd then FR.visible = true	TIM = timer.start{duration = 1, iterations = -1, callback = function() D.potcd = D.potcd - 1	if D.potmcd then D.potmcd = D.potmcd - 1	if D.potmcd <= 0 then D.potmcd = nil end end
	if D.potmcd and D.potmcd > D.potcd - L then PB.max = 5	PB.current = D.potmcd else PB.max = 30	PB.current = D.potcd - L	if PB.current <= 0 then FR.visible = false end end
	if D.potcd <= 0 then D.potcd = nil	TIM:cancel() end
end} end
end

local function registerModConfig()	local template = mwse.mcm.createTemplate("4NM_ALCHEMY!")	template:saveOnClose("4NM_ALCHEMY!", cfg)	template:register()		local page = template:createPage()
page:createYesNoButton{label = "Show messages", variable = mwse.mcm.createTableVariable{id = "msg", table = cfg}}
page:createYesNoButton{label = "English language", variable = mwse.mcm.createTableVariable{id = "eng", table = cfg}}
page:createYesNoButton{label = "Smart potion/poison discrimination mode. If the potion contains at least 1 negative effect, then this is poison.", variable = mwse.mcm.createTableVariable{id = "smart", table = cfg}}
page:createKeyBinder{label = "Assign a button to toggle poison mode (requires game restart). If poison mode enabled, you will create poisons instead of potions, and also apply them to your weapons instead of drinking", 
allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "poisonkey", table = cfg}}
page:createKeyBinder{label = "Hold this button while activating the apparatus to display the alchemy menu without adding it to your inventory. Hold this button while equipping the poison to use it for throwing",
allowCombinations = false, variable = mwse.mcm:createTableVariable{id = "expkey", table = cfg}}
page:createYesNoButton{label = "Replace potion icons with better ones. Requires game restart", variable = mwse.mcm.createTableVariable{id = "lab", table = cfg}}
end		event.register("modConfigReady", registerModConfig)


local function initialized(e)
	event.register("equip", onEquip)
	event.register("unequipped", onUnequipped)
	event.register("itemDropped", onItemDropped)
	event.register("activate", onActivate)
	event.register("projectileExpire", onProjectileExpire)
	event.register("damage", onDamage)
	event.register("loaded", onLoaded, {priority = -10})
	event.register("uiActivated", onUiActivated, {filter = "MenuAlchemy"})
	event.register("keyDown", onKey, {filter = cfg.poisonkey.keyCode})
	event.register("save", onSave)
	B = tes3.getObject("4nm_poisonbottle")	E = tes3.getObject("4nm_e_poisonbottle")
	BM = tes3.loadMesh("w\\4nm_bottle.nif")
	if cfg.lab then event.register("potionBrewed", onPotionBrewed)	for potion in tes3.iterateObjects(tes3.objectType.alchemy) do if not potion.icon:lower():find("^potions\\") then
		for _, q in pairs(qualities) do if potion.icon:lower():find(q) then potion.icon = "potions\\" .. q .. "_" .. potion.effects[1].id .. ".dds"	break end end
	end end end
end		event.register("initialized", initialized)