local data = require("kindi.ancestral tomb amulets.data")
local config = require("kindi.ancestral tomb amulets.config")
local core = {}

------------------------------------------------------------
-------------------AMULET SETUP-----------------------------
------------------------------------------------------------

--set amulet tooltips (if tooltips complete is installed)
core.setAmuletTooltips = function(ids)
    local tempstr = tes3.getObject(ids).name:match("%w+")
    local randomIntro = (math.random(0, 1) == 0) and "An heirloom" or "Lost relic"
    local custTooltip = data.customAmuletTooltip[tempstr .. " Ancestral Tomb"]
    local defaultTooltip = string.format(randomIntro .. " of the %s family", tempstr)

    if data.tooltipsComplete then
        data.tooltipsComplete.addTooltip(ids, custTooltip or defaultTooltip)
    end
end

core.getUnusedAmulet = function(n)
    local amuletid = "ata_kindi_amulet_" .. n
    local amulet = tes3.getObject(amuletid)

    if not table.find(tes3.player.data.ata_kindi_data.modifiedAmulets, amuletid) then
        return amulet
    end
end

--here we create the amulet and give it mesh, icons, enchantments, etc..
core.createAmuletForThisTomb = function(tomb)
    local rng = table.choice(data.effects)
    local amulet

    --make sure we pick a new amulet, we don't want to overwrite any already-created amulets
    for n = 1, 999 do
        if core.getUnusedAmulet(n) then
            amulet = core.getUnusedAmulet(n)
            break
        end
    end

    if amulet then
        amulet.enchantment =
            tes3enchantment.create(
            {
                id = amulet.id .. "_ata_ench",
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
        rng = math.random(1, table.size(data.amuletMesh))
        amulet.value = 1000
        amulet.weight = 1.0
        amulet.mesh = data.amuletMesh[rng]
        amulet.icon = data.amuletIcon[rng]
        amulet.name = tomb .. " Amulet"

        --add this newly created amulet to supercrate
        tes3.addItem {reference = data.superCrate, item = amulet}
        local itemData = tes3.addItemData {to = data.superCrate, item = amulet}
        itemData.data.tomb = tomb

        tes3.player.data.ata_kindi_data.modifiedAmulets[itemData.data.tomb] = amulet.id
        core.setAmuletTooltips(amulet.id)

        --modified as TRUE so we save the amulet changes
        amulet.modified = true
    else
        error("No amulet can be allocated! Mod needs to update.", 2)
    end
end

------------------------------------------------------------
-------------------INITIALIZATION---------------------------
------------------------------------------------------------

--after a load game, we gather all tombs that are available for this particular player character
core.initialize = function()
    setmetatable(tes3.player.data.ata_kindi_data.defaultTombs, data.meta)
    setmetatable(tes3.player.data.ata_kindi_data.customTombs, data.meta)
    setmetatable(tes3.player.data.ata_kindi_data.traversedCells, data.meta2)

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for door in cell:iterateReferences(tes3.objectType.door) do
            if
                door.destination and door.destination.cell and door.destination.cell.id and
                    string.match(door.destination.cell.id, "Ancestral Tomb")
             then
                if not string.match(door.destination.cell.id, ", ") and not door.cell.isInterior then
                    tes3.player.data.ata_kindi_data.defaultTombs[door.destination.cell.id] = door
                elseif not data.tombExtra[door.destination.cell.id] then
                    data.rejectedTombs[door.destination.cell.id] = door
                end
            end
        end
    end
    for tombID, destPos in pairs(data.tombExtra) do
        if tes3.getCell {id = tombID} then
            tes3.player.data.ata_kindi_data.customTombs[tombID] = destPos
        end
    end

    data.allTombs = tes3.player.data.ata_kindi_data.defaultTombs + tes3.player.data.ata_kindi_data.customTombs

    core.tombList()

    print(
        string.format(
            "[[Ancestral Tombs Amulet]] found %s Ancestral Tombs. Setting up mod..",
            table.size(data.allTombs)
        )
    ) --[[should be 88 for goty]]

    table.copy(tes3.player.data.ata_kindi_data.modifiedAmulets, data.allAmulets)

    mwse.log("[Ancestral Tomb Amulets] Initialized")
end

core.tombList = function()
    for tombID, door in pairs(data.allTombs) do
        if tes3.getCell {id = tombID} then
            if door.cell and door.cell.sourceMod then
                data.source[door.cell.sourceMod] = {}
            elseif data.tombExtra[tombID] and tes3.getCell {id = tombID}.sourceMod then
                data.source[tes3.getCell {id = tombID}.sourceMod] = {}
            elseif tes3.getCell {id = tombID}.sourceMod then
                data.source[tes3.getCell {id = tombID}.sourceMod] = {}
            else
                --data.source['Unknown_origin'] = {}
            end
        else
            --remove any tombs that is not in the game from the table
            data.allTombs[tombID] = nil
        end
    end

    for source, category in pairs(data.source) do
        for tombID, door in pairs(data.allTombs) do
            if tes3.getCell {id = tombID}.sourceMod == source then
                table.insert(category, tombID)
            elseif door.sourceMod == source then
                table.insert(category, tombID)
            elseif door.cell and door.cell.sourceMod == source then
                table.insert(category, tombID)
            elseif (door.cell and not door.cell.sourceMod) or not tes3.getCell {id = tombID}.sourceMod then
                data.unusedDoors[tombID] = door
            end
        end
    end
    for _, tombIDs in pairs(data.source) do
        table.sort(
            tombIDs,
            function(a, b)
                return a:lower() < b:lower()
            end
        )
    end
end

------------------------------------------------------------
-------------------AMULET AND CONTAINER---------------------
------------------------------------------------------------

core.autoEquipAmulet = function(mobActor, amulet)
    if mobActor.reference.object.inventory:contains(amulet) then
        if config.autoequipamuletattacked then
            return mobActor:equip {item = amulet, addItem = false}
        end
    end
end

core.teleport = function(cell, equipor)
    local cell = tes3.getCell {id = cell}
    local playerData = tes3.player.data

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
                local tombDoor = playerData.ata_kindi_data.defaultTombs[cell.id]
                local orientation
                local position

                if playerData.ata_kindi_data.customTombs[cell.id] then
                    orientation = playerData.ata_kindi_data.customTombs[cell.id]["rotation"]
                    position = playerData.ata_kindi_data.customTombs[cell.id]["position"]
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

                --[[using delayoneframe because #INFO or #INDO error can happen, unsure what it is. Not 100% reliable but no harm]]
                timer.delayOneFrame(
                    function()
                        if not tes3.getObject("atakinditelevfx") then
                            return
                        end
                        local teleportEffect =
                            tes3.createReference {
                            object = "atakinditelevfx",
                            position = equipor.position,
                            orientation = orientation,
                            cell = cell
                        }
                        teleportEffect.hasNoCollision = true
                        timer.start {
                            type = timer.real,
                            duration = 0.1,
                            iterations = 19,
                            callback = function()
                                if teleportEffect then
                                    teleportEffect.position = equipor.position
                                end
                            end
                        }
                    end
                )
            end
        }
    end
end

core.amuletCreation = function(cell)
    local containerTable = {} --temporary table to store containers in the cell
    local amuletTable = {} --temporary table to store available amulets left
    local aggrate = 0 --rating for cell danger factor
    local chance = tonumber(config.chance) --base chance
    local bestCont  --to store the ref of best container
    local raiderItem  --to store the tomb associated amulet
    local tempVar = 0 --temporary variable to store numbers
    local playerData = tes3.player.data

    for _, amulet in pairs(data.superCrate.object.inventory) do
        --we only want amulet that has an associated tomb in this particular game session
        if tes3.getCell {id = amulet.variables[1].data.tomb} then
            table.insert(amuletTable, amulet)
        end
        --if this cell is a tomb, get the amulet associated with it for tomb raider gameplay
        if cell.id:match("[^,]+") == amulet.variables[1].data.tomb then
            raiderItem = amulet
            if config.tombRaider then
                chance = 100
            end
        end
    end

    --these are all arbitrary values
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

    --if base chance is negative then all chances is nullified
    if tonumber(config.chance) < 0 then
        chance = -1
    end
    if math.random(100) > chance then
        return
    end

    --here we pick the suitable container
    for container in cell:iterateReferences(tes3.objectType.container) do
        if
            not container.object.organic and not container.object.respawns and
                (not container.object.script or config.affectScripted)
         then
            --get the largest container(for best container option)
            if container.object.capacity > tempVar then
                tempVar = container.object.capacity
                bestCont = container
            end
            table.insert(containerTable, container)
        end
    end

    --if there is no container in the cell, end the creation process
    if table.size(containerTable) <= 0 then
        return
    end

    --if there is no more amulet to be transferred, end creation process
    if #data.superCrate.object.inventory <= 0 or table.size(amuletTable) <= 0 then
        return
    end

    local luckyContainer
    local luckyAmulet = table.choice(amuletTable)

    --if we are using best container option, we set the lucky container to the best container
    if config.useBestCont then
        luckyContainer = bestCont
    else
        luckyContainer = table.choice(containerTable)
    end

    --if we are using tomb raider option, we set the lucky amulet to this tomb's amulet (if available)
    if config.tombRaider and raiderItem then
        luckyAmulet = raiderItem
    end

    --we transfer the amulet from supercrate to the container. FINISH!

    local transferred =
        tes3.transferItem {
        from = data.superCrate,
        to = luckyContainer,
        item = luckyAmulet.object.id,
        playSound = false
    }

    --debug
    if config.showSpawn and transferred > 0 then
        tes3.messageBox("The amulet is generated in " .. luckyContainer.object.name .. " - " .. chance)
    end
end

core.getOwnedAmulets = function()
    data.ownedAmulets = {}
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object.id:match("ata_kindi_amulet_") then
            if
                stack.variables and stack.variables[1].data and stack.variables[1].data.tomb and
                    tes3.getCell {id = stack.variables[1].data.tomb}
             then
                data.ownedAmulets[stack.variables[1].data.tomb] = stack.object
            end
        end
    end

    for _, stack in pairs(data.storageCrate.object.inventory) do
        if stack.object.id:match("ata_kindi_amulet_") then
            if
                stack.variables and stack.variables[1].data and stack.variables[1].data.tomb and
                    tes3.getCell {id = stack.variables[1].data.tomb}
             then
                data.ownedAmulets[stack.variables[1].data.tomb] = stack.object
            end
        end
    end
end
------------------------------------------------------------
---------------------TABLE UI-------------------------------
------------------------------------------------------------
core.storageCrateUI = function()
    if tes3ui.findMenu("MenuContents"):findChild("Buttons") then
        local closebutton = tes3ui.findMenu("MenuContents"):findChild("MenuContents_closebutton")
        local takeAllbutton = tes3ui.findMenu("MenuContents"):findChild("MenuContents_takeallbutton")
        local newButton = closebutton.parent:createButton {id = tes3ui.registerID("MenuContents_ATA_transferbutton")}
        newButton.text = "Transfer here"
        closebutton.parent:reorderChildren(closebutton, newButton, 1)
        newButton:register(
            "mouseClick",
            function()
                for _, amulet in pairs(tes3.player.object.inventory) do
                    if string.find(amulet.object.id, "ata_kindi_amulet_") then
                        tes3.transferItem {
                            from = tes3.player,
                            to = data.storageCrate,
                            item = amulet.object,
                            playSound = true,
                            updateGUI = false
                        }
                    end
                end
                tes3ui.updateInventorySelectTiles()
                tes3ui.updateInventorySelectTiles()
                tes3ui.updateInventoryTiles()
                tes3ui.forcePlayerInventoryUpdate()
                tes3.updateInventoryGUI {reference = data.storageCrate}
            end
        )
        closebutton:unregister("mouseClick")
        closebutton:register(
            "mouseClick",
            function()
                if tes3ui.findMenu("ATA_KNDI_TableMenu") then
                    tes3ui.findMenu("ATA_KNDI_TableMenu").disabled = false
                    tes3ui.findMenu("ATA_KNDI_TableMenu").visible = true
                    tes3ui.findMenu("MenuInventory").visible = false
                    tes3ui.findMenu("MenuContents"):destroy()
                    --event.trigger("ATA_KINDI_STORAGE_CLOSED_EVENT", {reference = data.storageCrate})
                    data.storageCrate:onCloseInventory()
                end
            end
        )
        takeAllbutton:unregister("mouseClick")
        takeAllbutton:register(
            "mouseClick",
            function()
                for _, amulet in pairs(data.storageCrate.object.inventory) do
                    tes3.transferItem {
                        from = data.storageCrate,
                        to = tes3.player,
                        item = amulet.object,
                        playSound = true,
                        limitCapacity = false,
                        updateGUI = false
                    }
                end
                tes3ui.updateInventorySelectTiles()
                tes3ui.updateInventorySelectTiles()
                tes3ui.updateInventoryTiles()
                tes3ui.forcePlayerInventoryUpdate()
                tes3.updateInventoryGUI {reference = data.storageCrate}
            end
        )
        return
    end
end
core.listTheTomb = function(tombList)
    local menus = tes3ui.findMenu("ATA_KNDI_TableMenu")
    local scroll = menus:findChild("ata_kindi_scrollpane")
    local inputs = menus:findChild("ata_kindi_buttons_Block"):findChild("ata_kindi_input")
    local key = inputs.text
    --tes3.messageBox(key)
    tombList:destroyChildren()

    for sourceMod, listOfTombID in pairs(data.source) do
        local sourcemodBlock = tombList:createBlock {id = tes3ui.registerID("ata_kindi_sourcemod_" .. sourceMod)}
        sourcemodBlock.autoWidth = true
        sourcemodBlock.autoHeight = true
        sourcemodBlock.flowDirection = "top_to_bottom"
        sourcemodBlock.widthProportional = 1.0
        sourcemodBlock.borderAllSides = 3
        sourcemodBlock.wrapText = true
        local pluginLabel =
            sourcemodBlock:createLabel {id = tes3ui.registerID("ata_kindi_sourcemod_label_" .. sourceMod)}
        pluginLabel.widthProportional = 0.1
        pluginLabel.wrapText = true
        pluginLabel.justifyText = "center"
        pluginLabel.font = 2
        if data.alternate then
            pluginLabel.text = ("\n%s\n"):format(sourceMod:upper())
        else
            pluginLabel.text = "\nCLICK ON THE TOMB NAME TO TELEPORT\n"
        end

        local insideDummy = {}
        local outsideDummy = {}

        for _, stack in pairs(data.superCrate.object.inventory) do
            insideDummy[stack.variables[1].data.tomb] = stack.object.id
        end

        for tombID, amuletID in pairs(data.allAmulets) do
            if not table.find(insideDummy, amuletID) then
                outsideDummy[tombID] = tes3.getObject(amuletID)
            end
        end

        for _, tombID in pairs(listOfTombID) do
            if data.ownedAmulets[tombID] and tombID:lower():match(key:lower()) then
                local tombB =
                    sourcemodBlock:createBlock {id = tes3ui.registerID("ata_kindi_tombblock_" .. tombID:match("%w+"))}
                tombB.autoWidth = true
                tombB.height = 35
                tombB.absolutePosAlignX = 0.5
                tombB.paddingLeft = 120
                tombB.paddingRight = 120
                tombB.flowDirection = "left_to_right"
                local tombYes = tombB:createTextSelect {}
                tombYes.text = tombID
                tombYes.widget.idleActive = tes3ui.getPalette("link_color")
                tombYes.widget.overActive = tes3ui.getPalette("link_over_color")
                tombYes.widget.pressedActive = tes3ui.getPalette("link_pressed_color")
                tombYes.widget.state = 4
                tombYes:register(
                    "mouseClick",
                    function()
                        if tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode) then
                            if not tes3.mobilePlayer:equip {item = data.ownedAmulets[tombID]} then
                                tes3.transferItem {
                                    from = data.storageCrate,
                                    to = tes3.player,
                                    item = data.ownedAmulets[tombID],
                                    playSound = false
                                }
                                tes3.playSound {sound = "mysticism area", pitch = 0.7}
                                tes3.mobilePlayer:equip {item = data.ownedAmulets[tombID]}
                            end
                            core.listTheTomb(tombList)
                            return
                        elseif tes3.worldController.inputController:isKeyDown(tes3.scanCode.lAlt) then
                            if sourceMod:match("Morrowind") then
                                os.openURL("https://en.uesp.net/wiki/Morrowind:" .. tombID:gsub("%s", "_"))
                            elseif sourceMod:match("Mainland") then
                                os.openURL("https://en.uesp.net/wiki/Tamriel_Rebuilt:" .. tombID:gsub("%s", "_"))
                            else
                                os.openURL("https://www.google.com/search?q=" .. tombID:gsub("%s", "+"))
                            end
                            return
                        end
                        timer.start {
                            type = timer.real,
                            duration = 0.05,
                            callback = function()
                                local cell = tombID
                                core.teleport(cell, tes3.player)
                                local menu = tes3ui.findMenu("ATA_KNDI_TableMenu")
                                if menu then
                                    tes3ui.leaveMenuMode(menu)
                                    menu.visible = false
                                end
                            end
                        }
                    end
                )
                tombYes:register(
                    "help",
                    function(e)
                        local tooltip = tes3ui.createTooltipMenu {item = data.ownedAmulets[tombID]}
                        local divider = tooltip:createDivider {}
                        local label = tooltip:createLabel {text = "Click to teleport to the Tomb"}
                        label.color = {0.90, 0.30, 0.00}
                    end
                )

                local isInStorage = data.storageCrate.object.inventory:contains(data.ownedAmulets[tombID])
                local tombLock = tombB:createTextSelect {}
                tombLock.text = isInStorage and " -" or " +"
                tombLock.widget.idleActive = tes3ui.getPalette("link_color")
                tombLock.widget.overActive = tes3ui.getPalette("link_over_color")
                tombLock.widget.pressedActive = tes3ui.getPalette("link_pressed_color")
                tombLock.widget.state = 4
                tombLock:register(
                    "mouseClick",
                    function()
                        timer.start {
                            type = timer.real,
                            duration = 0.05,
                            callback = function()
                                if isInStorage then
                                    tes3.transferItem {
                                        from = data.storageCrate,
                                        to = tes3.player,
                                        item = data.ownedAmulets[tombID],
                                        playSound = false
                                    }
                                    tes3.playSound {sound = "mysticism area", pitch = 0.7}
                                else
                                    tes3.transferItem {
                                        from = tes3.player,
                                        to = data.storageCrate,
                                        item = data.ownedAmulets[tombID],
                                        playSound = false
                                    }
                                    tes3.playSound {sound = "mysticism area", pitch = 1.3}
                                end
                                core.listTheTomb(tombList)
                            end
                        }
                    end
                )
            elseif data.alternate and insideDummy[tombID] and tombID:lower():match(key:lower()) then
                local tombB1 =
                    sourcemodBlock:createBlock {id = tes3ui.registerID("ata_kindi_tombblock_" .. tombID:match("%w+"))}
                tombB1.autoWidth = true
                tombB1.height = 35
                tombB1.absolutePosAlignX = 0.5
                tombB1.paddingLeft = 120
                tombB1.paddingRight = 120
                local tombNo = tombB1:createTextSelect {}
                tombNo.text = tombID
                tombNo.widget.state = 2
                tombNo:register(
                    "mouseClick",
                    function()
                        if
                            tes3.worldController.inputController:isKeyDown(tes3.scanCode.lCtrl) and
                                tes3.worldController.inputController:isKeyDown(tes3.scanCode.lAlt)
                         then
                            if data.superCrate.object.inventory:contains(insideDummy[tombID]) then
                                tes3.transferItem {
                                    from = data.superCrate,
                                    to = tes3.player,
                                    item = insideDummy[tombID],
                                    playSound = true
                                }
                                data.ownedAmulets[tombID] = insideDummy[tombID]
                                tes3.playSound {soundPath = ("vo\\misc\\hit heart %s.mp3"):format(math.random(4))}
                            end
                            core.listTheTomb(tombList)
                        end
                    end
                )
            end
            if
                outsideDummy[tombID] and not data.ownedAmulets[tombID] and data.alternate and
                    tombID:lower():match(key:lower())
             then
                local tombB2 =
                    sourcemodBlock:createBlock {id = tes3ui.registerID("ata_kindi_tombblock_" .. tombID:match("%w+"))}
                tombB2.autoWidth = true
                tombB2.height = 35
                tombB2.absolutePosAlignX = 0.5
                tombB2.paddingLeft = 120
                tombB2.paddingRight = 120
                local tombHalf = tombB2:createTextSelect {}
                tombHalf.text = tombID
                tombHalf.widget.idle = {0.8, 0.8, 0}
                tombHalf.widget.over = {1, 1, 0.2}
                tombHalf.widget.pressed = {1, 1, 0.4}
                tombHalf.widget.state = 1
                tombHalf:register(
                    "mouseClick",
                    function()
                        tes3.messageBox("This amulet is placed somewhere..")
                        --tes3.playSound {soundPath = ("vo\\misc\\hit heart %s.mp3"):format(math.random(5, 6))}
                    end
                )
                tombHalf:register(
                    "mouseOver",
                    function()
                        if tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode) then
                            local tooltip = tes3ui.createTooltipMenu {item = outsideDummy[tombID]}
                            local divider = tooltip:createDivider {}
                            local label = tooltip:createLabel {text = core.amuletInfoCheat(tombID)}
                            local tooltipsecret = tooltip:createLabel {}
                            tooltipsecret.text = "Dagoth Ur is displeased with your cheating"
                            tooltipsecret.font = 2
                        end
                    end
                )
            end
        end
    end

    if data.alternate and key == "" then
        local rejectedTombsBlock = tombList:createBlock {id = tes3ui.registerID("ata_kindi_zzzz_rejects")}
        rejectedTombsBlock.autoHeight = true
        rejectedTombsBlock.autoWidth = true
        rejectedTombsBlock.flowDirection = "top_to_bottom"
        rejectedTombsBlock.widthProportional = 1.0
        rejectedTombsBlock.borderAllSides = 3
        --rejectedTombsBlock.absolutePosAlignX = 0.5 --why dont this work except using ui inspector?
        local rejectedTombsLabel = rejectedTombsBlock:createLabel {}
        rejectedTombsLabel.text = ("\n%s Tomb Doors Rejected\n"):format(table.size(data.rejectedTombs))
        rejectedTombsLabel.wrapText = true
        rejectedTombsLabel.justifyText = "center"
        for tombID, door in pairs(data.rejectedTombs) do
            rejectedTombsLabel =
                rejectedTombsBlock:createLabel {id = tes3ui.registerID("ata_kindi_rejected_" .. tombID:match("%w+"))}
            rejectedTombsLabel.text = tombID .. " from " .. door.cell.id .. "\n"
            rejectedTombsLabel.wrapText = true
            rejectedTombsLabel.justifyText = "center"
        end
    end

    tombList:sortChildren(
        function(a, b)
            return a.name < b.name
        end
    )

    menus:updateLayout()
    scroll.widget:contentsChanged()
end

core.tableMenu = function(switchAlternate, hide)
    --tes3ui.getMenuOnTop():destroy()
    data.alternate =
        switchAlternate or tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode)

    core.getOwnedAmulets() --update data.ownedAmulets table

    local nOwnedAmulets = table.size(data.ownedAmulets)

    local menu = tes3ui.createMenu({id = tes3ui.registerID("ATA_KNDI_TableMenu"), dragFrame = true, fixedFrame = false})
    menu.visible = not hide
    menu.disabled = hide
    menu.text = "Table of Ancestral Tomb Amulets"
    menu.width = data.menuWidth or 400
    menu.height = data.menuHeight or 700
    menu.minWidth = 100
    menu.minHeight = 300
    menu.maxWidth = 450
    menu.positionX = data.menuPosx or menu.width / -2
    menu.positionY = data.menuPosy or menu.height / 2
    menu.alpha = tes3.worldController.menuAlpha
    menu.wrapText = true
    menu.justifyText = "center"

    local blockBar = menu:createBlock {id = tes3ui.registerID("ata_kindi_blockBar")}
    blockBar.autoWidth = true
    blockBar.autoHeight = true
    blockBar.flowDirection = "top_to_bottom"
    blockBar.widthProportional = 1.0
    blockBar.borderAllSides = 1

    local counter = blockBar:createLabel {id = tes3ui.registerID("ata_kindi_counter")}
    counter.widthProportional = 0.1
    counter.text = ("Amulets in your possession:\n\n")
    counter.wrapText = true
    counter.justifyText = "center"

    local bar =
        blockBar:createFillBar {
        id = tes3ui.registerID("ata_kindi_fillbar"),
        current = nOwnedAmulets,
        max = table.size(data.allTombs)
    }
    bar.widget.fillColor = {0.6, 0.3, 0}
    bar.widget.fillAlpha = 0.5
    bar.absolutePosAlignX = 0.5
    bar.absolutePosAlignY = 1
    bar.borderAllSides = 8

    local divider = menu:createDivider {}

    local list = menu:createVerticalScrollPane({id = tes3ui.registerID("ata_kindi_scrollpane")})

    local tombList = list:createBlock({id = tes3ui.registerID("ata_kindi_tombList")})
    tombList.autoWidth = true
    tombList.autoHeight = true
    tombList.flowDirection = "top_to_bottom"
    tombList.widthProportional = 1.0
    tombList.borderAllSides = 3
    tombList.wrapText = true

    local buttonBlock = menu:createBlock {id = tes3ui.registerID("ata_kindi_buttons_Block")}
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.widthProportional = 1.0
    buttonBlock.height = 32
    buttonBlock.borderTop = 3
    buttonBlock.autoWidth = true
    buttonBlock.autoHeight = true

    local closeButton =
        buttonBlock:createImageButton {
        id = tes3ui.registerID("ata_kindi_buttonClose"),
        idle = "Icons\\kindi\\exitidle.tga",
        over = "Icons\\kindi\\exitover.tga",
        pressed = "Icons\\kindi\\exitover.tga"
    }
    closeButton.height = 32
    closeButton.width = 32
    closeButton.absolutePosAlignX = 1.0
    for i = 1, #closeButton.children do
        closeButton.children[i].height = 32
        closeButton.children[i].width = 32
        closeButton.children[i].scaleMode = true
    end
    closeButton:register(
        "mouseClick",
        function()
            local menu = tes3ui.findMenu("ATA_KNDI_TableMenu")
            if menu then
                data.alternate = false
                core.listTheTomb(tombList)
                menu.visible = false
                menu:findChild("ata_kindi_input").text = ""
                tes3ui.leaveMenuMode(tes3ui.registerID("ATA_KNDI_TableMenu"))
                tes3.playSound {sound = "menu click"}
            end
        end
    )

    local storeAllButton =
        buttonBlock:createImageButton {
        id = tes3ui.registerID("ata_kindi_buttonStoreAll"),
        idle = "Icons\\kindi\\storeidle.tga",
        over = "Icons\\kindi\\storeover.tga",
        pressed = "Icons\\kindi\\storeover.tga"
    }
    storeAllButton.height = 32
    storeAllButton.width = 32
    for i = 1, #storeAllButton.children do
        storeAllButton.children[i].height = 32
        storeAllButton.children[i].width = 32
        storeAllButton.children[i].scaleMode = true
    end
    storeAllButton:register(
        "mouseClick",
        function()
            local successful
            if tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode) then
                menu.disabled = true
                menu.visible = false
                tes3.player:activate(data.storageCrate)
                tes3.game:clearTarget()
                core.storageCrateUI()
                return
            end
            for _, amulet in pairs(tes3.player.object.inventory) do
                if amulet.object.slot == tes3.clothingSlot.amulet then
                    if amulet.object.id:find("ata_kindi_amulet_") then
                        successful =
                            tes3.transferItem {
                            from = tes3.player,
                            to = data.storageCrate,
                            item = amulet.object.id,
                            playSound = false,
                            limitCapacity = false,
                            updateGUI = false
                        }
                    end
                end
            end
            tes3ui.updateInventoryTiles()
            tes3ui.forcePlayerInventoryUpdate()
            core.listTheTomb(tombList)
            if successful then
                --tes3.messageBox {message = "All amulets stored.", duration = 0.5}
                tes3.playSound {sound = "mysticism area", pitch = 1.3}
            end
        end
    )

    local returnAllButton =
        buttonBlock:createImageButton {
        id = tes3ui.registerID("ata_kindi_buttonReturnAll"),
        idle = "Icons\\kindi\\returnidle.tga",
        over = "Icons\\kindi\\returnover.tga",
        pressed = "Icons\\kindi\\returnover.tga"
    }
    returnAllButton.height = 32
    returnAllButton.width = 32
    for i = 1, #returnAllButton.children do
        returnAllButton.children[i].height = 32
        returnAllButton.children[i].width = 32
        returnAllButton.children[i].scaleMode = true
    end
    returnAllButton:register(
        "mouseClick",
        function()
            local successful
            if tes3.worldController.inputController:isKeyDown(config.hotkeyOpenModifier.keyCode) then
                menu.disabled = true
                menu.visible = false
                tes3.player:activate(data.storageCrate)
                core.storageCrateUI()
                return
            end
            for _, amulet in pairs(data.storageCrate.object.inventory) do
                successful =
                    tes3.transferItem {
                    from = data.storageCrate,
                    to = tes3.player,
                    item = amulet.object.id,
                    playSound = false,
                    limitCapacity = false,
                    updateGUI = false
                }
            end
            tes3ui.forcePlayerInventoryUpdate()
            core.listTheTomb(tombList)
            if successful then
                --tes3.messageBox {message = "All amulets returned.", duration = 0.5}
                tes3.playSound {sound = "mysticism area", pitch = 0.7}
            end
        end
    )

    local options =
        buttonBlock:createImageButton {
        id = tes3ui.registerID("ata_kindi_buttonOptions"),
        idle = "Icons\\kindi\\optionsidle.tga",
        over = "Icons\\kindi\\optionsover.tga",
        pressed = "Icons\\kindi\\optionsover.tga"
    }
    options.height = 32
    options.width = 32
    for i = 1, #options.children do
        options.children[i].height = 32
        options.children[i].width = 32
        options.children[i].scaleMode = true
    end
    options:registerAfter(
        "mouseClick",
        function()
            tes3ui.findMenu("ATA_KNDI_TableMenu").disabled = true
            tes3ui.findMenu("ATA_KNDI_TableMenu").visible = false

            tes3ui.findMenu("ATA_KNDI_OptionsMenu"):destroy()
            core.optionMenu(nil, false)
            tes3ui.findMenu("ATA_KNDI_OptionsMenu").visible = true

            tes3.messageBox {message = "Click on an icon to toggle activation", duration = 1.5, showInDialog = false}

            tes3ui.acquireTextInput(nil)
            tes3.playSound {sound = "menu click"}
        end
    )

    local switchTable =
        buttonBlock:createImageButton {
        id = tes3ui.registerID("ata_kindi_buttonSwitchTable"),
        idle = "Icons\\kindi\\alternatetableidle.tga",
        over = "Icons\\kindi\\alternatetableover.tga",
        pressed = "Icons\\kindi\\alternatetableover.tga"
    }
    switchTable.height = 32
    switchTable.width = 32
    for i = 1, #switchTable.children do
        switchTable.children[i].height = 32
        switchTable.children[i].width = 32
        switchTable.children[i].scaleMode = true
    end
    switchTable:registerAfter(
        "mouseClick",
        function()
            data.menuPosx = menu.positionX
            data.menuPosy = menu.positionY
            data.menuWidth = menu.width
            data.menuHeight = menu.height
            menu:destroy()
            core.tableMenu(not data.alternate)
            if tes3ui.findMenu("ATA_KNDI_TableMenu"):findChild("ata_kindi_input") then
                tes3ui.acquireTextInput(tes3ui.findMenu("ATA_KNDI_TableMenu"):findChild("ata_kindi_input"))
            end
            tes3.playSound {sound = "menu click"}
        end
    )

    local input = buttonBlock:createTextInput {id = tes3ui.registerID("ata_kindi_input")}
    input.borderLeft = 5
    input.borderRight = 5
    input.borderTop = 5
    input.borderBottom = 5
    input.font = 1
    input.widget.lengthLimit = 31
    input.widget.eraseOnFirstKey = true
    input:register(
        "keyPress",
        function(e)
            input:forwardEvent(e)
            --local keyCode = e.data0
            core.listTheTomb(tombList)
        end
    )

    buttonBlock:register(
        "mouseClick",
        function()
            tes3ui.acquireTextInput(input)
        end
    )
    input.color = tes3ui.getPalette("disabled_color")
    input.consumeMouseEvents = false
    core.listTheTomb(tombList)

    for i, child in ipairs(buttonBlock.children) do
        child.borderLeft = 4
        child.borderRight = 4
    end

    menu:updateLayout()
end

core.optionMenu = function(static, hide)
    local optionsMenu =
        tes3ui.createMenu({id = tes3ui.registerID("ATA_KNDI_OptionsMenu"), dragFrame = true, fixedFrame = false})
    optionsMenu.visible = not hide
    optionsMenu.disabled = hide
    optionsMenu.text = "Minor gameplay"
    optionsMenu.width = 300
    optionsMenu.height = 650
    optionsMenu.minWidth = 300
    optionsMenu.minHeight = 450
    optionsMenu.maxWidth = 300
    optionsMenu.maxHeight = 650
    optionsMenu.positionX = static and static[1] or optionsMenu.width / -2
    optionsMenu.positionY = static and static[2] or optionsMenu.height / 2
    optionsMenu.alpha = tes3.worldController.menuAlpha

    local list = optionsMenu:createVerticalScrollPane {id = tes3ui.registerID("optionmenulist")}
    list.borderBottom = 32
    list.widget.positionY = static and static[3] or 0

    local optionsMainBlock = list:createBlock {id = tes3ui.registerID("optionsmainblock")}
    optionsMainBlock.autoWidth = true
    optionsMainBlock.autoHeight = true
    optionsMainBlock.flowDirection = "top_to_bottom"
    optionsMainBlock.widthProportional = 1.0
    optionsMainBlock.borderAllSides = 1

    local iconenabled = "Icons\\kindi\\autoequipamuletover.tga"
    local icondisabled = "Icons\\kindi\\autoequipamuletidle.tga"
    local optionsAutoEquipTombCombat =
        optionsMainBlock:createImageButton {
        idle = config.autoequipamuletattacked and iconenabled or icondisabled,
        over = config.autoequipamuletattacked and iconenabled or icondisabled,
        pressed = config.autoequipamuletattacked and icondisabled or iconenabled
    }
    optionsAutoEquipTombCombat.height = 64
    optionsAutoEquipTombCombat.width = 64
    optionsAutoEquipTombCombat.absolutePosAlignX = 0.5
    for i = 1, #optionsAutoEquipTombCombat.children do
        optionsAutoEquipTombCombat.children[i].height = 64
        optionsAutoEquipTombCombat.children[i].width = 64
        optionsAutoEquipTombCombat.children[i].scaleMode = true
    end

    optionsAutoEquipTombCombat:register(
        "mouseClick",
        function()
            local scrollPosY = list.widget.positionY
            config.autoequipamuletattacked = not config.autoequipamuletattacked
            optionsMenu:destroy()
            core.optionMenu({optionsMenu.positionX, optionsMenu.positionY, scrollPosY}, false)
            tes3.playSound {sound = "menu click"}
        end
    )

    local optionsAutoEquipTombCombatLabel = optionsMainBlock:createLabel {}
    optionsAutoEquipTombCombatLabel.text =
        "The tomb amulet auto-equips when attacked by certain enemies or when opening traps in the tomb"
    optionsAutoEquipTombCombatLabel.wrapText = true
    optionsAutoEquipTombCombatLabel.justifyText = "center"
    -------------------------------------------------------------------------------------------------
    optionsMainBlock:createDivider {}
    -------------------------------------------------------------------------------------------------
    local iconenabled1 = "Icons\\kindi\\optionsprotectwearerover.tga"
    local icondisabled1 = "Icons\\kindi\\optionsprotectweareridle.tga"
    local optionsUndeadProtectWearer =
        optionsMainBlock:createImageButton {
        idle = config.undeadprotectwearer and iconenabled1 or icondisabled1,
        over = config.undeadprotectwearer and iconenabled1 or icondisabled1,
        pressed = config.undeadprotectwearer and icondisabled1 or iconenabled1
    }
    optionsUndeadProtectWearer.height = 64
    optionsUndeadProtectWearer.width = 64
    optionsUndeadProtectWearer.absolutePosAlignX = 0.5
    for i = 1, #optionsUndeadProtectWearer.children do
        optionsUndeadProtectWearer.children[i].height = 64
        optionsUndeadProtectWearer.children[i].width = 64
        optionsUndeadProtectWearer.children[i].scaleMode = true
    end
    optionsUndeadProtectWearer:register(
        "mouseClick",
        function()
            local scrollPosY = list.widget.positionY
            config.undeadprotectwearer = not config.undeadprotectwearer
            optionsMenu:destroy()
            core.optionMenu({optionsMenu.positionX, optionsMenu.positionY, scrollPosY}, false)
            tes3.playSound {sound = "menu click"}
        end
    )

    local optionsUndeadProtectWearerLabel = optionsMainBlock:createLabel {}
    optionsUndeadProtectWearerLabel.text = "The undead of the tomb defends the amulet wearer"
    optionsUndeadProtectWearerLabel.wrapText = true
    optionsUndeadProtectWearerLabel.justifyText = "center"
    -------------------------------------------------------------------------------------------------
    optionsMainBlock:createDivider {}
    -------------------------------------------------------------------------------------------------
    local iconenabled2 = "Icons\\kindi\\unlockdisarmtombover.tga"
    local icondisabled2 = "Icons\\kindi\\unlockdisarmtombidle.tga"
    local optionsUnlockDisarmTomb =
        optionsMainBlock:createImageButton {
        idle = config.unlockdisarmtomb and iconenabled2 or icondisabled2,
        over = config.unlockdisarmtomb and iconenabled2 or icondisabled2,
        pressed = config.unlockdisarmtomb and icondisabled2 or iconenabled2
    }
    optionsUnlockDisarmTomb.height = 64
    optionsUnlockDisarmTomb.width = 64
    optionsUnlockDisarmTomb.absolutePosAlignX = 0.5
    for i = 1, #optionsUnlockDisarmTomb.children do
        optionsUnlockDisarmTomb.children[i].height = 64
        optionsUnlockDisarmTomb.children[i].width = 64
        optionsUnlockDisarmTomb.children[i].scaleMode = true
    end
    optionsUnlockDisarmTomb:register(
        "mouseClick",
        function()
            local scrollPosY = list.widget.positionY
            config.unlockdisarmtomb = not config.unlockdisarmtomb
            optionsMenu:destroy()
            core.optionMenu({optionsMenu.positionX, optionsMenu.positionY, scrollPosY}, false)
            tes3.playSound {sound = "menu click"}
        end
    )

    local optionsUndeadProtectWearerLabel = optionsMainBlock:createLabel {}
    optionsUndeadProtectWearerLabel.text = "The tomb traps and locks are neutralized against the amulet wearer"
    optionsUndeadProtectWearerLabel.wrapText = true
    optionsUndeadProtectWearerLabel.justifyText = "center"
    -------------------------------------------------------------------------------------------------
    optionsMainBlock:createDivider {}
    -------------------------------------------------------------------------------------------------
    local iconenabled3 = "Icons\\kindi\\familymembersfriendlyover.tga"
    local icondisabled3 = "Icons\\kindi\\familymembersfriendlyidle.tga"
    local familyMembersFriendlyOnce =
        optionsMainBlock:createImageButton {
        idle = config.familymembersfriendlyonce and iconenabled3 or icondisabled3,
        over = config.familymembersfriendlyonce and iconenabled3 or icondisabled3,
        pressed = config.familymembersfriendlyonce and icondisabled3 or iconenabled3
    }
    familyMembersFriendlyOnce.height = 64
    familyMembersFriendlyOnce.width = 64
    familyMembersFriendlyOnce.absolutePosAlignX = 0.5
    for i = 1, #familyMembersFriendlyOnce.children do
        familyMembersFriendlyOnce.children[i].height = 64
        familyMembersFriendlyOnce.children[i].width = 64
        familyMembersFriendlyOnce.children[i].scaleMode = true
    end
    familyMembersFriendlyOnce:register(
        "mouseClick",
        function()
            local scrollPosY = list.widget.positionY
            config.familymembersfriendlyonce = not config.familymembersfriendlyonce
            optionsMenu:destroy()
            core.optionMenu({optionsMenu.positionX, optionsMenu.positionY, scrollPosY}, false)
            tes3.playSound {sound = "menu click"}
        end
    )

    local familyMembersFriendlyOnceLabel = optionsMainBlock:createLabel {}
    familyMembersFriendlyOnceLabel.text =
        "Hostile NPCs become friendly with the wearer of an amulet inscribed with their surname (affects once)"
    familyMembersFriendlyOnceLabel.wrapText = true
    familyMembersFriendlyOnceLabel.justifyText = "center"
    -------------------------------------------------------------------------------------------------
    optionsMainBlock:createDivider {}
    -------------------------------------------------------------------------------------------------
    local optionsCloseButtonBlock = optionsMenu:createBlock {id = tes3ui.registerID("optionsclosebuttonblock")}
    optionsCloseButtonBlock.flowDirection = "left_to_right"
    optionsCloseButtonBlock.widthProportional = 1.0
    optionsCloseButtonBlock.absolutePosAlignY = 1.0
    optionsCloseButtonBlock.absolutePosAlignX = 1.0
    optionsCloseButtonBlock.height = 32
    optionsCloseButtonBlock.borderTop = 3
    optionsCloseButtonBlock.autoWidth = true
    optionsCloseButtonBlock.autoHeight = true

    local optionsCloseButton =
        optionsCloseButtonBlock:createImageButton {
        idle = "Icons\\kindi\\exitidle.tga",
        over = "Icons\\kindi\\exitover.tga",
        pressed = "Icons\\kindi\\exitover.tga"
    }
    optionsCloseButton.height = 32
    optionsCloseButton.width = 32
    for i = 1, #optionsCloseButton.children do
        optionsCloseButton.children[i].height = 32
        optionsCloseButton.children[i].width = 32
        optionsCloseButton.children[i].scaleMode = true
    end
    optionsCloseButton:register(
        "mouseClick",
        function()
            --close the options menu and unhide the amulet table
            if tes3ui.findMenu("ATA_KNDI_TableMenu") then
                tes3ui.findMenu("ATA_KNDI_TableMenu").visible = true
                tes3ui.findMenu("ATA_KNDI_TableMenu").disabled = false
                optionsMenu.disabled = tes3ui.findMenu("ATA_KNDI_TableMenu").visible
                optionsMenu.visible = tes3ui.findMenu("ATA_KNDI_TableMenu").disabled
            else
                core.tableMenu()
            end
            tes3ui.acquireTextInput(tes3ui.findMenu("ATA_KNDI_TableMenu"):findChild("ata_kindi_input"))
            tes3.playSound {sound = "menu click"}
            mwse.saveConfig("ancestral_tomb_amulets", config)
        end
    )
    optionsMenu:updateLayout()
    optionsMenu:updateLayout()
    list.widget:contentsChanged()
    --tes3ui.enterMenuMode(tes3ui.registerID("ATA_KNDI_OptionsMenu"))
end
------------------------------------------------------------
-----------------------CHEATS-------------------------------
------------------------------------------------------------

core.amuletInfoCheat = function(dataT)
    local refs

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for ref in cell:iterateReferences() do
            if ref.object and ref.object.inventory and ref ~= data.superCrate then
                for _, stack in pairs(ref.object.inventory) do
                    if stack.variables and stack.variables[1] and stack.variables[1].data then
                        if stack.variables[1].data.tomb == dataT then
                            refs = ref
                            break
                        end
                    end
                end
            end
            if ref.data and ref.data.tomb == dataT then
                refs = ref
                break
            end
        end
    end

    if refs and refs.object.inventory then
        return ("Located in: %s\nInside: %s %s\n"):format(
            refs.cell,
            refs.object.name,
            refs.disabled and "(Disabled)" or ""
        )
    elseif refs then
        return ("Located in: %s\nCoordinates: %s %s\n"):format(
            refs.cell,
            refs.position:copy(),
            refs.disabled and "(Disabled)" or ""
        )
    else
        return ("This amulet is lost forever")
    end
end

core.cheat = function()
    local count = 0
    for _, item in pairs(data.superCrate.object.inventory) do
        tes3.transferItem {
            from = data.superCrate,
            to = tes3.player,
            item = item.object,
            playSound = false,
            limitCapacity = false,
            updateGUI = false
        }
        count = count + 1
    end
    tes3ui.forcePlayerInventoryUpdate()
    tes3.messageBox(string.format("%s amulets added for %s tombs", count, table.size(data.allTombs)))
end

------------------------------------------------------------
------------------------UTILITY-----------------------------
------------------------------------------------------------

core.clean = function(count, N, noMessage)
    local save = {}
    for _, amulet in pairs(tes3.player.object.inventory) do
        if string.find(amulet.object.id, "ata_kindi_amulet_") then
            local tomb = amulet.variables[1].data.tomb
            local enchantment = amulet.object.enchantment
            --remove duplicate
            while tes3.getItemCount {reference = tes3.player, item = amulet.object.id} > 1 do
                mwse.log("ATA Clean: Found [%s, %s] duplicate, fixed.", amulet.object.id, amulet.object.name)
                tes3.removeItem {reference = tes3.player, item = amulet.object}
                count = count + 1
            end
            --remove mismatches
            if data.allAmulets[tomb] ~= amulet.object.id then
                mwse.log("ATA Clean: Found [%s, %s] mismatch, fixed.", amulet.object.id, amulet.object.name)
                tes3.removeItem {reference = tes3.player, item = amulet.object, playSound = false, count = 9999}
                save[data.allAmulets[tomb]] = enchantment
                count = count + 1
            end
            --remove unknown amulets
            if amulet and amulet.object and not table.find(data.allAmulets, amulet.object.id) then
                mwse.log("ATA Clean: Found [%s, %s] bad reference, fixed.", amulet.object.id, amulet.object.name)
                tes3.removeItem {reference = tes3.player, item = amulet.object, count = 9999}
                count = count + 1
            end
        end
    end

    for _, amulet in pairs(data.superCrate.object.inventory) do
        --remove duplicate
        while tes3.getItemCount {reference = data.superCrate, item = amulet.object.id} > 1 do
            mwse.log("ATA Clean: Found [%s, %s] duplicate, fixed.", amulet.object.id, amulet.object.name)
            tes3.removeItem {reference = data.superCrate, item = amulet.object}
            count = count + 1
        end
        --remove mismatches
        if data.allAmulets[amulet.variables[1].data.tomb] ~= amulet.object.id then
            mwse.log("ATA Clean: Found [%s, %s] mismatch, fixed.", amulet.object.id, amulet.object.name)
            amulet.variables[1].data.tomb = table.find(data.allAmulets, amulet.object.id)
            count = count + 1
        end
        --remove unknown amulets
        if amulet and amulet.object and not table.find(data.allAmulets, amulet.object.id) then
            mwse.log("ATA Clean: Found [%s, %s] bad reference, fixed.", amulet.object.id, amulet.object.name)
            tes3.removeItem {reference = data.superCrate, item = amulet.object, count = 9999}
            count = count + 1
        end
    end

    for amuletid, enchantment in pairs(save) do
        tes3.transferItem {
            from = data.superCrate,
            to = tes3.player,
            item = amuletid,
            playSound = false
        }
        tes3.getObject(amuletid).enchantment = enchantment
    end

    --for some reason some items in inventories is not detected in the loop above? so we repeat again just to make sure we got all items. this number is arbitrary
    if N < 2 then
        core.clean(count, N + 1, noMessage)
        return
    end

    if not noMessage then
        tes3.messageBox("Clean operation completed. Info in mwse.log")
        mwse.log("ATA Clean: Operation completed with %s issues", (count ~= 0) and count .. " fixed" or "no")
    end
end

core.dropBad = function(noMessage)
    local count = 0
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        --replace/remove bad amulet reference
        for amulet in cell:iterateReferences(tes3.objectType.clothing) do
            if string.find(amulet.id, "ata_kindi_amulet_") then
                local tomb = amulet.data.tomb
                if data.allAmulets[tomb] ~= amulet.object.id then
                    local newRef =
                        tes3.createReference {
                        object = data.allAmulets[tomb],
                        position = amulet.position:copy(),
                        cell = cell
                    }
                    newRef.data.tomb = tomb
                    if data.superCrate.object.inventory:contains(data.allAmulets[tomb]) then
                        tes3.removeItem {
                            reference = data.superCrate,
                            item = data.allAmulets[tomb],
                            playSound = false,
                            count = 9999
                        }
                    end
                    mwse.log("ATA Clean: Found [%s, %s] bad reference, fixed.", amulet.object.id, amulet.object.name)
                    amulet:disable()
                    mwscript.setDelete {reference = amulet, delete = true}
                    count = count + 1
                elseif not tes3.getCell {id = tomb} then
                    mwse.log("ATA Clean: Found [%s, %s] bad reference, fixed.", amulet.object.id, amulet.object.name)
                    amulet:disable()
                    mwscript.setDelete {reference = amulet, delete = true}
                    count = count + 1
                end
            end
        end
        --remove amulets without a valid tomb
        for cont in cell:iterateReferences(tes3.objectType.container, tes3.objectType.actor) do
            if cont ~= data.superCrate then
                for _, amulet in pairs(cont.object.inventory) do
                    if string.find(amulet.object.id, "ata_kindi_amulet_") then
                        local tomb = amulet.variables[1].data.tomb
                        if data.allAmulets[tomb] ~= amulet.object.id then
                            tes3.transferItem {
                                from = cont,
                                to = data.superCrate,
                                item = amulet.object.id,
                                playSound = false
                            }
                        elseif not tes3.getCell {id = tomb} then
                            mwse.log("ATA Clean: Found [%s, %s] no cell, fixed.", amulet.object.id, amulet.object.name)
                            tes3.removeItem {reference = cont, item = amulet.object.id, playSound = false, count = 9999}
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    for _, amulet in pairs(tes3.player.object.inventory) do
        if string.find(amulet.object.id, "ata_kindi_amulet_") then
            local tomb = amulet.variables[1].data.tomb
            if not tes3.getCell {id = tomb} then
                mwse.log("ATA Clean: Found [%s, %s] no cell, fixed.", amulet.object.id, amulet.object.name)
                tes3.mobilePlayer:unequip {item = amulet.object.id}
                tes3.removeItem {reference = tes3.player, item = amulet.object.id, playSound = false, count = 9999}
                count = count + 1
            end
        end
    end

    core.clean(count, 0, noMessage)
end

core.hardReset = function(uninstall)
    tes3.messageBox("Reset executed..")

    local instances = 0
    tes3.player.data.ata_kindi_data = {}
    tes3.player.data.ata_kindi_data.defaultTombs = {}
    tes3.player.data.ata_kindi_data.customTombs = {}
    data.rejectedTombs = {}
    tes3.player.data.ata_kindi_data.modifiedAmulets = {}
    tes3.player.data.ata_kindi_data.traversedCells = {}

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        --remove all references of amulet
        for amulet in cell:iterateReferences(tes3.objectType.clothing) do
            if string.find(amulet.id, "ata_kindi_amulet_") then
                mwse.log(amulet.id .. "(" .. amulet.object.name .. ")" .. " has been removed in " .. cell.id)
                amulet.itemData = nil
                amulet.modified = false
                amulet:disable()
                mwscript.setDelete {reference = amulet, delete = true}
                instances = instances + 1
            end
        end

        --remove all amulets from inventories
        for instance in cell:iterateReferences(tes3.objectType.actor) do
            if instance.object and instance.object.inventory then
                for _, amulet in pairs(instance.object.inventory) do
                    if string.find(amulet.object.id, "ata_kindi_amulet_") then
                        mwse.log(
                            amulet.object.id .. "(" .. amulet.object.name .. ")" .. " has been removed in " .. cell.id
                        )
                        amulet.object.modified = false
                        if amulet.variables then
                            amulet.variables[1].data.tomb = nil
                        end
                        tes3.removeItem {reference = instance, item = amulet.object.id, count = 9999}
                        instances = instances + 1
                    end
                end
            end
        end

        --remove all amulets from player
        for _, amulet in pairs(tes3.player.object.inventory) do
            if string.find(amulet.object.id, "ata_kindi_amulet_") then
                mwse.log(
                    amulet.object.id .. "(" .. amulet.object.name .. ")" .. " has been removed in " .. tes3.player.id
                )
                amulet.object.modified = false
                if amulet.variables then
                    amulet.variables[1].data.tomb = nil
                end
                tes3.mobilePlayer:unequip {item = amulet.object.id}
                tes3.removeItem {reference = tes3.player, item = amulet.object.id, 9999}
                instances = instances + 1
            end
        end
    end

    mwse.log("Ancestral Tomb Amulet resetting.. " .. instances .. " instances has been deleted")
    tes3.messageBox("Reset complete! Full info in mwse.log")

    if uninstall then
        tes3.player.data.ata_kindi_data = nil
    else
        core.initialize()
    end
end

core.refreshMCM = function()
    local MCMModList = tes3ui.findMenu("MWSE:ModConfigMenu").children

    for child in table.traverse(MCMModList) do
        if child.text == "Ancestral Tomb Amulets" then
            child:triggerEvent("mouseClick")
        end
    end
end

return core
