-- SettlerPlayer.lua (cleaned)

-- Deps
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local v2 = util.vector2
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local input = require("openmw.input")
local async = require("openmw.async")

local Dialog = require("scripts.MoveObjects.Dialog")
local config = require("scripts.MoveObjects.config")

-- Mod-scoped state
local settlementModData = storage.globalSection("AASettlements")
local genModData = storage.globalSection("MoveObjectsCellGen")

local renameWindow = nil
local CreateSettlementBox = nil
local ConfigSettlementBox = nil

local currentSettlement = nil
local currentText = ""
local settlementMarker = nil
local maxSettlers = 0
local bedCount = 0

-- UI helpers (Daisy utils)
-- Expect these interfaces to be provided by your other modules
-- I.DaisyUtilsAA, I.DaisyUtilsUI_AA, I.MWUI

-- Utility: find current settlement id at player position
local function getCurrentSettlementId()
    if self.cell.isExterior then
        local list = settlementModData:get("settlementList") or {}
        for _, structure in ipairs(list) do
            local dx = self.position.x - structure.settlementCenterx
            local dy = self.position.y - structure.settlementCentery
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < (structure.settlementDiameter or 0) / 2 then
                return structure.markerId
            end
        end
    else
        local structures = genModData:get("generatedStructures") or {}
        for _, structure in ipairs(structures) do
            if self.cell.name == structure.InsideCellName then
                local dx = self.position.x - structure.InsidePos.x
                local dy = self.position.y - structure.InsidePos.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < 10000 then
                    local list = settlementModData:get("settlementList") or {}
                    for _, settlement in ipairs(list) do
                        if settlement and settlement.markerId == structure.settlementId then
                            return settlement.markerId
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Text edit callback for generic text inputs
local function textChanged(firstField)
    currentText = firstField or ""
end

-- "Create settlement" OK button
local function buttonClick()
    if not (currentText and #currentText > 0) then
        ui.showMessage("Please enter a settlement name.")
        return
    end
    if not settlementMarker then
        ui.showMessage("No settlement marker found.")
        return
    end
    core.sendGlobalEvent("addSettlementEvent", {
        settlementName = currentText,
        settlementMarker = settlementMarker,
        npcSpawnPosition = I.DaisyUtilsAA.findPosByOnNavMesh(settlementMarker.position, self.position),
    })
    I.UI.setMode()
    if CreateSettlementBox then
        CreateSettlementBox:destroy()
        CreateSettlementBox = nil
    end
end

-- Safely destroy rename window
local function destroyWindow()
    if renameWindow then
        renameWindow:destroy()
        renameWindow = nil
    end
end

-- Settlement config controls
local function increaseSettlers()
    if maxSettlers < bedCount then
        maxSettlers = maxSettlers + 1
    else
        ui.showMessage("Not enough beds!")
    end
    if ConfigSettlementBox then
        ConfigSettlementBox:destroy()
    end
    ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
end

local function decreaseSettlers()
    if maxSettlers > 0 then
        maxSettlers = maxSettlers - 1
        if ConfigSettlementBox then
            ConfigSettlementBox:destroy()
        end
        ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
    end
end

-- Race/gender allow-list
local raceList = {
    { keyName = "allow_female", buttonText = "Allow Female Settlers", state = false },
    { keyName = "allow_male",   buttonText = "Allow Male Settlers",   state = false },
    { keyName = "allow_bret",   buttonText = "Allow Breton Settlers", state = false },
    { keyName = "allow_arg",    buttonText = "Allow Argonian Settlers", state = false },
    { keyName = "allow_dunm",   buttonText = "Allow Dunmer Settlers", state = false },
    { keyName = "allow_helf",   buttonText = "Allow High Elf Settlers", state = false },
    { keyName = "allow_imp",    buttonText = "Allow Imperial Settlers", state = false },
    { keyName = "allow_orc",    buttonText = "Allow Orcish Settlers", state = false },
    { keyName = "allow_khaj",   buttonText = "Allow Khajiit Settlers", state = false },
    { keyName = "allow_nord",   buttonText = "Allow Nord Settlers", state = false },
    { keyName = "allow_redg",   buttonText = "Allow Redguard Settlers", state = false },
    { keyName = "allow_welf",   buttonText = "Allow Wood Elf Settlers", state = false },
}

local function buttonClickRename()
    if not (currentText and #currentText > 0) then
        ui.showMessage("Please enter a name.")
        return
    end
    core.sendGlobalEvent("renameSettlementEvent", {
        name = currentText,
        id = settlementMarker,
    })
    I.UI.setMode()
    destroyWindow()
end

local function HasSettlementTag(settlementId, tagName)
    local list = settlementModData:get("settlementList") or {}
    for _, settlement in ipairs(list) do
        if settlement.markerId == settlementId then
            local tags = settlement.settlementTags or {}
            for _, tag in ipairs(tags) do
                if tag == tagName then
                    return true
                end
            end
        end
    end
    return false
end

-- Generic "boxed" helpers
local function RenderToggleBox(toggleName, toggleText, toggleCallback, toggleBool)
    local booltext = toggleBool and "Yes" or "No"
    return I.DaisyUtilsUI_AA.boxedTextContent(
        (toggleText or toggleName) .. ": " .. booltext,
        async:callback(toggleCallback),
        0.8,
        toggleName
    )
end

local function RenderBox(name, text, cb)
    return I.DaisyUtilsUI_AA.boxedTextContent(text or name, async:callback(cb), 0.8, name)
end

-- Handle toggle clicks in the config window
local function ToggleTableItem(_, widget)
    local name = widget and widget.props and (widget.props.name or widget.props.text) or ""
    if name == "DoneButton" then
        if ConfigSettlementBox then
            ConfigSettlementBox:destroy()
            ConfigSettlementBox = nil
        end
        I.UI.setMode()
        return
    elseif name == "RenameButton" then
        if ConfigSettlementBox then
            ConfigSettlementBox:destroy()
            ConfigSettlementBox = nil
        end
        renameWindow = I.DaisyUtilsUI_AA.renderTextInput(
            { "", "", "What would you like this building to be named?" },
            "", -- start empty; textChanged will capture input
            textChanged,
            buttonClickRename
        )
        return
    end

    -- Flip the matching race/gender tag and propagate to global state
    for _, race in ipairs(raceList) do
        if race.keyName == name then
            race.state = not race.state
            local event = race.state and "addSettlementTagEvent" or "removeSettlementTagEvent"
            core.sendGlobalEvent(event, { settlementId = currentSettlement, tagName = race.keyName })
            break
        end
    end

    -- Re-render window to reflect change
    if ConfigSettlementBox then
        ConfigSettlementBox:destroy()
    end
    ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
end

-- Main config window
local function renderTextInput(settlementId)
    -- lookup settlement
    local mySettle, settlerCount = nil, 0
    bedCount, maxSettlers = 0, maxSettlers or 0
    local list = settlementModData:get("settlementList") or {}
    for _, s in ipairs(list) do
        if s.markerId == settlementId then
            mySettle = s
            bedCount = #(s.settlementBedIds or {})
            settlerCount = #(s.settlementNPCs or {})
            break
        end
    end
    if not mySettle then
        ui.showMessage("Settlement not found.")
        return
    end

    if ConfigSettlementBox then
        ConfigSettlementBox:destroy()
    end

    -- tag states
    local validRaceCount, validGender = 0, false
    for _, race in ipairs(raceList) do
        race.state = HasSettlementTag(settlementId, race.keyName)
        if (race.keyName == "allow_female" or race.keyName == "allow_male") and race.state then
            validGender = true
        elseif race.state then
            validRaceCount = validRaceCount + 1
        end
    end

    -- sizing
    local screenW = ui.layers[1].size.x
    local winW = math.max(320, math.min(420, math.floor(screenW * 0.35)))

    local content = {}
    table.insert(content, I.DaisyUtilsUI_AA.textContent("Settings: " .. (mySettle.settlementName or "")))
    table.insert(content, I.DaisyUtilsUI_AA.textContentLeft("Beds: " .. tostring(bedCount)))
    table.insert(content, I.DaisyUtilsUI_AA.textContentLeft("Settlers: " .. tostring(settlerCount)))

    -- desired settlers counter row
    table.insert(content, I.DaisyUtilsUI_AA.textContentLeft("Desired settlers:"))
    table.insert(content, {
        type = ui.TYPE.Flex,
        props = { horizontal = true, align = ui.ALIGNMENT.Center },
        content = ui.content {
            I.DaisyUtilsUI_AA.boxedTextContent("-", async:callback(decreaseSettlers)),
            I.DaisyUtilsUI_AA.textContent("  " .. tostring(maxSettlers) .. "  "),
            I.DaisyUtilsUI_AA.boxedTextContent("+", async:callback(increaseSettlers)),
        }
    })

    -- gender toggles side by side
    local femaleToggle, maleToggle
    for _, r in ipairs(raceList) do
        if r.keyName == "allow_female" then
            femaleToggle = RenderToggleBox(r.keyName, r.buttonText, ToggleTableItem, r.state)
        elseif r.keyName == "allow_male" then
            maleToggle = RenderToggleBox(r.keyName, r.buttonText, ToggleTableItem, r.state)
        end
    end
    table.insert(content, {
        type = ui.TYPE.Flex,
        props = { horizontal = true, align = ui.ALIGNMENT.Center },
        content = ui.content { femaleToggle, maleToggle }
    })

    -- race toggles in a simple vertical list (compact and works with Start alignment)
    for _, r in ipairs(raceList) do
        if r.keyName ~= "allow_female" and r.keyName ~= "allow_male" then
            table.insert(content, RenderToggleBox(r.keyName, r.buttonText, ToggleTableItem, r.state))
        end
    end

    -- warnings
    if (validRaceCount == 0) or (not validGender) then
        table.insert(content, I.DaisyUtilsUI_AA.textContentLeft("⚠ Current config allows no settlers."))
    end

    -- footer buttons
    table.insert(content, {
        type = ui.TYPE.Flex,
        props = { horizontal = true, align = ui.ALIGNMENT.Center },
        content = ui.content {
            RenderBox("RenameButton", "Rename", ToggleTableItem),
            RenderBox("DoneButton", "OK", ToggleTableItem),
        }
    })

    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            vertical = false,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.Start,
                    size = util.vector2(winW, 10),
                    padding = 8,
                },
                content = ui.content(content)
            }
        }
    }
end

local function showSettlementConfig(settlementId)
    currentSettlement = settlementId
    -- Spawn a creature? (kept as in original)
    I.DaisyUtilsAA.createItem("AA_TRAVELCREATURE", self.cell, self.position)

    ConfigSettlementBox = renderTextInput(currentSettlement)
    I.UI.setMode('Interface', { windows = {} })
end

-- Input handler: activate on marker to open config/create
local function onInputAction(id)
    if id ~= input.ACTION.Activate then return end

    local hit = I.DaisyUtilsAA.getObjInCrosshairs()
    local obj = hit and hit.hitObject or nil
    if not obj then
        return
    end

    if obj.recordId ~= "zhac_settlement_marker" then
        return
    end

    -- If this marker already belongs to a settlement, open config
    local list = settlementModData:get("settlementList") or {}
    for _, settlement in ipairs(list) do
        if settlement.markerId == obj.id then
            showSettlementConfig(obj.id)
            return
        end
    end

    -- Prevent creating too close to another marker
    for _, other in ipairs(nearby.activators) do
        if other.recordId == "zhac_settlement_marker" and other ~= obj then
            local dx = other.position.x - obj.position.x
            local dy = other.position.y - obj.position.y
            local dz = other.position.z - obj.position.z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist < 10000 then
                ui.showMessage("This marker is too close to an existing settlement!")
                return
            end
        end
    end

    settlementMarker = obj
    I.UI.setMode('Interface', { windows = {} })
    CreateSettlementBox = I.DaisyUtilsUI_AA.renderTextInput(
        { "", "", "What would you like this settlement to be named?" },
        "",
        textChanged,
        buttonClick
    )
end

-- Exposed helpers
local function createNewSettler(marker)
    if not marker then return end
    core.sendGlobalEvent("addSettlerEvent", {
        settlementId = marker.id,
        position = nearby.findRandomPointAroundCircle(marker.position, 400),
    })
end

local function updateSettlerUi()
    if ConfigSettlementBox then
        ConfigSettlementBox:destroy()
    end
    if currentSettlement then
        ConfigSettlementBox = I.SettlerPlayer.renderTextInput(currentSettlement)
    end
end

local function addActorToSettlement(marker)
    if not marker then return end
    local pos = nearby.findRandomPointAroundCircle(marker.position, 900)
    if not pos then
        error("Unable to find spawn location. Navigator may be disabled")
    end
    core.sendGlobalEvent("addSettlerEvent", {
        settlementId = marker.id,
        position = pos,
    })
end

local function onConsoleCommand(_, command, selectedObject)
    if command == "luasettler" and selectedObject and selectedObject.recordId == "zhac_settlement_marker" then
        core.sendGlobalEvent("addActorToSettlement", selectedObject.id)
    end
end

-- Dialog glue
local function processGreeting(data)
    if not data then return end
    local actor = data.npc
    local jobSiteData = data.jobSiteData
    if not actor then return end

    local actorRecord = types.NPC.record(actor)
    local playerRecord = types.Player.record(self)
    Dialog.sayGreeting(actorRecord, playerRecord, jobSiteData)
end

-- Stubs for optional handlers referenced by engineHandlers
local function onFrame(_) end
local function onSave() end

-- Public API
return {
    interfaceName = "SettlerPlayer",
    interface = {
        version = 1,
        destroyWindow = destroyWindow,
        renderTextInput = renderTextInput,
        createNewSettler = createNewSettler,
    },
    eventHandlers = {
        updateSettlerUi = updateSettlerUi,
        addActorToSettlement = addActorToSettlement,
        UiModeChanged = function(data)
            -- Clean up windows when UI mode closes
            if data.newMode == nil then
                if renameWindow then
                    renameWindow:destroy()
                    renameWindow = nil
                end
                if ConfigSettlementBox then
                    ConfigSettlementBox:destroy()
                    ConfigSettlementBox = nil
                end
                if CreateSettlementBox then
                    CreateSettlementBox:destroy()
                    CreateSettlementBox = nil
                end
            end
        end,
        processGreeting = processGreeting,
    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
        onSave = onSave,
        onConsoleCommand = onConsoleCommand,
    },
}