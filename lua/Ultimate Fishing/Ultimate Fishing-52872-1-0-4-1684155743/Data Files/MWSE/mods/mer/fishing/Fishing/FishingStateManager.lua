local common = require("mer.fishing.common")
local logger = common.createLogger("FishingStateManager")
local config = require("mer.fishing.config")

---@class Fishing.FishingStateManager
local FishingStateManager = {}

---@alias Fishing.FishingAction.type
---| "cast" #Cast the fishing rod
---| "castFinish" #Finish casting the fishing rod
---| "castCancel" #Cancel casting the fishing rod
---| "reel" #Reel in the fishing rod
---| "fishBite" #Fish bites
---| "biteFinish" #Finish fish bite
---| "fishEscape" #Fish escapes
---| "fishCaught" #Fish caught
---| "endFishing" #End fishing

---@alias Fishing.fishingState
---| "IDLE" #Idle state, not fishing
---| "CASTING" #Casting state
---| "WAITING" #Waiting state
---| "CHASING" #Chasing state - Fish is spawned and moving towards the lure
---| "BITING" #Biting state - Fish is biting the lure
---| "REELING" #Reeling state
---| "CATCHING" #The interval between snagging and showing the caught fish
---| "BLOCKED" #Blocked state - No action can be taken

---@class Fishing.TempData
---@field activeFish Fishing.FishType.instance?
---@field lureSafeRef mwseSafeObjectHandle?
---@field fishingCastStrength number
---@field fishingTension number?
---@field fishingLine FishingLine?
---@field previousWaveHeight number?
---@field particle niNode?


---@return Fishing.TempData
local function tempData()
    if not tes3.player.tempData.fishing then
        ---@type Fishing.TempData
        tes3.player.tempData.fishing = {}
    end
    return tes3.player.tempData.fishing
end


--State

---@return Fishing.fishingState
function FishingStateManager.getCurrentState()
    return config.persistent.fishingState or "IDLE"
end

---@param state Fishing.fishingState
function FishingStateManager.setState(state)
    logger:debug("Setting state: %s", state)
    config.persistent.fishingState = state
end

---@param state Fishing.fishingState
function FishingStateManager.isState(state)
    return FishingStateManager.getCurrentState() == state
end


--Fish
---@return Fishing.FishType.instance?
function FishingStateManager.getCurrentFish()
    return tempData().activeFish
end

---@param fish Fishing.FishType.instance?
function FishingStateManager.setActiveFish(fish)
    tempData().activeFish = fish
end


--Lure

---@return tes3reference?
function FishingStateManager.getLure()
    local safeRef = tempData().lureSafeRef
    if safeRef and safeRef:valid() then
        return safeRef:getObject()
    else
        local lure =  tes3.getReference("mer_lure_01")
        if lure then
            safeRef = tes3.makeSafeObjectHandle(lure)
            return lure
        end
    end
    return nil
end

---@param lure tes3reference
function FishingStateManager.setLure(lure)
    tempData().lureSafeRef = tes3.makeSafeObjectHandle(lure)
end

---@return boolean did remove
function FishingStateManager.removeLure()
    logger:debug("Removing lure")
    local lure = FishingStateManager.getLure()
    if lure then
        lure:delete()
        tempData().lureSafeRef = nil
        return true
    else
        logger:warn("Lure not found")
        return false
    end
end

--Cast

---@return number
function FishingStateManager.getCastStrength()
    return tempData().fishingCastStrength
end

function FishingStateManager.setCastStrength()
    tempData().fishingCastStrength = tes3.player.mobile.actionData.attackSwing
    logger:debug("Cast strength: %s", tes3.player.mobile.actionData.attackSwing)
end


--Fishing Line
---@return FishingLine|nil
function FishingStateManager.getFishingLine()
    return tempData().fishingLine
end

---@param line FishingLine|nil
function FishingStateManager.setFishingLine(line)
    tempData().fishingLine = line
end


---Particle
function FishingStateManager.getParticle()
    return tempData().particle
end

function FishingStateManager.setParticle(particle)
    tempData().particle = particle
end

---Wave height

---@return number|nil
function FishingStateManager.getPreviousWaveHeight()
    return tempData().previousWaveHeight
end

---@param height number|nil
function FishingStateManager.setPreviousWaveHeight(height)
    tempData().previousWaveHeight = height
end

function FishingStateManager.getIgnoreRefs()
    local ignoreNodes = {
        tes3.player.sceneNode,
        ---@diagnostic disable-next-line: undefined-field
        tes3.dataHandler.waterController.waterPlane
    }

    local lure = FishingStateManager.getLure()
    if lure then
        table.insert(ignoreNodes, lure.sceneNode)
    end
    local fishingLine = FishingStateManager.getFishingLine()
    if fishingLine then
        table.insert(ignoreNodes, fishingLine.sceneNode)
    end

    local particle = FishingStateManager.getParticle()
    if particle then
        table.insert(ignoreNodes, particle)
    end

    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences() do
            if ref.sceneNode and ref.mobile then
                table.insert(ignoreNodes, ref.sceneNode)
            end
        end
    end

    return ignoreNodes
end

--Clear all data
function FishingStateManager.clearData()
    logger:debug("Clearing fishing data")
    tempData().activeFish = nil
    tempData().lureSafeRef = nil
    tempData().fishingCastStrength = nil
    tempData().fishingTension = nil
    tempData().fishingLine = nil
    tempData().previousWaveHeight = nil
end

function FishingStateManager.endFishing()

    logger:debug("Cancelling fishing")
    FishingStateManager.removeLure()

    event.trigger("Fishing:UnclampWaves")
    FishingStateManager.clearData()
    --give time for waves to settle


    local alreadyEnded = FishingStateManager.isState("IDLE")
    if alreadyEnded then
        logger:debug("already ended")
        return
    end
    FishingStateManager.setState("BLOCKED")
    timer.start{
        duration = 0.5,
        callback = function()
            common.enablePlayerControls()
            FishingStateManager.setState("IDLE")
        end
    }
end


return FishingStateManager