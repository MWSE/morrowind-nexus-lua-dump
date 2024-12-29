-- Inital Setup --
local config = require("GreaterGhost.STRONGER.config")
dofile("GreaterGhost.STRONGER.mcm")
local effects = require("GreaterGhost.STRONGER.effects")

local base_fEncumbranceStrMult = 5
----------------------------

-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20200122) then
    local function warning()
        tes3.messageBox("[STRONGER: ERROR] Your MWSE is out of date!" ..
                            " You will need to update to a more recent version to use this mod.")
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

-- Check Magicka Expanded framework --
local framework = require("OperatorJack.MagickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox("[STRONGER: ERROR] Magicka Expanded framework is not installed!" ..
                            " You will need to install it to use this mod.")
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

-- Register Mod Initialization Event Handler --
local function onLoaded(e)

    tes3.findGMST("fEncumbranceStrMult").value = base_fEncumbranceStrMult * config.multiplier

    for object in tes3.iterateObjects({
        tes3.objectType.spell, tes3.objectType.enchantment, tes3.objectType.alchemy
    }) do
        if (object.effects) then
            for i = 1, 8 do
                if (object.effects[i]) then
                    if (config.stronger_feather and object.effects[i].id == tes3.effect.feather) then
                        object.effects[i].id = tes3.effect.strongerFeather
                    elseif (config.stronger_burden and object.effects[i].id == tes3.effect.burden) then
                        object.effects[i].id = tes3.effect.strongerBurden
                    end
                end
            end
        end
    end

    print("[STRONGER: INFO] Initialized.")
end
event.register("loaded", onLoaded)
-------------------------