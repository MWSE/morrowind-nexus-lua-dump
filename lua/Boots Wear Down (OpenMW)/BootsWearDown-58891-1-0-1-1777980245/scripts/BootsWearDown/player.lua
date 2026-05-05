---@diagnostic disable: missing-parameter
local storage = require('openmw.storage')
local self = require("openmw.self")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local core = require("openmw.core")

local settings = storage.playerSection("SettingsBootsWearDown_settings")
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
local selfEffects = self.type.activeEffects(self)

local wearPoints = 0

local function wearBoots(amount)
    if selfEffects:getEffect(core.magic.EFFECT_TYPE.Levitate).magnitude > 0
        or selfEffects:getEffect(core.magic.EFFECT_TYPE.SlowFall).magnitude > 0
        or self.type.isSwimming(self)
    then
        return
    end

    wearPoints = wearPoints + amount

    if wearPoints >= settings:get("wearPointsPerDurability") then
        wearPoints = 0
        local eq = self.type.getEquipment(self, self.type.EQUIPMENT_SLOT.Boots)
        if eq and types.Armor.objectIsInstance(eq) then
            core.sendGlobalEvent(
                "ModifyItemCondition",
                { actor = self, item = eq, amount = -1 }
            )
        end
    end

    -- print(wearPoints)
end

local function walking(groupname, key)
    if key ~= "loop start" then return end
    wearBoots(settings:get("walkingWearPoints"))
end
local function running(groupname, key)
    if key ~= "loop start" then return end
    wearBoots(settings:get("runningWearPoints"))
end

for _, group in ipairs(walkingAnimGroups) do
    I.AnimationController.addTextKeyHandler(group, walking)
end
for _, group in ipairs(runningAnimGroups) do
    I.AnimationController.addTextKeyHandler(group, running)
end
I.AnimationController.addTextKeyHandler("jump",
    function(groupname, key)
        if key ~= "start" then return end
        wearBoots(settings:get("jumpWearPoints"))
    end
)

-- I.AnimationController.addTextKeyHandler(
--     "",
--     function(groupname, key)
--         print(groupname, "|", key)
--     end
-- )

local function onSave()
    return {
        wearPoints = wearPoints
    }
end

local function onLoad(data)
    if not data then return end
    wearPoints = data.wearPoints or wearPoints
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    }
}
