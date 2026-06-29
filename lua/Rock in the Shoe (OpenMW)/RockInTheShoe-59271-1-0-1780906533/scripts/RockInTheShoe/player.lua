---@omw-context player
---@diagnostic disable: missing-parameter
local storage = require('openmw.storage')
local self = require("openmw.self")
local I = require("openmw.interfaces")
local async = require("openmw.async")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local core = require("openmw.core")

local function getBootsId()
    local boots = types.Player.getEquipment(self, types.Player.EQUIPMENT_SLOT.Boots)
    return boots and boots.id
end

local l10n = core.l10n("RockInTheShoe")
local settingsCache = require("scripts.RockInTheShoe.utils.settingsCache")
local settings = settingsCache.new(storage.playerSection("SettingsRockInTheShoe_settings"), async)
local walkingAnimGroups = {
    "walkforward",
    "walkback",
    "walkleft",
    "walkright",
}
local runningAnimGroups = {
    "runforward",
    "runback",
    "runleft",
    "runright",
}

local rockIntheBoots = false
local stepsTilDamage = settings.rockDamageInterval
local lastBootsId = getBootsId()

local function movementAnimHandler(groupname, key)
    if not rockIntheBoots and getBootsId() then
        rockIntheBoots = math.random(settings.rockChance) == settings.rockChance
        stepsTilDamage = settings.rockDamageInterval
        lastBootsId = getBootsId()
    end

    if rockIntheBoots then
        if stepsTilDamage == 0 then
            stepsTilDamage = settings.rockDamageInterval
            self:sendEvent("Hit", {
                damage = {
                    health = settings.rockDamage
                },
                sourceType = I.Combat.ATTACK_SOURCE_TYPES.Melee,
                strength = 1,
                successful = true,
            })
        else
            stepsTilDamage = stepsTilDamage - 1
        end
    end
end

time.runRepeatedly(
    function()
        local currBootsId = getBootsId()
        if lastBootsId ~= currBootsId then
            lastBootsId = currBootsId
            if rockIntheBoots then
                self:sendEvent("ShowMessage", { message = l10n("msg_bootsSafe") })
                rockIntheBoots = false
            end
        end
    end,
    1
)

for _, group in ipairs(walkingAnimGroups) do
    I.AnimationController.addTextKeyHandler(group, movementAnimHandler)
end
for _, group in ipairs(runningAnimGroups) do
    I.AnimationController.addTextKeyHandler(group, movementAnimHandler)
end
I.AnimationController.addTextKeyHandler("jump", movementAnimHandler)

-- I.AnimationController.addTextKeyHandler(
--     "",
--     function(groupname, key)
--         print(groupname, "|", key)
--     end
-- )

local function onSave()
    return {
        rockIntheBoots = rockIntheBoots,
        stepsTilDamage = stepsTilDamage,
    }
end

local function onLoad(data)
    if not data then return end
    rockIntheBoots = data.rockIntheBoots or rockIntheBoots
    stepsTilDamage = data.stepsTilDamage or stepsTilDamage
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    }
}
