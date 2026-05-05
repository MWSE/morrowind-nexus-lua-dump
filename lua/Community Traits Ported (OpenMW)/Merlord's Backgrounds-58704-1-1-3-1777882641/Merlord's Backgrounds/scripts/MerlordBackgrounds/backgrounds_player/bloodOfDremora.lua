local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local async = require("openmw.async")
local types = require("openmw.types")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background
local raycast = require("scripts.MerlordBackgrounds.utils.raycast")

local period = time.minute
local dremorasSpawned = 0
local timerStarted = false
local minDelay = 1 * time.hour
local maxDelay = 7 * time.day -- why such a long delay? so it would be sudden, ofc
local spawnDistance = 300
local selfName = self.type.records[self.recordId].name

local introPhrases = {
    '"Give me back my blood, mortal!"',
    "\"This is the end, {pcName}!\"",
    "\"Your soul belongs to me, {pcName}!\"",
    "\"You'll rue the day you took my blood, mortal!\"",
    "\"Curse you, {pcName}!\" I will kill you next time!",
}

local spawnDremora = async:registerTimerCallback(
    "spawnDremora",
    function()
        local summonerLevel = self.type.stats.level(self).current
        local leveledRecord = types.LevelledCreature.records["mer_bg_dremList"]
        local dremoraId = leveledRecord.getRandomId(leveledRecord, summonerLevel)
        core.sendGlobalEvent(
            "MerlordsTraits_safeSpawn",
            {
                player = self,
                actor = dremoraId,
                script = "scripts/MerlordBackgrounds/backgrounds_custom/bloodOfDremora.lua",
                pos = raycast.findSafeSpawnPos(self, spawnDistance)
            }
        )

        timerStarted = false
        dremorasSpawned = dremorasSpawned + 1

        local msg = introPhrases[math.random(#introPhrases)]
        self:sendEvent(
            "ShowMessage",
            { message = msg:gsub("{pcName}", selfName) }
        )
    end
)

local function checkLevel()
    local readyForDremora = self.type.stats.level(self).current >= 2 + dremorasSpawned * 2
    if not readyForDremora or timerStarted then return end

    async:newGameTimer(
        math.random(minDelay, maxDelay),
        spawnDremora
    )
    timerStarted = true
end

I.CharacterTraits.addTrait {
    id = "dremoraBlood",
    type = traitType,
    name = "Blood of the Dremora",
    description = (
        "Long ago, you performed a dark ritual to infuse your blood with that of a dremora. " ..
        "While it did increase your magical affinity, it also angered him a great deal.\n\n" ..
        "> Every once in a while, the daedra will summon himself to Nirn and hunt you down. " ..
        "Whenever he is defeated, you absorb his blood, causing all your magic skills to increase by 1."
    ),
    onLoad = function()
        time.runRepeatedly(checkLevel, period)
    end,
}

local function dremoraDied()
    local skills = self.type.stats.skills
    skills.alchemy(self).base = skills.alchemy(self).base + 1
    skills.alteration(self).base = skills.alteration(self).base + 1
    skills.conjuration(self).base = skills.conjuration(self).base + 1
    skills.destruction(self).base = skills.destruction(self).base + 1
    skills.enchant(self).base = skills.enchant(self).base + 1
    skills.illusion(self).base = skills.illusion(self).base + 1
    skills.mysticism(self).base = skills.mysticism(self).base + 1
    skills.restoration(self).base = skills.restoration(self).base + 1

    self:sendEvent(
        "ShowMessage",
        { message = "Dremora blood courses through your veins. Your magic skills have increased!" }
    )
end

local function onSave()
    return {
        dremorasSpawned = dremorasSpawned,
        dremoraTimerStarted = timerStarted,
    }
end

local function onLoad(data)
    if not data then return end
    dremorasSpawned = data.dremorasSpawned or dremorasSpawned
    timerStarted = data.dremoraTimerStarted or timerStarted
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad
    },
    eventHandlers = {
        MerlordsTraits_dremoraDied = dremoraDied,
    }
}
