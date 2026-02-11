local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local core = require('openmw.core')
local ambient = require('openmw.ambient')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local async = require('openmw.async')

local Actor = types.Actor
local attributes = types.Actor.stats.attributes
local dynamic = types.Actor.stats.dynamic
local NPCRecord = types.NPC.record(self)

local source = nil
local playertlung_settings = storage.playerSection('settingsPlayerTrainedLungs')
local spellId = "Hold Breath"

local posX, posY  = nil, nil
local function interpolate(skillTable, skillValue)
    local value = skillValue
    if value < skillTable[1][1] then
        return 0
    end

    if value >= skillTable[#skillTable][1] then
        return math.floor(skillTable[#skillTable][2])
    end

    -- Поиск интервала
    for i = 1, #skillTable - 1 do
        local a = skillTable[i]
        local b = skillTable[i + 1]
        if value >= a[1] and value < b[1] then
            local t = (value - a[1]) / (b[1] - a[1])
            return math.floor(a[2] + t * (b[2] - a[2]))
        end
    end

    return math.floor(skillTable[#skillTable][2]) -- fallback
end

local function durationLowLevelSmooth(endurance, athletics, nerf)
    local enduranceTable
    local athleticsTable
    if nerf then
        -- Таблицы прогрессии для каждого навыка
        enduranceTable = {
            {40, 10},
            {50, 40},
            {60, 70},
            {70, 100}
        }

        athleticsTable = {
            {30, 8},
            {40, 15},
            {50, 25},
            {60, 55},
            {70, 85}
        }
    else
        enduranceTable = {
            {40, 20},
            {50, 80},
            {60, 140},
            {70, 220},
        }

        athleticsTable = {
            {30, 16},
            {40, 30},
            {50, 50},
            {60, 110},
            {70, 160}
        }
    end 

    -- Получаем базовую длительность от каждого навыка
    local enduranceBonus = interpolate(enduranceTable, endurance)
    local athleticsBonus = interpolate(athleticsTable, athletics)

    -- Берём максимум как основу
    local duration = math.max(enduranceBonus, athleticsBonus)

    return duration
end
local function duratioHighLevelSmooth(endurance, athletics, nerf, duration)
    local maxDuration
    local bothBonus = 0
    local bothTable
    if nerf then
        -- Таблицы прогрессии для каждого навыка
        bothTable = {
            {70, 120},
            {80, 140},
            {90, 160},
        }
        maxDuration = 160
    else
        bothTable = {
            {70, 240},
            {80, 280},
            {90, 340},
        }
        maxDuration = 340
    end 
    -- Бонус, если оба навыка высокие
    if endurance >= 70 and athletics >= 70 then
        local both = math.min(endurance, athletics)
        bothBonus = interpolate(bothTable, both)
    end

    -- Ограничиваем максимум
    bothBonus = math.min(bothBonus, maxDuration)
    duration = math.max(bothBonus, duration)

    return duration
end


local function calculacteHoldBreathDuration(endurance, athletics)
    local duration = 0
    local nerf = playertlung_settings:get('trainedLungsMode') == "tlung_adept"

    duration = durationLowLevelSmooth(endurance, athletics, nerf)
    duration = duratioHighLevelSmooth(endurance, athletics, nerf, duration)

    return math.floor(duration)
end


local msg = core.l10n('TrainedLungs', 'en')
local element = nil
local v2 = util.vector2
local layout = {
    layer = 'Windows',
    template = I.MWUI.templates.boxSolid,
    props = {
        position = v2(0, 0),
        relativePosition = v2(.4, .07),
        anchor = v2(0, 1)
        -- size = v2(163, 63),    
    },
    userData = {
        windowStartPosition = v2(0.4, 0.7)
    },

    content = ui.content {{
        template = I.MWUI.templates.padding,
        content = ui.content {{
            layer = 'Windows',
            type = ui.TYPE.Text,
            name = "text",
            template = I.MWUI.templates.textNormal,
            props = {
                text = ""
            }
        }}
    }}
}

layout.events = {
    mousePress = async:callback(function(data, elem)
        if data.button == 1 then -- Left mouse button
            if not elem.userData then
                elem.userData = {}
            end
            elem.userData.isDragging = true
            elem.userData.dragStartPosition = data.position
            elem.userData.windowStartPosition = layout.props.position or v2(0, 0)
        end
        element:update()
    end),

    mouseRelease = async:callback(function(data, elem)
        if elem.userData then
            elem.userData.isDragging = false
        end
        element:update()
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

            layout.props.position = newPosition
            element:update()
        end
    end)
}

local function createTimerWindow()
    if element == nil then
        element = ui.create(layout)
    end

    if posX ~= nil and posY ~= nil then
        local newPosition = v2( posX, posY)
        element.layout.props.position = newPosition
        element:update()    
    end
end

local function destroyTimerWindow()
    if element ~= nil then
        element:destroy()
        element = nil
    end
end

local function BreathIn(data)
    if playertlung_settings:get('trainedLungsEnableSound') then
        local isMale = NPCRecord.isMale
        if isMale then
            ambient.playSoundFile('Sound\\TrainedLungs\\MaleBreath.wav')
        else
            ambient.playSoundFile('Sound\\TrainedLungs\\FemaleBreath.wav')
        end
    end
    ui.showMessage(msg("tlung_deep_breath", {
        duration = data.duration
    })) -- 'You take a deep breath. ('..data.duration..'s)')    
    Actor.spells(self):add(spellId)
end
local function BreathOut()
    Actor.spells(self):remove(spellId)
    destroyTimerWindow()
    -- ui.showMessage("Almost no air left.")
end
local function BreathLow(data)
    if not playertlung_settings:get('trainedLungsEnableTimer') then
        ui.showMessage(msg("tlung_not_much_air")) -- "There's not much air left. (10s)")    
    end
end
local function BreathFail()
    ui.showMessage(msg("tlung_cant_breath")) -- "Can't breath underwater.")    
end
local function BreathTimer(data)
    if playertlung_settings:get('trainedLungsEnableTimer') then
        createTimerWindow()
        --    if not element then return end
        element.layout.content[1].content[1].props.text = msg("tlung_hold_breath", {
            duration = data.duration
        })
        element:update()
    else
        destroyTimerWindow()
    end
end

local function isHeadUnderwater()
    if not self.cell.hasWater then return false end

    local isMale = NPCRecord.isMale
    local race = NPCRecord.race

    local height = 0
    if isMale then
        height = types.NPC.races.records[race].height.male
    else
        height = types.NPC.races.records[race].height.female
    end

-- в единице роста приблизительно 128 по оси Z
-- 112 уровень глаз

    local headHeight = self.position.z + (height * 128) 
    
    -- Получаем уровень воды в текущей ячейке
    local waterLevel = self.cell.waterLevel
    
    -- Если уровень воды существует и он выше головы
    if waterLevel and waterLevel > headHeight then
        return true
    end
    
    return false
end


local function onKeyPress(key)
    if not types.Player.isCharGenFinished(self) then
        return
    end

    if race == "argonian" and not playertlung_settings:get('trainedLungsEnableForArgonians') then
        return
    end

    if key.code == playertlung_settings:get('trainedLungsMenuKey') then
        local underwater = isHeadUnderwater()

        -- ui.showMessage('TrainedLungs: height? '..(height*128)..' z '..z)

        local isSwim = types.Actor.isSwimming(self)
        -- ui.showMessage('TrainedLungs: swim? '..tostring(isSwim))

        if isSwim and underwater then
            BreathFail()
            return
        end

        local endurance = attributes.endurance(self).modified
        local athletics = types.NPC.stats.skills.athletics(self).modified
        local fatigue = dynamic.fatigue(self).current / dynamic.fatigue(self).base
        local duration = calculacteHoldBreathDuration(endurance, athletics)

        if duration > 0 then
            -- ui.showMessage('TrainedLungs: endurance '..endurance)
            -- ui.showMessage('TrainedLungs: athletics '..athletics)
            -- ui.showMessage('TrainedLungs: fatigue '..fatigue)
            -- ui.showMessage('TrainedLungs: duration '..duration)

            if fatigue < 0.2 then
                fatigue = 0
            -- elseif fatigue < 0.4 then
            --     fatigue = 0.7
            -- else
            --     fatigue = 1
            end
            if playertlung_settings:get('trainedLungsFatigueMode') == "tlung_standard" then
                if fatigue < 0.4 then
                    fatigue = 0.7
                else
                    fatigue = 1            
                end
            end

            if fatigue > 0 then
                core.sendGlobalEvent("TrainedLungs", {
                    duration = duration,
                    swim = isSwim,
                    underwater = underwater,
                    fatigue = fatigue
                })
            else
                ui.showMessage(msg("tlung_catch_breath")) -- 'You need to catch your breath.') 
            end
            -- ui.showMessage('TrainedLungs: Ok')
        else
            ui.showMessage(msg("tlung_more_train")) -- "You have to train more to be able to do that.")
        end
    end
end

local function onLoad(data)
    posX, posY = data.posX, data.posY
end

local function onSave()
    return {posX=posX, posY=posY}
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        BreathFail = BreathFail,
        BreathIn = BreathIn,
        BreathOut = BreathOut,
        BreathLow = BreathLow,
        BreathTimer = BreathTimer
    }

}
