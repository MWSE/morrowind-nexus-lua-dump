local func = require("companionLeveler.functions.common")
local tables = require("companionLeveler.tables")

local ritual = {}

-- Helper: Show confirmation dialog
--- @ param msg string confirmation message
--- @ param spellID string spell id
--- @ param time number time spend to cast ritual
--- @ param tp integer amount of tp spent
local function showConfirmation(msg, spellID, time, tp)
    ritual.choice = tes3.getObject(spellID)
    ritual.time = time
    ritual.tp = tp
    tes3.messageBox({
        message = msg,
        buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
        callback = ritual.execution
    })
end

function ritual.createWindow(ref)
    ritual.id_menu = tes3ui.registerID("kl_ritual_menu")
    ritual.id_label = tes3ui.registerID("kl_ritual_label")
    ritual.id_cancel = tes3ui.registerID("kl_ritual_cancel_btn")

    ritual.ref = ref
    ritual.target = ref
    ritual.tech = require("companionLeveler.menus.techniques.techniques")

    local menu = tes3ui.createMenu { id = ritual.id_menu, fixedFrame = true }
    ritual.menu = menu
    local modData = func.getModData(ref)

    -- Labels
    local label = menu:createLabel { text = "Rituals", id = ritual.id_label }
    label.wrapText = true
    label.justifyText = "center"
    menu:createDivider { borderBottom = 28 }

    -- Button Block
    local ritual_block = menu:createBlock { id = "kl_ritual_block" }
    ritual_block.flowDirection = "top_to_bottom"
    ritual_block.autoHeight = true
    ritual_block.autoWidth = true
    ritual_block.paddingLeft = 10
    ritual_block.paddingRight = 10
    ritual_block.widthProportional = 1.0
    ritual_block.childAlignX = 0.5

    -- Ritual Buttons --

	--Creature Rituals
    if ref.object.objectType == tes3.objectType.creature or modData.metamorph == true then
        if modData.guildTraining and (modData.guildTraining[1] == tables.factions[5] or modData.guildTraining[2] == tables.factions[5]) then
            local msg = "Perform the Almsivi Intervention Ritual?\nTP Cost: 2\nTime Cost: 10 Minutes"
            ritual_block:createButton { text = "Almsivi Intervention" }
                :register("mouseClick", function() showConfirmation(msg, "almsivi intervention", (1 / 6), 2) end)
        end
        if modData.abilities[85] then
            local msg = ("Perform the Cure Common Disease Ritual on %s?\nTP Cost: 2\nTime Cost: 5 Minutes"):format(ref.object.name)
            ritual_block:createButton { text = "Cure Common Disease" }
                :register("mouseClick", function() showConfirmation(msg, "cure common disease", (1 / 12), 2) end)
        end
        if modData.abilities[87] then
            local msg = ("Perform the Cure Blight Disease Ritual on %s?\nTP Cost: 2\nTime Cost: 10 Minutes"):format(ref.object.name)
            ritual_block:createButton { text = "Cure Blight Disease" }
                :register("mouseClick", function() showConfirmation(msg, "cure blight disease", (1 / 6), 2) end)
        end
        if modData.abilities[89] then
            local msg = ("Perform the Telekinesis Ritual on %s?\nTP Cost: 2\nTime Cost: 5 Minutes"):format(tes3.player.object.name)
            ritual.target = tes3.mobilePlayer
            ritual_block:createButton { text = "Telekinesis" }
                :register("mouseClick", function() showConfirmation(msg, "kl_ritual_telekinesis", (1 / 12), 2) end)
        end
        if modData.abilities[91] then
            local msg = ("Perform the Levitation Ritual on %s?\nTP Cost: 2\nTime Cost: 5 Minutes"):format(tes3.player.object.name)
            ritual.target = tes3.mobilePlayer
            ritual_block:createButton { text = "Levitate" }
                :register("mouseClick", function() showConfirmation(msg, "levitate", (1 / 12), 2) end)
        end
        if modData.abilities[92] then
            local msg = ("Perform the Dispel Ritual on %s?\nTP Cost: 2\nTime Cost: 5 Minutes"):format(tes3.player.object.name)
            ritual.target = tes3.mobilePlayer
            ritual_block:createButton { text = "Dispel" }
                :register("mouseClick", function() showConfirmation(msg, "dispel", (1 / 12), 2) end)
        end
        if modData.abilities[95] then
            local msg = ("Perform the Second Barrier Ritual on %s?\nTP Cost: 2\nTime Cost: 5 Minutes"):format(ref.object.name)
            ritual_block:createButton { text = "Second Barrier" }
                :register("mouseClick", function() showConfirmation(msg, "second barrier", (1 / 12), 2) end)
        end
    end

    -- Cancel Button
    ritual_block:createButton { id = ritual.id_cancel, text = tes3.findGMST("sCancel").value }:register("mouseClick",
	function()
		menu:destroy()
		ritual.tech.createWindow(ref)
    end)

    menu:updateLayout()
    tes3ui.enterMenuMode(ritual.id_menu)
end

function ritual.execution(e)
    if not ritual.menu then return end
    if e.button ~= 0 then return end

    if ritual.choice == "almsivi intervention" then
		--Siwwy wittle teweport wituwals
        if tes3.getWorldController().flagTeleportingDisabled then
            func.clMessageBox(tes3.findGMST("sTeleportDisabled").value)
            return
        end
        if not func.spendTP(ritual.ref, ritual.tp) then return end
        tes3.setGlobal('GameHour', tes3.getGlobal('GameHour') + ritual.time)
        tes3ui.leaveMenuMode()
        ritual.menu:destroy()
        tes3.messageBox("%s performed the Ritual of Almsivi Intervention!", ritual.ref.object.name)
        local almsivi = tes3.findClosestExteriorReferenceOfObject { object = "TempleMarker", position = tes3.getLastExteriorPosition() }
        tes3.positionCell { reference = tes3.player, cell = almsivi.cell, position = almsivi.position, orientation = almsivi.orientation, forceCellChange = true }
        tes3.playSound { sound = "mysticism hit" }
        tes3.createVisualEffect { object = "VFX_MysticismHit", lifespan = 3, reference = ritual.ref }
    else
		--Normal Rituals
        if not func.spendTP(ritual.ref, ritual.tp) then return end
        tes3.setGlobal('GameHour', tes3.getGlobal('GameHour') + ritual.time)
        tes3ui.leaveMenuMode()
        ritual.menu:destroy()
        tes3.messageBox("%s performed the Ritual of %s!", ritual.ref.object.name, ritual.choice.name)
        if ritual.target == tes3.mobilePlayer and ritual.choice.effects[1].rangeType == tes3.effectRange.self then
            --Target Cast on Self
            tes3.cast { reference = ritual.target, target = ritual.target, spell = ritual.choice, instant = true, bypassResistances = true }
        else
            --Caster Cast on Target
            tes3.cast { reference = ritual.ref, target = ritual.target, spell = ritual.choice, instant = true, bypassResistances = true }
        end
    end
end

return ritual