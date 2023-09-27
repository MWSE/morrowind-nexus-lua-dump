local metadata = toml.loadMetadata("AURA")
local version = metadata.package.version
local config = require("tew.AURA.config")
local UIvol = config.volumes.misc.UIvol / 100

-- Makes use of Bethesda eating sound instead of old weird swallow sound --
local function eating(e)
    tes3.getSound("Swallow").volume = 0

    if e.item.objectType == tes3.objectType.ingredient then
        tes3.playSound{reference=e.reference, soundPath="Fx\\eating.wav", volume=0.8*UIvol}
    end
end

print("[AURA "..version.."] UI: Eating sound initialised.")
event.register("equip", eating)