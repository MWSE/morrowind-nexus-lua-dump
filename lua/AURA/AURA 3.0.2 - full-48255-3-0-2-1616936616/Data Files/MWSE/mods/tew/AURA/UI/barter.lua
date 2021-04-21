local modversion = require("tew\\AURA\\version")
local version = modversion.version
local config = require("tew\\AURA\\config")
local debugLogOn=config.debugLogOn
local UIvol=config.UIvol/200
--local moduleContainers=config.moduleContainers

local function debugLog(string)
    if debugLogOn then
       mwse.log("[AURA "..version.."] UI: "..string)
    end
 end

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

print("[AURA "..version.."] UI: Barter sounds initialised.")
event.register("uiActivated", playBarterSounds, {filter="MenuBarter", priority=-15})