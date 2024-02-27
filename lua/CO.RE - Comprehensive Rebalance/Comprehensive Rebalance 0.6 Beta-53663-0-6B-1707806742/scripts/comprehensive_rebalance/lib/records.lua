
createdRecords = nil

local function onSave()
    return {
        createdRecords = createdRecords
    }
end

local function onLoad(data)
    createdRecords = data.createdRecords
    print ("loaded")
end

local records = {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
}

function records.createRecord(oldRecord)
    print("Creating record")
end

return records
