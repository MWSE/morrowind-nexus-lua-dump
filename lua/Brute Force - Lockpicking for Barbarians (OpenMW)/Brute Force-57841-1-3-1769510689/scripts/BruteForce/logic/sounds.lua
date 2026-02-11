local core = require("openmw.core")
local types = require("openmw.types")

function PlaySFX(o, player, unlocked)
    if unlocked and o.type == types.Container then
        core.sound.playSoundFile3d("sound/container lock split.mp3", player, {
            pitch = 1,
            volume = 1.5,
        })
    elseif not unlocked and o.type == types.Container then
        core.sound.playSoundFile3d("sound/container lock bent.mp3", player, {
            volume = .6
        })
    elseif unlocked and o.type == types.Door then
        core.sound.playSoundFile3d("sound/door lock split.mp3", player, {
            volume = 1,
        })
        core.sound.playSoundFile3d("sound/container lock split.mp3", player, {
            pitch = .75
        })
    elseif not unlocked and o.type == types.Door then
        core.sound.playSoundFile3d("sound/door lock bent.mp3", player, {
            volume = 1
        })
    end
end
