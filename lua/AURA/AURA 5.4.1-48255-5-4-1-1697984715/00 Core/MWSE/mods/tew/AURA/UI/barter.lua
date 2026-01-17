local config = require("tew.AURA.config")
local common = require("tew.AURA.common")
local metadata = toml.loadMetadata("AURA")
local version = metadata.package.version
local UIvol = config.volumes.misc.UIvol / 100

local debugLog = common.debugLog

-- Plays the chest opening/closing sounds on bartering --
local function playBarterSounds(e)

    tes3.playSound{sound="chest open", volume=0.7*UIvol, pitch=0.6}
    debugLog("Barter menu opening sound played.")

    local closeBarterButton=e.element:findChild(tes3ui.registerID("MenuBarter_Cancelbutton"))
    if closeBarterButton then
        closeBarterButton:register("mouseDown", function()
        tes3.playSound{sound="chest close", volume=0.6*UIvol, pitch=0.8}
        debugLog("Barter menu closing sound played.")
        end)
    end

end

mwse.log("[AURA "..version.."] UI: Barter sounds initialised.")
event.register("uiActivated", playBarterSounds, {filter="MenuBarter", priority=-15})