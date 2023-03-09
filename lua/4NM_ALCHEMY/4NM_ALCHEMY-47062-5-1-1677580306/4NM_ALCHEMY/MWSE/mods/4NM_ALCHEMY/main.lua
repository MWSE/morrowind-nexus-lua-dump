local cf = mwse.loadConfig("4NM_ALCHEMY", {m = true, en = true, smartpoi = true, alc = true, lab = false, lim = 50, wpoi = 100, poisonkey = {keyCode = 25}, ekey = {keyCode = 56}})

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("4NM_ALCHEMY")	tpl:saveOnClose("4NM_ALCHEMY", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createYesNoButton{label = "Show messages", variable = var{id = "m", table = cf}}
p0:createYesNoButton{label = "English language", variable = var{id = "en", table = cf}}
p0:createSlider{label = cf.en and "Potion drink limit bonus. Default: 50" or "Бонус для лимита питья зелий. По умолчанию 50", min = 30, max = 100, step = 1, jump = 10, variable = var{id = "lim", table = cf}}
p0:createSlider{label = cf.en and "Bonus amount of poison for poisoning weapons. Default: 100" or "Бонусный объем яда для отравления оружия. По умолчанию 100", min = 50, max = 300, step = 1, jump = 10, variable = var{id = "wpoi", table = cf}}
p0:createYesNoButton{label = cf.en and "Enable advanced alchemy" or "Продвинутая алхимия", variable = var{id = "alc", table = cf}, restartRequired = true}
p0:createYesNoButton{label = cf.en and "Smart potion/poison discrimination mode. If the potion contains at least 1 negative effect, then this is poison" or
"Умный режим различения зелий и ядов. Работает со включенным режимом яда. Если зелье содержит хотябы 1 негативный эффект, то это яд, иначе зелье и вы его выпьете", variable = var{id = "smartpoi", table = cf}}
p0:createKeyBinder{variable = var{id = "ekey", table = cf}, label = cf.en and
[[Hold this key when: Equipping poison - to use it for throwing; Activating the apparatus - to display the alchemy menu without adding it to your inventory]] or
[[Удерживайте эту кнопку: При экипировке яда - чтобы кидать бутылки; При активации аппарата - чтобы алхимическое меню появилось без взятия этого апаарата]]}
p0:createKeyBinder{label = cf.en and "Assign a button to toggle poison mode. If poison mode enabled, you will create poisons instead of potions, and also apply them to your weapons instead of drinking" or
"Кнопка для режима яда. Когда режим яда включен, вы варите яды вместо зелий а также отравляете свое оружие ядом вместо выпивания", variable = var{id = "poisonkey", table = cf}}
p0:createYesNoButton{label = cf.en and "Replace potion icons with better ones" or "Заменить иконки зелий на информативные", variable = var{id = "lab", table = cf}, restartRequired = true}
end		event.register("modConfigReady", registerModConfig)

local p, mp, pp, D, wc, ic, MB		local mode = false		local G = {}	local B = {}		local T = {POT = timer}		local M = {}

local L = {
BotQ = {"bargain", "cheap", "standard", "quality", "exclusive"},
BotIc = {["m\\Tx_potion_bargain_01.tga"] = "bargain", ["m\\Tx_potion_cheap_01.tga"] = "cheap", ["m\\Tx_potion_fresh_01.tga"] = "cheap",
["m\\Tx_potion_standard_01.tga"] = "standard", ["m\\Tx_potion_quality_01.tga"] = "quality", ["m\\Tx_potion_exclusive_01.tga"] = "exclusive"},
BotMod = {["m\\misc_potion_bargain_01.nif"] = {"w\\4nm_bottle1.nif", "m\\Tx_potion_bargain_01.tga"}, ["m\\misc_potion_cheap_01.nif"] = {"w\\4nm_bottle2.nif", "m\\Tx_potion_cheap_01.tga"},
["m\\misc_potion_fresh_01.nif"] = {"w\\4nm_bottle2.nif", "m\\Tx_potion_fresh_01.tga"}, ["m\\misc_potion_standard_01.nif"] = {"w\\4nm_bottle3.nif", "m\\Tx_potion_standard_01.tga"},
["m\\misc_potion_quality_01.nif"] = {"w\\4nm_bottle4.nif", "m\\Tx_potion_quality_01.tga"}, ["m\\misc_potion_exclusive_01.nif"] = {"w\\4nm_bottle5.nif", "m\\Tx_potion_exclusive_01.tga"}},
nomag = {[39] = true, [45] = true, [46] = true, [69] = true, [70] = true, [72] = true, [73] = true}
}



local function EQUIP(e) if e.reference == p and e.item.weight > 0 then local o = e.item
if (o.objectType == tes3.objectType.alchemy or o.objectType == tes3.objectType.ingredient) then
	if o.objectType == tes3.objectType.alchemy and M.drop.visible then local Btab = L.BotMod[o.mesh:lower()]	if Btab then	local ispoison = true
		if cf.smartpoi then ispoison = nil		for i, ef in ipairs(o.effects) do if ef.object and ef.object.isHarmful then ispoison = true break end end end
		if ispoison then
			if ic:isKeyDown(cf.ekey.keyCode) then -- кидание бутылок
				if not G.pbotswap then G.pbotswap = true	local bot = L.pbottle
					if mp.readiedWeapon and mp.readiedWeapon.object == bot then mp:unequip{item = bot} end
					timer.delayOneFrame(function() G.pbotswap = nil
						local numdel = tes3.getItemCount{reference = p, item = bot}		if numdel > 0 then
							tes3.removeItem{reference = p, item = bot, count = numdel}		tes3.addItem{reference = p, item = D.poisonbid, count = numdel}		D.poisonbid = nil
							if cf.m then tes3.messageBox("%d %s", numdel, cf.en and "bottles unequipped" or "старых бутылок снято") end
						end
						local num = tes3.getItemCount{reference = p, item = o}	if num > 0 then		local enc = L.pench		local E = enc.effects	local pow = 3
							for i, ef in ipairs(o.effects) do E[i].id = ef.id		E[i].radius = 5		E[i].min = L.nomag[ef.id] and ef.min or ef.min/pow		E[i].max = L.nomag[ef.id] and ef.max or ef.max/pow
							E[i].duration = L.nomag[ef.id] and ef.duration/pow or ef.duration	E[i].rangeType = 1		E[i].attribute = ef.attribute		E[i].skill = ef.skill end
							bot.mesh = Btab[1]	bot.icon = Btab[2]	bot.weight = o.weight	D.poisonbid = o.id		enc.modified = true		bot.modified = true		
							tes3.removeItem{reference = p, item = o, count = num}		tes3.addItem{reference = p, item = bot, count = num}		mp:equip{item = bot}
							if cf.m then tes3.messageBox("%d %s", num, cf.en and "bootles are ready!" or "бутылок готово к броску!") end
						end
					end)
					return false
				else tes3.messageBox("Not so fast!") return false end
			else -- отравление оружия
				timer.delayOneFrame(function() if tes3.getItemCount{reference = p, item = o} > 0 then	local pow = 5
					for i, ef in ipairs(o.effects) do
						B.poi.effects[i].id = ef.id	B.poi.effects[i].min = L.nomag[ef.id] and ef.min or ef.min/pow		B.poi.effects[i].max = L.nomag[ef.id] and ef.max or ef.max/pow
						B.poi.effects[i].duration = L.nomag[ef.id] and ef.duration/pow or ef.duration		B.poi.effects[i].attribute = ef.attribute		B.poi.effects[i].skill = ef.skill
					end
					D.poison = cf.wpoi + (mp.alchemy.current + mp.agility.current)		M.WPB.widget.current = D.poison		M.WPB.visible = true
					tes3.removeItem{reference = p, item = o}
					if cf.m then tes3.messageBox("%s %d", cf.en and "Poison is ready! Charges =" or "Яд готов! объем =", D.poison) end
				end end)
				return false
			end
		end
	end end

	if D.potmcd then
		if cf.m then if cf.en then tes3.messageBox("Not so fast! I need at least %d seconds to swallow what is already in my mouth!", D.potmcd)
		else tes3.messageBox("Не так быстро! Мне надо еще хотя бы %d секунды чтобы проглотить то что уже у меня во рту!", D.potmcd) end end		return false
	elseif D.potcd and D.potcd > G.potlim then
		if cf.m then if cf.en then tes3.messageBox("Belly already bursting! I can't take o anymore... I have to wait at least %d seconds before I can swallow something else", D.potcd - G.potlim)
		else tes3.messageBox("Пузо уже по швам трещит! Больше не могу... Надо подождать хотя бы %d секунд прежде, чем я смогу заглотить что-то еще", D.potcd - G.potlim) end end	return false
	end
	D.potmcd = math.max(8 - mp.speed.current/20, 2)		D.potcd = (D.potcd or 0) + math.max(40 - mp.alchemy.current/10, 30)
	if not T.POT.timeLeft then T.POT = timer.start{duration = 1, iterations = -1, callback = function() D.potcd = D.potcd - 1	if D.potmcd then D.potmcd = D.potmcd - 1	if D.potmcd <= 0 then D.potmcd = nil end end
		if D.potmcd and D.potmcd > D.potcd - G.potlim then M.PCD.max = 5	M.PCD.current = D.potmcd else M.PCD.max = 30	M.PCD.current = D.potcd - G.potlim	if M.PCD.current <= 0 then M.PIC.visible = false end end
		if D.potcd <= 0 then D.potcd = nil	T.POT:cancel() end
	end} end
	M.PCD.max = 5	M.PCD.current = 5	M.PIC.visible = true	if cf.m then tes3.messageBox("%s %d / %d", cf.en and "Om-nom-nom! Belly filled at" or "Ням-ням! Пузо заполнилось на", D.potcd, G.potlim) end
end
end end		event.register("equip", EQUIP)



local function UNEQUIPPED(e) if e.reference == p then local it = e.item		if it.objectType == tes3.objectType.weapon then
	if it == L.pbottle and not G.pbotswap then timer.delayOneFrame(function() local num = mwscript.getItemCount{reference = p, item = it} if num > 0 then
		tes3.removeItem{reference = p, item = it, count = num}		tes3.addItem{reference = p, item = D.poisonbid, count = num}	D.poisonbid = nil
		if cf.m then tes3.messageBox("%d bottles unequipped", num) end
	end end) end
end end end		event.register("unequipped", UNEQUIPPED)


local function ITEMDROPPED(e) local r = e.reference
	if r.object == L.pbottle then local num = r.stackSize	tes3.addItem{reference = p, item = D.poisonbid, count = num}
		r:delete()	if cf.m then tes3.messageBox("%d %s", num, cf.en and "old bottles unequipped" or "старых бутылок снято") end
	end
end		event.register("itemDropped", ITEMDROPPED)



local function damage(e) if e.source == "attack" and e.attacker == mp and D.poison then		local pr = e.projectile
if pr or mp.readiedWeapon then	local t = e.mobile
	if not pr then D.poison = D.poison - math.max(100 - mp.agility.current/2,50)	M.WPB.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	M.WPB.visible = false end end
	local chance = 50 + (mp.agility.current/2 + mp.luck.current/4)*2 - t.agility.current/2 - t.luck.current/4 - math.max(t.resistPoison,0)/2 - t.armorRating/2
	if chance > math.random(100) then tes3.applyMagicSource{reference = e.reference, source = B.poi}		if cf.m then tes3.messageBox("Poisoned! Chance = %d%%  Poison charges = %s", chance, D.poison or 0) end
	elseif cf.m then tes3.messageBox("Poison failure! Chance = %d%%  Poison charges = %s", chance, D.poison or 0) end 
end
end end		event.register("damage", damage)


local function PROJECTILEEXPIRE(e) if e.firingReference == p and not e.mobile.spellInstance and D.poison then
	D.poison = D.poison - math.max(100 - mp.agility.current/2,50)		M.WPB.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	M.WPB.visible = false end
end end		event.register("projectileExpire", PROJECTILEEXPIRE)




local function ACTIVATE(e) if e.activator == p then
if e.target.object.objectType == tes3.objectType.apparatus and ic:isKeyDown(cf.ekey.keyCode) then	local app = {}
	for r in p.cell:iterateReferences(tes3.objectType.apparatus) do
		if (not app[r.object.type] or app[r.object.type].quality < r.object.quality) and tes3.hasOwnershipAccess{target = r} and pp:distance(r.position) < 800 then app[r.object.type] = r.object end
	end
	for i, ob in pairs(app) do tes3.addItem{reference = p, item = ob, playSound = false} end
	timer.delayOneFrame(function() local appar = app[0] or app[1] or app[2] or app[3]	if appar then
		mp:equip{item = appar}	timer.delayOneFrame(function() for i, ob in pairs(app) do tes3.removeItem{reference = p, item = ob, playSound = false} end end)
	end end)
	return false
end
end end		event.register("activate", ACTIVATE)



L.ALE = {[75]={5,20}, [76]={5,30}, [77]={10,60}, [74]={5,10}, [79]={20,60}, [83]={20,60}, [80]={20,60}, [81]={100,60}, [82]={100,120}, [84]={10,60}, [117]={30,60}, [42]={30,60}, [72]={1,1}, [73]={1,1}, [69]={1,1}, [70]={1,1},
[90]={30,60}, [91]={30,60}, [92]={30,60}, [93]={30,60}, [97]={30,60}, [98]={30,60}, [99]={30,60}, [94]={50,120}, [95]={50,120}, [96]={30,60},
[10]={10,30}, [8]={100,120}, [3]={30,60}, [4]={10,30}, [5]={10,30}, [6]={10,30}, [1]={30,60}, [2]={1,30}, [0]={1,60}, [9]={20,30}, [11]={20,60},
[41]={30,120}, [43]={30,120}, [39]={1,30}, [40]={30,60}, [57]={100,1}, [67]={10,60}, [68]={10,60}, [59]={30,60}, [64]={200,120}, [65]={200,120}, [66]={200,120},
[27]={5,20}, [23]={5,20}, [14]={5,20}, [15]={5,20}, [16]={5,20}, [24]={10,30}, [25]={10,30}, [22]={3,15}, [18]={50,60}, [19]={100,60}, [20]={100,60}, [17]={30,60}, [21]={30,60},
[28]={30,60}, [29]={30,60}, [30]={30,60}, [31]={30,60}, [34]={30,60}, [35]={30,60}, [36]={30,60}, [32]={50,120}, [33]={50,120}, [7]={100,60}, [45]={1,5}, [46]={1,10}, [47]={50,60}, [48]={50,60}}

local function MENUALCHEMY(e)	M.Alc = e.element
	M.AlcCH = e.element:createLabel{text = "Chance ?%%"}
	M.AlcCH.absolutePosAlignY = -0.1	M.AlcCH.positionY = -247 		e.element:updateLayout()
	if mp.alchemy.current < 100 then M.Alc:findChild(-25):registerBefore("mouseClick", function() tes3.messageBox("%s", cf.en and "You are not yet skilled enough to brew 4-ingredient potions" or
	"Вы еще недостаточно искусны чтобы варить зелья из 4 ингредиентов")		return false end) end
end		if cf.alc then event.register("uiActivated", MENUALCHEMY, {filter = "MenuAlchemy"}) end

local function POTIONBREWSKILLCHECK(e)	local Al, Int, Luc, Agi, Mort, Cal, Ret, Alem = mp.alchemy.base, mp.intelligence.base, mp.luck.base, mp.agility.base, math.min(e.mortar.quality,2),
	e.calcinator, e.retort, e.alembic			Cal, Ret, Alem = (Cal and math.min(Cal.quality or 0,2) or 0), (Ret and math.min(Ret.quality or 0,2) or 0), (Alem and math.min(Alem.quality or 0,2) or 0)
	local pow0 = Al/2 + Int/10 + Mort*20 + Luc/10	local pow = math.min(pow0,100)
	local Chance = Al + Mort*20 + Int/5 + Agi/5 + Luc*0.3 + math.max(pow0-100,0) - (Ret + Cal + Alem) * 10
	local Mag = 60 + (Ret + Cal) * 10
	local Dur = 60 + (Alem + Cal) * 10
	if math.random(100) <= Chance then e.potionStrength = pow	e.success = true
	else e.potionStrength = -1	e.success = false end
	
	G.PotM = Mag * pow/10000	G.PotD = Dur * pow/10000
	M.AlcCH.text = ("Chance %d%%  Power %d%%/%d%%/%d%%"):format(Chance, pow, Mag, Dur)		M.Alc:updateLayout()
end		if cf.alc then event.register("potionBrewSkillCheck", POTIONBREWSKILLCHECK) end

local function POTIONBREWED(e)	local ob = e.object		local Alem = e.alembic		Alem = Alem and math.min(Alem.quality or 0,2) or 0
--if cf.lab then local q = L.BotIc[ob.icon]	if q then ob.icon = ("potions\\%s_%s.dds"):format(q, ob.effects[1].id)		ob.mesh = ("m\\misc_potion_%s_01.nif"):format(q) end end
local cost = 0	for _, i in ipairs(e.ingredients) do if i then cost = cost + i.value end end	mp:exerciseSkill(16, cost/50)
if cf.alc then	local E = {}	local norm = not M.drop.visible		local gold = 40
	for i, ef in ipairs(ob.effects) do E[i] = ef	if ef.id ~= -1 then local AE = L.ALE[ef.id]		local harm = norm == ef.object.isHarmful		gold = gold + (harm and -20 or 20)
	if AE then E[i].min = math.max(G.PotM * AE[1]/(harm and (1 + Alem*2) or 1), 1)		E[i].max = E[i].min		E[i].duration = math.max(G.PotD * AE[2]/(harm and (1 + Alem) or 1), 1) end end end
	tes3.removeItem{reference = p, item = ob, playSound = false}
	tes3.addItem{reference = p, item = tes3alchemy.create({name = ob.name, mesh = ob.mesh, icon = ob.icon, weight = mp.alchemy.current >= 75 and 0.3 or 0.5, value = G.PotM * G.PotD * math.max(gold,10), effects = E}), playSound = false}
end		--	tes3.messageBox("id = %s  name = %s   cost = %d", ob.id, ob.name, cost)
end		event.register("potionBrewed", POTIONBREWED)



local function keyDown(e) if mode then mode = false 	M.drop.visible = false	tes3.messageBox("Poison Mode disabled") else mode = true	M.drop.visible = true	tes3.messageBox("Poison Mode enabled") end end
event.register("keyDown", keyDown, {filter = cf.poisonkey.keyCode})


local function ITEMTILEUPDATED(e)	local ob = e.item
	if ob.objectType == tes3.objectType.alchemy then	local eob = ob.effects[1].object	if eob then
		local Eic = e.element:createImage{path = ("icons\\%s"):format(eob.icon)}		--("icons\\s\\b_%s.tga"):format(icon)	Eic.width = 16		Eic.height = 16		Eic.scaleMode = true
		Eic.absolutePosAlignX = 1.0		Eic.absolutePosAlignY = 0.2		Eic.consumeMouseEvents = false
	end
end end		if cf.lab then event.register("itemTileUpdated", ITEMTILEUPDATED) end


local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		pp = p.position		D = tes3.player.data		local MU = tes3ui.findMenu(-526)
G.potlim = cf.lim + mp.endurance.base * 0.5
B.poi = tes3.getObject("4b_poison") or tes3alchemy.create{id = "4b_poison", name = "4b_poison", weight = 0.1, icon = "s\\b_tx_s_sun_dmg.dds"}	--B.poi.sourceless = true
L.pench = tes3.createObject{objectType = tes3.objectType.enchantment, id = "4nm_e_poisonbottle", castType = 1, chargeCost = 1, maxCharge = 1}
L.pbottle = tes3.createObject{objectType = tes3.objectType.weapon, id = "4nm_poisonbottle", name = "Bottle", type = 11, mesh = "w\\4nm_bottle1.nif", icon = "m\\Tx_potion_bargain_01.tga",
weight = 0, value = 0, maxCondition = 10, enchantCapacity = 10, reach = 1, speed = 1, chopMin = 0, chopMax = 3, slashMin = 0, slashMax = 1, thrustMin = 0, thrustMax = 1, enchantment = L.pench}

M.PIC = MU:findChild(-539).parent:createBlock{}		M.PIC.visible = false	M.PIC.autoHeight = true		M.PIC.autoWidth = true	M.PIC.borderAllSides = 2	M.PIC.flowDirection = "top_to_bottom"
local PICb = M.PIC:createThinBorder{}	PICb.height = 36	PICb.width = 36		local Picon = PICb:createImage{path = "icons/potions_blocked.tga"}	Picon.borderAllSides = 2
local potbar = M.PIC:createFillBar{current = 30, max = 30}	potbar.width = 36		potbar.height = 7		M.PCD = potbar.widget	M.PCD.showText = false		M.PCD.fillColor = {0,1,1}
if D.potcd then M.PIC.visible = true	T.POT = timer.start{duration = 1, iterations = -1, callback = function() D.potcd = D.potcd - 1	if D.potmcd then D.potmcd = D.potmcd - 1	if D.potmcd <= 0 then D.potmcd = nil end end
	if D.potmcd and D.potmcd > D.potcd - G.potlim then M.PCD.max = 5	M.PCD.current = D.potmcd else M.PCD.max = 30	M.PCD.current = D.potcd - G.potlim	if M.PCD.current <= 0 then M.PIC.visible = false end end
	if D.potcd <= 0 then D.potcd = nil	T.POT:cancel() end
end} end
M.drop = MU:findChild(-539).parent:createImage{path = "icons/poisondrop.tga"}	M.drop.visible = mode
M.WPB = MU:findChild(-547):createFillBar{current = D.poison or 0, max = 300}	M.WPB.width = 36	M.WPB.height = 7	M.WPB.widget.showText = false	M.WPB.widget.fillColor = {0,1,0}	M.WPB.visible = not not D.poison
end		event.register("loaded", loaded, {priority = -10})


local function initialized(e)	wc = tes3.worldController	ic = wc.inputController		MB = ic.mouseState.buttons
--if cf.lab then for pot in tes3.iterateObjects(tes3.objectType.alchemy) do if not pot.icon:lower():find("^potions\\") then
--	o = L.BotIc[pot.icon]		if o then pot.icon = ("potions\\%s_%s.dds"):format(o, pot.effects[1].id) end
--	for _, q in pairs(L.BotQ) do if pot.icon:lower():find(q) then pot.icon = ("potions\\%s_%s.dds"):format(q, pot.effects[1].id)	break end end
--end end end
end		event.register("initialized", initialized)