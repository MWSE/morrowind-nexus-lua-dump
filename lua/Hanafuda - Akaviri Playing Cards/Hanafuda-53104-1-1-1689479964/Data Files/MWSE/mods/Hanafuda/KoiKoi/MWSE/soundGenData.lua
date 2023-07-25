local this = {}

local soundData = require("Hanafuda.KoiKoi.soundData")

---@class KoiKoi.SoundGenData
---@field gen tes3.soundGenType

---@type {[KoiKoi.VoiceId] : KoiKoi.SoundGenData}
this.soundGenData = {
    [soundData.voice.continue] = { gen = tes3.soundGenType.moan },
    [soundData.voice.finish] = { gen = tes3.soundGenType.roar },
    [soundData.voice.loseRound] = { gen = tes3.soundGenType.scream },
    [soundData.voice.winGame] = { gen = tes3.soundGenType.roar },
    [soundData.voice.think] = { gen = tes3.soundGenType.moan },
    [soundData.voice.remind] = { gen = tes3.soundGenType.roar },
}

return this
