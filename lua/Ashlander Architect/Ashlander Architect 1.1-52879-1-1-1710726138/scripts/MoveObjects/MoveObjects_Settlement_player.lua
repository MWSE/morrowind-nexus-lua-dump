local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local async = require("openmw.async")
local config = require("scripts.MoveObjects.config")
local activeObjectTypes = {}

local Dialog = require("scripts.MoveObjects.Dialog")

local mySettlementName
local settlementModData = storage.globalSection("AASettlements")

local renameWindow = nil
local uithing = nil

local currentSettlement = nil

local bedCount = 0

local genModData = storage.globalSection("MoveObjectsCellGen")

local currentCategory = nil --if nil, then show the category selection level
local currentSubCat = nil   --if nil, but above isn't, show subcategories.

local function getCurrentSettlementId()
    local list = settlementModData:get("settlementList")
    local settlementId = nil
    if (self.cell.isExterior) then
        for x, structure in ipairs(settlementModData:get("settlementList")) do
            local dist = math.sqrt((self.position.x - structure.settlementCenterx) ^ 2 +
                (self.position.y - structure.settlementCentery) ^ 2)

            if (dist < structure.settlementDiameter / 2) then
                return structure.markerId
            end
        end
    else
        for x, structure in ipairs(genModData:get("generatedStructures")) do
            if (self.cell.name == structure.InsideCellName) then
                local dist = math.sqrt((self.position.x - structure.InsidePos.x) ^ 2 +
                    (self.position.y - structure.InsidePos.y) ^ 2)
                if (dist < 10000) then
                    for i, settlement in ipairs(settlementModData:get("settlementList")) do
                        if (settlement and settlement.markerId == structure.settlementId) then
                            return settlement.markerId
                        end
                    end
                end
            end
        end
    end
    return nil
end
local CreateSettlementBox = nil
local ConfigSettlementBox = nil
local currentText = ""
local buttonContext = ""
local doorID = ""
local settlementMarker = nil

local maxSettlers = 0
local function textChanged(firstField)
    currentText = (firstField)
end
local function buttonClick()
    print(currentText)
    core.sendGlobalEvent("addSettlementEvent",
        {
            settlementName = currentText,
            settlementMarker = settlementMarker,
            npcSpawnPosition = I.ZackUtilsAA.findPosByOnNavMesh(settlementMarker.position, self.position)
        })
    I.UI.setMode()
    CreateSettlementBox:destroy()
end

local function destroyWindow()
    renameWindow:destory()
end
local function increaseSettlers()
    if (maxSettlers < bedCount) then
        maxSettlers = maxSettlers + 1
        ConfigSettlementBox:destroy()
        ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
    else
        ui.showMessage("Not enough beds!")
    end
end

local function decreaseSettlers()
    if (maxSettlers > 0) then
        maxSettlers = maxSettlers - 1

        ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
    end
end
local allowMales = false
local function toggleMales()
    allowMales = not allowMales
    if (allowMales) then
        core.sendGlobalEvent("addSettlementTagEvent", { settlementId = currentSettlement, tagName = "allowMales" })
    else
        core.sendGlobalEvent("removeSettlementTagEvent", { settlementId = currentSettlement, tagName = "allowMales" })
    end

    ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
end


local function yesText(bool)
    if (bool == true) then
        return "Yes"
    else
        return "No"
    end
end
local raceList = {
    { keyName = "allow_female", buttonText = "Allow Female Settlers: ",         state = false },
    { keyName = "allow_male",   buttonText = "Allow Male Settlers: ",           state = false },
    { keyName = "allow_bret",   buttonText = "Allow Breton Settlers: ",         state = false },
    { keyName = "allow_arg",    buttonText = "Allow Argonian Settlers: ",       state = false },
    { keyName = "allow_dunm",   buttonText = "Allow Dunmer Settlers: ",         state = false },
    { keyName = "allow_helf",   buttonText = "Allow Allow High Elf Settlers: ", state = false },
    { keyName = "allow_imp",    buttonText = "Allow Imperial Settlers: ",       state = false },
    { keyName = "allow_orc",    buttonText = "Allow Orcish Settlers: ",         state = false },
    { keyName = "allow_khaj",   buttonText = "Allow Khajit Settlers: ",         state = false },
    { keyName = "allow_nord",   buttonText = "Allow Nord Settlers: ",           state = false },
    { keyName = "allow_redg",   buttonText = "Allow Redguard Settlers: ",       state = false },
    { keyName = "allow_welf",   buttonText = "Allow Wood Elf Settlers: ",       state = false }
}

local function buttonClickRename()
    print(currentText)
    core.sendGlobalEvent("renameSettlementEvent",
        {
            name = currentText,
            id = settlementMarker
        })
    I.UI.setMode()
end
local function ToggleTableItem(x, text)
    local text = text.props.name
    if (text == "DoneButton") then
        ConfigSettlementBox:destroy()
        ConfigSettlementBox = nil
        I.UI.setMode()
        return
    elseif (text == "RenameButton") then
        ConfigSettlementBox:destroy()
        ConfigSettlementBox = nil

        renameWindow = I.ZackUtilsUI_AA.renderTextInput(
            { "", "",
                "What would you like this building to be named?" }, mySettlementName, textChanged, buttonClickRename)

        return
    end
    print(text)
    for x, race in ipairs(raceList) do
        if (race.keyName == text) then
            race.state = not race.state
            if (race.state) then
                core.sendGlobalEvent("addSettlementTagEvent",
                    { settlementId = currentSettlement, tagName = race.keyName })
            else
                core.sendGlobalEvent("removeSettlementTagEvent",
                    { settlementId = currentSettlement, tagName = race.keyName })
            end
        end
    end
end
local aux_util = require('openmw_aux.util')
local allowFemales = false
local function toggleFemales(v1, v2)
    if (v1 ~= nil) then
        print("1", v1)
    end
    if (v2 ~= nil) then
        print(v2.props.text)
    end
    allowFemales = not allowFemales
    if (allowFemales) then
        core.sendGlobalEvent("addSettlementTagEvent", { settlementId = currentSettlement, tagName = "allowFemales" })
    else
        core.sendGlobalEvent("removeSettlementTagEvent", { settlementId = currentSettlement, tagName = "allowFemales" })
    end

    ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
end

local allowImperials = false
local function toggleImperials()
    allowImperials = not allowImperials

    ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
end


local function HasSettlementTag(settlementId, tagName)
    local list = settlementModData:get("settlementList")
    for x, settlement in ipairs(list) do
        if settlement.markerId == settlementId then
            if (list[x].settlementTags == nil) then

            end
            for i, tag in ipairs(list[x].settlementTags) do
                if (tag == tagName) then
                    return true
                end
            end
        end
    end
    return false
end



local allowDunmer = false
local function toggleDunmer()
    allowDunmer = not allowDunmer

    ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
end
local function RenderToggleBox(toggleName, toggleText, toggleCallback, toggleBool)
    local booltext = "Yes"



    if (toggleBool == false) then
        booltext = "No"
    end
    return I.ZackUtilsUI_AA.boxedTextContent(toggleText .. ": " .. booltext, async:callback(toggleCallback), 0.8,
        toggleName)
end
local function RenderBox(toggleName, toggleText, toggleCallback)
    return I.ZackUtilsUI_AA.boxedTextContent(toggleText, async:callback(toggleCallback), 0.8, toggleName)
end
local function renderTextInput(settlementId, existingText, editCallback, OKCallback, OKText)
    local mySettle = nil
    bedCount = 0
    local settlerCount = 0
    for x, settlement in ipairs(settlementModData:get("settlementList")) do
        if settlement.markerId == settlementId then
            mySettle = settlement
            if (settlement.settlementBedIds ~= nil) then
                for x, bed in ipairs(settlement.settlementBedIds) do
                    bedCount = bedCount + 1
                end
                for x, bed in ipairs(settlement.settlementNPCs) do
                    settlerCount = settlerCount + 1
                end
            end
        end
    end

    mySettlementName = mySettle.settlementName
    if (ConfigSettlementBox ~= nil) then
        ConfigSettlementBox:destroy()
    end
    if (OKText == nil) then
        OKText = "OK"
    end
    local vertical = 50
    local horizontal = (ui.layers[1].size.x / 2) - 400

    local vertical = 0
    local horizontal = ui.layers[1].size.x / 2 - 25
    local vertical = vertical + ui.layers[1].size.y / 2 + 100

    local content = {}
    table.insert(content, I.ZackUtilsUI_AA.textContent("Settings for Settlement: " .. mySettle.settlementName))
    table.insert(content, I.ZackUtilsUI_AA.textContentLeft("Current number of beds: " .. tostring(bedCount)))
    table.insert(content, I.ZackUtilsUI_AA.textContentLeft("Current number of Settlers: " .. tostring(settlerCount)))
    local textEdit = I.ZackUtilsUI_AA.boxedTextEditContent(existingText, async:callback(editCallback), 0.5, 100)
    local okButton = I.ZackUtilsUI_AA.boxedTextContent(OKText, async:callback(OKCallback))
    table.insert(content, I.ZackUtilsUI_AA.textContentLeft("Desired number of settlers:"))
    local okButton2 = I.ZackUtilsUI_AA.boxedTextContent("+", async:callback(increaseSettlers))
    table.insert(content, okButton2)
    table.insert(content, I.ZackUtilsUI_AA.textContentLeft(tostring(maxSettlers)))
    local okButton2x = I.ZackUtilsUI_AA.boxedTextContent("-", async:callback(decreaseSettlers))
    table.insert(content, okButton2x)
    local validRaceCount = 0
    local validGender = false
    for x, race in ipairs(raceList) do
        raceList[x].state = HasSettlementTag(settlementId, race.keyName)

        if (race.keyName == "allow_female" or race.keyName == "allow_male") then
            if (race.state == true) then
                validGender = true
            end
        elseif (raceList[x].state == true) then
            validRaceCount = validRaceCount + 1
        end
        table.insert(content, RenderToggleBox(race.keyName, race.buttonText, ToggleTableItem, race.state))
    end
    if (validRaceCount == 0 or validGender == false) then
        table.insert(content, I.ZackUtilsUI_AA.textContentLeft("Warning: The current configuration"))
        table.insert(content, I.ZackUtilsUI_AA.textContentLeft("will not allow any settlers to join."))
    end
    table.insert(content, RenderBox("RenameButton", "Rename", ToggleTableItem))
    table.insert(content, RenderBox("DoneButton", "OK", ToggleTableItem))
    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            --position = v2(horizontal, vertical),
            vertical = false,
            relativeSize = util.vector2(0.1, 0.1),
            arrange = ui.ALIGNMENT.Start
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.Start,
                    size = util.vector2(400, 10),
                }
            }
        }
    }
end
local function showSettlementConfig(settlementId)
    currentSettlement = settlementId
    I.ZackUtilsAA.createItem("AA_TRAVELCREATURE", self.cell, self.position)
    print("this")
    ConfigSettlementBox = renderTextInput(currentSettlement)

    I.UI.setMode('Interface', { windows = {} })
    --Need to show data here. Allow you to config which type of settler to allow, how many to allow(Defaults to 0), and
end
local function onInputAction(id)
    if id == input.ACTION.Activate then
        local obj = I.ZackUtilsAA.getObjInCrosshairs().hitObject
        if (obj == nil) then
            print("No object`")
            return
        end
        if (obj.recordId == "zhac_settlement_marker") then
            for x, settlement in ipairs(settlementModData:get("settlementList")) do
                if (settlement.markerId == obj.id) then
                    --Can't create a settlement if one exists here already.
                    showSettlementConfig(obj.id)
                    --ui.showMessage("Already exists here")
                    return
                end
            end

            if (obj.cell.name ~= "") then
                --ui.showMessage("You can't create a settlement in a named area.")
                -- return
            end
            for _, object in ipairs(nearby.activators) do
                if (object.recordId == "zhac_settlement_marker" and object ~= obj) then
                    local dist = math.sqrt((object.position.x - obj.position.x) ^ 2 +
                        (object.position.y - obj.position.y) ^ 2 + (object.position.z - obj.position.z) ^ 2)
                    if (dist < 10000) then
                        ui.showMessage("This marker is too close to an existing settlement!")
                        return
                    end
                end
            end
            settlementMarker = obj
            I.UI.setMode('Interface', { windows = {} })
            CreateSettlementBox = I.ZackUtilsUI_AA.renderTextInput(
                { "", "",
                    "What would you like this settlement to be named?" }, "", textChanged, buttonClick)
            print("trying")
        end
    end
end
local function createNewSettler(settlementMarker)
    core.sendGlobalEvent("addSettlerEvent",
        {
            settlementId = settlementMarker.id,
            position = nearby.findRandomPointAroundCircle(settlementMarker.position, 400)
        })
end
local function updateSettlerUi()
    if (ConfigSettlementBox ~= nil) then
        ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
    end
end
local function addActorToSettlement(settlementMarker)
    local pos = nearby.findRandomPointAroundCircle(settlementMarker.position, 400)
    if pos == nil then
        error("Unable to find spawn location. Navigator may be disabled")
    end
    core.sendGlobalEvent("addSettlerEvent",
        {
            settlementId = settlementMarker.id,
            position = pos
        })
end
local function onConsoleCommand(mode, command, selectedObject)
    if (command == "luasettler" and selectedObject.recordId == "zhac_settlement_marker") then
        core.sendGlobalEvent("addActorToSettlement", selectedObject.id)
    end
end
local function processGreeting(data)
    local actor = data.npc
    local jobSiteData = data.jobSiteData

    local actorRecord = actor.type.record(actor)
    local playerRecord = self.type.record(self)
    Dialog.sayGreeting(actorRecord,playerRecord,jobSiteData)

end

return {
    interfaceName = "SettlerPlayer",
    interface = {
        version = 1,
        createWindow = createWindow,
        destroyWindow = destroyWindow,
        renderTextInput = renderTextInput,
        createNewSettler = createNewSettler,

    },
    eventHandlers = {
        updateSettlerUi = updateSettlerUi,
        addActorToSettlement = addActorToSettlement,
        UiModeChanged = function(data)
            -- print('LMMUiModeChanged to', data.newMode, '(' .. tostring(data.arg) .. ')')
            if renameWindow ~= nil and data.newMode == nil then
                renameWindow:destroy()
            elseif ConfigSettlementBox ~= nil and data.newMode == nil then
                ConfigSettlementBox:destroy()
                ConfigSettlementBox = nil
            end
        end,
        processGreeting = processGreeting,
    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
        onSave = onSave,
        onConsoleCommand = onConsoleCommand,
    }
}
