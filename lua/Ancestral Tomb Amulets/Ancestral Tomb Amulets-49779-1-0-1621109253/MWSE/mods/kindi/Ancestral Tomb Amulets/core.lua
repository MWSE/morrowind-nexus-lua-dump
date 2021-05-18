local data = require("kindi.ancestral tomb amulets.data")
local config = require("kindi.ancestral tomb amulets.config")
local core = {}
core.alternate = false

core.listTheTomb = function()
    local menus = tes3ui.findMenu(ata_kindi_menuId)

    local scroll = menus:findChild(ata_kindi_listId)

    local inputs = menus:findChild(ata_kindi_buttonBlock):findChild(ata_kindi_input)
    local key = inputs.text
    tes3.messageBox(key)
    tombList:destroyChildren()

    for k, v in pairs(data.source) do
        pluginLabel = tombList:createLabel {id = ata_kindi_pluginId}
        pluginLabel.wrapText = true
        pluginLabel.justifyText = "center"
        pluginLabel.font = 2
        if core.alternate then
            pluginLabel.text = ("\n%s\n"):format(k:upper())
        else
            pluginLabel.text = "\nCLICK ON THE TOMB NAME TO TELEPORT\n"
        end

        for y, z in pairs(v) do
            if tes3.player.object.inventory:contains(table.find(data.usedAmulets, z)) and z:lower():match(key:lower()) then
                tombYes = tombList:createButton {id = ata_kindi_labelId2}
                tombYes.width = 400
                tombYes.absolutePosAlignX = 0.5
                tombYes.paddingLeft = 120
                tombYes.paddingRight = 120
                tombYes.text = z
                tombYes.widget.idleActive = tes3ui.getPalette("link_color")
                tombYes.widget.overActive = tes3ui.getPalette("link_over_color")
                tombYes.widget.pressedActive = tes3ui.getPalette("link_pressed_color")
                tombYes.widget.state = 4
                tombYes:register(
                    "mouseClick",
                    function()
                        timer.start {
                            type = timer.real,
                            duration = 0.05,
                            callback = function()
                                local cell = tes3.getCell {id = z}
                                core.teleport(cell, tes3.player)
                                local menu = tes3ui.findMenu(ata_kindi_menuId)
                                if menu then
                                    tes3ui.leaveMenuMode(menu)
                                    menu:destroyChildren()
                                    menu:destroy()
                                end
                            end
                        }
                    end
                )
            elseif core.alternate and not data.usedTombs[z] and z:lower():match(key:lower()) then
                tombNo = tombList:createButton {id = ata_kindi_labelId3}
                tombNo.width = 400
                tombNo.absolutePosAlignX = 0.5
                tombNo.paddingLeft = 120
                tombNo.paddingRight = 120
                tombNo.text = z
                tombNo.widget.state = 2
            elseif
                data.usedTombs[z] and not tes3.player.object.inventory:contains(table.find(data.usedAmulets, z)) and
                    core.alternate and
                    z:lower():match(key:lower())
             then
                tombHalf = tombList:createButton {id = ata_kindi_labelId4}
                tombHalf.width = 400
                tombHalf.absolutePosAlignX = 0.5
                tombHalf.paddingLeft = 120
                tombHalf.paddingRight = 120
                tombHalf.text = z
                tombHalf.widget.idle = {0.8, 0.8, 0}
                tombHalf.widget.over = {1, 1, 0.2}
                tombHalf.widget.pressed = {1, 1, 0.4}
                tombHalf.widget.state = 1
                tombHalf:register(
                    "mouseClick",
                    function()
                        core.goToAmuletRef(z)
                    end
                )
            end
        end
    end

    if core.alternate and key == "" then
        rejectedTombsLabel = tombList:createLabel {id = ata_kindi_rejectedId}
        rejectedTombsLabel.text = ("\n%s Tomb Doors Rejected\n"):format(table.size(data.rejectedTombs))
        rejectedTombsLabel.wrapText = true
        rejectedTombsLabel.justifyText = "center"
        for m, n in pairs(data.rejectedTombs) do
            local rejectedTombs = tombList:createLabel {}
            rejectedTombs.text = m .. " from " .. n .. "\n"
            rejectedTombs.wrapText = true
            rejectedTombs.justifyText = "center"
        end
    end

    local arbitraryHeight = 0
    for i = 0, #tombList.children do
        arbitraryHeight = arbitraryHeight + 35
    end
    --[[had to use this kinda hacky workaround because absolutePosAlignX messes up scrollpane autoheight accuracy//or im just bad at creating uis]]
    tombList.height = arbitraryHeight
    scroll.widget:contentsChanged()
end

core.getNewAmulet = function(id)
    local amulet = tes3.getObject(id)
    local rng = table.choice(data.effects)

    if amulet.enchantment ~= nil then
        amulet.enchantment =
            tes3enchantment.create(
            {
                id = id .. "_ata_ench",
                castType = tes3.enchantmentType.constant,
                chargeCost = 1,
                maxCharge = 1
            }
        )

        amulet.enchantment.effects[1].id = rng
        amulet.enchantment.effects[1].rangeType = tes3.effectRange.self
        amulet.enchantment.effects[1].radius = 0
        amulet.enchantment.effects[1].duration = 0
        amulet.enchantment.effects[1].min = 20
        amulet.enchantment.effects[1].max = 20
        amulet.enchantment.modified = true
    end
	rng = math.random(1, table.size(data.amuletMesh))
    amulet.value = 1000
    amulet.weight = 1.0
    amulet.mesh = data.amuletMesh[rng]
    amulet.icon = data.amuletIcon[rng]

    amulet.modified = true

    return amulet
end

core.setTombTable = function(door)
    for k, v in pairs(data.door) do
        data.tombTable[v] = k
    end

    setmetatable(
        data.tombTable,
        {
            __newindex = function()
                error("cannot write to a readonly property")
            end
        }
    )
    mwse.log(string.format("%s tombs have been set up!", table.size(data.tombTable)))
end

core.setAmuletTable = function()
    for i = 1, 999 do
        local amuletid = "ata_kindi_amulet_" .. i
        if tes3.getObject(amuletid) then
            data.amuletTable[amuletid] = amuletid
        end
    end

    setmetatable(
        data.amuletTable,
        {
            __newindex = function()
                error("cannot write to a readonly property")
            end
        }
    )

    mwse.log(string.format("%s amulets have been set up!", table.size(data.amuletTable)))
end

core.dropBad = function()
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for amulet in cell:iterateReferences(tes3.objectType.clothing) do
            if string.match(amulet.id, "ata_kindi_amulet_") then
                if not data.door[amulet.data.tomb] then
                    tes3.messageBox("Dropping bad reference " .. amulet.id)
                    mwse.log(
                        "[[Ancestral Tomb Amulets log]] ~ Dropping bad reference " ..
                            amulet.id .. " ( " .. amulet.name .. " ) "
                    )
                    mwscript.setDelete {reference = amulet}
                end
            end
        end
        for cont in cell:iterateReferences(tes3.objectType.container, tes3.objectType.actor) do
            for k, amulet in pairs(cont.object.inventory) do
                if string.match(amulet.object.id, "ata_kindi_amulet_") then
                    if not data.door[amulet.variables[1].data.tomb] then
                        tes3.messageBox("Dropping bad reference " .. amulet.object.id)
                        mwse.log(
                            "[[Ancestral Tomb Amulets log]] ~ Dropping bad reference " ..
                                amulet.object.id .. " ( " .. amulet.object.name .. " ) "
                        )
                        tes3.removeItem {reference = cont, item = amulet.object.id, playSound = false}
                    end
                end
            end
        end
    end
    for k, amulet in pairs(tes3.player.object.inventory) do
        if string.match(amulet.object.id, "ata_kindi_amulet_") then
            if not data.door[amulet.variables[1].data.tomb] or not data.amuletTable[amulet.object.id] then
                tes3.messageBox("Dropping bad reference " .. amulet.object.id)
                mwse.log(
                    "[[Ancestral Tomb Amulets log]] ~ Dropping bad reference " ..
                        amulet.object.id .. " ( " .. amulet.object.name .. " ) "
                )
                tes3.removeItem {reference = tes3.player, item = amulet.object.id, playSound = false}
            end
        end
    end
end

core.hardReset = function()
    tes3.messageBox("Reset executing..")
    local instances = 0
    data.usedTombs = {}
    data.usedAmulets = {}
    data.amuletTableTaken = {}
    data.cellTable = {}

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for cloths in cell:iterateReferences(tes3.objectType.clothing) do
            if string.startswith(cloths.id, "ata_kindi_amulet_") then
                mwse.log(cloths.id .. "(" .. cloths.object.name .. ")" .. " has been removed in " .. cell.id)
                cloths.modified = false
                cloths.data.tomb = nil
                mwscript.setDelete {reference = cloths}
                instances = instances + 1
            end
        end
        for instance in cell:iterateReferences(tes3.objectType.actor) do
            if instance.object and instance.object.inventory then
                for k, v in pairs(instance.object.inventory) do
                    if string.startswith(v.object.id, "ata_kindi_amulet_") then
                        mwse.log(v.object.id .. "(" .. v.object.name .. ")" .. " has been removed in " .. cell.id)
                        v.object.modified = false
                        if v.variables then
                            v.variables[1].data.tomb = nil
                        end
                        tes3.removeItem {reference = instance, item = v.object.id}
                        instances = instances + 1
                    end
                end
            end
        end
        for k, amulet in pairs(tes3.player.object.inventory) do
            if string.match(amulet.object.id, "ata_kindi_amulet_") then
                mwse.log(
                    amulet.object.id .. "(" .. amulet.object.name .. ")" .. " has been removed in " .. tes3.player.id
                )
                amulet.object.modified = false
                if amulet.variables then
                    amulet.variables[1].data.tomb = nil
                end
                tes3.removeItem {reference = tes3.player, item = amulet.object.id}
                instances = instances + 1
            end
        end
    end
    mwse.log("Ancestral Tomb Amulet resetting.. " .. instances .. " instances has been deleted")
    tes3.messageBox("Reset complete! Full info in mwse.log")
end

core.tombList = function(tombTable)
    for k, v in pairs(tombTable) do
        if v.destination then
            data.source[v.destination.cell.sourceMod] = {}
        end
    end

    for k, v in pairs(data.source) do
        for y, z in pairs(tombTable) do
            if z.destination and z.destination.cell.sourceMod == k then
                table.insert(v, z.destination.cell.id)
            end
        end
    end

    for k, v in pairs(data.tombExtra) do
        local cell = tes3.getCell {id = k}
        if cell then
            local sourcemod = cell.sourceMod
            table.insert(data.source[sourcemod], k)
        end
    end

    for k, v in pairs(data.source) do
        table.sort(
            v,
            function(a, b)
                return a:lower() < b:lower()
            end
        )
    end

end

core.teleport = function(cell, equipor)
    if not equipor then
        return
    end

    if not cell and equipor == tes3.player.mobile then
        tes3.messageBox("There is no tomb associated with this family")
        return
    end

    local canTeleport = not tes3.worldController.flagTeleportingDisabled
    if not canTeleport then
        tes3.messageBox("A mysterious force prevents the amulet's magic")
        return
    end

    if cell and canTeleport then
        tes3.messageBox(("Teleporting to %s"):format(cell))

        timer.start {
            type = timer.real,
            duration = 0.1,
            callback --[[using a short timer because tes3.positioncell bugs sometimes]] = function()
                tes3.playSound {sound = "conjuration hit"}
                local tombDoor = table.find(data.tombTable, cell.name)
                local orientation
                local position

                if data.tombExtra[cell.name] then
                    orientation = data.tombExtra[cell.name]["rotation"]
                    position = data.tombExtra[cell.name]["position"]
                elseif tombDoor.destination then
                    orientation = tombDoor.destination.marker.orientation
                    position = tombDoor.destination.marker.position
                end
                tes3.positionCell {
                    cell = cell,
                    orientation = orientation,
                    position = position,
                    reference = equipor,
                    teleportCompanions = false --[[otherwise #INFO or #INDO error may occur]]
                }
            end
        }
    end
end

core.amuletCreation = function(cell)
    local tempTable = {}
    local tempTable2 = {}
    local luckyTomb
    local amuletId
    local newAmulet
    local n = 0
    local aggrate = 0
    local chance = tonumber(config.chance)

    if config.dangerFactor then
        for ref in cell:iterateReferences(tes3.objectType.actor) do
            if
                ref.mobile and ref.mobile.fight > 70 and ref.mobile.health.current > 0 and
                    tes3.getCurrentAIPackageId({reference = ref}) ~= 3
             then
                if (ref.object.type == tes3.creatureType.daedra or ref.object.type == tes3.creatureType.humanoid) then
                    aggrate = aggrate + 3
                elseif (ref.object.type == tes3.creatureType.undead or (ref.id):match("centurion")) then
                    aggrate = aggrate + 2
                else
                    aggrate = aggrate + 1
                end
            end
        end
    end

    if aggrate >= 13 then
        chance = chance + 15
    elseif aggrate > 3 then
        chance = chance + 7.5
    end

    chance = chance + data.plusChance
    data.plusChance = 0

    if math.random(100) > math.floor(chance) then
        return
    end

    for container in cell:iterateReferences(tes3.objectType.container) do
        if
            not container.object.organic and not container.object.respawns and
                (not container.object.script or config.affectScripted)
         then
            --tempTable[container] = container
			table.insert(tempTable, container)
        end
    end

    if table.size(tempTable) < 1 --[[if cell has no container, end the creation process]] then
        return
    end

    if
        table.size(data.usedAmulets) >= table.size(data.amuletTable) or
            table.size(data.usedTombs) >= table.size(data.tombTable)
     then
        return
    end

    local luckyContainer = table.choice(tempTable)

    for _, amulet in pairs(data.waitCont.object.inventory) do
        table.insert(tempTable2, amulet.object.id)
    end

	if config.showSpawn then
        tes3.messageBox("The amulet is generated in " .. luckyContainer.object.name)
    end

    if math.random(100) < 50 and #tempTable2 > 0 then
        tes3.transferItem {
            from = data.waitCont,
            to = luckyContainer,
            item = table.choice(tempTable2),
            playSound = false
        }
        return
    end

    repeat
        luckyTomb = table.choice(data.tombTable)
    until data.usedTombs[luckyTomb] == nil
    repeat
        n = n + 1
        amuletId = "ata_kindi_amulet_" .. n
    until data.usedAmulets[amuletId] == nil

    local newAmulet = core.getNewAmulet(amuletId)

    newAmulet.name = luckyTomb .. " Amulet"

    local tempstr
    if luckyTomb then
        tempstr = string.match(luckyTomb, "%a+")
    end

    if data.tooltipsComplete then
        if data.customAmuletTooltip[luckyTomb] then
            data.tooltipsComplete.addTooltip(
                tostring(newAmulet.id),
                string.format("%s", data.customAmuletTooltip[luckyTomb])
            )
        elseif tempstr then
            data.tooltipsComplete.addTooltip(
                tostring(newAmulet.id),
                string.format("An heirloom of the %s family", tempstr)
            )
        end
    end

    tes3.addItem {reference = luckyContainer, item = newAmulet, playSound = false}

    local datas = tes3.addItemData {to = luckyContainer, item = tes3.getObject(newAmulet.id)}
    datas.data.tomb = luckyTomb
    data.usedAmulets[amuletId] = luckyTomb
    data.usedTombs[luckyTomb] = luckyTomb

    tempTable = nil
end

core.goToAmuletRef = function(z)
    local a = table.find(data.usedAmulets, z)
    local loc
    local s
    local refs

    if not tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode) then
        tes3.messageBox("This amulet exists but it is not in your inventory")
        return
    end
	--[[this is not optimized, only used for cheating afterall]]
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for ref in cell:iterateReferences() do
            if (ref.object.inventory and ref.object.inventory:contains(a)) or ref.id == a then
                loc = ref.cell
                refs = ref
                s = ("This amulet is located in %s"):format(loc)
                tes3.messageBox(s)
            end
        end
    end

    if tempclickatakindi and tempclickatakindi > 3 then
        tes3.positionCell {
            cell = loc,
            position = refs.position,
            orientation = refs.orientation,
            teleportCompanions = false
        }
        tes3ui.findMenu(ata_kindi_menuId):destroy()
        tes3ui.leaveMenuMode()
        tempclickatakindi = false
        return
    end
    tempclickatakindi = tempclickatakindi or 1
    tempclickatakindi = tempclickatakindi + 1
    tempclickatatimerkindi =
        timer.start {
        type = timer.real,
        duration = 1,
        callback = function()
            tempclickatakindi = 0
        end
    }
end

core.showTombList = function(mari_kita_beramput)
    tes3ui.getMenuOnTop():destroy()
    core.alternate = mari_kita_beramput or tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode)

    local inventoryAmulets = 0

    for k, v in pairs(tes3.player.object.inventory) do
        if string.startswith(v.object.id, "ata_kindi_amulet_") and data.usedAmulets[v.object.id] then
            inventoryAmulets = inventoryAmulets + 1
        end
    end

    menu = tes3ui.createMenu({id = ata_kindi_menuId, dragFrame = true, fixedFrame = false})
    menu.text = "Table of Ancestral Tomb Amulets"
    menu.width = 400
    menu.height = 700
    menu.minWidth = 400
    menu.minHeight = 700
    menu.maxWidth = 400
    menu.positionX = menu.width / -2
    menu.positionY = menu.height / 2
    menu.alpha = 1
    menu.wrapText = true
    menu.justifyText = "center"

    blockBar = menu:createBlock {id = ata_kindi_blockBarId}
    blockBar.autoWidth = true
    blockBar.autoHeight = true
    blockBar.flowDirection = "top_to_bottom"
    blockBar.widthProportional = 1.0
    blockBar.borderAllSides = 1

    counter = blockBar:createLabel {id = ata_kindi_counterId}
    counter.text = ("%s Amulets is in your inventory\n\n"):format(inventoryAmulets --[[table.size(amuletTableTaken)]])
    counter.wrapText = true
    counter.justifyText = "center"

    bar = blockBar:createFillBar {id = ata_kindi_barId, current = inventoryAmulets, max = table.size(data.door)}
    bar.widget.fillColor = {0.6, 0.3, 0}
    bar.widget.fillAlpha = 0.5
    bar.absolutePosAlignX = 0.5
    bar.absolutePosAlignY = 1
    bar.borderAllSides = 8

    divider = menu:createDivider {}

    list = menu:createVerticalScrollPane({id = ata_kindi_listId})
    list.wrapText = true
    list.justifyText = "center"

    tombList = list:createBlock({id = ata_kindi_tombList})
    tombList.autoWidth = true
    --[[tombList.autoHeight = true doesnt accurately adjust height if absoluteposalign is used   ]]
    tombList.flowDirection = "top_to_bottom"
    tombList.widthProportional = 1.0
    tombList.borderAllSides = 3
    tombList.wrapText = true

    buttonBlock = menu:createBlock {id = ata_kindi_buttonBlock}
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.widthProportional = 1.0
    buttonBlock.height = 32
    buttonBlock.borderTop = 3
    buttonBlock.autoWidth = true
    buttonBlock.autoHeight = true

    closeButton = buttonBlock:createButton {id = ata_kindi_buttonClose}
    closeButton.text = "Close"
    closeButton:register(
        "mouseClick",
        function()
            local menu = tes3ui.findMenu(ata_kindi_menuId)
            if menu then
                tes3ui.leaveMenuMode()
                core.alternate = false
                menu:destroyChildren()
                menu:destroy()
            end
        end
    )

    input = buttonBlock:createTextInput {id = ata_kindi_input}
    input.borderLeft = 5
    input.borderRight = 5
    input.borderTop = 2
    input.borderBottom = 4
    input.font = 1
    input.widget.lengthLimit = nil
    input.widget.eraseOnFirstKey = true
    input:register(
        "keyPress",
        function(e)
            input:forwardEvent(e)
            local key = e.data0
            core.listTheTomb()
        end
    )

    buttonBlock:register(
        "mouseClick",
        function()
            tes3ui.acquireTextInput(input)
        end
    )

    input.consumeMouseEvents = false
    core.listTheTomb()
    tes3ui.enterMenuMode(ata_kindi_menuId)
    menu:updateLayout()
    tes3ui.acquireTextInput(input)
end

core.cheat = function()
    for i = 1, table.size(data.tombTable) do
        local itemid = "ata_kindi_amulet_" .. i
        tes3.addItem {reference = tes3.player, item = itemid}
        tes3.messageBox(itemid .. " added!")
        count = i
    end

    tes3.messageBox(string.format("%s amulets added for %s tombs", count, table.size(data.tombTable)))
end

return core
