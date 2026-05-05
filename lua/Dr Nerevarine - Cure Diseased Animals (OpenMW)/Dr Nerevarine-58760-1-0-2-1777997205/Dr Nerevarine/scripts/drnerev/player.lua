-- spell_guesser.lua
local core = require("openmw.core")
local camera = require("openmw.camera")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local self = require("openmw.self")
local core = require("openmw.core")
local input = require("openmw.input")
local async = require("openmw.async")
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local cure = require('Scripts.drnerev.cure')

local function findTarget(wayForTarget)

    local cameraPos = camera.getPosition()
    local baseActivationDistance = wayForTarget
    local viewDirection = camera.viewportToWorldVector(util.vector2(0.5, 0.5))

    -- Вычисляем общее расстояние до объекта
    local activationDistance = baseActivationDistance + camera.getThirdPersonDistance()

    -- Пробрасываем луч для определения целевого объекта
    local raycastResult = nearby.castRenderingRay(cameraPos, cameraPos + viewDirection * activationDistance, {
        ignore = self
    })

    -- Если луч не попал в объект — завершаем
    if not raycastResult.hitObject then
        return nil
    end

    local hitObject = raycastResult.hitObject

    -- Проверяем тип объекта и состояние "уже прочитан"
    if types.Creature.objectIsInstance(hitObject) then
        local hitPoint = raycastResult.hitPos
        local distance = (hitPoint - cameraPos):length()

        --print(hitObject, hitObject.id, distance)
        return {
            target = hitObject,
            distance = distance
        }
    end

    return nil
end

local function getCastEffects()
    local spell = self.type.getSelectedSpell(self)
    local item = self.type.getSelectedEnchantedItem(self)
    local effects
    local spellid
    local itemid

    -- print("getCast", spell and spell.name, item and item.name)
    if spell then
        effects = spell.effects
        spellid = spell.id
    end
    if item then

        local itemRecord = item.type.record(item)
        local enchant = core.magic.enchantments.records[itemRecord.enchant]
        effects = enchant.effects
        itemid = itemRecord.id
    end

    return effects or {}
end

local spelling = false
input.bindAction("Use", async:callback(function(dt, use)

    if not use or I.UI.getMode() then -- ничего не кастуем, сбрасываем флаг
        spelling = false
        return use
    end

    if spelling then
        return use
    end -- уже кастуем

    spelling = true -- начинаем кастовать

    -- print(self.controls.use)
    -- print("use", use, dt)
    local quikSpellCasting = self.controls.use == 1 and self.type.getStance(self) == self.type.STANCE.Spell
    local ordinarySpellCasting = self.type.getStance(self) == self.type.STANCE.Spell and use and dt > 0

    if quikSpellCasting or ordinarySpellCasting then
        local effects = getCastEffects()
        if effects then
            local wayForTarget = 5000
            local target = findTarget(wayForTarget)

            if target then
                --print("spell on ", target.target, target.target.id, target.distance)
                cure.checkEffectsOnActor({
                    actor = target.target,
                    distance = target.distance,
                    effects = effects,
                    player = self
                })
            end
        end
        spelling = false
    end
    return use
end), {})

return {
    eventHandlers = {
        drnrShowMessage = function(data)
            ui.showMessage(data.message)
        end
    }
}
