--[[
    ZdoImmersiveDeath

    Source code based on the code from
    Timely Escape v1.1.3 by JaceyS
]]--

local config = require("ZdoImmersiveDeath.config")
local escaping
local perspective
local teleporting
local timeScale
local report = ""

local storedDamagesTotal = 1
local storedDamages = {}
local maxStoredDamages = 10
local nextStoredDamageIndex = 1

-- prevent the player from saving during the escape, which would break everything if they then reloaded the save.
local function blockSave()
    if (escaping == true) then
        tes3.messageBox "I cannot save right now, I am dying"
        return false
    end
end
-- Prevent the player from loading during while the temporary event-registered functions are spun up, so that they don't stay on if they load a new game.
local function loadBlocker()
    return false
end

local function log(fmt, ...)
    return mwse.log("[ZdoImmersiveDeath] " .. fmt, ...)
end

local function removeDamagingEffects()
    -- remove damaging spell effects so that it does not immediately kill the player again
    for i=1, table.size(config.damagingEffectIDs) do
        tes3.removeEffects({effect = config.damagingEffectIDs[i], reference = tes3.player})
    end
end

local function finalizeEscape()
    -- if we played the death animation, we need to undo the effects of it.
    if(config.deathAnimation == true) then
        if (perspective == false)then tes3.force1stPerson() end
        tes3.mobilePlayer.controlsDisabled = false
        tes3.playAnimation({
            reference = tes3.mobilePlayer,
            group = tes3.animationGroup.idle,
            startFlag = tes3.animationStartFlag.immediate,
            loopCount = 1
        })
    end

    removeDamagingEffects()

    tes3.mobilePlayer.health.current = 4
    tes3.mobilePlayer.invisibility = 0

    local effects = {
        { -- For updating HP in UI, anything else does not work.
            id=tes3.effect.restoreHealth,
            duration=1,
            min=1,
            max=1
        }
    }

    if config.invisibilityDuration > 0 then
        table.insert(effects, {
            id=tes3.effect.invisibility,
            duration=config.invisibilityDuration
        })
    end
    if config.chameleonDuration > 0 then
        table.insert(effects, {
            id=tes3.effect.chameleon,
            duration=config.chameleonDuration,
            min=config.chameleonMagnitude,
            max=config.chameleonMagnitude
        })
    end

    tes3.applyMagicSource({
        reference=tes3.mobilePlayer,
        name="Immersive death",
        effects=effects
    })

    event.unregister("load", loadBlocker)
    tes3.fadeIn({duration = 1})

    if config.reportLostItems then
        if string.len(report) > 0 then
            tes3.addJournalEntry({text=report, showMessage=true})
        end
    end

    escaping = false
    log("finalizeEscape")
end

-- Put timescale back to normal, and proceed
local function endTimeSkip()
    tes3.findGlobal("TimeScale").value = timeScale
    finalizeEscape()
end

-- if natural is enabled, then speed up time until that has been elapsed. Otherwise, proceed.
local function timeSkip()
    removeDamagingEffects()

    if (config.natural == true) then
        timeScale = tes3.findGlobal("TimeScale").value
        tes3.findGlobal("TimeScale").value = 172800 -- pass 1 day every .5 second.
        timer.start({type = timer.game, duration = config.recoveryTime, callback = endTimeSkip})
    else
        finalizeEscape()
    end
end

-- fallback for the edgecase in which the player is already in the cell the intervention would have taken them.
local function hasCellChanged()
    if (teleporting == true) then
        teleporting = false
        timer.delayOneFrame(timeSkip)
    end
end

-- wait until the player has been teleported to the new cell to proceed
local function onCellChanged()
    if (teleporting == true) then
        teleporting = false
        timer.delayOneFrame(timeSkip)
    end
end

local function appendWithSeparator(s1, separator, s2)
    if string.len(s1) > 0 then
        return string.format("%s%s%s", s1, separator, s2)
    else
        return s2
    end
end

local function applyPenalties()
    local dropFactor = config.itemDropProbability / 100.0
    local worsenConditionFactor = config.itemWorsenConditionProbability / 100.0

    local reportLost = ""
    local reportBroken = ""

    local inv = tes3.mobilePlayer.inventory
    for _k, itemStack in pairs(inv) do
        if itemStack.variables ~= nil then
            for _k, itemData in pairs(itemStack.variables) do
                -- itemStack can be or can become nil
                if itemStack ~= nil then
                    local shouldWorsenCondition = math.random() < worsenConditionFactor
                    if shouldWorsenCondition then
                        -- itemData can still be nil
                        if itemData ~= nil and itemData.condition > 0 then
                            itemData.condition = 0
                        end
                    end

                    local shouldDrop = math.random() < dropFactor
                    if shouldDrop then
                        log("Drop %s", itemStack.object.id)
                        if config.reportLostItems then
                            reportLost = appendWithSeparator(reportLost, ", ", itemStack.object.name)
                        end

                        tes3.dropItem({reference=tes3.mobilePlayer, item=itemStack.object, itemData=itemData})
                    end

                    if shouldWorsenCondition and not shouldDrop then
                        if config.reportLostItems then
                            reportBroken = appendWithSeparator(reportBroken, ", ", itemStack.object.name)
                        end
                    end
                end
            end
        else
            local shouldDrop = math.random() < dropFactor
            local dropCount = math.random(1, itemStack.count)

            log("Drop %s %d", itemStack.object.id, dropCount)
            if config.reportLostItems then
                if dropCount > 1 then
                    reportLost = appendWithSeparator(reportLost, ", ", string.format("%d %s", dropCount, itemStack.object.name))
                else
                    reportLost = appendWithSeparator(reportLost, ", ", itemStack.object.name)
                end
            end

            tes3.dropItem({reference=tes3.mobilePlayer, item=itemStack.object, count=dropCount})
        end
    end

    report = ""

    if string.len(reportLost) > 0 then
        report = string.format("Lost: %s", reportLost)
    end

    if string.len(reportBroken) > 0 then
        report = appendWithSeparator(report, "\n\n", string.format("Broken: %s", reportBroken))
    end
end

local function recursivelyFindActivatorToExteriorCell(cell, visitedCells)
    if visitedCells[cell.id] ~= nil then
        log("Skipping already visited cell %s", cell.id)
        return nil
    end

    visitedCells[cell.id] = 1
    log("Marking cell is visited %s", cell.id)

    local activator = cell.activators.head
    while activator ~= nil do
        if activator.destination ~= nil and not activator.destination.marker.disabled and not activator.destination.marker.deleted then
            local nextCell = activator.destination.cell
            log("Found activator with destination to %s", nextCell.id)

            if nextCell.isOrBehavesAsExterior then
                log("Is exterior, returning activator to %s", nextCell.id)
                return {cell=nextCell, activator=activator.destination.marker}
            end

            log("Not exterior, going deeper into cell %s", nextCell.id)
            local exteriorCellOrNil = recursivelyFindActivatorToExteriorCell(nextCell, visitedCells)
            if exteriorCellOrNil ~= nil then
                log("Got non-nil result from deeper cell %s", exteriorCellOrNil)
                return exteriorCellOrNil
            end
        end

        activator = activator.nextInCollection
    end

    return nil
end

local function findExteriorCellAndActivator(currentCell)
    local visitedCells = {}
    return recursivelyFindActivatorToExteriorCell(currentCell, visitedCells)
end

local function addStaticIfEligible(static, eligibleStatics)
    if static.position.z < 0 then
        -- below water
        return
    end

    --[[ Ideas:
    filter out statics too close to hostile actors
    ]]--

    table.insert(eligibleStatics, static)
end

local function findFreeSpaceNearStatic(static)
    local offset = 300
    local maxZ = 2000

    for x=-1,0,1 do
        for y=-1,0,1 do
            if x ~= 0 and y ~= 0 then
                local r = tes3.rayTest({
                    position={
                        static.position.x + offset * x,
                        static.position.y + offset * y,
                        static.position.z + maxZ
                    },
                    direction={0,0,-1},
                    findAll=true,
                    maxDistance=(maxZ + 1),
                    observeAppCullFlag=false
                });

                if r == nil then
                    log("rayTest is nil")
                end

                if r ~= nil and #r > 0 then
                    local topMostZ = r[1].intersection.z
                    local terrainZ = r[#r].intersection.z
                    local delta = topMostZ - terrainZ
                    if delta < 128 then
                        return r[1].intersection
                    end
                end
            end
        end
    end
end

local function findPlaceToRespawn(cell)
    local static = cell.statics.head
    local eligibleStatics = {}

    while static ~= nil do
        addStaticIfEligible(static, eligibleStatics)

        if #eligibleStatics >= 300 then
            break
        end

        static = static.nextInCollection
    end

    log("Found %d eligible statics", #eligibleStatics)

    while #eligibleStatics > 0 do
        local index = math.random(1, #eligibleStatics)
        local static = eligibleStatics[index]
        table.remove(eligibleStatics, index)
        local position = findFreeSpaceNearStatic(static)

        if position ~= nil then
            return position
        end
    end
end

local function fallbackDie()
    tes3.messageBox({message="Cannot find place to escape, going to die here", showInDialog=false})
    tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
end

local function teleportToRandomPositionInCell()
    log("teleportToRandomPositionInCell")

    local exteriorCell = tes3.mobilePlayer.cell
    local position = findPlaceToRespawn(exteriorCell)

    if position == nil then
        log("Did not find place to respawn", position)
        fallbackDie()
        return
    end

    log("Place to respawn in %s is %s", exteriorCell.id, position)
    tes3.positionCell({position=position, cell=exteriorCell});
end

local function escape()
    applyPenalties()

    -- flag for the onCellChange function
    teleporting = true

    local currentCell = tes3.mobilePlayer.cell;
    if currentCell.isOrBehavesAsExterior then
        log("In exterior cell right now, teleporting to random location")
        teleportToRandomPositionInCell()
    else
        log("Not in exterior cell right now")

        local exteriorCellResult = findExteriorCellAndActivator(currentCell)
        if exteriorCellResult == nil then
            log("Did not find exterior cell")
            fallbackDie()
            return
        end
        log("Exterior cell result is %s", exteriorCellResult)

        local exteriorCell = exteriorCellResult["cell"];
        local exteriorCellActivator = exteriorCellResult["activator"];

        log("Exterior cell is %s", exteriorCell.id)
        log("Teleporting to marker %s", exteriorCellActivator)

        tes3.positionCell({cell=exteriorCell, position=exteriorCellActivator.position})
        log("Teleported")
    end

    event.register("load", loadBlocker)

    -- fallback for the edgecase where the player is already in the cell where the intervention would have taken them.
    timer.start({duration = 3, callback = hasCellChanged})
end

-- if enabled, get confirmation before proceeding
local function confirm()
    if (config.confirmation == true) then
        tes3.messageBox({
            message = "I am lying down in my own blood,\npretending that I am dead.\nWhat do I do?",
            buttons = {
                "Try to quietly crawl away",
                "Keep quiet for a bit",
                "Die"
            },
            callback = function(e)
                if (e.button == 1) then
                    tes3.mobilePlayer.controlsDisabled = true
                    tes3.mobilePlayer.invisibility = 100

                    tes3.fadeIn({duration = 0.5})

                    timer.start({duration=10, callback=function ()
                        tes3.mobilePlayer.controlsDisabled = false
                        tes3.fadeOut({duration = 0.5})

                        confirm()
                    end})
                    return
                elseif (e.button == 2) then
                    tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
                    return
                else
                    timer.delayOneFrame(escape)
                end
            end
        })
    else
        timer.delayOneFrame(escape)
    end
end

--After the delay for the animation, proceed as normal.
local function endAnimate()
    tes3.fadeOut({duration = 0.5})
    timer.start({duration = 0.5, callback = confirm})
end

-- prepare for the escape, by checking for confounding factors, fading the screen, and playing animations, if enabled.
local function prepareEscape()
    -- A series of checks to kill the player if something is to prevent the teleportation.
    -- kill player if teleporting is disabled (such as in the Heart chamber)
    if (tes3.worldController.flagTeleportingDisabled == true) then
        escaping = false
        tes3.setStatistic({name = "health", current = 0, reference = tes3.mobilePlayer})
        return
    end

    removeDamagingEffects()
    tes3.mobilePlayer.invisibility = 100

    -- if the option is enabled, simulate the vanilla death routine.
    if(config.deathAnimation == true) then
        perspective = tes3.is3rdPerson()
        tes3.mobilePlayer.controlsDisabled = true
        tes3.force3rdPerson()
        tes3.streamMusic({path = "Special\\MW_Death.mp3", crossfade = 0.2})
        tes3.playAnimation({
            reference = tes3.mobilePlayer,
            group = config.deathAnimations[math.random(5)],
            startFlag = tes3.animationStartFlag.immediate,
            loopCount = 1
        })
        timer.start({duration = 3, callback = endAnimate})
    else
        tes3.fadeOut({duration = 0.5})

        -- without this delay it crashes
        timer.start({duration = 0.5, callback = confirm})
    end
end

local function saveBeforeDying()
    if config.saveBeforeDeath then
        local saved = tes3.saveGame({file="immersivedeath", name="ImmersiveDeath"})
        log("Saved %s", tostring(saved))
    end
end

-- detect a killing blow on the player, and negate it. If not already escaping, start the escape process.
local function onDamage(e)
    if(e.mobile == tes3.mobilePlayer and config.enable) then
        if escaping then
            return false
        end

        local difficulty = tes3.getWorldController().difficulty
        local difficultyMult = tes3.findGMST(tes3.gmst.fDifficultyMult).value
        local difficultyFactor
        if(difficulty > 0) then
            difficultyFactor = 1 + difficultyMult * difficulty
        else
            difficultyFactor = 1 + difficulty / difficultyMult
        end -- If damage is from an attack, apply the difficulty modifier before checking to see if it would kill the player.

        local hpAfter = 0
        if e.source == "attack" then
            hpAfter = tes3.mobilePlayer.health.current - math.abs(e.damage) * difficultyFactor
        else
            hpAfter = tes3.mobilePlayer.health.current - math.abs(e.damage)
        end

        local isKillBlow = hpAfter <= 1.1

        local newStoredDamage = {
            index=storedDamagesTotal,
            currentHp=tes3.mobilePlayer.health.current,
            hpAfter=hpAfter,
            isKillBlow=isKillBlow,
            damage=e.damage,
            difficultyFactor=difficultyFactor,
            source=e.source
        }
        storedDamagesTotal = storedDamagesTotal + 1
        storedDamages[nextStoredDamageIndex] = newStoredDamage
        nextStoredDamageIndex = nextStoredDamageIndex + 1
        if nextStoredDamageIndex > maxStoredDamages then
            nextStoredDamageIndex = 1
        end

        if isKillBlow then
            log("Kill blow detected index=%d", newStoredDamage["index"])

            if (escaping ~= true) then
                saveBeforeDying()

                escaping = true
                tes3.mobilePlayer.health.current = 10000
                prepareEscape()
            end

            return false
        end
    end
end

local function onDamaged(e)
    if(e.mobile == tes3.mobilePlayer and config.enable) then
        if e.killingBlow then
            -- For debugging.
            log("onDamaged, escaping=%s killingblow=%s", tostring(escaping), tostring(e.killingBlow))
            log("onDamaged, stored damages: %s", json.encode(storedDamages))

            -- Probably, does not work.
            --escaping = true
            --tes3.mobilePlayer.health.current = 10000
            --prepareEscape()
        end
    end
end

--[[Reset the variables upon loading, to prevent undesired behavior if the player
starts a new game or loads a game during the escape process.]]--
local function resetVariables()
    escaping = false
    perspective = nil
    teleporting = false
    timeScale = nil
    report = ""
    tes3.fadeIn({duration = 0.01})
end

-- Register the events to be used in baseline behavior
local function initialized()
    event.register("damage", onDamage, {priority = 100000})
    event.register("damaged", onDamaged, {priority = 100000})
    event.register("save", blockSave)
    event.register("cellChanged", onCellChanged)
    event.register("loaded", resetVariables)
	log("Initialized " .. config.version)
end

-- register the initialized event
event.register("initialized", initialized)

--register our mod when mcm is ready for it
event.register("modConfigReady", function()
	require("ZdoImmersiveDeath.mcm")
end)