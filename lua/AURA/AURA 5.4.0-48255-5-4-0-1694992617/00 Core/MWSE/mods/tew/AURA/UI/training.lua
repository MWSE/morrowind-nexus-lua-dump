local trainingData = require("tew.AURA.UI.trainingData")
local metadata = toml.loadMetadata("AURA")
local version = metadata.package.version
local config = require("tew.AURA.config")
local common = require("tew.AURA.common")
local UIvol = config.volumes.misc.UIvol / 100

local debugLog = common.debugLog

-- Play skill sounds on training --
local function onTrainingMenu(e)

    if not e.newlyCreated then
        return
    end

    local element=e.element
    element=element:findChild(-1155)

    -- OOOOPH --
    for _, vF in pairs(element.children) do
        if vF.name=="null" then
            for _, skillClick in pairs(vF.children) do
                if string.find(skillClick.text, "gp") then
                    skillClick:register("mouseDown", function()
                        for skill, sound in pairs(trainingData) do
                            if string.find(skillClick.text, skill) then
                                tes3.playSound{sound=sound, reference=tes3.player, volume=0.7*UIvol}
                                debugLog(sound.." played.")
                            end
                        end
                    end)
                end
            end
        end
    end
end


print("[AURA "..version.."] UI: Training sounds initialised.")
event.register("uiActivated", onTrainingMenu, {filter="MenuServiceTraining"})