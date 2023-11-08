local distantLandConfig = require("colossus.distantLandConfig")
local cameraShake = require("colossus.effects.cameraShake")
local heartBeat = require("colossus.effects.heartBeat")

local flash = require("colossus.shaders.flash")
local blackout = require("colossus.shaders.blackout")

local log = require("colossus.log")
local utils = require("colossus.utils")

local exteriorConfig = {}
local interiorConfig = {
    render = {
        reflectSky = false,
        reflectInterior = false,
        reflectNearStatics = false,
        reflectiveWater = false,
    },
    colors = {
        ambientDayColor     = { 0.08369, 0.08995, 0.08263 },
        ambientNightColor   = { 0.12549, 0.13725, 0.16470 },
        ambientSunriseColor = { 0.18431, 0.25882, 0.37647 },
        ambientSunsetColor  = { 0.26666, 0.29411, 0.37647 },
        fogDayColor         = { 0.02032, 0.03054, 0.02176 },
        fogNightColor       = { 0.03529, 0.03921, 0.04313 },
        fogSunriseColor     = { 1.00000, 0.74117, 0.61568 },
        fogSunsetColor      = { 1.00000, 0.74117, 0.61568 },
        skyDayColor         = { 0.00000, 0.00000, 0.00000 },
        skyNightColor       = { 0.03529, 0.03921, 0.04313 },
        skySunriseColor     = { 0.45882, 0.55294, 0.64313 },
        skySunsetColor      = { 0.21960, 0.34901, 0.50588 },
        sunDayColor         = { 0.00029, 0.00000, 0.00000 },
        sunNightColor       = { 0.23137, 0.38039, 0.69019 },
        sunSunriseColor     = { 0.94901, 0.62352, 0.46666 },
        sunSunsetColor      = { 1.00000, 0.44705, 0.30980 },
        sundiscSunsetColor  = { 1.00000, 0.74117, 0.61568 },
    },
}

local function cacheExteriorConfig()
    if next(exteriorConfig) == nil then
        local weather = tes3.getCurrentWeather()

        exteriorConfig.render = {}
        for name in pairs(interiorConfig.render) do
            exteriorConfig.render[name] = mge.render[name]
        end

        exteriorConfig.colors = {}
        for name in pairs(interiorConfig.colors) do
            local color = weather[name]
            exteriorConfig.colors[name] = { color.r, color.g, color.b }
        end
    end
end

local function applyConfig(config)
    local weather = tes3.getCurrentWeather()

    for name, value in pairs(config.render) do
        mge.render[name] = value
    end
    for name, value in pairs(config.colors) do
        local color = weather[name]
        color.r = value[1]
        color.g = value[2]
        color.b = value[3]
    end

    tes3.worldController.weatherController:updateVisuals()
end

timer.register("colossus:jailArrival", function()
    tes3.updateJournal({ id = "ggw_02_tg", index = 5 })

    tes3.mobilePlayer.fatigue.current = 1

    -- Add Time Slow spell
    tes3.addSpell({ reference = tes3.player, spell = "ggw_slow_time" })

    -- Remove spell effects added by the artifact.

    for _, spell in pairs({
        "ggw_cave_spelleffect_01",
        "ggw_cave_spelleffect_02",
        "ggw_cave_spelleffect_02a",
        "ggw_cave_spelleffect_03",
        "ggw_cave_spelleffect_04",
        "ggw_cave_spelleffect_04a",
        "ggw_cave_spelleffect_05",
    }) do
        tes3.removeSpell({
            reference = tes3.player,
            spell = spell,
            updateGUI = false,
        })
    end

    -- Transfer items to the evidence chest.

    local evidenceChest = tes3.getReference("ggw_evidence_chest")
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object.canCarry ~= false then
            tes3.transferItem({
                from = tes3.player,
                to = evidenceChest,
                item = stack.object,
                count = stack.count,
                playSound = false,
                updateGUI = false,
            })
        end
    end

    tes3.updateInventoryGUI({ reference = tes3.player })
end)

timer.register("colossus:teleportJail", function()
    blackout.stop()
    cameraShake.stop()

    tes3.positionCell({
        cell = "Elsweyr, Imperial Outpost",
        position = { 508.01, -67.72, -628.55 },
        orientation = { 0.00, 0.00, 0.02 },
    })

    tes3.fadeIn({ duration = 6.0 })
    timer.start({ duration = 6.0, callback = "colossus:jailArrival" })
end)

timer.register("colossus:collapse", function()
    tes3.mobilePlayer.fatigue.current = -10000

    tes3.fadeOut({ duration = 1.5 })
    timer.start({ duration = 6.0, callback = "colossus:teleportJail" })
end)

--- Trigger effects when activating the artifact.
---
---@param e activateEventData
local function onActivate(e)
    if e.target.id ~= "ggw_artifact" then
        return
    end

    e.target:disable()

    flash.trigger({ duration = 1.5 })

    tes3.playSound({
        reference = tes3.player,
        sound = "ggw_teleport",
        mixChannel = tes3.soundMix.master,
    })

    -- Teleport to desert and do additional effects.
    timer.delayOneFrame(function()
        local pos = tes3.player.position
        local src = tes3.getReference("ggw_dune_teleport_src").position
        local dst = tes3.getReference("ggw_dune_teleport_dst").position
        tes3.player.position = dst + (pos - src)

        applyConfig(exteriorConfig)
        log:debug("exterior config applied")

        -- Skip to 7 am for pretty sunrise lighting.
        utils.setCurrentHour(7)

        -- Stop the artifact effects.
        heartBeat.stop()

        cameraShake.start({
            intensity = 2.0,
            duration = 15.0,
        })

        blackout.start({
            leadup = 4.0,
            duration = 15.0,
            delayMin = 1.5,
            delayMax = 3.0,
        })

        timer.start({
            duration = 15.0,
            callback = "colossus:collapse",
        })
    end)

    return false
end
event.register("activate", onActivate)


local function enteredAdasamsibi()
    local ref = tes3.getReference("ggw_artifact")
    if ref == nil then
        log:error("getReference Failed: 'ggw_artifact'")
        return
    end

    cacheExteriorConfig()

    applyConfig(interiorConfig)
    log:debug("interior config applied")

    distantLandConfig.setEnabled(true)

    local index = tes3.getJournalIndex({ id = "ggw_01_intro" })
    if index < 100 then
        heartBeat.start(ref)
        tes3.streamMusic({ path = "ggw\\silence.mp3", situation = tes3.musicSituation.uninterruptible })
    end
end


local function exitedAdasamsibi()
    applyConfig(exteriorConfig)
    log:debug("exterior config applied")

    heartBeat.stop()
    distantLandConfig.setEnabled(false)

    tes3.streamMusic({ path = "ggw\\silence.mp3", situation = tes3.musicSituation.uninterruptible })
end


local function onCellChanged(e)
    local isAdasamsibi = e.cell.id == "Adasamsibi"
    local wasAdasamsibi = e.previousCell and e.previousCell.id == "Adasamsibi"
    if isAdasamsibi and not wasAdasamsibi then
        enteredAdasamsibi()
    elseif wasAdasamsibi and not isAdasamsibi then
        exitedAdasamsibi()
    end
end
event.register("cellChanged", onCellChanged, { priority = 1 })

local function onMusicSelectTrack(e)
    local cell = tes3.getPlayerCell()
    if cell.id == "Adasamsibi" then
        e.music = "ggw\\silence.mp3"
        return false
    end
end
event.register("musicSelectTrack", onMusicSelectTrack, { priority = 360 })
