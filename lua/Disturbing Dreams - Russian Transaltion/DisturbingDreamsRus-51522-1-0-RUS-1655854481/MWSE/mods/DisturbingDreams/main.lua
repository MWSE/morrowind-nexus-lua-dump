local function safeDelete(reference)
    tes3.positionCell{
        reference = reference, 
        position = { 0, 0, 10000, },
    }
    reference:disable()
    timer.delayOneFrame(function()
        mwscript.setDelete{reference = reference}
    end)
end

local function onUiShowRestMenu(e)
    return false
end

local function dreamEnd()
    tes3.positionCell{
        reference = tes3.player,
        cell = tes3.player.data.DisturbingDreams.cell,
        position = tes3.player.data.DisturbingDreams.position,
        teleportCompanions = false
    }
    for i, stack in pairs(tes3.player.object.inventory) do
        -- tes3.removeItem{
        --     reference = tes3.player,
        --     item = stack.object,
        --     count = stack.count,
        --     playSound = false,
        --     reevaluateEquipment = false,
        -- }
        tes3.transferItem{
            from = tes3.player,
            to = "sx_lame_01",
            item = stack.object,
            count = stack.count,
            playSound = false,
            limitCapacity = false,
            reevaluateEquipment = true,
        }
    end
    local sleepStash = tes3.getReference("DD_SleepStash")
    for i, stack in pairs(sleepStash.object.inventory) do
        local item = stack.object.id
        local equipped = mwscript.hasItemEquipped{reference = sleepStash, item = item}
        tes3.transferItem{
            from = sleepStash,
            to = tes3.player,
            item = stack.object,
            count = stack.count,
            playSound = false,
            limitCapacity = false,
            reevaluateEquipment = false,
        }
        if equipped then
			tes3.mobilePlayer:equip{item=item}
		end
    end
    safeDelete(sleepStash)
    tes3.getCell("Path of the Sleeper").modified = false
    event.unregister("uiShowRestMenu", onUiShowRestMenu)
end

dreamExit = {
    --DD_ExitDoor = true,
    DD_bedrollExit = true
}

local function onActivate(e)
    if dreamExit[e.target.id] then
        if tes3.canRest({checkForSolidGround = false}) then
            dreamEnd()
            return false
        else
            tes3.messageBox(tes3.findGMST("sNotifyMessage2").value)
        end
    end
    -- if e.target.baseObject.objectType == tes3.objectType.miscItem then
    --     tes3.messageBox("Misc is picked up")
    --     tes3.createReference{
    --         object = e.target.id,
    --         cell = "Path of the Sleeper",
    --         position = e.target.position,
    --         orientation = e.target.orientation
    --     }
    -- end
end

local function onEquip(e)
    if e.reference == tes3.player then
        if string.startswith(e.item.id, "DD_ingred_6th_corprusmeat_") then
            tes3.mobilePlayer:equip{item="DD_CorprusMeat", addItem=true}
        end
    end
end

local function dreamStart()
    mwscript.stopScript("DD_DreamStart_Script")
    tes3.player.data.DisturbingDreams = {
        cell = tes3.getPlayerCell().id,
        position = {tes3.player.position.x, tes3.player.position.y, tes3.player.position.z}
    }
    tes3.positionCell{
        reference = tes3.player,
        cell = tes3.getCell{id = "Path of the Sleeper"},
        position = {7285, 4920, 177720},
        teleportCompanions = false
    }
    local sleepStash = tes3.createReference{
        object = "DD_SleepStash",
        cell = "Path of the Sleeper",
        position = {7285, 4920, 177720},
        orientation = {0,0,0}
    }
    for i, stack in pairs(tes3.player.object.inventory) do
        --mwse.log("Trasfering %s", stack.object.id)
        local equipped = mwscript.hasItemEquipped{reference = tes3.player, item = stack.object.id}
		local item = stack.object.id
        tes3.transferItem{
            from = tes3.player,
            to = sleepStash,
            item = stack.object,
            count = stack.count,
            playSound = false,
            limitCapacity = false,
            reevaluateEquipment = false,
        }
        if equipped then
			sleepStash.mobile:equip{item=item}
		end
    end
    tes3.worldController.flagTeleportingDisabled = true
    tes3.worldController.flagLevitationDisabled = true
    event.register("activate", onActivate)
    event.register("uiShowRestMenu", onUiShowRestMenu)
    event.register("equip", onEquip)
end



local function onLoaded(e)
    event.unregister("uiShowRestMenu", onUiShowRestMenu)
    event.unregister("activate", onActivate)
    tes3.worldController.flagTeleportingDisabled = false
    tes3.worldController.flagLevitationDisabled = false
    tes3.getObject("sx_lame_01").name = tes3.player.object.name
    tes3.getObject("DD_Lame").name = tes3.player.object.name
    if tes3.getPlayerCell().id == "Path of the Sleeper" or tes3.getPlayerCell().id == "Dome of the Sleeper" then
        tes3.worldController.flagTeleportingDisabled = true
        tes3.worldController.flagLevitationDisabled = true
        event.register("uiShowRestMenu", onUiShowRestMenu)
        event.register("activate", onActivate)
        event.register("equip", onEquip)
    end
end

local function onInitialized(e)
    if tes3.isModActive("DisturbingDreams.esp") then
        mwse.log("Disturbing Dreams: DisturbingDreams.esp is active. Mod content is enabled")
        mwse.overrideScript("DD_DreamStart_Script",  dreamStart)
        event.register("loaded", onLoaded)
    else
        mwse.log("Disturbing Dreams: DisturbingDreams.esp is not active. Mod content is disabled")
    end
end


event.register("initialized", onInitialized)