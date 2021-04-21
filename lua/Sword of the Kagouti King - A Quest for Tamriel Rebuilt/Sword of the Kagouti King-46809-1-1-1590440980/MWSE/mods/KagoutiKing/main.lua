--[[
	Mod: Kagouti King Sword
	Author: Melchior Dahrk & RubberMan
--]]

local kk_shavingsCount

-- Collect Shavings

local function collectShavings(e)

    -- must be the player activating
    if e.activator ~= tes3.player then
        return
    end

    -- must be the correct target object
    local object = e.target.baseObject
    if object.id:lower() ~= "contain_bm_stalhrim_01" then
        return
    end

    -- must have correct weapon equipped
    local weapon = tes3.mobilePlayer.readiedWeapon
    if (weapon and weapon.object.id) ~= "kk_chisel" then
        return
    end

    if kk_shavingsCount.value == 5 then
        tes3.playSound{reference=e.target, sound="repair fail"}
        tes3.messageBox("The chisel is too dull to collect any shavings.")
    else
        kk_shavingsCount.value = kk_shavingsCount.value + 1
        tes3.playSound{reference=e.target, sound="repair"}
        mwscript.addItem{reference=tes3.player, item="kk_shavings", count=1}
        tes3.messageBox("You collect a handful of shavings. Chisel uses (%d/5)", 5 - kk_shavingsCount.value)
    end
	
	return false
	
end

-- Mod Initialization

event.register("initialized", function()
	if tes3.isModActive("Kagouti King Sword.ESP") then
		-- register events
		event.register("activate", collectShavings)
		-- cache globals
		kk_shavingsCount = tes3.findGlobal("kk_shavingsCount")
	end
end)
