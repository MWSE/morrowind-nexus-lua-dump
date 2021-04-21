local config = require("sneakyStrike.config")
local strings = require("sneakyStrike.strings")

event.register("modConfigReady", function()
	config = require("sneakyStrike.config")
    require("sneakyStrike.mcm")
end)

local BASE_CRIT_MULT = 4 

local function calcCritMult(weapon)
	if weapon then
		speed = weapon.object.speed
	else
		speed = 2
	end
	tes3.findGMST("fCombatCriticalStrikeMult").value = BASE_CRIT_MULT * speed - config.coefShift 
	--tes3.messageBox("Current critical multiplier: %f", tes3.findGMST("fCombatCriticalStrikeMult").value)
end

local function onDamage(e)
	if not e.projectile or not e.projectile.firingWeapon then 
		return
	end
	if e.projectile.firingMobile == tes3.mobilePlayer then
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
		local sneakIcon = menu:findChild(tes3ui.registerID("MenuMulti_sneak_icon"))
		if sneakIcon and sneakIcon.visible then
			e.damage = e.damage * (BASE_CRIT_MULT + 1 - config.coefShift)
			tes3.messageBox(strings.criticalDamage)
			tes3.playSound{sound = "critical damage", reference = tes3.player}
		end
	end
end

local function onWeaponReadied(e)
	if e.reference ~= tes3.player then return end
	calcCritMult(e.weaponStack)
end
	

local function onWeaponUnreadied(e)
	if e.reference ~= tes3.player then return end
	tes3.findGMST("fCombatCriticalStrikeMult").value = BASE_CRIT_MULT
	--tes3.messageBox("Current critical multiplier: %f", tes3.findGMST("fCombatCriticalStrikeMult").value)
end

local function onLoaded(e)
	calcCritMult(tes3.mobilePlayer.readiedWeapon)
end

local function initialized(e)
	if config.modEnabled then
		event.register("weaponReadied", onWeaponReadied)
		event.register("weaponUnreadied", onWeaponUnreadied)
		event.register("loaded", onLoaded)
		BASE_CRIT_MULT = tes3.findGMST("fCombatCriticalStrikeMult").value
		event.register("damage", onDamage)
		mwse.log("[Sneaky Strike: Enabled]")
	else
		event.unregister("weaponReadied", onWeaponReadied)
		event.unregister("weaponUnreadied", onWeaponUnreadied)
		event.unregister("loaded", onLoaded)
		if BASE_CRIT_MULT then
			tes3.findGMST("fCombatCriticalStrikeMult").value = BASE_CRIT_MULT
		end
		mwse.log("[Sneaky Strike: Disabled]")
	end
end

event.register("initialized", initialized)