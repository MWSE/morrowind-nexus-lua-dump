local cf = mwse.loadConfig("4NM_MENU", {spmak = true, alc = true, spellbook = false, lin = 15})
local L = {ATR = {[0] = "strength", [1] = "intelligence", [2] = "willpower", [3] = "agility", [4] = "speed", [5] = "endurance", [6] = "personality", [7] = "luck"},
ATRIC = {[0] = "icons/k/attribute_strength.dds", [1] = "icons/k/attribute_int.dds", [2] = "icons/k/attribute_wilpower.dds", [3] = "icons/k/attribute_agility.dds", [4] = "icons/k/attribute_speed.dds",
[5] = "icons/k/attribute_endurance.dds", [6] = "icons/k/attribute_personality.dds", [7] = "icons/k/attribute_luck.dds"},
ALF={[1]={75,76,77,74,79,80,81,82,72,73,69,70,90,91,92,93,97,99,94}, [2]={10,8,4,5,6,0,1,2,43,39,41,57,67,68,59,64,65,66}, [3]={27,23,24,25,22,18,19,20,17,7,45,47}, [4]={}},
ALFEF = {[17]=0, [22]=0, [74]=0, [79]=0, [85]=0}}
local M = {}

local function MENUENCHANTMENT(e)	e.element.minWidth = 1200	e.element.minHeight = 800		local vol = 15	local EL = e.element:findChild(-1155)	local lin = math.ceil(#EL.children/vol)
local M0 = e.element:findChild(-1260)		M0.width = 32*(vol+1)
EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
s:createImage{path = "icons/s/b_" .. s:getPropertyObject("MenuEnchantment_Effect").icon:sub(3)}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end

local function MENUSPELLMAKING(e)	e.element.minWidth = 1200	e.element.minHeight = 800		local vol = 15	local EL = e.element:findChild(-1155)	local lin = math.ceil(#EL.children/vol)
local M0 = e.element:findChild(-827).parent		M0.width = 32*(vol+1)
EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
s:createImage{path = "icons/s/b_" .. s:getPropertyObject("MenuSpellmaking_Effect").icon:sub(3)}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end

local function MENUALCHEMY(e)
	local RFI = e.element:findChild(-1111):findChild(-32588):createImage{path = "icons/potions_blocked.tga"}
	RFI:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = "Reset alchemy filter"} end)
	RFI:register("mouseClick", function() M.Alf = nil	M.AlfAt = nil	tes3.messageBox("Alchemy filter reset") end)
	e.element:updateLayout()
end

local function MENUINVENTORYSELECT(e) e.element.height = 1000	e.element.width = 800	if e.element:findChild(-344).text == tes3.findGMST("sIngredients").value then	local EL = {{},{},{},{}}
	for l, tab in ipairs(L.ALF) do EL[l].b = e.element:createThinBorder{}	EL[l].b.autoHeight = true	EL[l].b.autoWidth = true	for i, ef in ipairs(tab) do
		EL[l][i] = EL[l].b:createImage{path = "icons/s/b_" .. tes3.getMagicEffect(ef).icon:sub(3)}		EL[l][i]:register("mouseClick", function() M.Alf = ef	tes3ui.updateInventorySelectTiles() end)
	end end
	for i = 0, 7 do EL[4][i] = EL[4].b:createImage{path = L.ATRIC[i]}		EL[4][i]:register("mouseClick", function() M.AlfAt = i	tes3ui.updateInventorySelectTiles() end)
	EL[4][i]:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = L.ATR[i]} end) end
	EL[4][8] = EL[4].b:createImage{path = "icons/k/magic_alchemy.dds"}		EL[4][8]:register("mouseClick", function() M.AlfAt = nil	tes3ui.updateInventorySelectTiles() end)
	EL[4][8]:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = "All Attributes"} end)
	EL[4][9] = EL[4].b:createImage{path = "icons/potions_blocked.tga"}		EL[4][9]:register("mouseClick", function() M.Alf = nil	M.AlfAt = nil	tes3ui.updateInventorySelectTiles() end)
	EL[4][9]:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt:createLabel{text = "Reset alchemy filter"} end)
elseif M.Alf then M.Alf = nil	tes3ui.updateInventorySelectTiles() end end

local function FILTERINVENTORYSELECT(e) if M.Alf and e.item.objectType == tes3.objectType.ingredient then local filt = false	for i, ef in ipairs(e.item.effects) do if ef == M.Alf then
	if L.ALFEF[ef] and M.AlfAt then if e.item.effectAttributeIds[i] == M.AlfAt then filt = true	break end else filt = true	break end
end end		e.filter = filt end end


local function LOADED(e)
local MM = tes3ui.findMenu(-434)	local PL = MM:findChild(-441)	PL.flowDirection = "left_to_right"		local SL = MM:findChild(-444)	local ML = math.ceil(#SL.children/cf.lin)
MM:findChild(-1155).children[1].visible = false		MM:findChild(-1155).children[4].visible = false		MM:findChild(-442).visible = false		MM:findChild(-445).visible = false		MM:findChild(-446).visible = false
for i, s in ipairs(PL.children) do s:createImage{path = "icons/s/b_" .. s:getPropertyObject("MagicMenu_Spell").effects[1].object.icon:sub(3)}	s.minHeight = 32	s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil end
SL.minWidth = 32*(cf.lin+1)		SL.maxWidth = SL.minWidth	SL.minHeight = 32*(ML+1)	SL.maxHeight = SL.minHeight		SL.autoHeight = true	SL.autoWidth = true
for i, s in ipairs(SL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil	s:createImage{path = "icons/s/b_" .. s:getPropertyObject("MagicMenu_Spell").effects[1].object.icon:sub(3)}	
s.absolutePosAlignX = 1/cf.lin * ((i%cf.lin > 0 and i%cf.lin or cf.lin)-1)		s.absolutePosAlignY = 1/ML * (math.ceil(i/cf.lin)-1) end
end


local function registerModConfig()	local template = mwse.mcm.createTemplate("4NM_MENU")	template:saveOnClose("4NM_MENU", cf)	template:register()	local var = mwse.mcm.createTableVariable	local p = template:createPage()
p:createYesNoButton{label = "Spellmaking and enchanting menu", variable = var{id = "spmak", table = cf}}
p:createYesNoButton{label = "Alchemy filter", variable = var{id = "alc", table = cf}}
p:createYesNoButton{label = "Spellbook", variable = var{id = "spellbook", table = cf}}
p:createSlider{label = "Set number of icons on 1 line in Spellbook", min = 10, max = 50, step = 1, jump = 5, variable = var{id = "lin", table = cf}}
end		event.register("modConfigReady", registerModConfig)

if cf.spellbook then event.register("loaded", LOADED) end
if cf.spmak then event.register("uiActivated", MENUSPELLMAKING, {filter = "MenuSpellmaking"})	event.register("uiActivated", MENUENCHANTMENT, {filter = "MenuEnchantment"}) end
if cf.alc then event.register("uiActivated", MENUINVENTORYSELECT, {filter = "MenuInventorySelect"}) event.register("uiActivated", MENUALCHEMY, {filter = "MenuAlchemy"})	event.register("filterInventorySelect", FILTERINVENTORYSELECT) end