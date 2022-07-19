local modversion = require("tew\\AURA\\version")
local version = modversion.version
local config = require("tew\\AURA\\config")
local UIvol=config.UIvol/200

local function eating(e)
    tes3.getSound("Swallow").volume = 0

    if e.item.objectType == tes3.objectType.ingredient then
        tes3.playSound{reference=e.reference, soundPath="Fx\\eating.wav", volume=1.0*UIvol}
    end
end

print("[AURA "..version.."] UI: Eating sound initialised.")
event.register("equip", eating)