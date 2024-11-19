local common = require("mer.darkShard.common")
local logger = common.createLogger("Scream")
---@class DarkShard.Scream
local Scream = {}

Scream.infos = {
    ['argonian'] = {
        male = "vo\\a\\m\\Hit_AM001.mp3",
        female = "vo\\a\\f\\Hit_AF001.mp3",
    },
    ['breton'] = {
        male = "vo\\b\\m\\Hit_BM003.mp3",
        female = "vo\\b\\f\\Hit_BF001.mp3",
    },
    ['dark elf'] = {
        male = "vo\\d\\m\\Hit_DM006.mp3",
        female = "vo\\d\\f\\Hit_DF006.mp3",
    },
    ['high elf'] = {
        male = "vo\\h\\m\\Hit_HM015.mp3",
        female = "vo\\h\\f\\Hit_HF001.mp3",
    },
    ['imperial'] = {
        male = "vo\\i\\m\\Hit_IM002.mp3",
        female = "vo\\i\\f\\Hit_IF001.mp3",
    },
    ['khajiit'] = {
        male = "vo\\k\\m\\Hit_KM001.mp3",
        female = "vo\\k\\f\\Hit_KF001.mp3",
    },
    ['nord'] = {
        male = "vp/n/m/Hit_NM009.mp3",
        female = "vo\\n\\f\\Hit_NF015.mp3",
    },
    ['orc'] = {
        male = "vo\\o\\m\\Hit_OM006.mp3",
        female = "vo\\o\\f\\Hit_OF006.mp3",
    },
    ['redguard'] = {
        male = "vo\\r\\m\\Hit_RM007.mp3",
        female = "vo\\r\\f\\Hit_RF010.mp3",
    },
    ['wood elf'] = {
        male = "vo\\w\\m\\Hit_WM006.mp3",
        female = "vo\\w\\f\\Hit_WF001.mp3",
    },
}

function Scream.play()
    local race = tes3.player.object.race.id:lower()
    local sex = tes3.player.object.female and "female" or "male"
    local soundPath = Scream.infos[race][sex]
    logger:debug("Playing scream sound path: %s", soundPath)
    tes3.say{
        reference = tes3.player,
        soundPath =  soundPath,
        "AIIEEE."
    }
end

return Scream