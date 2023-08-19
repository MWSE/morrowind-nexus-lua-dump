local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation
local recordingData = {}
local currentFrame = 0
local currentRecordingName = nil
local recorderState = { notPlaying = 1, playingBack = 2, recordingMovement = 3, }
local recordingState = recorderState.notPlaying

local function setRecordingName(name)
    currentRecordingName = name
    if not recordingData[name] then
        recordingData[name] = {}
    end
end
local function onUpdate(dt)

end
local function startRecording(shipId)
    recordingState = recorderState.recordingMovement
    if not currentRecordingName then
        setRecordingName("DefaultRecord")
    end
    currentFrame = 0
    recordingData[currentRecordingName].initPos = {}
    print(shipId)
    for index, obj in ipairs(I.AOutpost_ShipManage.getShipObjects(shipId)) do
        recordingData[currentRecordingName].initPos[obj.id] = { pos = obj.position, rot = obj.rotation }
    end
end
local function resetToDefaultPos(data)
    local rname = data.recordingName
    local shipId = data.shipId
    if recordingData[rname] then
        if not I.AOutpost_ShipManage.getShipObjects(shipId) then
            print(shipId)
        end
        for index, obj in ipairs(I.AOutpost_ShipManage.getShipObjects(shipId)) do
            local initPos = recordingData[rname].initPos[obj.id].pos
            local initRot = recordingData[rname].initPos[obj.id].rot
            obj:teleport(obj.cell, initPos, initRot)
        end
    end
end
local function stopRecording(shipId)
    --resetToDefaultPos({ recordingName = currentRecordingName,shipId = shipId })
    world.players[1]:sendEvent("AOSmessage", "Created recording with " .. tostring(currentFrame) .. " frames")
    recordingState = recorderState.notPlaying
    for index, value in pairs(recordingData[currentRecordingName].initPos) do
    end
end
local function startPlayback(shipId)
    resetToDefaultPos({ recordingName = currentRecordingName, shipId = shipId })
    currentFrame = 0
    recordingState = recorderState.playingBack
end
local function advanceFrame()
    if recordingState ~= recorderState.notPlaying then
        currentFrame = currentFrame + 1
    end
end
local function loadFromFrame(shipData)
    if recordingData[currentRecordingName] == nil then
        return
    end
    if recordingData[currentRecordingName].shipFrames[shipData.mainObjectId][currentFrame] == nil then
        shipData.vertMovement = 0
        shipData.forwMovement = 0
        shipData.sideMovement = 0
        shipData.degRot = 0
        recordingState = recorderState.notPlaying
        return
    end
    local frameData = recordingData[currentRecordingName].shipFrames[shipData.mainObjectId][currentFrame]
    shipData.vertMovement = frameData.vertMovement
    shipData.forwMovement = frameData.forwMovement
    shipData.sideMovement = frameData.sideMovement
    shipData.degRot = frameData.degRot
end
local function getMode()
    return recordingState
end
local function recordFrame(shipData)
    if recordingState == recorderState.playingBack then
        loadFromFrame(shipData)
        return
    end
    if recordingData[currentRecordingName] == nil then
        return
    end
    if recordingData[currentRecordingName].shipFrames == nil then
        recordingData[currentRecordingName].shipFrames = {}
    end
    if recordingData[currentRecordingName].shipFrames[shipData.mainObjectId] == nil then
        recordingData[currentRecordingName].shipFrames[shipData.mainObjectId] = {}
    end
    recordingData[currentRecordingName].shipFrames[shipData.mainObjectId][currentFrame] = {
        vertMovement = shipData.vertMovement,
        forwMovement = shipData.forwMovement,
        sideMovement = shipData.sideMovement,
        degRot = shipData.degRot
    }
end
return {
    interfaceName  = "AOutpost_ShipRecorder",
    interface      = {
        version = 1,
        setRecordingName = setRecordingName,
        setShipSpeed = setShipSpeed,
        setShipRot = setShipRot,
        recordFrame = recordFrame,
        resetToDefaultPos = resetToDefaultPos,
        advanceFrame = advanceFrame,
        loadFromFrame = loadFromFrame,
        getMode = getMode
    },
    engineHandlers = {
        onActorActive = onActorActive,
        onObjectActive = onObjectActive,
        onLoad = onLoad,
        onUpdate = onUpdate,
        onSave = onSave,
    },
    eventHandlers  = {
        ChangeShipObject = ChangeShipObject,
        airshipKeysPressed = airshipKeysPressed,
        lockShipObject = lockShipObject,
        startRecording = startRecording,
        stopRecording = stopRecording,
        startPlayback = startPlayback,
    },
}
