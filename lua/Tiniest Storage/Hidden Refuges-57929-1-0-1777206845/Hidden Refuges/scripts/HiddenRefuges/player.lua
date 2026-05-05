local core = require("openmw.core")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local util = require("openmw.util")
local self = require("openmw.self")
local ui = require("openmw.ui")

-- Точки укрытий: позиция, радиус активации и зона безопасности (в квадрате для оптимизации)
local hideoutPoints = {
    {
        position = util.vector3(10553.603516, -54485.804688, 1334.851440),
        maxDistanceSq = 200^2,
        safeZoneSq = 2000^2
    },
    {
        position = util.vector3(-16337.129883, -11486.500977, 1159.347778),
        maxDistanceSq = 200^2,
        safeZoneSq = 2000^2
    }
}

-- Проверяет, находится ли игрок в пределах одной из точек укрытия
local function nearestHideout()
    local playerPos = self.position
    for _, point in ipairs(hideoutPoints) do
        if (playerPos - point.position):length2() <= point.maxDistanceSq then
            return point
        end
    end
    return nil
end

-- Проверяет, находится ли актёр в указанной зоне вокруг игрока
local function isActorInSafeZone(actor, safeZoneSq)
    return (self.position - actor.position):length2() <= safeZoneSq
end

-- Обработчик окончания отдыха
local function UiModeChanged(data)
    -- Реагируем только на переход из режима отдыха в активный
    if data.oldMode ~= "Rest" or data.newMode ~= nil then
        return
    end

    local point = nearestHideout()
    if not point then
        return
    end

    local creaturesRemoved = false
    for _, actor in ipairs(nearby.actors) do
        local bandit = false
        if actor.type == types.NPC then
            local npc = types.NPC.record(actor)
            bandit = (npc.name == "Bandit")
        end
        if (actor.type == types.Creature or bandit) and isActorInSafeZone(actor, point.safeZoneSq) then
            core.sendGlobalEvent("hrRemoveActor", { actor = actor })
            local creatureName = (actor and actor.name) or "кто-то"
 	    ui.showMessage("")
	    ui.showMessage("")
            ui.showMessage("Your rest has been interrupted by a nightmare")
            creaturesRemoved = true
        end
    end
end

return {
    eventHandlers = {
        UiModeChanged = UiModeChanged
    }
}