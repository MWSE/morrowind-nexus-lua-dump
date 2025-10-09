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
local playerSettings = storage.playerSection('SettingsPlayerTrainedLungs')
local spellId = "Hold Breath"

local posX, posY  = nil, nil

local function calculacteHoldBreathDuration(endurance, athletics)
    local duration = 0
    if endurance > 90 and athletics > 90 then
        duration = 360
    elseif endurance > 80 and athletics > 80 then
        duration = 300
    elseif endurance > 70 and athletics > 70 then
        duration = 240
    elseif endurance > 80 or athletics > 70 then
        duration = 160
    elseif endurance > 70 or athletics > 60 then
        duration = 120
    elseif endurance > 60 or athletics > 50 then
        duration = 60
    elseif endurance > 50 or athletics > 40 then
        duration = 30
    elseif endurance > 40 or athletics > 30 then
        duration = 15
    elseif athletics > 25 then
        duration = 10
    elseif endurance > 30 then
        duration = 6
    end
    return duration
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
    if playerSettings:get('trainedLungsEnableSound') then
        local isMale = NPCRecord.isMale
        if isMale then
            ambient.playSoundFile('Sound\\TrainedLungs\\MaleBreath.wav')
        else
            ambient.playSoundFile('Sound\\TrainedLungs\\FemaleBreath.wav')
        end
    end
    ui.showMessage(msg("deep_breath", {
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
    if not playerSettings:get('trainedLungsEnableTimer') then
        ui.showMessage(msg("not_much_air")) -- "There's not much air left. (10s)")    
    end
end
local function BreathFail()
    ui.showMessage(msg("cant_breath")) -- "Can't breath underwater.")    
end
local function BreathTimer(data)
    if playerSettings:get('trainedLungsEnableTimer') then
        createTimerWindow()
        --    if not element then return end
        element.layout.content[1].content[1].props.text = msg("hold_breath", {
            duration = data.duration
        })
        element:update()
    else
        destroyTimerWindow()
    end
end

local function onKeyPress(key)
    if not types.Player.isCharGenFinished(self) then
        return
    end
    local isMale = NPCRecord.isMale
    local race = NPCRecord.race

    if race == "argonian" and not playerSettings:get('trainedLungsEnableForArgonians') then
        return
    end

    if key.code == playerSettings:get('trainedLungsMenuKey') then
        local z = self.position.z

        local height = 0
        if isMale then
            height = types.NPC.races.records[race].height.male
        else
            height = types.NPC.races.records[race].height.female
        end

        -- в единице роста приблизительно 128 по оси Z
        -- 112 уровень глаз
        local underwater = z < -(height * 128) -- голова под водой

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
            elseif fatigue < 0.4 then
                fatigue = 0.7
            else
                fatigue = 1
            end

            if fatigue > 0 then
                core.sendGlobalEvent("TrainedLungs", {
                    duration = duration,
                    swim = isSwim,
                    underwater = underwater,
                    fatigue = fatigue
                })
            else
                ui.showMessage(msg("catch_breath")) -- 'You need to catch your breath.') 
            end
            -- ui.showMessage('TrainedLungs: Ok')
        else
            ui.showMessage(msg("more_train")) -- "You have to train more to be able to do that.")
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
