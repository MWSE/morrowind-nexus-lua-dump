
local common = require("TeamVoluptuousVelks.DeeperDagothUr.common")

-- Dagoth Ur Mechanics --
local journalId = "C3_DestroyDagoth"
local cellId = "Akulakhan's Chamber"
local barrierId = "DDU_AkulakhanForcefield"
local heartId = "heart_akulakhan"

local stagesDagothUr = {}
local barrier = nil
local heart = nil
local dagothUr = nil

local function onHeartSimulate(e)
    if (tes3.player.position:distance(heart.position) <= 500) then
        stagesDagothUr.thirdStage.initialize()
        event.unregister("simulate", onHeartSimulate)
    end
end

stagesDagothUr = {
    ["firstStage"] = {
        initialize = function()
            common.debug("Dagoth Ur Fight: Beginning First Stage")

            -- Get Dagoth Ur reference
            dagothUr = tes3.getReference(common.data.mechanics.dagothUr.ids.dagothUrs.dagoth_ur_2)

            -- Disable barrier.
            barrier = tes3.getReference(barrierId)

            -- Set timer to continue to teleport dagoth ur.
            timer.start({
                duration = 8,
                callback = function ()          
                    -- Teleport Dagoth Ur to the second stage area.
                    tes3.positionCell({
                        reference = dagothUr,
                        position = { -199, 7356, -1834 },
                        orientation = { 0, 0, 115 },
                        cell = tes3.player.cell
                    })
                end,
                iterations = 1
            })

            local spawnCreatures = function()
                local ref1 = tes3.createReference({
                    object = common.data.mechanics.dagothUr.ids.creatures.ashSlave,
                    position = {263, 734, 2232},
                    orientation = tes3.player.orientation,
                    cell = tes3.player.cell
                })
                local ref2 = tes3.createReference({
                    object = common.data.mechanics.dagothUr.ids.creatures.ashGhoul,
                    position = {263, 734, 2232},
                    orientation = tes3.player.orientation,
                    cell = tes3.player.cell
                })
                local ref3 = tes3.createReference({
                    object = common.data.mechanics.dagothUr.ids.creatures.ashSlave,
                    position = {-569, 775, 2232},
                    orientation = tes3.player.orientation,
                    cell = tes3.player.cell
                })
                local ref4 = tes3.createReference({
                    object = common.data.mechanics.dagothUr.ids.creatures.ashGhoul,
                    position = {-569, 775, 2232},
                    orientation = tes3.player.orientation,
                    cell = tes3.player.cell
                })

                mwscript.startCombat({reference = ref1, target = tes3.player})
                mwscript.startCombat({reference = ref2, target = tes3.player})
                mwscript.startCombat({reference = ref3, target = tes3.player})
                mwscript.startCombat({reference = ref4, target = tes3.player})
            end

            -- Set timer to spawn first wave.
            timer.start({
                duration = 8,
                callback = function ()     
                    spawnCreatures()

                    -- Set timer to spawn enemies
                    timer.start({
                        duration = 12,
                        callback = function ()
                            spawnCreatures()
                        end,
                        iterations = 4
                    })
                end,
                iterations = 1
            })

            -- Set timer to continue to next stage.
            timer.start({
                duration = 60,
                callback = function ()          
                    barrier:disable()
                    tes3.messageBox("The barrier to the next platform dissipates, opening the way to continue. However, you feel yourself being moved through the cavern before you can continue.")
                    stagesDagothUr.secondStage.initialize()
                end,
                iterations = 1
            })
        end
    },
    ["secondStage"] = {
        initialize = function()
            common.debug("Dagoth Ur Fight: Beginning Second Stage")

            -- Fade screen during teleport.
            tes3.fadeOut()
            timer.start({
                duration = 1,
                callback = function ()       
                    local orientationRad = tes3vector3.new(
                        math.rad(0),
                        math.rad(0),
                        math.rad(337)
                    )
                    -- Teleport Player to the second stage area.
                    tes3.positionCell({
                        reference = tes3.player, 
                        position = { 735, 2471, -4678 },
                        orientation = orientationRad,
                        cell = tes3.player.cell
                    })
                    tes3.fadeIn()
                end,
                iterations = 1
            })



            -- Resurrect the heartwights & add them to table.
            for _, heartwight in pairs(common.data.mechanics.dagothUr.heartwights) do

                local orientationRad = tes3vector3.new(
                    math.rad(heartwight.orientation[1]),
                    math.rad(heartwight.orientation[2]),
                    math.rad(heartwight.orientation[3])
                )
                local heartwightRef = tes3.createReference({
                    object = heartwight.id,
                    position = heartwight.position,
                    orientation = orientationRad,
                    cell = tes3.player.cell
                })

                local heartwightRefBaseHealth = heartwightRef.mobile.health.current
                tes3.modStatistic({
                    reference = heartwightRef,
                    name = "health",
                    current = heartwightRefBaseHealth * .5 * -1
                })

                local heartwightRefBaseMagicka = heartwightRef.mobile.magicka.current
                tes3.modStatistic({
                    reference = heartwightRef,
                    name = "magicka",
                    current = heartwightRefBaseMagicka * .5 * -1
                })

                mwscript.startCombat({reference = heartwightRef, target = tes3.player})

            end

            -- Get the Heart reference
            heart = tes3.getReference(heartId)

            -- Register simulate event
            event.register("simulate", onHeartSimulate)
        end
    },
    ["thirdStage"] = {
        initialize = function()
            common.debug("Dagoth Ur Fight: Beginning Third Stage")

            timer.start({
                duration = 4,
                callback = function()                
                    -- Teleport Dagoth Ur to the third stage area, near the heart.
                    tes3.positionCell({
                        reference = dagothUr,
                        position = tes3.player.position,
                        orientation = tes3.player.orientation,
                        cell = tes3.player.cell
                    })

                    tes3.worldController.flagLevitationDisabled = false
                end,
                iterations = 1
            })
        end
    }
}


local function onCellChanged(e)
    common.debug( cellId .. " - " .. e.cell.id)
    if (cellId == e.cell.id) then
        common.debug("Dagoth Ur Fight: Initializing fight.")
        tes3.worldController.flagLevitationDisabled = true
        stagesDagothUr.firstStage.initialize()
    end
end

local function onJournal(e)
    if (e.topic.id ~= journalId) then
        return
    end

    event.unregister("cellChanged", onCellChanged)
    event.unregister("journal", onJournal)
end

local function onLoaded(e)
    local journalIndex = tes3.getJournalIndex(journalId) 
    if (journalIndex == nil or journalIndex < 5) then
        event.register("cellChanged", onCellChanged)
        event.register("journal", onJournal)
    end
end

event.register("loaded", onLoaded)
------------------------------------------
