local cf = mwse.loadConfig("4NM_MENU", {UIen = true, UIsp = true, UIcol = 0, spmak = true, alc = true, lin = 15, q0 = {keyCode = 156}})
local L = {ATR = {[0] = "strength", [1] = "intelligence", [2] = "willpower", [3] = "agility", [4] = "speed", [5] = "endurance", [6] = "personality", [7] = "luck"},
ATRIC = {[0] = "icons/k/attribute_strength.dds", [1] = "icons/k/attribute_int.dds", [2] = "icons/k/attribute_wilpower.dds", [3] = "icons/k/attribute_agility.dds", [4] = "icons/k/attribute_speed.dds",
[5] = "icons/k/attribute_endurance.dds", [6] = "icons/k/attribute_personality.dds", [7] = "icons/k/attribute_luck.dds"},
ALF={[1]={75,76,77,74,79,80,81,82,72,73,69,70,90,91,92,93,97,99,94}, [2]={10,8,4,5,6,0,1,2,43,39,41,57,67,68,59,64,65,66}, [3]={27,23,24,25,22,18,19,20,17,7,45,47}, [4]={}},
ALFEF = {[17]=0, [22]=0, [74]=0, [79]=0, [85]=0},
UItcolor = {{0,0,0},{0,0,1},{0,1,0},{0,1,1},{1,0,0},{1,0,1},{1,1,0},{1,1,1}}}
local M = {}	local D

--local function iconp(ic) local pat = "icons\\" .. ic:gsub([[\]],"/b_",1)	return tes3.getFileExists(pat) and pat or "icons/k/magicka.dds" end -- "icons/s/b_" .. ic:sub(3)

L.UpdateSpellM = function()	local ob, ic, mc	local ls = cf.lin	local F = {}	local S = {}
local MM = tes3ui.findMenu("MenuMagic")	local PL = MM:findChild("MagicMenu_power_names")	PL.borderBottom = 5		PL.flowDirection = "left_to_right"		local SL = MM:findChild("MagicMenu_spell_names")
local MC = MM:findChild("PartScrollPane_pane").children		MC[1].visible = false	MC[3].visible = false	MC[4].visible = false	MC[6].visible = false	MC[7].visible = false
MM:findChild("MagicMenu_power_costs").visible = false		MM:findChild("MagicMenu_spell_costs").visible = false		MM:findChild("MagicMenu_spell_percents").visible = false
MM:findChild("MagicMenu_icons_list_inner").flowDirection = "left_to_right"
for i, s in ipairs(PL.children) do s:createImage{path = "icons\\" .. s:getPropertyObject("MagicMenu_Spell").effects[1].object.bigIcon}	s.minHeight = 32	s.minWidth = 32		s.text = nil end
for i, s in ipairs(SL.children) do s.minHeight = 32		s.minWidth = 32		s.text = nil	ob = s:getPropertyObject("MagicMenu_Spell")		ic = s:createImage{path = "icons\\" .. ob.effects[1].object.bigIcon}
if cf.UIcol ~= 0 then mc = ic:createLabel{text = ("%s"):format(ob.magickaCost)}	mc.color = L.UItcolor[cf.UIcol]		mc.font = 1 end		table.insert(D.FS[ob.id] and F or S, s) end
if SL.children[1] then SL.children[1]:register("destroy", function(e) timer.delayOneFrame(L.UpdateSpellM, timer.real) end) end
local Flin = math.ceil(#F/ls)	local Slin = math.ceil(#S/ls)	local ML = Flin + Slin
MC[5].maxHeight = 32*ML	+ 5		SL.minWidth = 32*(ls+1)		SL.maxWidth = SL.minWidth	SL.minHeight = 32*(ML+1)	SL.maxHeight = SL.minHeight
for i, s in ipairs(F) do s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ML * (math.ceil(i/ls)-1) end
for i, s in ipairs(S) do s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ML * (math.ceil(i/ls)-1+Flin) end
end

L.UpdateEnM = function() local MM = tes3ui.findMenu("MenuMagic")		local MC = MM:findChild("PartScrollPane_pane").children		local ob, ic, icm, mc		local ls = cf.lin
local IL = MM:findChild("MagicMenu_item_names")	local ILin = math.max(math.ceil(#IL.children/ls), 1)		MC[8].maxHeight = 32*ILin + 5
IL.minWidth = 32*(ls+1)		IL.maxWidth = IL.minWidth	IL.minHeight = 32*(ILin+1)	IL.maxHeight = IL.minHeight
for i, s in ipairs(IL.children) do s.minHeight = 32		s.minWidth = 32		s.text = nil	ob = s:getPropertyObject("MagicMenu_object")		ic = s:createImage{path = ("icons\\%s"):format(ob.icon)}
if ob.objectType ~= tes3.objectType.book then icm = ic:createImage{path = ("icons\\%s"):format(ob.enchantment.effects[1].object.icon)}		icm.absolutePosAlignX = 1	icm.absolutePosAlignY = 1
if cf.UIcol ~= 0 then mc = ic:createLabel{text = ("%s"):format(ob.enchantment.chargeCost)}	mc.color = L.UItcolor[cf.UIcol]		mc.font = 1 end end
s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ILin * (math.ceil(i/ls)-1) end
if IL.children[1] then IL.children[1]:register("destroy", function(e) M.EnDF = false	if tes3ui.menuMode() then timer.delayOneFrame(L.UpdateEnM, timer.real) end end)	M.EnDF = true end
end


local function MENUENTER(e)
	if cf.UIen and not M.EnDF then local Mag = tes3ui.findMenu("MenuMagic")		if Mag and Mag.visible and Mag:findChild("MagicMenu_item_names").children[1] then L.UpdateEnM() end end
end		event.register("menuEnter", MENUENTER)



local function MENUENCHANTMENT(e)	local El = e.element	El.minWidth = 1200	El.minHeight = 800		local vol = 15	local EL = El:findChild("PartScrollPane_pane")	local lin = math.ceil(#EL.children/vol)
El:findChild("MenuEnchantment_magicEffectsContainer").width = 32*(vol+1)
EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
s:createImage{path = "icons\\" .. s:getPropertyObject("MenuEnchantment_Effect").bigIcon}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end

local function MENUSPELLMAKING(e)	local El = e.element	El.minWidth = 1200	El.minHeight = 800		local vol = 15	local EL = El:findChild("PartScrollPane_pane")	local lin = math.ceil(#EL.children/vol)
El:findChild("MenuSpellmaking_EffectsLayout").width = 32*(vol+1)
EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
s:createImage{path = "icons\\" .. s:getPropertyObject("MenuSpellmaking_Effect").bigIcon}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end

local function MENUALCHEMY(e)
	local RFI = e.element:findChild("PartNonDragMenu_main").children[1]:createImage{path = "icons/potions_blocked.tga"}
	RFI:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "Reset alchemy filter"} end)
	RFI:register("mouseClick", function() M.Alf = nil	M.AlfAt = nil	tes3.messageBox("Alchemy filter reset") end)
	e.element:updateLayout()
end

local function MENUINVENTORYSELECT(e) e.element.height = 1000	e.element.width = 800	if e.element:findChild("MenuInventorySelect_prompt").text == tes3.findGMST("sIngredients").value then	local EL = {{},{},{},{}}
	for l, tab in ipairs(L.ALF) do EL[l].b = e.element:createThinBorder{}	EL[l].b.autoHeight = true	EL[l].b.autoWidth = true	for i, ef in ipairs(tab) do
		EL[l][i] = EL[l].b:createImage{path = "icons/s/b_" .. tes3.getMagicEffect(ef).icon:sub(3)}		EL[l][i]:register("mouseClick", function() M.Alf = ef	tes3ui.updateInventorySelectTiles() end)
		EL[l][i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = tes3.getMagicEffect(ef).name} end)
	end end

	for i = 0, 7 do EL[4][i] = EL[4].b:createImage{path = L.ATRIC[i]}		EL[4][i]:register("mouseClick", function() M.AlfAt = i	tes3ui.updateInventorySelectTiles() end)
	EL[4][i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = L.ATR[i]} end) end
	EL[4][8] = EL[4].b:createImage{path = "icons/k/magic_alchemy.dds"}		EL[4][8]:register("mouseClick", function() M.AlfAt = nil	tes3ui.updateInventorySelectTiles() end)
	EL[4][8]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "All Attributes"} end)
	EL[4][9] = EL[4].b:createImage{path = "icons/potions_blocked.tga"}		EL[4][9]:register("mouseClick", function() M.Alf = nil	M.AlfAt = nil	tes3ui.updateInventorySelectTiles() end)
	EL[4][9]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "Reset alchemy filter"} end)
elseif M.Alf then M.Alf = nil	tes3ui.updateInventorySelectTiles() end end

local function FILTERINVENTORYSELECT(e) if M.Alf and e.item.objectType == tes3.objectType.ingredient then local filt = false	for i, ef in ipairs(e.item.effects) do if ef == M.Alf then
	if L.ALFEF[ef] and M.AlfAt then if e.item.effectAttributeIds[i] == M.AlfAt then filt = true	break end else filt = true	break end
end end		e.filter = filt end end


local function KEYDOWN(e) if not tes3ui.menuMode() then local CS = tes3.mobilePlayer.currentSpell
	if e.isAltDown then D.FS = {}	tes3.messageBox("Favorite spell list cleared")
	elseif CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 then
		if D.FS[CS.id] then D.FS[CS.id] = nil	tes3.messageBox("%s removed from Favorite Spells", CS.name) else D.FS[CS.id] = CS.flags == 4 and 1 or 0		tes3.messageBox("%s added to Favorite Spells", CS.name) end
	end
end end		event.register("keyDown", KEYDOWN, {filter = cf.q0.keyCode})

local function LOADED(e)
D = tes3.player.data	if not D.FS then D.FS = {} end
if cf.UIsp then L.UpdateSpellM() end
if cf.UIen then local MM = tes3ui.findMenu("MenuMagic")	MM:findChild("MagicMenu_item_costs").visible = false		MM:findChild("MagicMenu_item_percents").visible = false		M.EnDF = false end
end		event.register("loaded", LOADED)


local function registerModConfig()	local template = mwse.mcm.createTemplate("4NM_MENU")	template:saveOnClose("4NM_MENU", cf)	template:register()	local var = mwse.mcm.createTableVariable	local p = template:createPage()
p:createYesNoButton{label = "Spellmaking and enchanting menu", variable = var{id = "spmak", table = cf}, restartRequired = true}
p:createYesNoButton{label = "Alchemy filter", variable = var{id = "alc", table = cf}, restartRequired = true}
p:createYesNoButton{label = "Improved spell menu (requires save load)", variable = var{id = "UIsp", table = cf}}
p:createYesNoButton{label = "Improved enchanted items menu (requires save load)", variable = var{id = "UIen", table = cf}}
p:createSlider{label = "Set number of icons in 1 line in Improved magic menu", min = 5, max = 50, step = 1, jump = 5, variable = var{id = "lin", table = cf}}
p:createSlider{label = "Font color in Improved magic menu (0 = no text)", min = 0, max = 8, step = 1, jump = 1, variable = var{id = "UIcol", table = cf}}
p:createKeyBinder{variable = var{id = "q0", table = cf}, label = [[Press this button to add/remove current spell to Favorite Spells list. Press this button with ALT to clear this list.
Spells from Favorite list are placed at the top of the Improved Magic Menu. Changes to the list take effect after loading the save.]]}
end		event.register("modConfigReady", registerModConfig)

if cf.spmak then event.register("uiActivated", MENUSPELLMAKING, {filter = "MenuSpellmaking"})	event.register("uiActivated", MENUENCHANTMENT, {filter = "MenuEnchantment"}) end
if cf.alc then event.register("uiActivated", MENUINVENTORYSELECT, {filter = "MenuInventorySelect"}) event.register("uiActivated", MENUALCHEMY, {filter = "MenuAlchemy"})	event.register("filterInventorySelect", FILTERINVENTORYSELECT) end