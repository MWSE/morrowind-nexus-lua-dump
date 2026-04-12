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
local animation = require('openmw.animation')

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

local inCombatNPC = {}

-- Возвращает список NPC, которые видят игрока
local function getNpcsSeeingPlayer(maxViewDistance)
    local nearbyActors = nearby.actors
    local seeingNpcs = {}

    local playerPos = self.position
    --local viewAngleRad = math.rad(viewAngleDegrees or 90)
    --local cosMaxAngle = math.cos(viewAngleRad)

    for _, actor in ipairs(nearbyActors) do
        -- Пропускаем не-NPC и мёртвых

        if types.NPC.objectIsInstance(actor) 
        and not types.Actor.isDead(actor) 
        and not inCombatNPC[actor.recordId]
        then

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
                    print("all:", actor, actor.recordId, inCombatNPC[actor.recordId])
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

local function checkSuspiciousEffect(effects, isCast)
    local dataLoc = {
        cellId = self.cell.id,
        cellName = self.cell.name,
        cellRegion = self.cell.region
    } 
    if not (playerSettings:get('smSuspiciousEffect') and lctn.issuspiciousActivities(dataLoc) ) then return end
       
    local seeYou = getNpcsSeeingPlayer(1500) 
    if self.controls.sneak or #seeYou == 0 then return end
    
    local chameleon = types.Actor.activeEffects(self):getEffect(EFF.Chameleon)
    local chameleonMag = chameleon.magnitude

    if isCast then
        for _, effect in pairs(effects) do
            if suspiciousCast[effect.id] and chameleonMag < 90 then
                core.sendGlobalEvent("punishSuspicious", {hasEffect = true})
                return
            end
        end
    else
        if lctn.isTelvanni(dataLoc) then return end 

        local hasEffect = false
        local hasInvisible = false


        for _, effect in pairs(effects) do
            if effect.id == "levitate" and lctn.isVivecLevitationAllow(dataLoc) then
                -- пропускаем еффект левитации в храме Вивека
            elseif suspiciousEffects[effect.id] then
                hasEffect = true
            elseif effect.id == "chameleon" then
                if chameleonMag >= 90 then
                    hasInvisible = true
                else
                    hasEffect = true
                end               
            elseif effect.id == "invisibility" then
                hasInvisible = true
            end
        end

        core.sendGlobalEvent("punishSuspicious", {hasEffect = hasEffect and not hasInvisible})
    end
end

local function checkSchool(effect, isScroll)
    --if isScroll and playerSettings:get('smUnlimitScrools') then return true end

    if playerSettings:get('smSaneMagicCap') == "Disabled" then
        return true
    end
    if isScroll and playerSettings:get('smSaneMagicCap') == "OnlySpells" then
        return true
    end

    if effect.id == EFF.Open and playerSettings:get('smOpen')
    or effect.id == EFF.Chameleon and playerSettings:get('smChameleon') then return true end

    local exceptionSpell = {
        ["disintegratearmor"] = true,
        ["disintegrateweapon"] = true,
	    ["burden"] = true,
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
    local magintude = 0
    local scrollMsg   
    
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

        if effect.magnitudeMax and effect.magnitudeMin then
            magintude = (effect.magnitudeMax+effect.magnitudeMin)/2 
        else
            magintude = effect.magnitudeMax or 0
        end
        checkParameter = math.max( magintude , effect.duration or 0 )
        --print(effect.magnitudeMax, effect.magnitudeMin, checkParameter)

        checkValue = skills[school](self).modified
    end
    --print(playerSettings:get('smSaneMagicCap'))
    if isScroll then 
        if playerSettings:get('smSaneMagicCap') == "Lax" then
            if magintude <= 1 then
                checkParameter = 40
            else
                checkParameter = magintude
            end
            --print("Lax - intel")
        end
        checkValue = attributes.intelligence(self).modified
        scrollMsg = "smNotEnoughIntel"
        --print("Intel", checkValue, "limit", checkParameter)
    end    

    checkParameter = math.floor(checkParameter)

    --print(effect.magnitudeMax, effect.duration, checkParameter, checkValue)
    if checkParameter > checkValue and not (playerSettings:get('sm100Unlimit')  and checkValue > 100) then
        if playerSettings:get('smMessage') then 
            if isScroll then 
                ui.showMessage(msg(scrollMsg, {need = checkParameter}))
            else
                ui.showMessage(msg("smNotEnough", {
                    school = capitalize(school), need = checkParameter
                }))
            end
        end
        return false
    end        

    --print("magnitude", magintude)
    checkParameter = math.max(effect.duration or effect.area) or 0 
    if playerSettings:get('smSaneMagicCap') == "Lax" and isScroll and checkParameter > 0 then
        --print("Lax - will")

        checkValue = attributes.willpower(self).modified
        checkParameter = math.max(effect.duration or effect.area) or 0 
        --print("Will", checkValue, "limit", checkParameter)

        if checkParameter > checkValue and not (playerSettings:get('sm100Unlimit')  and checkValue > 100) then
            if playerSettings:get('smMessage') then 
                ui.showMessage(msg("smNotEnoughWill", {need = checkParameter}))
            end
            return false
        end          
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

local function getCastItem()
    local spell = self.type.getSelectedSpell(self)
    local item = self.type.getSelectedEnchantedItem(self)
    local effects
    local spellid
    local itemid   

    --print("getCast", spell and spell.name, item and item.name)
    if spell then
        if spell.type ~= core.magic.SPELL_TYPE.Power and spell.type ~= core.magic.SPELL_TYPE.Spell  then
            return nil
        end 
        --Не проверяем силы
        if (spell and spell.type == core.magic.SPELL_TYPE.Power)  then return nil end

        if spell.alwaysSucceedFlag then return nil end
        
        effects = spell.effects
        spellid = spell.id 
    end
    if item then

        local itemRecord = item.type.record(item)
        local enchant = core.magic.enchantments.records[itemRecord.enchant]
        effects = enchant.effects
        itemid = itemRecord.id
    end
    

    return { effects = effects, isScroll = item ~= nil, spell = spell, item = item }
end


local function chechEffects(effects, isScroll)
    for _, effect in pairs(effects) do
        -- проверяем заклинания и свитки
        if not checkSchool(effect, isScroll ) then 
            self.type.setStance(self, self.type.STANCE.Nothing)
            self.controls.use = 0
            --self.type.setSelectedEnchantedItem(self, {})
            self.type.setSelectedSpell(self, nil)

            --animation.cancel(self, spellGroupName)
            --animation.clearAnimationQueue(self, true)           
            return false 
        end   
        checkNewSummon(effect)
    end

    return true
end


input.bindAction("Use", async:callback(function(dt, use)

    local currentMode = I.UI.getMode()
    if currentMode then return use end -- окна и диалоги не должны быть открыты
    
    --print(self.controls.use)
    local quikSpellCasting = self.controls.use == 1  and self.type.getStance(self) == self.type.STANCE.Spell
    local ordinarySpellCasting = self.type.getStance(self) == self.type.STANCE.Spell and use and dt > 0 

    if quikSpellCasting or ordinarySpellCasting then
        --print ("Use cast", quikSpellCasting, ordinarySpellCasting)
        --print(self.type.getStance(self), dt, use)

        core.sendGlobalEvent('SaneMagicSettings', {
            smCharm =  playerSettings:get('smCharm'),
            smFrenzyCrime =  playerSettings:get('smFrenzyCrime'),
        })

        if spelling then return use end
        spelling = true
        
        --local target = findTarget(wayForTarget)
        local casiItem = getCastItem()
        if not casiItem then return use end
    
        local effects = casiItem.effects or {}
        local isScroll = casiItem.isScroll

        if chechEffects(effects, isScroll) then 
            checkSuspiciousEffect( effects, true) 
            checkFortifyPersonality(effects, 1)
        else
            return false 
        end        
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
    if core.isWorldPaused() or I.UI.getMode() ~= nil then return end


    local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region, npcs = nearby.actors}
    if playerSettings:get('smSummon') then
        local seeYou = getNpcsSeeingPlayer(1000)
        if not self.controls.sneak and #seeYou > 0 then
            core.sendGlobalEvent("checkSummon", dataLoc)
        end
    end

    local spells = types.Actor.activeSpells(self)
    local wasChecked = false


    local effects = {}

    for spellid, actspell in pairs(spells) do
        if actspell.item then
            for _, effect in pairs(actspell.effects) do
                table.insert(effects, effect)
            end
        else
            local spell = core.magic.spells.records[spellid]
            if spell.type == core.magic.SPELL_TYPE.Spell then
                for _, effect in pairs(actspell.effects) do
                    table.insert(effects, effect)
                end
            end
        end
    end

    checkSuspiciousEffect( effects, false) 

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

--QuickCast support
local quickKeyActions = {}
for i = 1, 10 do
   quickKeyActions[(input.ACTION)['QuickKey' .. tostring(i)]] = true
end

local function checkCurrentSpell()

    local castItem = getCastItem(true)
    if not castItem then return end
    if castItem.isScroll then return end

    local effects = castItem.effects or {}
    local isScroll = castItem.isScroll

    --print("qc", castItem.spell, castItem.item)
    if chechEffects(effects, false) then
        checkSuspiciousEffect( effects, true) 
        checkFortifyPersonality(effects, 1)
    end
end
--QuickCast support

-- ZerkishHotkeysImproved support
local function ZHI_HotkeySelectEvent(data)

    if playerSettings:get('smQuickKeyCompatible') ~= "ZerkishHotbar" then return end

    if not data then return end
    local isScroll
    local effects

    if data.itemEnchant then 
        local item = data.itemEnchant

        local itemRecord = types[item.typeName].record(item.recordId)
        local enchant = core.magic.enchantments.records[itemRecord.enchant]
        effects = enchant.effects
        isScroll = true
        --print("zhi", itemRecord)
    end

    if data.spell  then

        local spell = core.magic.spells.records[data.spell.id]
        if spell.type ~= core.magic.SPELL_TYPE.Power and spell.type ~= core.magic.SPELL_TYPE.Spell  then
            return 
        end 
        --Не проверяем силы
        if (spell and spell.type == core.magic.SPELL_TYPE.Power)  then return end

        if spell.alwaysSucceedFlag then return end
        
        effects = spell.effects
        isScroll = false

        --print("zhi", spell)
    end

    if effects then
        if chechEffects(effects, isScroll) then
            checkSuspiciousEffect( effects, true) 
            checkFortifyPersonality(effects, 1)
        else 
            data.spell = {} 
        end
    end
end
-- ZerkishHotkeysImproved support

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onConsume = onConsume,
        onInputAction = function(action)
            --print(playerSettings:get('smQuickKeyCompatible'))
--QuickCast support
            if playerSettings:get('smQuickKeyCompatible') ~= "QuickCast" then return end

            if quickKeyActions[action] then
                checkCurrentSpell()
            end
--QuickCast support
        end,        
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        ZHI_HotkeySelectEvent = ZHI_HotkeySelectEvent,
        smInCombat = function(data)
            inCombatNPC[data.npc] = data.inCombat

        end,
        smShowMessage = function(data)
            if playerSettings:get('smMessage') then 
                ui.showMessage(data.message)
            end
        end        
    }
}
