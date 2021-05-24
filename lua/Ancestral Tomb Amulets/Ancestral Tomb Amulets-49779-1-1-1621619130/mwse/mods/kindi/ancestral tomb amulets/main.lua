local config
local data = require("kindi.ancestral tomb amulets.data")
local core = require("kindi.ancestral tomb amulets.core")
local dial = require("kindi.ancestral tomb amulets.dialogue")
local LSID = {}

local curC = nil

local function giveSecretHint(e)
    if tes3.onMainMenu() then
        return
    end
    if not tes3.menuMode() then
        return
    end

    if not config.littleSecret or not config.modActive then
        return
    end

    if not tes3ui.findMenu("MenuDialog") then
        return
    end --[[only want infoGetText to trigger inside dialogue window]]

    local temp = {}
    local temp2 = {}
    local town = tes3.getPlayerCell().id:match("[^,]+")
    local actor = tes3ui.getServiceActor().reference
    local cell = tes3.getCell {id = town}
    if not cell then
        return
    end
    if curC and town:match(curC) then
        return
    end

    for _, cells in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if string.startswith(cells.id, town) then
            table.insert(temp2, cells.id)
        end
    end

    for k, v in pairs(temp2) do
        for npc in tes3.getCell {id = v}:iterateReferences(tes3.objectType.npc) do
            if
                npc.mobile and npc.mobile.health.current > 0 and npc.mobile.fight <= 70 and
                    npc.object.class.id ~= "Guard" and
                    npc.object.class.id ~= "Slave" and
                    not npc.object.name:match("Guard") and
                    not npc.object.isRespawn and
                    npc ~= actor
             then
                if not tes3.getPlayerCell().isInterior or npc.cell ~= tes3.getPlayerCell() then
                    table.insert(temp, npc)
                end
            end
        end
    end

    if not next(temp) then
        return
    end

    local npc = table.choice(temp)
    local female = npc.object.female
    local name = npc.object.name
    local hasItem

    if npc.data and npc.data.ATA_GIVEN_AMULET == true then
        return
    end

    for k, v in pairs(npc.object.inventory) do
        if v.object.id:match("ata_kindi_amulet_") then
            return
        end
    end

    if LSID[e.info.id] == true and #data.waitCont.object.inventory > 0 then
        local text = dial.secret[math.random(#dial)]
        if female then
            text = text:gsub("%w+", {his = "her", he = "she", him = "her"})
        end
        text = text:gsub("ACTOR", name)
        e.text = text

        local tempinv = {}
        for k, v in pairs(data.waitCont.object.inventory) do
            table.insert(tempinv, v.object.id)
        end
        local item = table.choice(tempinv)

        tes3.transferItem {from = data.waitCont, to = npc, item = item, playSound = false}
        npc.data.ATA_GIVEN_AMULET = true
        curC = tes3.getPlayerCell().id:match("[^,]+")
        tes3.messageBox("Amulet location hint!")
    end
end

local function amuletEquipped(this)
    if not string.startswith(this.item.id, "ata_kindi_amulet_") then
        return
    end
    local item = this.item
    local equipor = this.mobile
    local itemdata = this.itemData
    local cell

    if itemdata and itemdata.data and itemdata.data.tomb then
        cell = itemdata.data.tomb
    end

    if not cell then
        cell = tes3.getCell {id = this.item.name:sub(0, -8)}.id
    end

    if equipor == tes3.player.mobile then
        data.amuletTableTaken[this.item.id] = this.item.name:sub(0, -8)
        tes3.messageBox {
            message = this.item.name:sub(0, -8),
            buttons = {"Teleport", "Equip"},
            callback = function(e)
                if e.button == 0 then
                    equipor:unequip {item = item}
                    core.teleport(cell, equipor)
                    equipor = nil
                end
            end
        }
    elseif cell and equipor ~= tes3.player.mobile then
        equipor:unequip {item = item}
        core.teleport(cell, equipor)
        equipor = nil
    end
end

local function initialization()
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for doors in cell:iterateReferences(tes3.objectType.door) do
            if
                doors.destination and doors.destination.cell and doors.destination.cell.name and
                    string.match(doors.destination.cell.name, "Ancestral Tomb")
             then
                if not string.match(doors.destination.cell.name, ", ") and not doors.cell.isInterior then
                    data.door[doors.destination.cell.name] = doors
                elseif not data.tombExtra[doors.destination.cell.name] then
                    data.rejectedTombs[doors.destination.cell.name] = doors.cell.name
                end
            end
        end
    end
    for k, v in pairs(data.tombExtra) do
        if tes3.getCell {id = k} then
            data.door[k] = k
        end
    end
    print(string.format("[[Ancestral Tombs Amulet]] found %s Ancestral Tombs. Setting up mod..", table.size(data.door))) --[[should be 88 for goty]]

    core.setTombTable()
    core.tombList(data.door)

    for c in tes3.getCell {id = "atakindidummycell"}:iterateReferences() do
        if c.id == "ata_kindi_dummy_crate" then
            data.waitCont = c
            mwse.log("ATA storage has been set up!")
            break
        end
    end

    for k, v in pairs(tes3.dataHandler.nonDynamicData.dialogues) do
        if v.id == "little secret" then
            for i = 1, #v.info do
                if table.find(dial.replaceSecret, v.info[i].text) then
                    LSID[v.info[i].id] = true
                    break
                end
            end
        end
    end

    if table.size(LSID) < 1 then
        error("Little secret gameplay option cannot work because vanilla topic response has been altered.")
    end

    event.register("infoGetText", giveSecretHint)

    mwse.log("[Ancestral Tomb Amulets] Initialized")
end

local function amuletCreationCellRecycle(e)
    if not config.modActive then
        return
    end

    local thisCell = e.cell or e

    if config.removeRecycle and data.plusChance == 0 and e.previousCell then
        for cont in e.previousCell:iterateReferences(tes3.objectType.container) do
            for k, v in pairs(cont.object.inventory) do
                if (v.object.id):match("ata_kindi_amulet_") and not data.amuletTableTaken[v.object.id] then
                    tes3.transferItem {from = cont, to = data.waitCont, item = v.object.id, playSound = false}

                    data.plusChance = 10
                end
            end
        end
    end

    if not e.previousCell then
        return
    end

    if config.tombRaider and data.waitCont.object.inventory:contains(data.amuletTable[thisCell.id]) then
        table.removevalue(data.cellTable, thisCell.id)
    end

    if tes3.findGlobal("ChargenState").value ~= -1 then
        return
    end

    if not thisCell.isInterior then
        return
    end

    if table.find(data.cellTable, thisCell.id) then
        return
    end

    table.insert(data.cellTable, thisCell.id)

    while table.size(data.cellTable) > tonumber(config.maxCycle) do
        if config.showReset then
            tes3.messageBox(data.cellTable[1] .. " can roll again")
        end
        table.remove(data.cellTable, 1)
    end

    core.amuletCreation(thisCell)
end

local function setDataforAmuletsInPlayerInventory(this)
    --[[if tes3.onMainMenu then return end//necessary?]]
    if not tes3.player then
        return
    end
    local luckyTomb
    local amuletId

    for k, v in pairs(tes3.player.object.inventory) do
        if string.startswith(v.object.id, "ata_kindi_amulet_") then
            local datas = tes3.addItemData {to = tes3.player, item = v.object.id}

            if tes3.getCell {id = v.object.name:sub(0, -8)} then
                v.variables[1].data.tomb = v.object.name:sub(0, -8)
                data.amuletTableTaken[v.object.id] = v.variables[1].data.tomb
            end
        end
    end

    local _ = this.target or this.reference

    if _ == nil then
        return
    end

    if string.startswith(_.id, "ata_kindi_amulet_") then
        data.amuletTableTaken[_.id] = _.object.name:sub(0, -8)
    end
end

local function loadDataAndCheckMod(loaded)
    if not tes3.isModActive("Ancestral Tomb Amulets.esm") then
        tes3.messageBox {
            message = "[Ancestral Tomb Amulets] mod is missing the ESM, please ensure the mod is installed properly.",
            buttons = {tes3.findGMST(26).value}
        }
    end
    local fileName = loaded.filename

    local toLoadData = mwse.loadConfig("ata_kindi_data") or {}
    toLoadData = toLoadData[fileName] or {}
    data.cellTable = toLoadData["cellTable"] or {}
    data.amuletTableTaken = toLoadData["amuletTableTaken"] or {}
    data.modifiedAm = toLoadData["modifiedAm"] or {}

    core.chestSetup(data.waitCont)

    mwscript.startScript {script = "Main"}
    curC = nil
end

local function saveData(saved)
    local fileName = string.sub(saved.filename, 0, -5)

    local toSaveData = {}
    toSaveData["cellTable"] = data.cellTable
    toSaveData["amuletTableTaken"] = data.amuletTableTaken
    toSaveData["modifiedAm"] = data.modifiedAm
    local currentData = mwse.loadConfig("ata_kindi_data") or {}
    currentData[fileName] = toSaveData
    mwse.saveConfig("ata_kindi_data", currentData)
end

local function openList(k)
    if tes3.menuMode() or tes3.onMainMenu() then
        return
    end

    if config.hotkey and k.keyCode == config.hotkeyOpenTable.keyCode then
        core.showTombList()
    end
end

local function closeAtaTableRC()
    local todd = tes3ui.findMenu(ata_kindi_menuId)
    if todd then
        core.alternate = false
        todd:destroy()
    end
end

event.register(
    "modConfigReady",
    function()
        require("kindi.ancestral tomb amulets.mcm")
        config = require("kindi.ancestral tomb amulets.config")
    end
)

--[[local function getall()
    for a in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do
        for k, v in pairs(a.object.inventory) do
            if v.object.id:match("ata_kindi_amulet") then
                tes3.transferItem {from = a, to = tes3.player, item = v.object.id, playSound = true}
            end
        end
    end
    amuletCreationCellRecycle(tes3.getPlayerCell())
end

event.register("keyDown", getall, {filter = tes3.scanCode.g})]]
event.register("menuExit", closeAtaTableRC)
event.register("keyDown", openList)
event.register("saved", saveData)
event.register("loaded", loadDataAndCheckMod)
event.register("cellChanged", amuletCreationCellRecycle)
event.register("initialized", initialization)
event.register("equipped", amuletEquipped)
event.register("menuExit", setDataforAmuletsInPlayerInventory)
event.register("menuEnter", setDataforAmuletsInPlayerInventory)
event.register("itemDropped", setDataforAmuletsInPlayerInventory)
event.register("activate", setDataforAmuletsInPlayerInventory)
