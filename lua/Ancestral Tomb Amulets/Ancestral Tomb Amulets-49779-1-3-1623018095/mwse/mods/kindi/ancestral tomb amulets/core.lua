local data = require("kindi.ancestral tomb amulets.data")
local config = require("kindi.ancestral tomb amulets.config")
local core = {}
core.alternate = false
core.doorxmod = {}
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

        local insideDummy = {}
        local outsideDummy = {}
        local insidePlayer = {}

        for k, v in pairs(data.waitCont.object.inventory) do
            insideDummy[v.variables[1].data.tomb] = v.object.id
        end

        for k, v in pairs(data.amuletTable) do
            if not insideDummy[k] then
                outsideDummy[k] = v
            end
        end

        for k, v in pairs(tes3.player.object.inventory) do
            if v.object.id:match("ata_kindi_amulet_") then
                if v.variables and v.variables.data and v.variables.data.tomb then
                    insidePlayer[v.variables[1].data.tomb] = v.object.id
                else
                    insidePlayer[v.object.name:sub(0, -8)] = v.object.id
                end
            end
        end

        for y, z in pairs(v) do
            if insidePlayer[z] and z:lower():match(key:lower()) then
                local tombB = tombList:createBlock {}
                tombB.autoWidth = true
                tombB.height = 35
                tombB.absolutePosAlignX = 0.5
                tombB.paddingLeft = 120
                tombB.paddingRight = 120
                tombYes = tombB:createTextSelect {}
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
                                local cell = z
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
            elseif core.alternate and insideDummy[z] and z:lower():match(key:lower()) then
                local tombB1 = tombList:createBlock {}
                tombB1.autoWidth = true
                tombB1.height = 35
                tombB1.absolutePosAlignX = 0.5
                tombB1.paddingLeft = 120
                tombB1.paddingRight = 120
                tombNo = tombB1:createTextSelect {}
                tombNo.text = z
                tombNo.widget.state = 2
                tombNo:register(
                    "mouseClick",
                    function()
                        if
                            tes3.worldController.inputController:isKeyDown(tes3.scanCode.lCtrl) and
                                tes3.worldController.inputController:isKeyDown(tes3.scanCode.lAlt)
                         then
                            tes3.transferItem {
                                from = data.waitCont,
                                to = tes3.player,
                                item = insideDummy[z],
                                playSound = true
                            }
                            core.listTheTomb()
                        end
                    end
                )
            end
            if outsideDummy[z] and not insidePlayer[z] and core.alternate and z:lower():match(key:lower()) then
                local tombB2 = tombList:createBlock {}
                tombB2.autoWidth = true
                tombB2.height = 35
                tombB2.absolutePosAlignX = 0.5
                tombB2.paddingLeft = 120
                tombB2.paddingRight = 120
                tombHalf = tombB2:createTextSelect {}
                tombHalf.text = z
                tombHalf.widget.idle = {0.8, 0.8, 0}
                tombHalf.widget.over = {1, 1, 0.2}
                tombHalf.widget.pressed = {1, 1, 0.4}
                tombHalf.widget.state = 1
                tombHalf:register(
                    "mouseClick",
                    function()
                        core.goToAmuletRef(outsideDummy[z])
                    end
                )
                tombHalf:register(
                    "mouseOver",
                    function()
                        if tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode) then
                            core.amuletInfoCheat(outsideDummy[z])
                        end
                    end
                )
            end
        end
    end

    if core.alternate and key == "" then
        rejectedTombsLabel = tombList:createLabel {}
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

    scroll.widget:contentsChanged()
end

core.getNewAmulet = function(id, luckyTomb)
    local amulet = tes3.getObject(id)
    local rng = table.choice(data.effects)

    if amulet.modified then
        data.modifiedAm[luckyTomb] = id
        return amulet
    end
    if amulet.enchantment ~= nil then
        amulet.enchantment =
            tes3enchantment.create(
            {
                id = id .. "_ata_ench",
                castType = tes3.enchantmentType.constant,
                chargeCost = 1,
                maxCharge = 10
            }
        )
        amulet.enchantment.effects[1].id = rng
        amulet.enchantment.effects[1].rangeType = tes3.effectRange.self
        amulet.enchantment.effects[1].radius = 0
        amulet.enchantment.effects[1].duration = 1
        amulet.enchantment.effects[1].min = 20
        amulet.enchantment.effects[1].max = 20
        amulet.enchantment.modified = true
    end
    rng = math.random(1, table.size(data.amuletMesh))
    amulet.value = 1000
    amulet.weight = 1.0
    amulet.mesh = data.amuletMesh[rng]
    amulet.icon = data.amuletIcon[rng]
    amulet.name = luckyTomb .. " Amulet"
    amulet.modified = true
    data.modifiedAm[luckyTomb] = id
    return amulet
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
                    amulet.modified = false
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
                        amulet.object.modified = false
                        tes3.removeItem {reference = cont, item = amulet.object.id, playSound = false}
                    end
                end
            end
        end
    end
    for k, amulet in pairs(tes3.player.object.inventory) do
        if string.match(amulet.object.id, "ata_kindi_amulet_") then
            if not data.door[amulet.variables[1].data.tomb] then
                tes3.messageBox("Dropping bad reference " .. amulet.object.id)
                mwse.log(
                    "[[Ancestral Tomb Amulets log]] ~ Dropping bad reference " ..
                        amulet.object.id .. " ( " .. amulet.object.name .. " ) "
                )
                amulet.object.modified = false
                tes3.mobilePlayer:unequip {item = amulet.object.id}
                tes3.removeItem {reference = tes3.player, item = amulet.object.id, playSound = false}
            end
        end
    end
end

core.hardReset = function()
    tes3.messageBox("Reset executing..")
    local instances = 0
    data.amuletTableTaken = {}
    data.cellTable = {}
    data.modifiedAm = {}
    data.amuletTable = {}
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        --if cell.id ~= "atakindidummycell" then
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
                tes3.mobilePlayer:unequip {item = amulet.object.id}
                tes3.removeItem {reference = tes3.player, item = amulet.object.id}
                instances = instances + 1
            end
        end
        --end
    end

    core.chestSetup(data.waitCont)

    mwse.log("Ancestral Tomb Amulet resetting.. " .. instances .. " instances has been deleted")
    tes3.messageBox("Reset complete! Full info in mwse.log")
end

core.setTombTable = function()
    for k, v in pairs(data.door) do
        data.tombTable[v] = k
    end

    setmetatable(
        data.tombTable,
        {
            __newindex = function()
                error("readonly property")
            end
        }
    )

    if table.size(data.tombTable) > 999 then
        print("Maximum number of tombs reached, contact author for updates")
        tes3.messageBox {
            message = "[[Ancestral Tomb Amulets]] Maximum number of tombs reached, contact author for updates",
            buttons = {"OK"}
        }
    --os.exit() overKill
    end
    mwse.log(string.format("%s tombs have been set up!", table.size(data.tombTable)))
end

core.tombList = function(tombdoor)
    for k, v in pairs(tombdoor) do
        if v.destination then
            data.source[v.destination.cell.sourceMod] = {}
        end
    end

    for k, v in pairs(data.source) do
        for y, z in pairs(tombdoor) do
            if z.destination and z.destination.cell.sourceMod == k then
                table.insert(v, z.destination.cell.id)

                table.insert(core.doorxmod, y)
            elseif tes3.getCell {id = tostring(z)} and tes3.getCell {id = z}.sourceMod == k then
                table.insert(core.doorxmod, tostring(z))
            else
                data.unusedDoors[y] = z
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

    table.sort(
        core.doorxmod,
        function(a, b)
            return a:lower() < b:lower()
        end
    )
end

core.teleport = function(cell, equipor)
    local cell = tes3.getCell {id = cell}

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
                local tombDoor = table.find(data.tombTable, cell.id)
                local orientation
                local position

                if data.tombExtra[cell.id] then
                    orientation = data.tombExtra[cell.id]["rotation"]
                    position = data.tombExtra[cell.id]["position"]
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
                --local r = mwscript.placeAtPC{reference = equipor, object = "atakinditelevfx", distance = 1}
                if not tes3.getObject("atakinditelevfx") then
                    return
                end
                --[[using delayoneframe because #INFO or #INDO error can happen, unsure what it is. Not 100% reliable but no harm]]
                timer.delayOneFrame(
                    function()
                        local r =
                            tes3.createReference {
                            object = "atakinditelevfx",
                            position = equipor.position,
                            orientation = orientation,
                            cell = cell
                        }
                        r.hasNoCollision = true
                        timer.start {
                            duration = 0.1,
                            iterations = 19,
                            callback = function()
                                r.position = equipor.position
                            end
                        }
                    end
                )
            end
        }
    end
end

core.chestSetup = function(cont)
    local amuletId
    local luckyTomb
    local newAmulet
    local n = 0

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for ref in cell:iterateReferences(tes3.objectType.actor) do
            if ref and ref.object and ref.object.inventory then
                for k, v in pairs(ref.object.inventory) do
                    if v.object.id:match("ata_kindi_amulet_") then
                        data.modifiedAm[v.variables[1].data.tomb] = v.object.id
                        v.object.modified = true
                    end
                end
            end
            if ref and ref.data and ref.data.tomb then
                data.modifiedAm[ref.data.tomb] = ref.object.id
                ref.object.modified = true
            end
        end
    end

    for k, v in pairs(tes3.player.object.inventory) do
        if v.object.id:match("ata_kindi_amulet_") then
            data.modifiedAm[v.variables[1].data.tomb] = v.object.id
            v.object.modified = true
        end
    end

    for k, v in pairs(data.waitCont.object.inventory) do
        data.modifiedAm[v.variables[1].data.tomb] = v.object.id
    end

    for i = 1, #core.doorxmod do
        local amuletid = "ata_kindi_amulet_"

        if not data.modifiedAm[core.doorxmod[i]] then
            repeat
                n = n + 1
                data.newAm[core.doorxmod[i]] = amuletid .. n
            until tes3.getObject(amuletid .. n).modified == false
        end
    end

    table.copymissing(data.amuletTable, data.modifiedAm)
    table.copymissing(data.amuletTable, data.newAm)

    for k, v in pairs(data.newAm) do
        newAmulet = core.getNewAmulet(v, k)

        if not cont.object.inventory:contains(newAmulet.id) and not data.amuletTableTaken[newAmulet.id] then
            tes3.addItem {reference = cont, item = newAmulet.id, playSound = false}

            local datas = tes3.addItemData {to = cont, item = tes3.getObject(newAmulet.id)}
            datas.data.tomb = k
        end
    end

    --using amulet name to set tooltips
    for k, v in pairs(data.amuletTable) do
        local tempstr = tes3.getObject(v).name:sub(0, -8)

        if data.tooltipsComplete then
            if data.customAmuletTooltip[tempstr] then
                data.tooltipsComplete.addTooltip(tostring(v), string.format("%s", data.customAmuletTooltip[tempstr]))
            elseif tempstr then
                data.tooltipsComplete.addTooltip(
                    tostring(v),
                    string.format("An heirloom of the %s family", tempstr:match("%a+"))
                )
            end
        end
    end
end

core.amuletCreation = function(cell)
    local tempTable = {}
    local tempTable2 = {}
    local newAmulet
    local n = 0
    local aggrate = 0
    local chance = tonumber(config.chance)
    local bestCont = 0
    local raiderItem

    for _, amulet in pairs(data.waitCont.object.inventory) do
        --if an amulet has a valid tomb, put inside the table
        if
            table.find(data.amuletTable, amulet.object.id) and
                tes3.getCell {id = table.find(data.amuletTable, amulet.object.id)}
         then
            table.insert(tempTable2, amulet)
        end

        --if this cell is a tomb, get the amulet associated with it for tomb raider gameplay
        if amulet.variables and amulet.variables[1].data and cell.id == amulet.variables[1].data.tomb then
            raiderItem = amulet
			if config.tombRaider then chance = 100 end
        end
    end

    if config.dangerFactor then
        for ref in cell:iterateReferences(tes3.objectType.actor) do
            if
                ref.mobile and ref.mobile.fight > 70 and not ref.mobile.isDead and
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

	if tonumber(config.chance) < 0 then chance = -1 end
    if math.random(100) > chance then
        return
    end

    local tempVar = 0
    for container in cell:iterateReferences(tes3.objectType.container) do
        if
            not container.object.organic and not container.object.respawns and
                (not container.object.script or config.affectScripted)
         then
            --tempTable[container] = container
            if container.object.capacity > tempVar then
                tempVar = container.object.capacity
                bestCont = container
            end
            table.insert(tempTable, container)
        end
    end

    if table.size(tempTable) < 1 then
        return
    end

    --if there is no more amulet to be transferred, end this process
    if #data.waitCont.object.inventory < 1 then
        return
    end

    local luckyContainer
    local luckyAmulet = table.choice(tempTable2)
    if config.useBestCont then
        luckyContainer = bestCont
    else
        luckyContainer = table.choice(tempTable)
    end
    if not luckyAmulet and not luckyAmulet.variables then
        error("No Tomb Data Found! To help improve the mod, submit a bug report in the modpage")
    end

    if config.tombRaider and raiderItem then
        luckyAmulet = raiderItem
    end

    local transferred =
        tes3.transferItem {
        from = data.waitCont,
        to = luckyContainer,
        item = luckyAmulet.object.id,
        playSound = false
    }

    if config.showSpawn and transferred > 0 then
        tes3.messageBox("The amulet is generated in " .. luckyContainer.object.name .. " - ".. chance)
    end
    tempTable = nil
end

core.filterNpcLittleSecret = function(npc)
    if
        npc.mobile and not npc.mobile.isDead and npc.mobile.fight <= 70 and npc.object.class.id ~= "Guard" and
            npc.object.class.id ~= "Slave" and
            not npc.object.name:match("Guard") and
            not npc.object.isRespawn
     then
        return true
    else
        return false
    end
end

core.goToAmuletRef = function(z)
    local loc
    local s
    local refs

    if not tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode) then
        tes3.messageBox("This amulet has spawned but it is not in your inventory")

        return
    end
    --[[this is not optimized, only used for cheating]]
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for ref in cell:iterateReferences() do
            if (ref.object.inventory and ref.object.inventory:contains(z)) or ref.id == z then
                loc = ref.cell
                refs = ref
                tes3.playSound {soundPath = ("vo\\misc\\hit heart %s.mp3"):format(math.random(4))}
            end
        end
    end

    if tes3.worldController.inputController:isKeyDown(tes3.scanCode.lCtrl) then
        tes3.messageBox(loc.name)
        tes3.positionCell {
            cell = loc,
            position = refs.position,
            orientation = refs.orientation,
            teleportCompanions = false
        }
        tes3ui.findMenu(ata_kindi_menuId):destroy()
        tes3ui.leaveMenuMode()
        tes3.playSound {soundPath = ("vo\\misc\\hit heart %s.mp3"):format(math.random(5, 6))}
    end
end

core.amuletInfoCheat = function(item)
    local loc
    local refs

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for ref in cell:iterateReferences() do
            if (ref.object and ref.object.inventory and ref.object.inventory:contains(item)) or ref.id == item then
                loc = ref.cell
                refs = ref
                break
            end
        end
    end
    local tooltip = tes3ui.createTooltipMenu()
    tooltip.autoWidth = true
    tooltip.autoHeight = true
    tooltip.maxWidth = 440
    tooltip.flowDirection = "top_to_bottom"
    tooltiptext = tooltip:createLabel {}

    if refs then
        tooltiptext.text = ("Located in:\n %s\nInside:\n %s\n"):format(refs.cell, refs.object.name)
    else
        tooltiptext.text = ("This amulet is lost forever")
        return
    end
    tooltipsecret = tooltip:createLabel {}
    tooltipsecret.text = "Press Left Control\nwith Modifier to \ngo to the location"
    tooltipsecret.font = 2
end

core.showTombList = function(mari_kita_beramput)
    tes3ui.getMenuOnTop():destroy()
    core.alternate =
        mari_kita_beramput or tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode)

    local inventoryAmulets = 0

    for k, v in pairs(tes3.player.object.inventory) do
        if string.startswith(v.object.id, "ata_kindi_amulet_") then
            if
                v.variables and v.variables[1].data and v.variables[1].data.tomb and
                    table.find(data.tombTable, v.variables[1].data.tomb) and
                    data.amuletTable[v.variables[1].data.tomb]
             then
                inventoryAmulets = inventoryAmulets + 1
            end
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
    counter.text = ("%s Amulets is in your inventory\n\n"):format(inventoryAmulets)
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
    tombList.autoHeight = true
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

core.represh = function()
end

core.cheat = function()
    local count
    for i = 1, table.size(data.tombTable) do
        local itemid = "ata_kindi_amulet_" .. i
        tes3.removeItem {reference = data.waitCont, item = itemid}
        tes3.addItem {reference = tes3.player, item = itemid}
        count = i
    end

    tes3.messageBox(string.format("%s amulets added for %s tombs", count, table.size(data.tombTable)))
end

return core
