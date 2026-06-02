local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local self = require('openmw.self')
local combat = require('openmw.interfaces').Combat

local storage = require('openmw.storage')
local conj = require('Scripts.SaneMagic.conjuration_s')

local conjData = storage.globalSection('SaneMagicConjuration')

-- code from CursedTombs by Sosnoviy Bor
-- https://www.nexusmods.com/morrowind/mods/58258
local SPAWN_Z_OFFSET = 50
local GROUND_CHECK_Z = 200

local function findSpawnPos(actor, distance)
    local backward = actor.rotation:apply(util.vector3(0, -1, 0))
    local right   = actor.rotation:apply(util.vector3(1, 0, 0))

    local candidateDirs = {
        backward,
        backward + right * 0.4,
        backward - right * 0.4,
        backward + right * 0.8,
        backward - right * 0.8,
    }

    for _, dir in ipairs(candidateDirs) do
        local candidate = actor.position + dir:normalize() * distance

        local wallCheck = nearby.castRay(
            actor.position + util.vector3(0, 0, 60),
            candidate      + util.vector3(0, 0, 60),
            {
                collisionType = nearby.COLLISION_TYPE.World,
                ignore = { actor }
            }
        )

        if not wallCheck.hit then
            local groundCheck = nearby.castRay(
                candidate + util.vector3(0, 0, SPAWN_Z_OFFSET),
                candidate - util.vector3(0, 0, GROUND_CHECK_Z),
                { collisionType = nearby.COLLISION_TYPE.World }
            )

            if groundCheck.hit then
                local heightDiff = math.abs(groundCheck.hitPos.z - actor.position.z)
                if heightDiff < 120 then
                    return groundCheck.hitPos + util.vector3(0, 0, 10)
                end
            end
        end
    end

    return actor.position + util.vector3(0, 0, 80)
end
-- end

local function findNPCById(id)
    for _, actor in ipairs(nearby.actors) do -- обход всех загруженных ячеек
        if actor.id == id then
            return actor -- найден экземпляр NPC
        end
    end
    return nil
end

local function onActive()
    local mode = conjData:get('smConjurationMode')

    -- If completely disabled or only summon breach, don't set up damage sharing
    if mode == "Disabled" then
        return
    end

    if not conj.triggersCreatures[self.recordId] then
        return
    end

    if I.AI.getActivePackage().type == 'Follow' then
        local owner = I.AI.getActivePackage().target
        local health = types.Actor.stats.dynamic.health(self).current

        -- print("Follow", self, owner)

        core.sendGlobalEvent("smSetConjurationData", {
            key = "owner" .. self.id,
            value = owner.id
        })
        core.sendGlobalEvent("smSetConjurationData", {
            key = "health" .. self.id,
            value = health
        })



        core.sendGlobalEvent("smNewSummonConjuration", {
            summon = self.recordId,
            pos = self.position,
            cell = self.cell.name,
            ownerPos = findSpawnPos(owner, 20),
            ownerCell = owner.cell.name,
        })
    end
end

local function onUpdate()
    if core.isWorldPaused() then
        return
    end

    local mode = conjData:get('smConjurationMode')

    if mode == "Disabled" or mode == "SummonBreach" then
        return
    end

    if types.Actor.isDead(self) then
        return
    end

    if not conj.triggersCreatures[self.recordId] then
        return
    end

    local ownerId = conjData:get("owner" .. self.id)
    local health = conjData:get("health" .. self.id)

    if not ownerId then
        return
    end

    local currentHealth = types.Actor.stats.dynamic.health(self).current
    local maxHealth = types.Actor.stats.dynamic.health(self).base
    local damage = health - currentHealth

    if damage > 0 and maxHealth > 0 then

        local owner = findNPCById(ownerId)
        if not owner then

            return
        end

        if not types.Player.objectIsInstance(owner) and  conjData:get("smConjurationOnlyPlayerDamage")  then
            return
        end

        local conjSkill = math.min(types.NPC.stats.skills.conjuration(owner).modified, 100)
        local init_damage = conjData:get('smConjurationDamage') or 0.6
        local k_damage = math.max(0, init_damage - (conjSkill - 1) * (0.55 / 99))
        local damageType = conjData:get('smConjurationDamageType') or "Health"

        -- Новая формула: процент потерянного здоровья призыва
        local healthLostPercent = damage / maxHealth -- доля от 0 до 1

        owner:sendEvent("smConjurationHurt", {
            summon = self,
            healthLostPercent = healthLostPercent,
            kDamage = k_damage,
            damageType = damageType
        })

        -- ВАЖНО: Обновляем сохранённое здоровье после отправки урона
        health = currentHealth
        core.sendGlobalEvent("smSetConjurationData", {
            key = "health" .. self.id,
            value = health
        })
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = onActive
    }
}
