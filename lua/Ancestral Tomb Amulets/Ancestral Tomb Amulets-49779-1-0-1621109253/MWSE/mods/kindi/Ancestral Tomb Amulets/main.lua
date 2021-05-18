local config
local once = false
local data = require("kindi.ancestral tomb amulets.data")
local core = require("kindi.ancestral tomb amulets.core")

--[[gives a choice whether to teleport or to just equip the amulet]]
local function amuletEquipped(this)
    if not string.startswith(this.item.id, "ata_kindi_amulet_") then
        return
    end
    local item = this.item
    local equipor = this.mobile
    local itemdata = this.itemData
    local fallbackTomb = data.usedAmulets[this.item.id]
    if not fallbackTomb then
        for _, amulet in pairs(equipor.object.inventory) do
            if string.startswith(amulet.object.id, "ata_kindi_amulet_") then
                local data = tes3.addItemData {to = equipor.reference, item = amulet.object.id}
                repeat
                    fallbackTomb = table.choice(data.tombTable)
                until data.usedTombs[fallbackTomb] == nil

                amulet.variables[1].data.tomb = fallbackTomb

                core.getNewAmulet(this.item.id)
                tes3.messageBox(amulet.variables[1].data.tomb)

                this.item.name = fallbackTomb .. " Amulet"
                data.usedAmulets[this.item.id] = fallbackTomb
                data.usedTombs[fallbackTomb] = fallbackTomb

                if equipor.object.objectType == tes3.objectType.npc then
                    equipor:unequip {item = this.item.id}
                    equipor:equip {item = this.item.id}
                end
            end
        end
    end

    if not itemdata then
        return
    end

    local cell = tes3.getCell {id = itemdata.data.tomb}
    if equipor == tes3.player.mobile then
        data.amuletTableTaken[this.item.id] = itemdata.data.tomb
        tes3.messageBox {
            message = itemdata.data.tomb,
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

--[[collects all tomb when the game is started]]
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

    core.setAmuletTable()
    core.setTombTable(data.door)
    core.tombList(data.door)

	for c in tes3.getCell{id = "atakindidummycell"}:iterateReferences() do
	if c.id == "ata_kindi_dummy_crate" then
	data.waitCont = c
	mwse.log("ATA storage has been set up!")
	break
	end
	end



    mwse.log("[Ancestral Tomb Amulets] Initialized")
end

local function amuletCreationCellRecycle(e)

	if not config.modActive then return end

	if config.removeRecycle and data.plusChance == 0 and e.previousCell then
	for cont in e.previousCell:iterateReferences(tes3.objectType.container) do
		for k, v in pairs(cont.object.inventory) do
			if (v.object.id):match("ata_kindi_amulet_") and not data.amuletTableTaken[v.object.id] then
				tes3.transferItem{from = cont, to = "ata_kindi_dummy_crate", item = v.object.id, playSound = false}

				data.plusChance = 10
			end
		end
	end
	end

	if not e.previousCell then return end

	if tes3.findGlobal("ChargenState").value ~= -1 then
		return
	end

    if not e.cell.isInterior then
        return
    end

    if table.find(data.cellTable, e.cell.id) then
        return
    end

    --[[lazy mans way to prevent cell spamming]]
    --[[if cell visited becomes more than n, the oldest cell can roll again]]
    table.insert(data.cellTable, e.cell.id)

    while table.size(data.cellTable) > tonumber(config.maxCycle) do
        if config.showReset then
            tes3.messageBox(data.cellTable[1] .. " can roll again")
        end
        table.remove(data.cellTable, 1)
    end

    core.amuletCreation(e.cell)
end

--[[when the player obtains the amulet, we collect and set some data]]
local function setDataforAmuletsInPlayerInventory(this)
    --[[if tes3.onMainMenu then return end//necessary?]]

    local luckyTomb
    local amuletId



    for k, v in pairs(tes3.player.object.inventory) do
        if string.startswith(v.object.id, "ata_kindi_amulet_") then
            amuletId = v.object.id
            if data.usedAmulets[v.object.id] == nil then

                repeat
                    luckyTomb = table.choice(data.tombTable)
                until data.usedTombs[luckyTomb] == nil

                data.usedAmulets[v.object.id] = luckyTomb
                data.usedTombs[luckyTomb] = luckyTomb

                core.getNewAmulet(v.object.id)
                local data = tes3.addItemData {to = tes3.player, item = v.object.id}
                v.object.name = luckyTomb .. " Amulet"

                v.variables[1].data.tomb = luckyTomb
            end
            if data.tooltipsComplete and not once then
                if data.customAmuletTooltip[v.variables[1].data.tomb] then
                    data.tooltipsComplete.addTooltip(
                        tostring(amuletId),
                        string.format("%s", data.customAmuletTooltip[data.usedAmulets[amuletId]])
                    )
                elseif data.usedAmulets[amuletId] then
                    data.tooltipsComplete.addTooltip(
                        tostring(amuletId),
                        string.format("An heirloom of the %s family", string.match(data.usedAmulets[amuletId], "%a+"))
                    )
                end
            end
            data.amuletTableTaken[amuletId] = amuletId
        end
    end

	once = true --[[tooltip will be generated once every new game session]]

    local _ = this.target or this.reference

    if _ == nil then
        return
    end

    if string.startswith(_.id, "ata_kindi_amulet_") then
        data.amuletTableTaken[_.id] = _.id or _.data.tomb
    end
end

--[[check whether the ESM file is loaded and loads json files if any]]
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
    data.usedAmulets = toLoadData["usedAmulets"] or {}
    data.usedTombs = toLoadData["usedTombs"] or {}
    data.amuletTableTaken = toLoadData["amuletTableTaken"] or {}


	core.dropBad() --[[this function will drop//remove bad amulet references if no associated tomb for it is found in the game]]
end

--[[saves data]]
local function saveData(saved)
    local fileName = string.sub(saved.filename, 0, -5)

    local toSaveData = {}
    toSaveData["cellTable"] = data.cellTable
    toSaveData["usedAmulets"] = data.usedAmulets
    toSaveData["usedTombs"] = data.usedTombs
    toSaveData["amuletTableTaken"] = data.amuletTableTaken

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
