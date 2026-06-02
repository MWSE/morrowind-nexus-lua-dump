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
local time = require('openmw_aux.time')

local msg = core.l10n('drnerev', 'en')

local cure = require('Scripts.drnerev.cure_s')

local function getInfected(type, creatureId)

    local spellid
    local resist
    if type == "blight" then
        spellid = cure.blight[math.random(1, #cure.blight)]
        resist = types.Actor.activeEffects(self):getEffect("resistcommondisease")
    elseif type == "common" then
        local dis = cure.diseaseByCreature[creatureId]
        if dis then 
            spellid = dis[math.random(1, #dis)]
            resist = types.Actor.activeEffects(self):getEffect("resistblightdisease")
        end
    end

    local chance = 0.25*(1-math.min(resist.magnitude, 100)/100)
    if math.random() >= chance then
        return
    end


    if spellid then
        types.Actor.spells(self):add(spellid)
        self:sendEvent("OnActorInfected", {
            spellId = spellid
        })
        -- Задержка сообщения на 5 секунды
        time.newSimulationTimer(5.0, time.registerTimerCallback("InfectedMsg_" .. self.id, function()
            if self and self:isValid() then
                ui.showMessage(msg("drnrInfected"))
            end
        end))        
    end
end


-- Основная функция проверки эффектов на актёре
local function checkEffectsOnActor(data)

    local dist = data.distance
    local actor = data.actor

    local activeEffectsList
    if data.effects then
        activeEffectsList = data.effects
    else
        activeEffectsList = types.Actor.activeEffects(actor)
    end

    local healfyId = cure.illHealfy[actor.recordId]
    if not healfyId then
        -- print(actor.recordId)
        -- print(actor.id)
        return false
    end

    -- Перебираем все активные эффекты
    for _, effect in pairs(activeEffectsList) do
        -- print(effect.id, effect.recordId)
        local inRange = (effect.range == core.magic.RANGE.Touch and dist <= 300) or
                            (effect.range == core.magic.RANGE.Target and dist <= 2000)

        if inRange and effect.id == "curecommondisease" and string.find(actor.recordId, "diseased") and effect.range ~=
            core.magic.RANGE.Self then
            --print("curecommondisease", actor)
            core.sendGlobalEvent("drnrReplaceCreature", {
                ill = actor,
                healfy = healfyId,
                diseases = "common",
            })

            if inRange and effect.range == core.magic.RANGE.Touch then
                getInfected("common", healfyId)
            end
            return true
        elseif inRange and effect.id == "cureblightdisease" and string.find(actor.recordId, "blighted") and effect.range ~=
            core.magic.RANGE.Self then
            --print("cureblightdisease", actor)
            core.sendGlobalEvent("drnrReplaceCreature", {
                ill = actor,
                healfy = healfyId,
                disease = "blight",
            })

            if inRange and effect.range == core.magic.RANGE.Touch then
                getInfected("blight", healfyId)
            end
            return true
        end
    end

end

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

        -- print(hitObject, hitObject.id, distance)
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

    -- print(self.controls.use)
    -- print("use", use, dt)
    local quikSpellCasting = self.controls.use == 1 and self.type.getStance(self) == self.type.STANCE.Spell
    local ordinarySpellCasting = self.type.getStance(self) == self.type.STANCE.Spell and use and dt > 0

    if quikSpellCasting or ordinarySpellCasting then

        if spelling then
            return use
        end

        local effects = getCastEffects()
        if effects then
            local wayForTarget = 5000
            local target = findTarget(wayForTarget)

            if target then
                print("Found ", target.target, target.distance)
                -- print("spell on ", target.target, target.target.id, target.distance)
                checkEffectsOnActor({
                    actor = target.target,
                    distance = target.distance,
                    effects = effects,
                    player = self
                })
                spelling = true
            end
        end
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
