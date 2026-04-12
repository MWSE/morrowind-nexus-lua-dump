local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local AI = require('openmw.interfaces').AI
local util = require('openmw.util')

local function updateTradersItems()
    for _, chest in ipairs(nearby.containers) do
        if chest.owner.recordId == self.recordId then
            -- print('scribo: found trader chest ' .. chest.recordId)
            local inventory = types.Container.inventory(chest)
            core.sendGlobalEvent('UpdateTradersItems', {
                trader = self,
                container = chest
            })
        end
    end

    local misc = 0
    local ingredient = 0

    for _, items in ipairs(nearby.items) do
        if items.owner.recordId == self.recordId then
            -- print('scribo: found trader item ' .. items.recordId)
            if items.type == types.Miscellaneous then
                misc = misc + 1
            end
            if items.type == types.Ingredient then
                ingredient = ingredient + 1
            end
        end
    end
    local inventory = types.Actor.inventory(self)
    core.sendGlobalEvent('UpdateTradersItems', {
        trader = self,
        container = self,
        misc = misc,
        ingredient = ingredient
    })
end


-- Возвращает список NPC, которые видят игрока
local function getNpcsSeeingPlayer(maxViewDistance)
    local nearbyActors = nearby.actors
    local seeingNpcs = {}

    local playerPos = self.position
    --local viewAngleRad = math.rad(viewAngleDegrees or 90)
    --local cosMaxAngle = math.cos(viewAngleRad)

    for _, actor in ipairs(nearbyActors) do
        -- Пропускаем не-NPC и мёртвых
        if types.NPC.objectIsInstance(actor) and not types.Actor.isDead(actor) then

            local npcPos = actor.position
            local toPlayer = playerPos - npcPos
            local distance = toPlayer:length()

            -- Проверка дистанции поиска и видимости
            if distance <= maxViewDistance and distance > 0.5 then
                -- toPlayer:normalize()
                -- Проверка прямой видимости (между головами)
                local raycastResult = nearby.castRay(npcPos, -- + util.vector3(0, 0, 1.2),
                    playerPos, { -- + util.vector3(0, 0, 1.0), {
                        ignore = {actor}
                    })

                --print(actor, raycastResult.hitObject, raycastResult.hitObject.type == types.Player)    
                if raycastResult.hitObject and raycastResult.hitObject.type == types.Player then
                    table.insert(seeingNpcs, actor)
                end
            end
        end
    end

    return seeingNpcs
end


local function checkCombat()

    local player = nearby.players[1]
    
    -- Получаем активный пакет ИИ
    local package = AI.getActivePackage()
    local state = "Peace"  -- По умолчанию — мирное состояние

    -- Проверяем, находится ли NPC в боевом режиме
    if package and package.type == "Combat" then
        local dist2 = (self.position - player.position):length2()

        local target = AI.getActiveTarget()
        if target and target.type == types.Player and dist2 <= 1000*1000 then
            state = "Combat"
        end
    end

    -- Отправляем результат внешним обработчикам
    core.sendGlobalEvent("CheckCombat", {
        type = state,
        npc = self.recordId
    })
end



local function string_ends_with(str, ending)
    local len = string.len(str)
    local end_len = string.len(ending)
    if end_len > len then
        return false
    end
    return string.sub(str, -end_len) == ending
end

local function onActivated(actor)
    local class = types.NPC.record(self).class

    if class == "trader service" or class == "bookseller" or class == "pawnbroker" then
        --print('scribo: NPC traders activated')
        updateTradersItems()
    end
end
local function onUpdate(dt)
    --if not playerSettings:get('scrbInCombatCheckOff') then
    if not core.isWorldPaused() then
        checkCombat()
    end
    --end
end

return {
    engineHandlers = {
        onActivated = onActivated,
        onUpdate = onUpdate
    }
}
