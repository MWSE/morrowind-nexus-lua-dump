local quest = require("firemoth.quests.lib")
local diversion = require("firemoth.quests.diversion")
local skeletonSpawner = require("firemoth.quests.skeletonSpawner")
local skeletonEquipper = dofile("firemoth.quests.skeletonEquipper")

--[[
    Journal Events
--]]

event.register("firemoth:questAccepted", function()
    quest.setPersistentReferencesDisabled(false)
    quest.setClutterReferencesDisabled(false)
end)

event.register("firemoth:travelAccepted", function()
    -- Remove the boat from Seyda Neen.
    quest.setClutterReferencesDisabled(true)

    -- Disable skeleton spawning until NPCs are ready.
    tes3.player.data.fm_skeletonSpawnerDisabled = true

    -- Position player and companions beside the boat.
    tes3.positionCell({
        reference = tes3.player,
        position = { -56035.83, -72520.91, 14.56 },
        orientation = { 0.00, 0.00, -3.10 },
    })
    tes3.positionCell({
        reference = quest.npcs.hjrondir,
        position = { -55987.22, -72829.97, 30.80 },
        orientation = { 0.00, 0.00, -0.12 },
    })
    tes3.positionCell({
        reference = quest.npcs.aronil,
        position = { -56195.62, -72756.86, 12.85 },
        orientation = { 0.00, 0.00, 0.55 },
    })
    tes3.positionCell({
        reference = quest.npcs.mara,
        position = { -55812.18, -72776.85, 46.03 },
        orientation = { 0.00, 0.00, -0.50 },
    })
    tes3.positionCell({
        reference = quest.npcs.silmdar,
        position = { -55663.70, -72566.48, 64.11 },
        orientation = { 0.00, 0.00, -1.71 },
    })

    for ref in quest.companionReferences() do
        -- Disable greetings; we play custom sounds instead.
        ref.mobile.hello = 0
        -- Bias idle chances to prefer "Look over shoulders".
        tes3.setAIWander({ reference = ref, range = 0, idles = { 30, 30, 10, 10, 10, 10, 0 } })
    end

    timer.start({
        duration = 1.5,
        callback = function()
            tes3.say({ reference = quest.npcs.mara, soundPath = "vo\\w\\f\\Idl_WF006.mp3" })
        end,
    })

    timer.start({
        duration = 3.5,
        callback = function()
            tes3.say({ reference = quest.npcs.aronil, soundPath = "vo\\h\\m\\Hlo_HM060.mp3" })
        end,
    })

    timer.start({
        duration = 6.5,
        callback = function()
            tes3.say({ reference = quest.npcs.hjrondir, soundPath = "vo\\n\\m\\bIdl_NM013.mp3" })
        end,
    })

    diversion.start()
end)

event.register("firemoth:backdoorEntered", function()
    quest.npcs.mara:disable()
    quest.npcs.aronil:disable()
    quest.npcs.hjrondir:disable()

    quest.npcs.hjrondirUndead:enable()
    quest.npcs.hjrondirUndead.data.fm_skeletonsIgnore = true
end)

-- Override behavior of various Firemoth doors.
event.register(tes3.event.activate, function(e)
    ---@cast e activateEventData

    if e.activator ~= tes3.player then
        return
    elseif quest.backdoorEntered() then
        return
    end

    local destination = e.target.destination
    local cell = destination and destination.cell
    if not (cell and cell.isInterior) then
        return
    end

    local id = cell.id
    if not id:startswith("Firemoth") then
        return
    end
    if id == "Firemoth, Upper Mines" then
        if quest.diversionStarted() then
            quest.setBackdoorEntered()
            pcall(function() quest.npcs.silmdar.mobile.health.current = 0 end)
        end
        return
    end

    if not tes3.player.object.inventory:contains("fm_keep_key") then
        tes3.playSound({ sound = "LockedDoor" })
        return false
    end
end)

-- Disable traveling until all NPCs are recruited.
event.register(tes3.event.activate, function(e)
    ---@cast e activateEventData

    if e.activator ~= tes3.player then
        return
    elseif quest.travelFinished() then
        return
    elseif e.target ~= quest.npcs.silmdar then
        return
    end

    local variable = tes3.findGlobal("fm_companions_gathered")
    variable.value = 1 -- all companions gathered

    local position = tes3.player.position
    for ref in quest.companionReferences() do
        if position:distance(ref.position) > 1024 then
            variable.value = 0 -- companion missing
        end
    end
end)

-- Handle compaion recall scroll quest item.
event.register(tes3.event.equip, function(e)
    ---@cast e equipEventData

    if e.reference ~= tes3.player then
        return
    elseif e.item.id ~= "fm_sc_recall" then
        return
    end

    if not quest.backdoorEntered() then
        tes3.messageBox("This scroll can only be used inside Fort Firemoth.")
        return false
    end

    if not quest.companionsRecalled() then
        quest.setCompanionsRecalled()

        tes3ui.leaveMenuMode()

        tes3.playSound({
            reference = tes3.player,
            sound = "mysticism area",
        })

        tes3.createVisualEffect({
            reference = tes3.player,
            object = "VFX_MysticismCast",
            lifespan = 1.0,
        })

        timer.start({
            iterations = -1,
            duration = 0.35,
            callback = "firemoth:recallCompanions", ---@diagnostic disable-line
            persist = true,
        })

        return false
    end

    return false
end)

---@param e deathEventData
local function onDeath(e)
    if e.reference.baseObject.id == "fm_grurn" then
        tes3.player.data.fm_skeletonSpawnerDisabled = true
        tes3.player.data.fm_lightningDisabled = true
    end
end
event.register(tes3.event.death, onDeath)
