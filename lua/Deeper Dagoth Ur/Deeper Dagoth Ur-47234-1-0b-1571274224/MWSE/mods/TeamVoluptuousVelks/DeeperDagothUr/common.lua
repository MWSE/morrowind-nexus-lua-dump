local this = {}

local debug = false

this.debug = function (message)
    if (debug == true) then
        local prepend = '[Deeper Dagoth Ur: DEBUG] '
        message = prepend .. message
        mwse.log(message)
        tes3.messageBox(message)
    end
end

this.error = function (message)
    local prepend = '[Deeper Dagoth Ur: ERROR] '
    message = prepend .. message
    mwse.log(message)
    tes3.messageBox(message)
end

this.data = {
    dialogue = {
        ascendedSleeper = {
            [1] = "As the Ascended Sleeper dies, you hear a whisper: 'What are you doing? You have no idea." .. 
            " Poor animal. You struggle and fight, and understand nothing.'",
            [2] = "With it's last breath, the Ascended Sleeper gasps: 'A bug. A weed. A piece of dust. Busy, " ..
            "busy, busy.'",
            [3] = "A calmness radiates from the Ascended Sleeper, and it says 'You think what you do has meaning? " .. 
                " You think you slay me, and I am dead? It is just dream and waking over and over, one appearance after another, " .. 
                "nothing real. What you do here means nothing. Why do we waste our breath on you?'"
        },
        ashVampires = {
            araynys = "'A fair fight it was.'",
            endus = "'One drop more, before I go.'",
            gilvoth = "'I never thought I would fall to you.'",
            odros = "'Remember, why risk blood and life for that which might be won by words and service?'",
            tureynul = "As Dagoth Tureynul falls, his face remains a visage of silence.",
            uthol = "'Lord Dagoth was right. You cannot leave a thing well enough alone.'",
            vemyn = "'All of this time, and I am brought low by you. At least it was not from talking.'"
        }
    },
    spellIds = {
        dispelLevitation = "DDU_DispelLevitation",
        dispelLevitationSelf = "DDU_DispelLevitationSelf",
        dispelLevitationJavelin = "DDU_DispelLevitationJavelin",
        ascendedSleeperSummonAshSlaves = "DDU_AscendedSlprSummonAshSlvs",
        ascendedSleeperHeal = "hearth heal",
        ashVampireSummonAscendedSleepers = "DDU_AshVmprSummonAscndSlprs"
    },
    diseaseIds = {
        blackHeartBlight = {
            id = "black-heart blight",
            name = "Black-Heart Blight"
        },
        ashWoeBlight = {
            id = "ash woe blight",
            name = "Ash Woe Blight"
        },
        ashChancreBlight = {
            id = "ash-chancre",
            name = "Ash-chancre"
        },
        chanthraxBlight = {
            id = "chanthrax blight",
            name = "Chanthrax Blight"
        }
    },
    mechanics = {
        dagothUr = {
            ids = {
                creatures = {
                    ascendedSleeper = "ascended_sleeper",
                    ashSlave = "ash_slave",
                    ashGhoul = "ash_ghoul"
                },
                dagothUrs = {
                    dagoth_ur_1 = "dagoth_ur_1",
                    dagoth_ur_2 = "dagoth_ur_2"
                }
            },
            heartwights = {
                araynys = {
                    id = "dagoth araynys",
                    position = {1394, 2056, -4632},
                    orientation = {0, 0, 337}
                },
                endus = {
                    id = "dagoth endus",
                    position = {-412, 3268, -4313},
                    orientation = {0, 0, 132}
                },
                gilvoth = {
                    id = "dagoth gilvoth",
                    position = {456, 3748, -4505},
                    orientation = {0,0,160}
                },
                odros = {
                    id = "dagoth odros",
                    position = {1607, 3638, -4030},
                    orientation = {0, 0, 212}
                },
                tureynul = {
                    id = "dagoth tureynul",
                    position = {86, 4628, -4673},
                    orientation = {0, 0, 183}
                },
                uthol = {
                    id = "dagoth uthol",
                    position = {-1356, 4302, -4730},
                    orientation = {0, 0, 103}
                },
                vemyn = {
                    id = "dagoth vemyn",
                    position = {-521, 4754, -4681},
                    orientation = {0, 0, 195}
                } 
            }
        }
    }
}


this.shouldPerformRandomEvent = function (percentChanceOfOccurence)
    if (math.random(-1, 101) <= percentChanceOfOccurence) then
        return true
    end
    return false
end

this.getActorsNearTargetPosition = function(cell, targetPosition, distanceLimit)
    local actors = {}
    -- Iterate through the references in the cell.
    for ref in cell:iterateReferences() do
        -- Check that the reference is a creature or NPC.
        if (ref.object.objectType == tes3.objectType.npc or
            ref.object.objectType == tes3.objectType.creature) then
            -- Check that the distance between the reference and the target point is within the distance limit. If so, save the reference.
            local distance = targetPosition:distance(ref.position)
            if (distance <= distanceLimit) then
                table.insert(actors, ref)
            end
        end
    end
    return actors
end

this.forceCast = function(params)
    tes3.playAnimation({
        reference = params.reference,
        group = tes3.animationGroup.idle,
        startFlag = 1
    })

    tes3.cast({
        reference = params.reference,
        target = params.target,
        spell = params.spell
    })
end

return this