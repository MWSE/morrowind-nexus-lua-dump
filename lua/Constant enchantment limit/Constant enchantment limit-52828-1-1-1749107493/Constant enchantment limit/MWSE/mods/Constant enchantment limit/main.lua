local cf = mwse.loadConfig("Constant enchantment limit", {base = 4000, mult = 40, antiexp = true})

local function registerModConfig()		local template = mwse.mcm.createTemplate("Constant enchantment limit")	template:saveOnClose("Constant enchantment limit", cf)	template:register()		local p0 = template:createPage()
p0:createSlider{label = "Base Limit", min = 0, max = 10000, step = 100, jump = 1000, variable = mwse.mcm.createTableVariable{id = "base", table = cf}}
p0:createSlider{label = "Enchant Skill Multiplier", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "mult", table = cf}}
p0:createYesNoButton{label = "Anti-exploit with doubling the power of enchantments", variable = mwse.mcm.createTableVariable{id = "antiexp", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local p, mp, D		local M = {}
local L = {CLEN = {500,500,500,1000,1000,1000,500,1000,1000,[0]=500}, AREN = {500,100,100,300,500,1000,1000,500,500,500,[0]=1000}}
local ME = {[75]=2, [76]=2, [77]=2}

local function ConstEnLim()	D.ENconst = 0
	for _, s in pairs(p.object.equipment) do if s.object.enchantment and s.object.enchantment.castType == 3 then
		if s.object.objectType == tes3.objectType.clothing then D.ENconst = D.ENconst + math.max(L.CLEN[s.object.slot] or 0, s.object.enchantCapacity)
		elseif s.object.objectType == tes3.objectType.armor then D.ENconst = D.ENconst + math.max(L.AREN[s.object.slot] or 0, s.object.enchantCapacity) end
	end end
	D.ENconMax = cf.base + mp.enchant.base * cf.mult
	if M.INV then M.ENL.current = D.ENconst		M.ENL.max = D.ENconMax end
end


local function unequipped(e) if e.reference == p then local it = e.item
	if it.enchantment and it.enchantment.castType == 3 then ConstEnLim() end
end end		event.register("unequipped", unequipped)


local function spellResist(e) if e.target == p and e.resistAttribute == 28 and e.source.objectType == tes3.objectType.enchantment and e.source.castType == 3 then		local ef = e.effect
	ConstEnLim()	
	if D.ENconst > D.ENconMax  then e.resistedPercent = 100	tes3.messageBox("Enchant limit exceeded! %d / %d", D.ENconst, D.ENconMax)	tes3.playSound{sound = "Spell Failure Conjuration"}
	elseif cf.antiexp and ef.min ~= ef.max and ME[ef.id] ~= 2 then e.resistedPercent = 50	tes3.messageBox("Anti-exploit! Enchant power reduced by half!") end
end end		event.register("spellResist", spellResist)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		D = p.data		M = {}
M.INV = tes3ui.findMenu("MenuInventory")
if M.INV then		M.INV:register("destroy", function() M.INV = nil end)
	M.ENLB = M.INV:findChild("MenuInventory_character_box"):createFillBar{current = D.ENconst or 0, max = D.ENconMax or 1000}
	M.ENLB.width = 150	M.ENLB.height = 14	M.ENL = M.ENLB.widget	M.ENL.fillColor = {1,0,1}
	M.ENLB:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "Constant enchant limit"} end)
	local el = M.ENLB:findChild("PartFillbar_text_ptr")	el.absolutePosAlignY = 0.7		el.color = {1,1,1}
end
end		event.register("loaded", loaded)