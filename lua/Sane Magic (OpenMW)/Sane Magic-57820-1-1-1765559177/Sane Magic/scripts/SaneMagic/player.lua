-- spell_guesser.lua
local core = require("openmw.core")
local input = require("openmw.input")
local async = require("openmw.async")
local camera = require("openmw.camera")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require('openmw.storage')
local self = require("openmw.self")
local ui = require('openmw.ui')
local msg = core.l10n('SaneMagic', 'en')
local I = require('openmw.interfaces')

local EFF = core.magic.EFFECT_TYPE
local playerSettings = storage.playerSection('SettingsPlayerSaneMagic')

-- Предположим, что игрок заранее выбрал заклинание, и мы храним его в переменной
local skills = types.NPC.stats.skills
local attributes = types.Actor.stats.attributes

local spelling = false
local wayForTarget = 1000

local function findTarget(wayForTarget)

    local cameraPos = camera.getPosition()
    local baseActivationDistance = wayForTarget
    local viewDirection = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    
    -- Вычисляем общее расстояние до объекта
    local activationDistance = baseActivationDistance + camera.getThirdPersonDistance()
    
    -- Пробрасываем луч для определения целевого объекта
    local raycastResult = nearby.castRenderingRay(
        cameraPos,
        cameraPos + viewDirection * activationDistance,
        { ignore = self }
    )

    -- Если луч не попал в объект — завершаем
    if not raycastResult.hitObject then
        return
    end

    local hitObject = raycastResult.hitObject

    -- Проверяем тип объекта и состояние "уже прочитан"
    if types.NPC.objectIsInstance(hitObject) then
        return hitObject
    end
end


local function isSummon(effectId)
    local summonEffects = {
        summonancestralghost = true,
        summonskeletalminion = true,
        summonbonewalker = true,
        summongreaterbonewalker = true,
        summonbonelord = true,
    }

    return summonEffects[effectId] or false
end

local function checkPosiblityEffects(effects)
    for _, effect in ipairs(effects) do
        if isSummon(effect.id) and playerSettings:get('smSummon') then
            core.sendGlobalEvent("checkNewSummon")
        elseif effect.id == EFF.Open and playerSettings:get('smOpen') then
            local school = effect.effect.school
            if effect.magnitudeMax  > skills[school](self).modified then
                if playerSettings:get('smMessage') then 
                    ui.showMessage(msg("smNotEnough", {
                        school = school
                    }))
                end
                return false
            end
        elseif effect.id == EFF.Chameleon and playerSettings:get('smChameleon')then
            local school = effect.effect.school
            if effect.magnitudeMax > skills[school](self).modified then
                if playerSettings:get('smMessage') then 
                    ui.showMessage(msg("smNotEnough", {
                        school = school
                    }))
                end
                return false
            end
        elseif effect.id == EFF.FortifyAttribute and effect.affectedAttribute == "personality" then
            if playerSettings:get('smFortifyPersonMaxPerosonFix') and attributes.personality(self).modified >= 50 then
                if playerSettings:get('smMessage') then 
                    ui.showMessage(msg("smCanNotFix"))
                end
                return false
            end
            if playerSettings:get('smFortifyPerson') and not self.controls.sneak then
                core.sendGlobalEvent("loseDisposition", {
                    value = effect.magnitudeMax,
                    duration = effect.duration,
                    list = nearby.actors
                })
            end
        elseif effect.id == EFF.FrenzyHumanoid and playerSettings:get('smFrenzySneakLimit') then
            if skills.sneak(self).modified < 50 then
                if playerSettings:get('smMessage') then 
                    ui.showMessage(msg("smSeeYou"))
                end
                return false
            else
                if playerSettings:get('smMessage') then 
                    ui.showMessage(msg("smNotSeeYou"))
                end
            end
        end
    end
    return true
end

input.bindAction("Use", async:callback(function(dt, use)
    local currentMode = I.UI.getMode()
    if currentMode then return use end -- окна и диалоги не должны быть открыты

    if self.type.getStance(self) == self.type.STANCE.Spell and use and dt > 0 then

        core.sendGlobalEvent('SaneMagicSettings', {
            smCharm =  playerSettings:get('smCharm'),
            smFrenzyCrime =  playerSettings:get('smFrenzyCrime')
        })

        if spelling then return use end
        spelling = true
        
        local target = findTarget(wayForTarget)
        local spell = self.type.getSelectedSpell(self)
        local item = self.type.getSelectedEnchantedItem(self)
        local effects
        local spellid
        local itemid

        --print("spell ", spell, spell.id, spell.recordId)
        --print("item ", item, item.id, item.recordId)
        if spell then
            effects = spell.effects
            spellid = spell.id 
        end
        if item then
            --local enchant = core.magic.enchantments[item.enchant]
            effects = item.enchant.effects
            itemid = item.id
        end

        if not checkPosiblityEffects(effects) then 
            self.type.setStance(self, self.type.STANCE.Nothing)
            return false 
        end    
    else
        spelling = false
    end
    return use
end), {})

local function onUpdate(dt)
    if playerSettings:get('smSummon') then
        core.sendGlobalEvent("checkSummon", {  actor = self, cellId = self.cell.id, cellName = self.cell.name})
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        dcShowMessage = function(data)
            if playerSettings:get('smMessage') then 
                ui.showMessage(data.message)
            end
        end        
    }
}
