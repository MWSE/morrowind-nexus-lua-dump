local knownData = {}

local function getData(key)
    return knownData[key]
end

local function setData(key, data)
    knownData[key] = data
end
return {
    interfaceName = "ZS_DataManager",
    interface = {
        getData = getData,
        setData = setData,
    },
    engineHandlers = {
        onSave = function ()
            return {knownData = knownData}
        end,
        onLoad = function (data)
            if not data then return end
            knownData = data.knownData
        end,
    },
    eventHandlers = {
    }
}
