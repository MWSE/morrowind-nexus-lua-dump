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

local lctn = require('Scripts.SaneMagic.location')

local EFF = core.magic.EFFECT_TYPE
local playerSettings = storage.playerSection('SettingsPlayerSaneMagic')

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


-- Функция: делает первую букву заглавной
local function capitalize(word)
    if not word or word == "" then
        return ""
    end
    return word:sub(1, 1):upper() .. word:sub(2):lower()
end

local suspiciousEffects = {
    ["levitate"] = true,
    ["jump"] = true,
}
local suspiciousCast = {
    ["chameleon"] = true,
    ["invisibility"] = true,
}
local suspiciousCrime = false
local function checkSuspiciousEffect(effects, isCast)
    local dataLoc = {
        cellId = self.cell.id,
        cellName = self.cell.name,
        cellRegion = self.cell.region
    }    
    if not (playerSettings:get('smSuspiciousEffect') and lctn.issuspiciousActivities(dataLoc) ) then return end
    
    local chameleon = types.Actor.activeEffects(self):getEffect(EFF.Chameleon)
    if isCast then
        for _, effect in pairs(effects) do
            if suspiciousCast[effect.id] and chameleon.magnitude < 90 then
                suspiciousCrime = true
                core.sendGlobalEvent("punishSuspicious")
                return
            end
        end
    else
        if lctn.isTelvanni(dataLoc) then return end 

        local hasEffect = false
        local hasInvisible = false

        for _, effect in pairs(effects) do
            if suspiciousEffects[effect.id] then
                hasEffect = true
            elseif effect.id == "invisibility" then
                hasInvisible = true
            elseif effect.id == "chameleon" and effect.magnitude >= 90 then
                hasInvisible = true
            end
        end
        if hasInvisible then return end
        if hasEffect then 
            if not suspiciousCrime then
                suspiciousCrime = true
                core.sendGlobalEvent("punishSuspicious")
            end
        else
            suspiciousCrime = false
        end
    end
end

local function checkSchool(effect, isScroll)
    if isScroll and playerSettings:get('smUnlimitScrools') then return true end

    if not ( playerSettings:get('smAllSpellLimit') 
    or effect.id == EFF.Open and playerSettings:get('smOpen')
    or effect.id == EFF.Chameleon and playerSettings:get('smChameleon') ) then return true end

    local exceptionSpell = {
        ["disintegratearmor"] = true,
        ["disintegrateweapon"] = true,
        ["almsiviintervention"] = true,
        ["mark"] = true,
        ["recall"] = true,
        ["curepoison"] = true,
        ["cureparalyzation"] = true,
        ["detectanimal"] = true,
        ["detectenchantment"] = true,
        ["detectkey"] = true,
        ["telekinesis"] = true
    }
    if exceptionSpell[effect.id] then return true end

    local checkValue
    local checkParameter
    local school
            
    if effect.id == EFF.CureCommonDisease then
        school = msg("smRestoration")
        checkParameter = 50
        checkValue = skills.restoration(self).modified        
    elseif effect.id == EFF.CureBlightDisease then
        school = msg("smRestoration")
        checkParameter = 75
        checkValue = skills.restoration(self).modified
    else
        school = effect.effect.school
        checkParameter = math.max(effect.magnitudeMax or 0, effect.duration or 0 )

        checkValue = skills[school](self).modified
    end
    if isScroll then 
        checkValue = attributes.intelligence(self).modified
    end    

    --print(effect.magnitudeMax, effect.duration, checkValue)
    if checkParameter > checkValue and not (playerSettings:get('sm100Unlimit')  and checkValue > 100) then
        if playerSettings:get('smMessage') then 
            if isScroll then 
                ui.showMessage(msg("smNotEnoughIntel"))
            else
                ui.showMessage(msg("smNotEnough", {
                    school = capitalize(school)
                }))
            end
        end
        return false
    end        
    return true    
end
local function checkNewSummon(effect)
    if not playerSettings:get('smSummon') then return end
    if isSummon(effect.id) then
        core.sendGlobalEvent("checkNewSummon")
    end
end

local function checkFortifyPersonality(effects, percent)
    if not playerSettings:get('smFortifyPersonPotions') then return end
    local seeYou = getNpcsSeeingPlayer(1500)
    if self.controls.sneak or #seeYou == 0 then return end



    for _, effect in ipairs(effects) do
        if effect.id == EFF.FortifyAttribute and effect.affectedAttribute == "personality" then
            if #seeYou > 0 then
                ui.showMessage(msg("smSeeYou"))
            end
            core.sendGlobalEvent("loseDisposition", {
                value = effect.magnitudeMax*percent/2,
                duration = effect.duration,
                list = seeYou -- nearby.actors
            })
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
            smFrenzyCrime =  playerSettings:get('smFrenzyCrime'),
        })

        if spelling then return use end
        spelling = true
        
        local target = findTarget(wayForTarget)
        local spell = self.type.getSelectedSpell(self)
        local item = self.type.getSelectedEnchantedItem(self)
        local effects
        local spellid
        local itemid

        if spell then
            if spell.type ~= core.magic.SPELL_TYPE.Power and spell.type ~= core.magic.SPELL_TYPE.Spell  then
                return use
            end 

            if spell.alwaysSucceedFlag then return use end
            
            effects = spell.effects
            spellid = spell.id 
        end
        if item then

            local itemRecord = item.type.record(item)
            local enchant = core.magic.enchantments.records[itemRecord.enchant]
            effects = enchant.effects
            itemid = itemRecord.id

        end

        for _, effect in pairs(effects) do
            --Не проверяем силы
            if (spell and spell.type == core.magic.SPELL_TYPE.Power)  then goto skip end

            -- проверяем заклинания и свитки
            if not checkSchool(effect, item ~= nil ) then 
                self.type.setStance(self, self.type.STANCE.Nothing)
                return false 
            end   
            ::skip::
            checkNewSummon(effect)
        end
        checkSuspiciousEffect( effects, true) 
        checkFortifyPersonality(effects, 1)

    else
        spelling = false
    end
    return use
end), {})

local function onConsume(item)
    --print("onConsume", item)
    local percent = 1.0
    if item.recordId == "potion_t_bug_musk_01" then
        percent = 0.75
    end
    local potion = types.Potion.record(item)
    local effects = potion.effects

    checkFortifyPersonality(effects, percent)
end

local function onUpdate(dt)
    local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region, npcs = nearby.actors}
    if playerSettings:get('smSummon') then
        core.sendGlobalEvent("checkSummon", dataLoc)
    end
    checkSuspiciousEffect( types.Actor.activeEffects(self), false)
end

local bountyPoints = 0

local function isFobbidenEffects(effects)
    local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}    
    if not (playerSettings:get('smSuspiciousEffect') and lctn.issuspiciousActivities(dataLoc) ) then return end
    if lctn.isTelvanni(dataLoc) then return end 
            
    for _, effect in pairs(effects) do
        if suspiciousEffects[effect.id] then
            return true
        end
    end
    return false
end    

local function UiModeChanged(data)
    --print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
    if data.newMode == "Dialogue" then
        bountyPoints = types.Player.getCrimeLevel(self)
        --print("bp", bountyPoints)
    end
    if data.oldMode == "Dialogue" then
        local newBountyPoints = types.Player.getCrimeLevel(self)
        --print("new bp", newBountyPoints)
        if newBountyPoints < bountyPoints then
            --clear fobbiden stuff
            local equip = {}
            for _, slot in pairs(types.Actor.EQUIPMENT_SLOT) do
                local item = self.type.getEquipment(self, slot)
                equip[slot] = item
            end

            local spells = types.Actor.activeSpells(self)
            for _, spell in pairs(spells) do
                if spell.fromEquipment and isFobbidenEffects(spell.effects) then
                    for slot, item in pairs(equip) do
                        if item == spell.item then
                            equip[slot] = nil
                        end
                    end
                    -- OpenMW 50
                    --self:sendEvent('Unequip', {item = spell.item})
                end
            end
            -- OpenMW 49
            self.type.setEquipment(self, equip)

            self.type.activeSpells(self):add({id = "dispel", effects = {0}})
            --print("dispel")
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onConsume = onConsume 
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        smShowMessage = function(data)
            if playerSettings:get('smMessage') then 
                ui.showMessage(data.message)
            end
        end        
    }
}
