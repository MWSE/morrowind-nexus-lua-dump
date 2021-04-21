-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20200122) then
  local function warning()
      tes3.messageBox(
        "[Enhanced Light ERROR] Your MWSE is out of date!"
          .. " You will need to update to a more recent version to use this mod."
      )
  end
  event.register("initialized", warning)
  event.register("loaded", warning)
  return
end
----------------------------

-- Check Magicka Expanded framework --
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Enhanced Light ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------

-- Initial Setup --
require("OperatorJack.EnhancedLight.effects")
require("OperatorJack.EnhancedLight.spells")
local functions = include("OperatorJack.EnhancedLight.functions")
-------------------------


-- Register Mod Initialization Event Handler --
local function onLoaded(e)
  for object in tes3.iterateObjects({tes3.objectType.spell, tes3.objectType.enchantment, tes3.objectType.alchemy}) do
      if (object.effects) then
          for i=1, 8 do
              if (object.effects[i]) then
                  if (object.effects[i].id == tes3.effect.light) then
                      object.effects[i].id = tes3.effect.magelight
                  end
              end
          end
      end
  end

  print("[Enhanced Light: INFO] Initialized.")
end
event.register("loaded", onLoaded)
-------------------------