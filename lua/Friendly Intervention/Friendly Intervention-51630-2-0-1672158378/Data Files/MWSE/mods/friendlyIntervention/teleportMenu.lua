local config = require("friendlyIntervention.config")
local logger = require("logging.logger")
local log = logger.getLogger("Friendly Intervention")
local func = require("friendlyIntervention.common")
local tables = require("friendlyIntervention.tables")


local port = {}

function port.openMenu(ref)
    log = logger.getLogger("Friendly Intervention")
    log:debug("Teleport menu initialized.")

    --Teleportation Disabled Check
    if tes3.worldController.flagTeleportingDisabled == true then
        log:info("Teleport menu aborted. Teleportation is currently disabled.")
        local vanRace = 0
        for i = 1, 10 do
            if ref.object.race.name == tables.raceNames[i] then
                tes3.messageBox({ message = tables.noTeleportMsg[i], duration = 0 })
                vanRace = 1
            end
        end
        if vanRace == 0 then
            tes3.messageBox({ message = tes3.findGMST("sTeleportDisabled").value, duration = 0 })
        end
        return
    end

    --Initialize IDs
    port.id_menu = tes3ui.registerID("kl_teleport_menu")
    port.id_pane = tes3ui.registerID("kl_teleport_pane")
    port.id_ok = tes3ui.registerID("kl_teleport_ok")
    port.id_cancel = tes3ui.registerID("kl_teleport_cancel")
    port.id_mark = tes3ui.registerID("kl_teleport_mark")

    --Initialize menu variables
    port.teleTable = {}
    port.magickaCost = 0
    port.teleporter = ref
    port.destination = 0
    port.currentMyst = ref.mobile:getSkillValue(14)
    port.costRoundT = func.calculateCost(port.currentMyst)
    port.costRoundM = func.calculateCost(port.currentMyst + 20)

    local menu = tes3ui.createMenu { id = port.id_menu, fixedFrame = true }

    -- Create layout
    local input_label = menu:createLabel { text = "Who should " .. ref.object.name .. " teleport?" }
    input_label.borderBottom = 5

    local pane_block = menu:createBlock { id = "pane_block_sum" }
    pane_block.autoWidth = true
    pane_block.autoHeight = true

    local border = pane_block:createThinBorder {}
    border.positionX = 4
    border.positionY = -4
    border.width = 220
    border.height = 280
    border.borderAllSides = 4
    border.borderTop = 5
    border.paddingAllSides = 4

    local pane = border:createVerticalScrollPane({ id = port.id_pane })
    pane.height = 290
    pane.width = 220
    pane.positionX = 4
    pane.positionY = -4
    pane.widget.scrollbarVisible = true
    pane.wrapText = true

    --Populate Pane--------------------------------------------------------------------------------

    --Targets Divider
    local targetLabel = pane:createLabel({ text = "Targets" })
    if config.noColor == false then
        targetLabel.color = { 0.92, 0.58, 0.9 }
    end
    targetLabel.wrapText = true
    targetLabel.justifyText = "center"
    local divider2 = pane:createDivider()
    divider2.borderBottom = 12

    --Party Members
    local companionTable = {}
    for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if (func.validCompanionCheck(mobileActor)) then
            companionTable[#companionTable + 1] = mobileActor.reference
            log:debug("" .. mobileActor.reference.object.name .. " added to companion list.")
        end
    end

    if config.skillLimit == true then
        --Check if NPC can teleport others
        if port.currentMyst >= config.npcSkillReqO then
            local player = pane:createTextSelect { text = "" .. tes3.mobilePlayer.object.name .. "",
                id = "kl_teleport_ref_0" }
            player:register("mouseClick", function(e) port.onSelect(tes3.mobilePlayer, 0) end)

            for i = #companionTable, 1, -1 do
                local companionRef = companionTable[i]
                local name = companionRef.object.name
                local listItem = pane:createTextSelect { text = "" .. name .. "", id = "kl_teleport_ref_" .. i .. "" }
                listItem:register("mouseClick", function(e) port.onSelect(companionRef, i) end)
            end
        else
            local self = pane:createTextSelect { text = "" .. port.teleporter.object.name .. "", id = "kl_teleport_ref_0" }
            self:register("mouseClick", function(e) port.onSelect(port.teleporter, 0) end)
        end
    else
        local player = pane:createTextSelect { text = "" .. tes3.mobilePlayer.object.name .. "",
            id = "kl_teleport_ref_0" }
        player:register("mouseClick", function(e) port.onSelect(tes3.mobilePlayer, 0) end)

        for i = #companionTable, 1, -1 do
            local companionRef = companionTable[i]
            local name = companionRef.object.name
            local listItem = pane:createTextSelect { text = "" .. name .. "", id = "kl_teleport_ref_" .. i .. "" }
            listItem:register("mouseClick", function(e) port.onSelect(companionRef, i) end)
        end
    end

    --Destinations Divider
    local destinationLabel = pane:createLabel({ text = "Destinations" })
    if config.noColor == false then
        destinationLabel.color = { 0.92, 0.58, 0.9 }
    end
    destinationLabel.borderTop = 24
    destinationLabel.wrapText = true
    destinationLabel.justifyText = "center"
    local divider4 = pane:createDivider()
    divider4.borderBottom = 12

    --Vanilla Destinations
    local almsivi = pane:createTextSelect { text = "Almsivi Intervention",
        id = "kl_teleport_dest_1" }
    almsivi:register("mouseClick", function(e) port.onSelectD(1) end)

    local divine = pane:createTextSelect { text = "Divine Intervention",
        id = "kl_teleport_dest_2" }
    divine:register("mouseClick", function(e) port.onSelectD(2) end)

    local recallCheck = tes3.mobilePlayer.markLocation
    if recallCheck then
        local recall = pane:createTextSelect { text = "Recall (" .. tes3.mobilePlayer.object.name .. ")",
            id = "kl_teleport_dest_3" }
        recall:register("mouseClick", function(e) port.onSelectD(3) end)
    end

    if config.npcMark == true then
        local modData = func.getModData(ref)
        if modData.cell ~= "" then
            local recall = pane:createTextSelect { text = "Recall (" .. ref.object.name .. ")",
                id = "kl_teleport_dest_16" }
            recall:register("mouseClick", function(e) port.onSelectD(16) end)
        end
    end

    --Magicka Expanded Destinations

    if config.mExpanded == true then
        for i = 4, 15 do
            if tes3.hasSpell({ reference = tes3.mobilePlayer, spell = tables.meSpells[i] }) == true then
                local listItems = pane:createTextSelect { text = tables.meText[i],
                    id = "kl_teleport_dest_" .. i .. "" }
                listItems:register("mouseClick", function(e) port.onSelectD(i) end)
            end
        end
    end

    --Populate Details----------------------------------------------------------------------------------------------
    local border2 = pane_block:createThinBorder { id = "kl_border2_sum" }
    border2.positionX = 204
    border2.positionY = 0
    border2.width = 320
    border2.height = 280
    border2.borderAllSides = 5
    border2.paddingAllSides = 4
    border2.borderRight = 4
    border2.wrapText = true
    border2.flowDirection = "top_to_bottom"

    --Teleporter Mysticism Skill
    local mystDetail = border2:createLabel({ text = "" ..
        ref.object.name .. "'s Mysticism Skill: " .. port.currentMyst .. "", id = "kl_portdetail_myst" })
    if config.noColor == false then
        local mystValue = port.currentMyst
        if mystValue < 1 then
            mystValue = 1
        end
        local r = 1 - (mystValue / 300)
        if r < 0.38 then
            r = 0.38
        end
        local g = 1 - (mystValue / 155)
        if g < 0.13 then
            g = 0.13
        end
        local b = 1 - (mystValue / 302)
        if b < 0.36 then
            b = 0.36
        end
        mystDetail.color = { r, g, b }
    end

    --Teleporter Magicka
    local mgkDetail = border2:createLabel({ text = "" ..
        ref.object.name .. "'s Magicka: " .. ref.mobile.magicka.current .. "/" .. ref.mobile.magicka.base .. "",
        id = "kl_portdetail_mgk_current" })
    if (config.magickaReq == true and config.noColor == false) then
        local r = 1.14 - (ref.mobile.magicka.normalized)
        if r < 0.2 then
            r = 0.2
        end
        if r > 0.7 then
            r = 0.7
        end
        local g = ref.mobile.magicka.normalized + 0.14
        if g < 0.2 then
            g = 0.2
        end
        if g > 0.7 then
            g = 0.7
        end
        mgkDetail.color = { r, g, 0.2 }
    end
    mgkDetail.borderBottom = 12

    --Teleport Costs
    if config.magickaReq == true then
        local teleDetail = border2:createLabel({ text = "Teleport Target Cost: " .. port.costRoundT .. "",
            id = "kl_portdetail_tele_cost" })
        if config.npcMark == true then
            local markDetail = border2:createLabel({ text = "Mark Cost: " .. port.costRoundM .. "",
                id = "kl_portdetail_mark_cost" })
            markDetail.borderBottom = 12
        else
            teleDetail.borderBottom = 12
        end
    end

    local totalCostDetail = border2:createLabel({ text = "Total Cost: " .. port.magickaCost .. "",
        id = "kl_portdetail_mgk_cost" })
    totalCostDetail.borderBottom = 12

    border2:createLabel({ text = "Destination:", id = "kl_portdetail_dest" })

    --button block
    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 1.0

    local button_ok = button_block:createButton { id = port.id_ok, text = "Teleport" }

    if config.npcMark == true then
        local button_mark = button_block:createButton { id = port.id_mark, text = "Cast Mark" }
        button_mark:register("mouseClick", function(e) port.onMark(ref) end)
    end

    local button_cancel = button_block:createButton { id = port.id_cancel, text = tes3.findGMST("sCancel").value }

    -- Events
    button_ok:register(tes3.uiEvent.mouseClick, port.onOK)
    button_cancel:register(tes3.uiEvent.mouseClick, port.onCancel)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(port.id_menu)
end

function port.onSelect(ref, i)
    local menu = tes3ui.findMenu(port.id_menu)
    local listItem = menu:findChild("kl_teleport_ref_" .. i .. "")
    local mgkLabel = menu:findChild("kl_portdetail_mgk_cost")

    if listItem.widget.state == 4 then
        --remove from list
        listItem.widget.state = 1

        for n = #port.teleTable, 1, -1 do
            if port.teleTable[n] == ref then
                table.remove(port.teleTable, n)
            end
        end

        --Update Magicka
        if port.magickaCost > 0 then
            if config.smnFree == true then
                local smnCheck = string.startswith(ref.object.name, "Summoned")
                if smnCheck == true then
                    log:debug("" .. ref.object.name .. " is a summoned creature. No magicka reduction!")
                else
                    port.magickaCost = port.magickaCost - port.costRoundT
                end
            else
                port.magickaCost = port.magickaCost - port.costRoundT
            end
        end

        mgkLabel.text = "Total Cost: " .. port.magickaCost .. ""
        if config.noColor == false then
            if port.magickaCost > port.teleporter.mobile.magicka.current then
                --red
                mgkLabel.color = { 0.65, 0.2, 0.2 }
            else
                --vanilla default
                mgkLabel.color = { 0.792, 0.647, 0.376 }
            end
        end
    else
        --add to list
        listItem.widget.state = 4
        port.teleTable[#port.teleTable + 1] = ref

        --Update Magicka
        if config.magickaReq == true then
            local costApplies = 1
            if config.smnFree == true then
                local smnCheck = string.startswith(ref.object.name, "Summoned")
                if smnCheck == true then
                    log:debug("" .. ref.object.name .. " is a summoned creature. Free teleport!")
                    costApplies = 0
                end
            end
            if costApplies == 1 then
                port.magickaCost = port.magickaCost + port.costRoundT
            end
        end

        mgkLabel.text = "Total Cost: " .. port.magickaCost .. ""
        if config.noColor == false then
            if port.magickaCost > port.teleporter.mobile.magicka.current then
                --red
                mgkLabel.color = { 0.65, 0.2, 0.2 }
            else
                --vanilla default
                mgkLabel.color = { 0.792, 0.647, 0.376 }
            end
        end
    end
    menu:updateLayout()
end

function port.onSelectD(i)
    local menu = tes3ui.findMenu(port.id_menu)
    local pane = menu:findChild(port.id_pane)
    local destSelection = menu:findChild("kl_teleport_dest_" .. i .. "")
    local destLabel = menu:findChild("kl_portdetail_dest")
    if destSelection.widget.state == 1 then

        for n = 1, 16 do
            local others = pane:findChild("kl_teleport_dest_" .. n .. "")
            if others then
                if others.widget.state == 4 then
                    others.widget.state = 1
                end
            end
        end
        destSelection.widget.state = 4

        --Update Destination
        destLabel.text = "Destination: " .. destSelection.text .. ""

        if i == 1 then
            local almsivi = tes3.findClosestExteriorReferenceOfObject({
                object = "TempleMarker",
                position = tes3.getLastExteriorPosition(),
            })
            destLabel.text = "Destination: " .. almsivi.cell.displayName .. ""
        end
        if i == 2 then
            local divine = tes3.findClosestExteriorReferenceOfObject({
                object = "DivineMarker",
                position = tes3.getLastExteriorPosition(),
            })
            destLabel.text = "Destination: " .. divine.cell.displayName .. ""
        end
        if i == 3 then
            local mark = tes3.mobilePlayer.markLocation
            destLabel.text = "Destination: " .. mark.cell.displayName .. ""
        end
        if i == 16 then
            local modData = func.getModData(port.teleporter)
            local cell = modData.cell
            destLabel.text = "Destination: " .. cell.name .. ""
        end

        port.destination = i
        menu:updateLayout()
    end
end

function port.onCancel()
    local menu = tes3ui.findMenu(port.id_menu)
    if menu then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

function port.onMark(ref)
    local menu = tes3ui.findMenu(port.id_menu)
    --Confirm Mark to avoid mistakes
    if (menu) then
        if config.magickaReq == true then
            tes3.messageBox({ message = "Set " ..
                ref.object.name .. "'s mark to " .. ref.cell.displayName .. " for " .. port.costRoundM .. " magicka?",
                buttons = { "Yes", "No" }, callback = port.castMark })
        else
            tes3.messageBox({ message = "Set " ..
                ref.object.name .. "'s mark to " .. ref.cell.displayName .. "?",
                buttons = { "Yes", "No" }, callback = port.castMark })
        end
    end
end

function port.castMark(e)
    local menu = tes3ui.findMenu(port.id_menu)
    if menu then
        --Cast Mark
        if e.button == 0 then
            local modData = func.getModData(port.teleporter)
            local cell = port.teleporter.cell
            local position = tes3.getPlayerEyePosition()

            if config.magickaReq == true then
                --Magicka Required
                if port.teleporter.mobile.magicka.current < port.costRoundM then
                    --Not Enough Magicka
                    if config.playSound == true then
                        tes3.playSound({ sound = "Spell Failure Mysticism", volume = 0.8 })
                    end
                    tes3.messageBox("" .. port.teleporter.object.name .. " doesn't have enough magicka!")
                else
                    --Enough Magicka
                    local mgkLabel = menu:findChild("kl_portdetail_mgk_current")
                    tes3.setStatistic({ name = "magicka",
                        current = (port.teleporter.mobile.magicka.current - port.costRoundM),
                        reference = port.teleporter })
                    mgkLabel.text = "" ..
                        port.teleporter.object.name ..
                        "'s Magicka: " ..
                        port.teleporter.mobile.magicka.current .. "/" .. port.teleporter.mobile.magicka.base .. ""
                    if config.noColor == false then
                        local r = 1.14 - (port.teleporter.mobile.magicka.normalized)
                        if r < 0.25 then
                            r = 0.25
                        end
                        if r > 0.75 then
                            r = 0.75
                        end
                        local g = port.teleporter.mobile.magicka.normalized + 0.14
                        if g < 0.25 then
                            g = 0.25
                        end
                        if g > 0.75 then
                            g = 0.75
                        end
                        mgkLabel.color = { r, g, 0.25 }
                    end
                    --Set Mark Cell/Position
                    modData.cell = cell
                    modData.position = position
                    if config.playSound == true then
                        tes3.playSound({ sound = "mysticism cast", volume = 0.8 })
                    end
                    tes3.messageBox("" .. port.teleporter.object.name .. " set their mark.")
                end
            else
                --No Magicka Required
                modData.cell = cell
                modData.position = position
                if config.playSound == true then
                    tes3.playSound({ sound = "mysticism cast", volume = 0.8 })
                end
                tes3.messageBox("" .. port.teleporter.object.name .. " set their mark.")
            end
        end
    end
end

function port.onOK()
    if port.destination == 0 then
        tes3.messageBox("Select a destination.")
        return
    end
    if #port.teleTable < 1 then
        tes3.messageBox("No targets selected.")
        return
    end

    local almsivi = tes3.findClosestExteriorReferenceOfObject({
        object = "TempleMarker",
        position = tes3.getLastExteriorPosition(),
    })
    local divine = tes3.findClosestExteriorReferenceOfObject({
        object = "DivineMarker",
        position = tes3.getLastExteriorPosition(),
    })

    local recall = tes3.mobilePlayer.markLocation
    local menu = tes3ui.findMenu(port.id_menu)
    local modData = func.getModData(port.teleporter)
    if config.magickaReq == true then
        --Not Enough Magicka
        if port.teleporter.mobile.magicka.current < port.magickaCost then
            if config.playSound == true then
                tes3.playSound({ sound = "Spell Failure Mysticism", volume = 0.8 })
            end
            tes3.messageBox("" .. port.teleporter.object.name .. " doesn't have enough magicka!")
        else
            --Enough Magicka
            if (menu) then
                for i = #port.teleTable, 1, -1 do
                    local companionRef = port.teleTable[i]
                    local name = companionRef.object.name
                    local pitch = func.calculatePitch()
                    if config.playEffect == true then
                        tes3.createVisualEffect({ object = "VFX_MysticismHit", lifespan = 1, reference = companionRef })
                    end
                    --almsivi
                    if port.destination == 1 then
                        tes3.positionCell({ reference = companionRef, cell = almsivi.cell, position = almsivi.position,
                            orientation = almsivi.orientation,
                            teleportCompanions = false, forceCellChange = true })
                        if config.msgEnabled == true then
                            tes3.messageBox("" .. name .. " teleported using Almsivi Intervention!")
                        end
                    end
                    --divine
                    if port.destination == 2 then
                        tes3.positionCell({ reference = companionRef, cell = divine.cell, position = divine.position,
                            orientation = divine.orientation,
                            teleportCompanions = false, forceCellChange = true })
                        if config.msgEnabled == true then
                            tes3.messageBox("" .. name .. " teleported using Divine Intervention!")
                        end
                    end
                    --player recall
                    if port.destination == 3 then
                        tes3.positionCell({ reference = companionRef, cell = recall.cell, position = recall.position,
                            teleportCompanions = false, forceCellChange = true })
                        if config.msgEnabled == true then
                            tes3.messageBox("" .. name .. " teleported using Recall!")
                        end
                    end
                    --NPC recall
                    if port.destination == 16 then
                        tes3.positionCell({ reference = companionRef, cell = modData.cell, position = modData.position,
                            teleportCompanions = false, forceCellChange = true })
                        if config.msgEnabled == true then
                            tes3.messageBox("" .. name .. " teleported using Recall!")
                        end
                    end
                    --magicka expanded
                    for n = 4, 15 do
                        if port.destination == n then
                            tes3.positionCell({
                                reference = companionRef,
                                position = tables.mePosition[n],
                                orientation = tables.meOrientation[n],
                                cell = tables.meText[n],
                                teleportCompanions = false,
                                forceCellChange = true
                            })
                            if config.msgEnabled == true then
                                tes3.messageBox("" .. name .. " teleported to " .. tables.meText[n] .. "!")
                            end
                        end
                    end
                    if config.playSound == true then
                        tes3.playSound({ sound = "mysticism hit", volume = 0.8, pitch = pitch })
                    end
                    if config.playEffect == true then
                        tes3.createVisualEffect({ object = "VFX_MysticismHit", lifespan = 3, reference = companionRef })
                    end
                end
                tes3.setStatistic({ name = "magicka",
                    current = (port.teleporter.mobile.magicka.current - port.magickaCost), reference = port.teleporter })
                tes3ui.leaveMenuMode()
                menu:destroy()
            end
        end
    else
        --No Magicka Needed
        if (menu) then
            for i = #port.teleTable, 1, -1 do
                local companionRef = port.teleTable[i]
                local name = companionRef.object.name
                local pitch = func.calculatePitch()
                if config.playEffect == true then
                    tes3.createVisualEffect({ object = "VFX_MysticismHit", lifespan = 1, reference = companionRef })
                end
                --almsivi
                if port.destination == 1 then
                    tes3.positionCell({ reference = companionRef, cell = almsivi.cell, position = almsivi.position,
                        orientation = almsivi.orientation,
                        teleportCompanions = false, forceCellChange = true })
                    if config.msgEnabled == true then
                        tes3.messageBox("" .. name .. " teleported using Almsivi Intervention!")
                    end
                end
                --divine
                if port.destination == 2 then
                    tes3.positionCell({ reference = companionRef, cell = divine.cell, position = divine.position,
                        orientation = divine.orientation,
                        teleportCompanions = false, forceCellChange = true })
                    if config.msgEnabled == true then
                        tes3.messageBox("" .. name .. " teleported using Divine Intervention!")
                    end
                end
                --player recall
                if port.destination == 3 then
                    tes3.positionCell({ reference = companionRef, cell = recall.cell, position = recall.position,
                        teleportCompanions = false, forceCellChange = true })
                    if config.msgEnabled == true then
                        tes3.messageBox("" .. name .. " teleported using Recall!")
                    end
                end
                --NPC recall
                if port.destination == 16 then
                    tes3.positionCell({ reference = companionRef, cell = modData.cell, position = modData.position,
                        teleportCompanions = false, forceCellChange = true })
                    if config.msgEnabled == true then
                        tes3.messageBox("" .. name .. " teleported using Recall!")
                    end
                end
                --magicka expanded
                for n = 4, 15 do
                    if port.destination == n then
                        tes3.positionCell({
                            reference = companionRef,
                            position = tables.mePosition[n],
                            orientation = tables.meOrientation[n],
                            cell = tables.meText[n],
                            teleportCompanions = false,
                            forceCellChange = true
                        })
                        if config.msgEnabled == true then
                            tes3.messageBox("" .. name .. " teleported to " .. tables.meText[n] .. "!")
                        end
                    end
                end
                if config.playSound == true then
                    tes3.playSound({ sound = "mysticism hit", volume = 0.8, pitch = pitch })
                end
                if config.playEffect == true then
                    tes3.createVisualEffect({ object = "VFX_MysticismHit", lifespan = 3, reference = companionRef })
                end
            end
            tes3ui.leaveMenuMode()
            menu:destroy()
        end
    end
end

return port
