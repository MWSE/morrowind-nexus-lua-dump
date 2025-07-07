local public = {}

local common = require("StormAtronach.TT.common")
local config = common.config
-- Logging stuff
local log = mwse.Logger.new({
	name = config.name,
	level = config.log_level,
})

-- Spellbatting mechanic - the prequel
local coolShieldMechanic = tes3.isLuaModActive("OperatorJack.EnhancedReflection")

-- Spellbatting 1: the window of opportunity.  I wish I had data on how each weapon works, but this needs to be fun rather than precise.
local function spellBatting()
    if coolShieldMechanic then
         tes3.applyMagicSource({
        reference = tes3.player,
        bypassResistances = true,
        effects = { { id = tes3.effect.shield, min = 100, max = 100, duration = config.bat_window } },
        name = "Spell batting",
        })
         log:trace("Spell batting activated with EnhancedReflection shield effect")
    else
         tes3.applyMagicSource({
        reference = tes3.player,
        bypassResistances = true,
        effects = { { id = tes3.effect.reflect, min = 100, max = 100, duration = config.bat_window } },
        name = "Spell batting",
        })
        log:trace("Spell batting activated with vanilla reflect effect")
    end
end

function public.activateBatting()
     -- Check if the player has the required skill
     local playerWeapon    = tes3.mobilePlayer.readiedWeapon
     local weaponType = playerWeapon and playerWeapon.object.type or nil
     local areYouGoodEnough  = common.weaponSkillCheck({thisMobileActor = tes3.mobilePlayer, weapon = weaponType, valueToCheckAgainst = config.bat_min_skill})
     -- Now for the actual triggering
     -- Note to self: Yes, it would be great to have different weapon attack times and such for timing this properly. Alas, that's too much work, and probably does not add to the fun
     if tes3.mobilePlayer.actionData.attackSwing == 1 and areYouGoodEnough.check then
          log:trace("Spell batting trigger timer started")
          timer.start({duration = config.bat_start_delay, callback = spellBatting, type = timer.simulate})
     end
end

return public