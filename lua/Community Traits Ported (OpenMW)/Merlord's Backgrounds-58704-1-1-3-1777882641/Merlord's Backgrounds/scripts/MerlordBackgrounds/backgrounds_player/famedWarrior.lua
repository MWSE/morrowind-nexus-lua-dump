---@diagnostic disable: assign-type-mismatch
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local async = require("openmw.async")

local traitType = require("scripts.MerlordBackgrounds.utils.traitTypes").background
local swordNameUi = require("scripts.MerlordBackgrounds.ui.famedWarrior")
local raycast = require("scripts.MerlordBackgrounds.utils.raycast")

-- local period = 1
-- local minDelay = 1
-- local maxDelay = 7
local period = time.minute
local minDelay = 1 * time.hour
local maxDelay = 7 * time.day -- why such a long delay? so it would be sudden, ofc
local rivalsSpawned = 0
local timerStarted = false
local spawnDistance = 300
local stopTimer
local bgPicked = false
local currSwordRecordId

local rivals = {
    "mer_bg_rival_01",
    "mer_bg_rival_02",
    "mer_bg_rival_03",
    "mer_bg_rival_04",
    "mer_bg_rival_05",
    "mer_bg_rival_06",
    "mer_bg_rival_07",
    "mer_bg_rival_08",
    "mer_bg_rival_09",
    "mer_bg_rival_10",
}

local spawnRival = async:registerTimerCallback(
    "spawnRival",
    function()
        core.sendGlobalEvent(
            "MerlordsTraits_safeSpawn",
            {
                player = self,
                actor = rivals[rivalsSpawned + 1],
                script = "scripts/MerlordBackgrounds/backgrounds_custom/famedWarrior.lua",
                pos = raycast.findSafeSpawnPos(self, spawnDistance)
            }
        )
        timerStarted = false
        rivalsSpawned = rivalsSpawned + 1
    end
)

local function checkLevel()
    if rivalsSpawned > #rivals then
        stopTimer()
        return
    end

    local readyForRival = self.type.stats.level(self).current > rivalsSpawned
    if not readyForRival or timerStarted then return end

    async:newGameTimer(
        math.random(minDelay, maxDelay),
        spawnRival
    )
    timerStarted = true
end

I.CharacterTraits.addTrait {
    id = "famedWarrior",
    type = traitType,
    name = "Famed Warrior",
    description = (
        "Back in your homeland, you had a reputation as a mighty warrior. " ..
        "Renown comes with a price, however. There are many would-be heroes who would stake their claim " ..
        "as the warrior who finally defeated you in battle. As such, you will likely encounter these rivals in " ..
        "your travels.\n" ..
        "\n" ..
        "+10 Long Blade\n" ..
        "+10 Reputation\n" ..
        "> You start with your infamous sword. For each rival you defeat, your blade will grow in power if it's in your inventory."
    ),
    checkDisabled = function()
        return core.API_REVISION < 121
    end,
    doOnce = function()
        ---@diagnostic disable-next-line: undefined-field
        local rep = self.type.stats.reputation(self)
        rep.current = rep.current + 10

        local longBlade = self.type.stats.skills.longblade(self)
        longBlade.base = longBlade.base + 10
        core.sendGlobalEvent("MerlordsTraits_grantRep", 10)
    end,
    onLoad = function()
        bgPicked = true
        stopTimer = time.runRepeatedly(checkLevel, period)
    end,
}

local function tryNamingSword()
    if not bgPicked or currSwordRecordId then return end

    swordNameUi.show()
    ---@diagnostic disable-next-line: missing-fields
    I.UI.setMode('Interface', { windows = {} })
    core.sendGlobalEvent('Pause', 'ui')
end

local function swordRecieved(sword)
    I.UI.setMode()
    core.sendGlobalEvent('Unpause', 'ui')
    currSwordRecordId = sword.recordId
end

local function swordUpgraded(sword)
    currSwordRecordId = sword.recordId
end

local function rivalDied()
    core.sendGlobalEvent(
        "MerlordsTraits_upgradeSword",
        {
            player = self,
            currSwordRecordId = currSwordRecordId,
            swordLevel = rivalsSpawned
        }
    )
end

local function onSave()
    return {
        rivalsSpawned = rivalsSpawned,
        timerStarted = timerStarted,
        currSwordRecordId = currSwordRecordId
    }
end

local function onLoad(data)
    if not data then return end
    rivalsSpawned = data.rivalsSpawned or rivalsSpawned
    timerStarted = data.timerStarted or timerStarted
    currSwordRecordId = data.currSwordRecordId or currSwordRecordId
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad
    },
    eventHandlers = {
        CharacterTraits_allTraitsPicked = tryNamingSword,
        MerlordsTraits_swordRecieved = swordRecieved,
        MerlordsTraits_swordUpgraded = swordUpgraded,
        MerlordsTraits_rivalDied = rivalDied,
    }
}
