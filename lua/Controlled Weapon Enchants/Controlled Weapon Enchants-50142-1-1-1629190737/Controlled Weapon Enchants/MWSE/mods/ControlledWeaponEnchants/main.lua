local cf = mwse.loadConfig("Controlled Weapon Enchants", {KEY = {keyCode = 34}})		
local p, D, EnCr

local function KEYDOWN(e) if not tes3ui.menuMode() then
	D.NoEnStrike = not D.NoEnStrike		EnCr.visible = D.NoEnStrike	
end end		event.register("keyDown", KEYDOWN, {filter = cf.KEY.keyCode})

local function enchantChargeUse(e)    if e.isCast and e.caster == p and e.source.castType == 1 then
	if D.NoEnStrike then e.charge = 50000 end
	local w = tes3.mobilePlayer.readiedWeapon	if w and w.variables.charge < e.charge then timer.delayOneFrame(function() tes3.removeSound{sound = e.source.effects[1].object.spellFailureSoundEffect, reference = p} end) end
end	end		event.register("enchantChargeUse", enchantChargeUse)

local function LOADED(e) p = tes3.player	D = tes3.player.data
	EnCr = tes3ui.findMenu(-526):findChild(-543):createImage{path = "icons\\enchant_marker.tga"}	EnCr.absolutePosAlignX = 1	EnCr.absolutePosAlignY = 0		EnCr.visible = not not D.NoEnStrike
end		event.register("loaded", LOADED)

local function initialized(e) tes3.findGMST("sMagicInsufficientCharge").value = "" end
event.register("initialized", initialized)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Controlled Weapon Enchants")	tpl:saveOnClose("Controlled Weapon Enchants", cf)	tpl:register()
local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{variable = var{id = "KEY", table = cf}, label = "Button to change the mode of enchantments when attacking. Requires restart of the game"}
end		event.register("modConfigReady", registerModConfig)