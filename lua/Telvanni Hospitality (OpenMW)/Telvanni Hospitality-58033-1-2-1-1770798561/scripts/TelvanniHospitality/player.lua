
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

local I = require('openmw.interfaces')
local lctn = require('Scripts.TelvanniHospitality.location')
local msg = core.l10n('TelvanniHospitality', 'en')

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

local function checkTelvanniEffect(effects, isCast)
    local dataLoc = { cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}
    local hasEffect = false
    for _, effect in pairs(effects) do
        if lctn.telvanniAllowedEffects[effect.id] or (lctn.telvanniAllowedEffectsTelNaga[effect.id] and lctn.isTelvanniTelNaga(dataLoc)) then goto continue2 end

        if isCast then
            if effect.school == "destruction" then 
                hasEffect = true
                break
            end
            if lctn.telvanniNotAllowedCast[effect.id] then 
                hasEffect = true 
                break 
            end
        else
            if lctn.telvanniNotAllowedEffects[effect.id] then 
                hasEffect = true 
                break 
            end
        end                
        ::continue2::
    end

    if hasEffect then
        local seeYou = getNpcsSeeingPlayer(1500)
        if #seeYou > 0 then
            local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}
            if not lctn.isTelvanniTelNaga(dataLoc) then
                -- for _, actor in pairs(seeYou) do
                --     if actor.id ~= "gals arethi" then
                --         actor:sendEvent('StartAIPackage', {type='Combat', target=self})
                --     end
                -- end
                seeYou = {}
            end  
            core.sendGlobalEvent("punishTelvanni", {isCast = isCast, seeYou = seeYou}) --, isSadrithMora = lctn.isTelvanniSadrithMora(dataLoc) })
        end
    end
    return hasEffect
end

    
local function checkTelvanniEffects()
    local spells = types.Actor.activeSpells(self)
    local effects
    local hasEffect = false
    for _, aspell in pairs(spells) do
        --print(aspell.id, aspell.item)
        if aspell.item then 
            effects = aspell.effects            
        else
            local spell = core.magic.spells.records[aspell.id]
            if spell.type == core.magic.SPELL_TYPE.Spell or spell.type == core.magic.SPELL_TYPE.Power then
                effects = spell.effects
            else
                goto continue
            end
        end    
        if checkTelvanniEffect(effects, false) then 
            hasEffect = true 
            break 
        end
        -- local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}
        -- if lctn.isTelvanniTelNaga(dataLoc) then
        --     local seeYou = getNpcsSeeingPlayer(1500)
        --     for _, actor in pairs(seeYou) do
        --         if actor.id ~= "gals arethi" then
        --             actor:sendEvent('StartAIPackage', {type='Combat', target=self})
        --         end
        --     end
        -- end  
        -- hasEffect = true
        ::continue::
    end

    if not hasEffect then core.sendGlobalEvent("resetTelvanniCrime") end
end

input.bindAction("Use", async:callback(function(dt, use)
    local currentMode = I.UI.getMode()
    if currentMode then return use end -- окна и диалоги не должны быть открыты
    
    local telvanniRank = types.NPC.getFactionRank(self, "telvanni")
    if telvanniRank >= 2 then return use end

    if self.type.getStance(self) == self.type.STANCE.Spell and use and dt > 0 then
        local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}

        if lctn.isTelvanni(dataLoc) and not lctn.isMage(dataLoc) and not lctn.isInn(dataLoc) then
            if spelling then return use end
            spelling = true

            local spell = self.type.getSelectedSpell(self)
            local item = self.type.getSelectedEnchantedItem(self)
            local effects

            if spell then
                if spell.type ~= core.magic.SPELL_TYPE.Spell then
                    return use
                end 
                effects = spell.effects
            end
            if item then
                local itemRecord = item.type.record(item)
                local enchant = core.magic.enchantments.records[itemRecord.enchant]
                effects = enchant.effects
            end

            checkTelvanniEffect(effects, true)    
        end
    else
        spelling = false
    end
    return use
end), {})


local function onUpdate(dt)

    local telvanniRank = types.NPC.getFactionRank(self, "telvanni")
    if telvanniRank >= 2 then return end

    local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}

    if lctn.isTelvanniSadrithMoraNotAllow(dataLoc) then 
        local inventory = types.Actor.inventory(self)   
        if not inventory:find("bk_hospitality_papers") then
            core.sendGlobalEvent("punishSadrithMora")
            local seeYou = getNpcsSeeingPlayer(1500)
            for _, actor in pairs(seeYou) do
                if actor.id ~= "gals arethi" then
                    actor:sendEvent('StartAIPackage', {type='Combat', target=self})
                end
            end
        end
    else
        core.sendGlobalEvent("resetSadrithMora")
    end

    if lctn.isTelvanni(dataLoc) and not lctn.isMage(dataLoc) and not lctn.isInn(dataLoc) then 
        checkTelvanniEffects()
    end
end

local bountyPoints = 0

local function isFobbidenEffects(effects)
    local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}    
    for _, effect in pairs(effects) do
        if lctn.telvanniAllowedEffects[effect.id] or (lctn.telvanniAllowedEffectsTelNaga[effect.id] and lctn.isTelvanniTelNaga(dataLoc)) then goto continue end
        if lctn.telvanniNotAllowedEffects[effect.id] then 
            return true
        end
        ::continue::
    end
    return false
end    
local function UiModeChanged(data)
    --print('UiModeChanged from', data.oldMode , 'to', data.newMode, '('..tostring(data.arg)..')')
    if data.newMode == "Dialogue" then
        bountyPoints = types.Player.getCrimeLevel(self)
        --print("bp", bountyPoints)
        local npc = data.arg
        if bountyPoints > 0 then
            if data.arg then 
                local npc = data.arg
                if npc.recordId == "angaredhel" then 
                    -- ui.showMessage(msg("thDontTalkToCrime"), {showInDialogue = false})
                    -- self:sendEvent('SetUiMode', {})
                elseif npc.recordId == "telvanni guard" then
                    local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}    
                    if lctn.isTelvanniSadrithMora(dataLoc) then
                        local inventory = types.Actor.inventory(self)   
                        local item = inventory:find("bk_hospitality_papers")
                        if item then
                            core.sendGlobalEvent("thRemovePapers")
                            ui.showMessage(msg("thRemovePapers"), {showInDialogue = true})  
                        end
                    end
                end
            end
        end
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

            local dataLoc = {  cellId = self.cell.id, cellName = self.cell.name, cellRegion = self.cell.region}    
            if lctn.isTelvanniSadrithMora(dataLoc) then
                local inventory = types.Actor.inventory(self)   
                local item = inventory:find("bk_hospitality_papers")
                if not item then
                    core.sendGlobalEvent("thTeleportTavern")
                end
            end

            --print("dispel")
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,

        thShowMessage = function(data)
            ui.showMessage(data.message)
        end,
        -- thShowMessageBox = function(data)
        --     ui.showMessage(data.message, {showInDialogue = true})            
        -- end
    }
}
