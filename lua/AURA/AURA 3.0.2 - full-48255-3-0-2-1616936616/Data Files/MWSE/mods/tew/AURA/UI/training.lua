local trainingData = require("tew\\AURA\\UI\\trainingData")
local modversion = require("tew\\AURA\\version")
local version = modversion.version
local config = require("tew\\AURA\\config")
local UIvol=config.UIvol/200

--[[
local config = require("tew\\AURA\\config")
local debugLogOn=config.debugLogOn

local function debugLog(string)
    if debugLogOn then
       mwse.log("[AURA "..version.."] Training: "..string)
    end
end--]]

local function onTrainingMenu(e)

    if not e.newlyCreated then
        return
    end

    local element=e.element
    element=element:findChild(-1155)

    for _, vF in pairs(element.children) do
        if vF.name=="null" then
            for _, skillClick in pairs(vF.children) do
                if string.find(skillClick.text, "gp") then
                    skillClick:register("mouseDown", function()
                        for skill, sound in pairs(trainingData) do
                            if string.find(skillClick.text, skill) then
                                tes3.playSound{soundPath=sound, reference=tes3.player, volume=0.7*UIvol}
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