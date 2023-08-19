local tpEffect = {}
--local main = require("mundis.main")
tpEffect.destination = ""
function tpEffect.stage1()
    tes3.playSound({ sound = "Dwemer Door Close" })
    tes3.fadeOut({ duration = 1 })
    timer.start({ duration = 1.5, callback = tpEffect.stage2 })
end

function tpEffect.stage2()
    tes3.playSound({ sound = "Dwemer Door Open" })
    tes3.playSound({ sound = "endboom3" })
    tes3.playSound({ sound = "Dwemer Door Close" })
    tes3.fadeOut({ duration = 1 })
    tes3.fadeIn({ duration = 0.7 })
    tes3.setPlayerControlState({ enabled = true })
    tes3.player.data.Mundis.currentDest = tpEffect.destination

    tpEffect.parent.fixDoorData()
end

function tpEffect.startTeleport(destination, parent)
    --disable player controls
    tpEffect.destination = destination
    tpEffect.parent = parent
    tes3.setPlayerControlState({ enabled = false })
    tes3.playSound({ sound = "howl8" })
    timer.start({ duration = 1, callback = tpEffect.stage1 })
end

return tpEffect
