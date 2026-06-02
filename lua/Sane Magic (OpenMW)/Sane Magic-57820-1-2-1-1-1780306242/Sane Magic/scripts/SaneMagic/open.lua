local input = require('openmw.input')
local async = require('openmw.async')
local core = require('openmw.core')
local self = require('openmw.self')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local types = require('openmw.types')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local time = require('openmw_aux.time')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')

local EFF = core.magic.EFFECT_TYPE
local playerSettingsOther = storage.playerSection('SettingsPlayerSaneMagic05_Other')
local msg = core.l10n('SaneMagic', 'en')
-- Локальная ссылка на функцию — небольшое оптимизация для часто вызываемых функций
local fatigue = types.Actor.stats.dynamic.fatigue(self)
local security = types.NPC.stats.skills.security(self)

local posX, posY = nil, nil

local v2 = util.vector2
local MWUI = I.MWUI
local BONUS_DURATION_SEC = 30
local bonusTimerElement = nil
local bonusTimerLayout = {
    layer = 'Windows',
    template = MWUI.templates.boxSolid,
    props = {
        relativePosition = v2(0.5, 0.15),
        anchor = v2(0.5, 0)
    },
    userData = {
        windowStartPosition = v2(0.4, 0.7)
    },
    content = ui.content {{
        template = MWUI.templates.padding,
        content = ui.content {{
            layer = 'Windows',
            name = 'timer',
            type = ui.TYPE.Text,
            template = MWUI.templates.textNormal,
            props = {
                text = ''
            }
        }}
    }}
}

bonusTimerLayout.events = {
    mousePress = async:callback(function(data, elem)
        if data.button == 1 then -- Left mouse button
            if not elem.userData then
                elem.userData = {}
            end
            elem.userData.isDragging = true
            elem.userData.dragStartPosition = data.position
            elem.userData.windowStartPosition = bonusTimerLayout.props.position or v2(0, 0)
        end
        bonusTimerElement:update()
    end),

    mouseRelease = async:callback(function(data, elem)
        if elem.userData then
            elem.userData.isDragging = false
        end
        bonusTimerElement:update()
    end),

    mouseMove = async:callback(function(data, elem)
        if elem.userData and elem.userData.isDragging then
            -- Calculate new position based on mouse movement
            local deltaX = data.position.x - elem.userData.dragStartPosition.x
            local deltaY = data.position.y - elem.userData.dragStartPosition.y
            local newPosition = v2(elem.userData.windowStartPosition.x + deltaX,
                elem.userData.windowStartPosition.y + deltaY)

            posX = newPosition.x
            posY = newPosition.y

            bonusTimerLayout.props.position = newPosition
            bonusTimerElement:update()
        end
    end)
}

-- Данные активного бонуса
local activeBonus = {
    active = false,
    amount = 0,
    stopFn = nil,
    till = nil,
    fatiguePercent = 0,
}

local function createBonusTimerWindow()
    if bonusTimerElement then
        return
    end
    bonusTimerElement = ui.create(bonusTimerLayout)
end
local function destroyBonusTimerWindow()
    if bonusTimerElement then
        bonusTimerElement:destroy()
        bonusTimerElement = nil
    end
end
local function showBonusTimeLeft(seconds)
    if seconds <= 0 then
        destroyBonusTimerWindow()
        return
    end
    createBonusTimerWindow()
    if not bonusTimerElement then
        return nil
    end
    -- путь как в TrainedLungs: padding → content → Text "timer"
    bonusTimerElement.layout.content[1].content[1].props.text = msg('smOpenBuffTimer', {
        seconds = seconds
    })

    bonusTimerElement:update()
end

-- Функция для снятия бонуса и остановки тика fatigue
local function removeSecurityBonus()
    -- Если бонус не активен — выходим сразу
    if not activeBonus.active then
        return
    end

    -- Останавливаем повторяющийся таймер, если он запущен
    if activeBonus.stopFn then
        activeBonus.stopFn() -- Вызываем функцию остановки
        activeBonus.stopFn = nil -- Обнуляем ссылку, предотвращая повторный вызов
    end

    -- Сохраняем текущий модификатор навыка, чтобы избежать nil-ошибок
    local currentModifier = security.modifier or 0

    -- print ("before:", security.modifier)
    -- Возвращаем модификатор в исходное состояние (вычитаем применённый бонус)
    -- Проверка нужна, чтобы не уйти в отрицательные значения из-за внешних изменений
    security.modifier = math.max(0, currentModifier - activeBonus.amount)

    -- print ("after:", security.modifier)

    -- if activeBonus.active and activeBonus.ticksRemaining <= 0 then
    --     ui.showMessage(msg('smOpenBuffEnded'))
    -- end

    -- Сбрасываем все поля состояния бонуса для полной деактивации
    activeBonus.active = false
    activeBonus.amount = 0
    activeBonus.fatiguePercent = 0
    activeBonus.till = nil

    destroyBonusTimerWindow()
    -- [Опционально] Можно добавить звук или визуальный эффект завершения
    -- Например: anim.addVfx(self, "sm_bonus_end", { loop = false })
end

local function getSecondsLeft(till)
    return math.max(0, math.floor((till - core.getGameTime()) / core.getGameTimeScale()))
end

-- Таймер снятия fatigue каждую секунду
local function fatigueTick()
    if core.isWorldPaused() then
        return
    end
    if not activeBonus.active then
        return
    end
    if not activeBonus.till then
        activeBonus.active = false
        return
    end

    local secondsLeft = getSecondsLeft(activeBonus.till)

    -- Если таймер истек, снимаем бонус
    if secondsLeft <= 0 then
        removeSecurityBonus()
        return
    end

    local current = fatigue.current
    -- Это делает расход усталости экспоненциальным (более реалистично при высокой fatigue)
    local reductionFactor = 1 - (activeBonus.fatiguePercent / 100)
    local newCurrent = math.max(0, current * reductionFactor)

    fatigue.current = newCurrent
    showBonusTimeLeft(secondsLeft)

end

-- Функция применения бонуса
local function applySecurityBonus(magnitude)

    -- print("applySecurityBonus")
    removeSecurityBonus()

    local security = types.NPC.stats.skills.security(self)
    local securityBase = security.base

    -- Проверка на минимальный уровень Security
    if securityBase < 15 then
        ui.showMessage(msg("smLowSecurity"))
        return false
    else
        ui.showMessage(msg("smOpenBuff"))
    end

    -- Рассчитываем бонус (магнитуда * 0.6, макс 75)
    local bonus = util.clamp(math.floor(magnitude * 0.3 + (securityBase - 15) * 0.2), 5, 75)

    -- Применяем бонус через модификатор
    security.modifier = (security.modifier or 0) + bonus
    activeBonus.amount = bonus
    activeBonus.active = true
    activeBonus.till = core.getGameTime() + BONUS_DURATION_SEC * core.getGameTimeScale()
    -- showBonusTimeLeft(BONUS_DURATION_SEC)

    -- Рассчитываем процентное снижение fatigue: зависит от magnitude и навыка
    -- Чем выше навык, тем меньше усталость (снижается на 1% за каждые 6 пунктов навыка)
    local efficiencyReduction = security.modified / 6 -- modified учитывает все модификаторы
    activeBonus.fatiguePercent = util.clamp(magnitude * 0.3 - efficiencyReduction, 5, 100)
    -- Минимум 5%, максимум 100% (защита от слишком низких/высоких значений)

    -- Запускаем тик каждую секунду
    activeBonus.stopFn = time.runRepeatedly(fatigueTick, time.second)
    fatigueTick()

    return true
end

local function findTargetLock(wayForTarget)

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
    if types.Door.objectIsInstance(hitObject) or types.Container.objectIsInstance(hitObject) then
        return hitObject
    end

    return nil
end

local function showAnim(effect)
    local startKey
    local stopKey


    -- local startKey = 'start'
    -- local stopKey = 'stop'
    -- if effect and effect.range then
    --     if effect.range == core.magic.RANGE.Self then
            startKey = 'self start'
            stopKey = 'self stop'
    --     elseif effect.range == core.magic.RANGE.Touch then
    --         startKey = 'touch start'
    --         stopKey = 'touch stop'
    --     elseif effect.range == core.magic.RANGE.Target then
    --         startKey = 'target start'
    --         stopKey = 'target stop'
    --     end
    -- end

    if not anim.hasGroup(self, 'spellcast') then
        -- print('no spellcast group')
        return
    end
    self.type.setStance(self, self.type.STANCE.Spell)
    I.AnimationController.playBlendedAnimation('spellcast', {
        startKey = startKey,
        stopKey = stopKey,
        loops = 0,
        speed = 1,
        -- autoDisable = true,
        priority = anim.PRIORITY.Scripted
    })
end

local function showVFX(target, effect, cast)

    local mgef = core.magic.effects.records[EFF.Open]

    local vfx = cast and mgef.castStatic or mgef.hitStatic
    local sound = cast and mgef.castSound or mgef.hitSound

    if target then
        if vfx then
            self:sendEvent('AddVfx', {
                model = types.Static.record(vfx).model,
                options = {
                    vfxId = mgef.id,
                    particleTextureOverride = mgef.particle,
                    loop = false
                }
            })

            -- anim.removeVfx(target, mgef.id)
        end
        if not sound or sound == "" then
            -- 'Sound/Fx/magic/altrC.wav' -- 'Sound/Fx/magic/altrH.wav'
            sound = cast and 'alteration cast' or 'alteration hit'
        end
        self:sendEvent('PlaySound3d', {
            sound = sound
        })
    end
end

local function cancelSpellCast()
    -- print('cancelSpellCast')
    self.controls.use = 0
    types.Actor.setStance(self, self.type.STANCE.Nothing)
    anim.clearAnimationQueue(self, true)
    anim.cancel(self, 'spellcast')
end

local function checkOpenEffect(effect)
    -- print('checkOpenEffect')
    -- 1) отмена ванильного каста (состояние ввода)
    cancelSpellCast()
    -- 2) мана до анимации и бонуса
    local magnitude = math.random(effect.magnitudeMin, effect.magnitudeMax)
    local area = effect.area or 0
    local manaCost = (magnitude * 2 + area) / 40
    local magicka = types.Actor.stats.dynamic.magicka(self)
    if magicka.current < manaCost then
        ui.showMessage("smNotEnoughMana")
        return false
    end
    -- 3) анимация + VFX каста
    showAnim(effect)
    showVFX(self, effect, true)
    -- 4) списание маны
    magicka.current = magicka.current - manaCost
    -- 5) VFX на цель (если есть)
    -- local target = findTargetLock(1500)
    -- if target then
    --     local lockLevel = types.Lockable.getLockLevel(target)
    --     if lockLevel > magnitude then
    --         target:sendEvent('PlaySound3d', {
    --             sound = 'Spell Failure Alteration' -- file = '/Sound/Fx/magic/altrFAIL.wav'
    --         })
    --     else
            showVFX(target, effect, false)
            -- 6) бонус Security
            applySecurityBonus(magnitude)
        -- end
    --end

    return true
end

-- Сохранение/загрузка состояния бонуса
local function onSave()
    return {
        active = activeBonus.active,
        amount = activeBonus.amount,
        till = activeBonus.till,
        fatiguePercent = activeBonus.fatiguePercent,
        posX = posX,
        posY = posY
    }
end

local function onLoad(data)


    if data then
        posX, posY = data.posX, data.posY
        activeBonus.active = data.active or false
        activeBonus.amount = data.amount or 0
        activeBonus.till = data.till
        activeBonus.fatiguePercent = data.fatiguePercent or 0

        -- print ("active", activeBonus.active)
        -- print ("amount", activeBonus.amount)
        -- print ("till", activeBonus.till)

        if activeBonus.active and activeBonus.till then
            local secondsLeft = getSecondsLeft(activeBonus.till)

            if secondsLeft > 0 then
                local fatigueTimer = time.runRepeatedly(fatigueTick, time.second)
                activeBonus.stopFn = fatigueTimer
                fatigueTick()
            else
                removeSecurityBonus()
            end
        else
            activeBonus.active = false
        end
    end
end

return {

    -- engineHandlers = {
    --     onSave = onSave,
    --     onLoad = onLoad
    -- },
    checkOpenEffect = checkOpenEffect,
    onSave = onSave,
    onLoad = onLoad
}
