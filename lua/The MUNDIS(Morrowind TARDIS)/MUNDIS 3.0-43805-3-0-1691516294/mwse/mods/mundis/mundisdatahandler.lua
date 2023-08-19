local MUNDISStartData = require("mundis.mundis_startdata")
local startCell = "Odrosal, Tower"
local function getData()
    return MUNDISStartData
end
local changeToX = nil
local function getCellFromId(id)
    for index, dataItem in ipairs(tes3.player.data.Mundis.LocData) do
        if dataItem.id == id then
            return dataItem.cell
        end
    end
end
local function getIDFromCell(cell)
    for index, dataItem in ipairs(tes3.player.data.Mundis.LocData) do
        if dataItem.cell == cell then
            return dataItem.id
        end
    end
end
local function setCellButton(cell, buttonId, setUnSet)
    local destCell = nil
    if tes3.player.data.Mundis.buttonData["mundis_switch_" .. buttonId]  == -1 then
        
        tes3.getObject("mundis_switch_" .. buttonId).name = "Not Set"
        return
    end
    if not tes3.player.data.Mundis.buttonData["mundis_switch_" .. buttonId] then
        for index, dataItem in ipairs(tes3.player.data.Mundis.LocData) do
            if (dataItem.contentFile and string.lower(cell) == string.lower(dataItem.cell)) and tes3.isModActive( dataItem.contentFile) then
                print(string.lower(dataItem.cell))
                local text = cell
                dataItem.visited = true
                if not changeToX then

                else
                    text = text .. " - Activate to change to " .. tes3.player.data.Mundis.currentDest
                end
                tes3.player.data.Mundis.buttonData["mundis_switch_" .. buttonId] = dataItem.id
                tes3.getObject("mundis_switch_" .. buttonId).name = text
                return
            end
        end
        for index, dataItem in ipairs(tes3.player.data.Mundis.LocData) do
            if (string.lower(cell) == string.lower(dataItem.cell)) and not dataItem.contentFile then
                print(string.lower(dataItem.cell))
                local text = cell
                dataItem.visited = true
                if not changeToX then

                else
                    text = text .. " - Activate to change to " .. tes3.player.data.Mundis.currentDest
                end
                tes3.player.data.Mundis.buttonData["mundis_switch_" .. buttonId] = dataItem.id
                tes3.getObject("mundis_switch_" .. buttonId).name = text
                return
            end
        end
    else
        local text = getCellFromId(tes3.player.data.Mundis.buttonData["mundis_switch_" .. buttonId])
        tes3.getObject("mundis_switch_" .. buttonId).name = text
        return
    end

    if setUnSet == true then
        tes3.player.data.Mundis.buttonData["mundis_switch_" .. buttonId] = -1
        tes3.getObject("mundis_switch_" .. buttonId).name = "Not Set"
    end
end
local function generateUniqueID()
    if not tes3.player.data.Mundis.idCounter then
        tes3.player.data.Mundis.idCounter = 0
    end
    tes3.player.data.Mundis.idCounter = tes3.player.data.Mundis.idCounter + 1
    return tes3.player.data.Mundis.idCounter
end
local function addMundisLocation(extPos, extRot, cellName, contentFile)
    local newData = { px = extPos.x, py = extPos.y, pz = extPos.z, rotation = extRot, cell = cellName,
        id = generateUniqueID(), visited = false, contentFile = contentFile }
    table.insert(tes3.player.data.Mundis.LocData, newData)
    return newData
end
local function initButtons(changeTo)
    changeToX = changeTo
    setCellButton("Balmora", "front_01")
    setCellButton("Vivec, Arena", "front_02")
    setCellButton("Ald-ruhn", "front_03")
    setCellButton("Sadrith Mora", "front_04")
    setCellButton("Caldera", "front_05")
    setCellButton("Gnisis", "front_06")
    setCellButton("Vos", "front_07")
    setCellButton("Seyda Neen", "front_08")

    setCellButton("Tel Aruhn", "side01")
    setCellButton("Khuul", "side02")
    setCellButton("Molag Mar", "side03")
    setCellButton("Pelagiad", "side04")
    setCellButton("Suran", "side05")
    setCellButton("Ebonheart", "side06")
    setCellButton("Fort Frostmoth", "side07")
    setCellButton("Mournhold, Temple Courtyard", "side08")

    setCellButton("Odai Plateau", "side09")
    setCellButton("Uvirith's Grave", "side10")
    setCellButton("Bal Isra", "side11")
    setCellButton("Dagon Fel", "side12")
    setCellButton("Moonmoth Legion Fort", "side13")
    setCellButton("Hla Oad", "side14")
    setCellButton("Tel Mora", "side15")
    setCellButton("Ald Velothi", "side16")


    setCellButton("Windmoth Legion Fort", "side29", true)
    setCellButton("Vhul", "side30", true)
    setCellButton("Gorne", "side31", true)
    setCellButton("Ranyon-ruhn", "side32", true)
    setCellButton("Nivalis", "side17", true)
    setCellButton("Bodrum", "side18", true)
    setCellButton("Port Telvannis", "side19", true)
    setCellButton("Firewatch", "side20", true)

    setCellButton("Akamora", "side21", true)
    setCellButton("Old Ebonheart", "side22", true)
    setCellButton("Andothren", "side23", true)
    setCellButton("Almas Thirr", "side24", true)
    setCellButton("Helnim", "side25", true)
    setCellButton("Necrom", "side26", true)
    setCellButton("Bahrammu", "side27", true)
    setCellButton("Roa Dyr", "side28", true)
end
local function setData(data)
    MUNDISStartData = data
end
local function onInit()
    --local MUNDISData = storage.globalSection('MundisData')
    --if(MUNDISData:get("LocationData" ) == nil ) then
    if not tes3.player.data.Mundis then
        tes3.player.data.Mundis = {}

        tes3.player.data.Mundis.LocIndex = 0
        tes3.player.data.Mundis.LocData = {}
        tes3.player.data.Mundis.legacySummon = false

        tes3.player.data.Mundis.LocData = {}
        for index, dataItem in ipairs(MUNDISStartData) do
            addMundisLocation(tes3vector3.new(dataItem.px, dataItem.py, dataItem.pz), dataItem.rz, dataItem.cell,
                dataItem.contentFile)
        end
    end
    if not tes3.player.data.Mundis.currentDest then
        tes3.player.data.Mundis.currentDest = getIDFromCell(startCell)
    end
    if not tes3.player.data.Mundis.buttonData then
        tes3.player.data.Mundis.buttonData = {}
    end
  --  
    -- myModData:set("MUNDISStartData", MUNDISStartData)
    -- core.sendGlobalEvent("MUNDISInit", nil)
end
local function loaded()
    onInit()
    initButtons()
end
event.register(tes3.event.loaded, loaded)
return {
    interfaceName = "MundisDataHandler",
    interface = {
        version = 1,
        getData = getData,
        setData = setData,
        setCellButton = setCellButton,
        initButtons = initButtons,
        addMundisLocation = addMundisLocation,
        getCellFromId = getCellFromId,
    },
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
    }
}
