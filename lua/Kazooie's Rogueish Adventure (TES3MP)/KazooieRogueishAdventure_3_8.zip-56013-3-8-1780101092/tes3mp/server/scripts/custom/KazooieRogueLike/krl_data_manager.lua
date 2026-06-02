local savedDataFilename = "KazooieRogueLikeData.json"
local cachedSavedData = nil

function KRL_SaveData(identifier, value)
    cachedSavedData[identifier] = value
    jsonInterface.quicksave(savedDataFilename, cachedSavedData)
end

function KRL_GetSaveData(identifier)
    return cachedSavedData[identifier]
end

customEventHooks.registerHandler("OnServerPostInit", function()
    math.randomseed(os.time())

    local savedData = nil

    if tes3mp.DoesFileExist(tes3mp.GetModDir().."/"..savedDataFilename) then
        savedData = jsonInterface.load(savedDataFilename)
    end

    if not savedData then
        savedData = {runNumber = 1}
        jsonInterface.quicksave(savedDataFilename, savedData)
    end

    cachedSavedData = savedData
end)
