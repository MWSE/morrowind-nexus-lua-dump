local modversion = require("tew\\AURA\\version")
local version = modversion.version
local config = require("tew\\AURA\\config")
local UIvol=config.UIvol/200
local common = require("tew.AURA.common")

local debugLog = common.debugLog

local silts={
    "Silt_1",
    "Silt_2",
    "Silt_3"
}

local function travelFee(e)
    local npcId=tes3ui.getServiceActor(e)
    local class=npcId.reference.object.class.id
    local function playFee()
        tes3.playSound{sound="Item Gold Up", volume=0.9*UIvol, reference=tes3.player}
        if class=="Caravaner" then
            debugLog("Caravaner travel fee sound played.")
            tes3.playSound{sound=silts[math.random(1,#silts)], volume=0.6*UIvol, reference=tes3.player}
            tes3.playSound{sound="wind trees2", reference=tes3.player}
        elseif class=="Shipmaster" then
            debugLog("Shipmaster travel fee sound played.")
            tes3.playSound{sound="tew_boat", volume=0.6*UIvol, reference=tes3.player}
            tes3.playSound{sound="Flag", volume=0.7, reference=tes3.player}
        elseif class=="Gondolier" then
            debugLog("Gondolier travel fee sound played.")
            tes3.playSound{sound="tew_gondola", volume=0.6*UIvol, reference=tes3.player}
        end
    end

    local element=e.element
    element=element:findChild(-1155)
    for _, vF in pairs(element.children) do
        if vF.name=="null" then
            for _, vS in pairs(vF.children) do
                if string.find(vS.text, "gp") then
                    local travelClick=vS
                    travelClick:register("mouseDown", playFee)
                end
            end
        end
    end

end

print("[AURA "..version.."] UI: Travel menu sounds initialised.")
event.register("uiActivated", travelFee, {filter="MenuServiceTravel", priority=-15})