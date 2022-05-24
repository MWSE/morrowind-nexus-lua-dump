local cf = mwse.loadConfig("HardTrade", {m6 = false, en = true})
local p, mp		local M = {}
local L = {BartT = {bartersAlchemy = true, bartersApparatus = true, bartersArmor = true, bartersBooks = true, bartersClothing = true, bartersEnchantedItems = true, bartersIngredients = true,
bartersLights = true, bartersLockpicks = true, bartersMiscItems = true, bartersProbes = true, bartersRepairTools = true, bartersWeapons = true}}

local function BARTEROFFER(e)	local m = e.mobile	local k = 0		local C		--#e.selling	#e.buying	tile.item, tile.count		Эвент не срабатывает если игрок не изменил цену первого предложения!
if e.value > 0 then k = e.offer/e.value - 1 else k = e.value/e.offer - 1 end
if k > 0 then	local k0 = 0.2 + math.min(mp.personality.current,100)/2000		local disp = m.object.disposition or 50
	if k <= k0 then C = 50*(1.1 - k/k0) * math.min(disp, 150)/100
		* (20 + mp.mercantile.current + mp.speechcraft.current/2.5 + math.min(mp.personality.current,100)/5 + math.min(mp.luck.current,100)/5)/(m:getSkillValue(24)+50)
	else C = 0 end
	M.Bart2.text = ("  %d%%/%d  %d%%/%d%%"):format(C, disp, k*100, k0*100)
	if cf.m6 then tes3.messageBox("Chance = %d  Koef = %.1f%%  Max = %.1f%%  Gold = %d (%d - %d) Merc = %d  Disp = %d", C, k*100, k0*100, e.offer - e.value, e.offer, e.value, m:getSkillValue(24), disp) end
	e.success = math.random(100) < C		if e.success then mp:exerciseSkill(24, math.abs(e.value)/1000 + (e.offer - e.value)/30) end
end
end		event.register("barterOffer", BARTEROFFER)	

local function BarterK(m) local rang = m.object.faction and m.object.faction.playerRank + 1 or 0		return rang,
(mp.mercantile.current + mp.speechcraft.current/5 + mp.personality.current/5 + mp.luck.current/10 + rang*10 + p.object.factionIndex/2)/200,
(m:getSkillValue(24) + m:getSkillValue(25)/5 + m.personality.current/5 + m.luck.current/10 + 150 - math.min(m.object.disposition or 50, 150))/200
end

local function CALCBARTERPRICE(e)	local rang, k1, k2 = BarterK(e.mobile)		--if e.item.id == "Gold_001" then e.price = e.count		buying (игрок покупает)
	local k0 = 1 + (e.buying and 0.5 or 0.8)		local koef = math.max(k0 - k1 + k2, 1.25)		local val	local ob, ida = e.item, e.itemData
	if ob.isSoulGem and ida and ida.soul then	local soulval = ida.soul.soul	val = (soulval ^ 3) / 10000 + soulval * 2
	elseif ida and ida.condition and ob.maxCondition then val = ob.value * (0.5 + ida.condition * 0.5 / ob.maxCondition)
	else val = ob.value end
	local bp = math.max(e.buying and math.ceil(val * koef) or math.floor(val / koef), 1)			e.price = bp * e.count
	M.Bart1.text = (" %d%%"):format(koef*100 - 100)
	if cf.m6 then tes3.messageBox("%d = %d * %d   Koef = %.2f (%.2f - %.2f + %.2f)  Disp/Rang = %s/%s", e.price, bp, e.count, koef, k0, k1, k2, e.mobile.object.disposition, rang) end
end		event.register("calcBarterPrice", CALCBARTERPRICE)

local function CALCPRICE(e)	local rang, k1, k2 = BarterK(e.mobile)		local koef = math.max(1 - k1 + k2, 0.5)		e.price = e.basePrice * koef
	if cf.m6 then tes3.messageBox("Price = %d (base = %d)  Rang = %s  koef = %.2f (1 - %.2f + %.2f)", e.price, e.basePrice, rang, koef, k1, k2) end
end
event.register("calcTrainingPrice", CALCPRICE)		event.register("calcSpellPrice", CALCPRICE)		event.register("calcTravelPrice", CALCPRICE) 	event.register("calcRepairPrice", CALCPRICE)


local function MENUBARTER(e) local m = tes3ui.getServiceActor()		local ai = m.object.aiConfig	local aisave
	if mp.mercantile.base > 99 then aisave = {}		for it, _ in pairs(L.BartT) do aisave[it] = ai[it]	ai[it] = true end		timer.delayOneFrame(function() for it, _ in pairs(L.BartT) do ai[it] = aisave[it] end end) end
	
	local DI = m.reference.data		local bob = m.object.baseObject		if not DI.invest then DI.invest = {g = bob.barterGold, i = 0} end	DI = DI.invest
	local max = math.round(mp.mercantile.base/10)		local gold = math.ceil(DI.g/2)
	M.Invest = e.element:findChild("MenuBarter_yourgold").parent:createFillBar{current = DI.i, max = 10}		M.Invest.width = 150	M.Invest.height = 12	M.InvestW = M.Invest.widget		M.InvestW.fillColor = {1,0.9,0}	M.InvestW.showText = false
	M.Invest:register("help", function() tes3ui.createTooltipMenu():createLabel{text = ("%s: %d / %d  (%s %d)"):format(cf.en and "Investments" or "Инвестиции", M.InvestW.current, max,
	cf.en and "Click LMB to invest" or "Нажмите ЛКМ чтобы инвестировать", gold)} end)
	M.Invest:register("mouseClick", function() if DI.i < max and tes3.getPlayerGold() >= gold then DI.i = DI.i + 1		bob.barterGold = DI.g * math.min(1 + DI.i * 0.1, 2)		mp:exerciseSkill(24, gold/100)
		tes3.removeItem{reference = p, item = "gold_001", count = gold}		M.InvestW.current = DI.i	M.Invest:updateLayout()
		tes3.messageBox("Invested in %s   Gold = %s / %s  Investments: %s / %s", bob.id, m.barterGold, bob.barterGold, DI.i, max)
		if aisave then timer.delayOneFrame(function() bob.modified = true end) else bob.modified = true end
	end end)
	
	M.Bart = e.element:findChild("MenuBarter_Price").parent
	M.Bart1 = M.Bart:createLabel{text = " 0%"}	M.Bart1:register("help", function() tes3ui.createTooltipMenu():createLabel{text = cf.en and "Markup" or "Наценка"} end)
	M.Bart2 = M.Bart:createLabel{text = " "}	M.Bart2:register("help", function() tes3ui.createTooltipMenu():createLabel{text = cf.en and "Chance for a deal / Merchant's disposition    Profit / Max profit" or
	"Шанс на сделку / Отношение торговца   Выгода / Максимальная выгода"} end)
	M.Bart:reorderChildren(2, 3, 2)
	
--	for _, stack in pairs(m.object.baseObject.inventory) do mwse.log("base  %s - %s", stack.count, stack.object.id) end
--	for _, stack in pairs(m.object.inventory) do mwse.log("%s - %s", stack.count, stack.object.id) end
	--timer.delayOneFrame(function() m.health.current = 0		TFR(2, function() tes3.runLegacyScript{command = "resurrect", reference = m.reference} end) end, timer.real)
end		event.register("uiActivated", MENUBARTER, {filter = "MenuBarter"})

local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer	end		event.register("loaded", loaded)


local function registerModConfig()		local template = mwse.mcm.createTemplate("HardTrade")	template:saveOnClose("HardTrade", cf)	template:register()		local p0 = template:createPage()	local var = mwse.mcm.createTableVariable
p0:createYesNoButton{label = "Show messages", variable = var{id = "m6", table = cf}}
p0:createYesNoButton{label = "English language", variable = var{id = "en", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local function initialized(e)
tes3.findGMST("fEnchantmentValueMult").value = 100
tes3.findGMST("fBarterGoldResetDelay").value = 12
tes3.findGMST("fBribe10Mod").value = 20				tes3.findGMST("fBribe100Mod").value = 50				tes3.findGMST("fBribe1000Mod").value = 100
end		event.register("initialized", initialized)