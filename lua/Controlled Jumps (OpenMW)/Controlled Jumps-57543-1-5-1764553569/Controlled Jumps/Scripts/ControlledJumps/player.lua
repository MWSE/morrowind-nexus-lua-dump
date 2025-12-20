local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local types = require('openmw.types')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local controls = require('openmw.interfaces').Controls
local storage = require('openmw.storage')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local camera = require('openmw.camera')

local playerSettings = storage.playerSection('SettingsPlayerControlledJumps')
local playerSettings2 = storage.playerSection('SettingsPlayerControlledJumps2')
local playerSettings3 = storage.playerSection('SettingsPlayerControlledJumps3')
local msg = core.l10n('ControlledJumps', 'en')

local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic
local NPCRecord = types.NPC.record(self)

local acrobaticsModifier = 0
local acrobaticsDamage = 0

local jumping = false
local count = 0
local startPos = nil

local hasBonus = false
local maxCount = 100

local element = nil
local v2 = util.vector2
local layout = {
    layer = 'Windows',
    template = I.MWUI.templates.boxSolid,
    props = {
        position = v2(0, 0),
        relativePosition = v2(.50, .80),
        anchor = v2(0, 1)
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

local posX, posY = nil, nil

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
end
local function destroyTimerWindow()
    if element ~= nil then
        element:destroy()
        element = nil
    end
end

local function cjJump(count)
    acrobaticsModifier = 0
    acrobaticsDamage = 0

    local acrobaticsBase = skills.acrobatics(self).modified

    local enableBoost = playerSettings:get('cjEnableExpBoost') 
    local fatiguePercent = (dynamic.fatigue(self).current / dynamic.fatigue(self).base) * 100

    if enableBoost and count > 60 then
        I.SkillProgression.skillUsed("acrobatics", {
            scale = 1,
            useType = I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Jump
        })
    end

    if playerSettings:get('cjBonus') and hasBonus and count == 100 and fatiguePercent >= 80 then
        if enableBoost then
            I.SkillProgression.skillUsed("acrobatics", {
                scale = 1,
                useType = I.SkillProgression.SKILL_USE_TYPES.Acrobatics_Jump
            })
        end

        acrobaticsModifier = playerSettings:get('cjBoost')
        skills.acrobatics(self).modifier = skills.acrobatics(self).modifier+acrobaticsModifier

        if playerSettings:get('cjBonusSound') then
            local isMale = NPCRecord.isMale
            if isMale then
                ambient.playSoundFile('Sound/ControlledJumps/MaleChargedJump.wav')
            else
                ambient.playSoundFile('Sound/ControlledJumps/FemaleChargedJump.wav')
            end
        end
    else
        hasBonus = false
        acrobaticsDamage = math.floor(skills.acrobatics(self).modified * (1 - count / 100))
        skills.acrobatics(self).damage = skills.acrobatics(self).damage+acrobaticsDamage
    end
    jumping = true
    print("acrobatics base "..acrobaticsBase.." damage "..acrobaticsDamage.." (" .. count .. "%)")
end

local function cjCount(data)
    count = data.count
    if count > maxCount then
        count = maxCount
    end

    if count == 60 then
        local finishPos = self.position
        if finishPos == startPos then
            hasBonus = true
        end
    end

    if count < maxCount then
        createTimerWindow()
        element.layout.content[1].content[1].props.text = "" .. count .. "%"
        element:update()
    else
        destroyTimerWindow()
    end
end

local function onKeyPress(key)
    if I.UI.getMode() ~= nil then
        return
    end -- не прыгает при открытом меню

    if not playerSettings:get('cjEnable') then
        return
    end

    if key.code == playerSettings:get('cjKey') then
        if types.Actor.isOnGround(self) and not types.Actor.isSwimming(self) then
            startPos = self.position
            hasBonus = false
            -- controls.overrideMovementControls(true)
            core.sendGlobalEvent("cjStart", {})
        end
    end
end

local function onKeyRelease(key)
    if I.UI.getMode() ~= nil then
        return
    end -- не прыгает при открытом меню
    if not playerSettings:get('cjEnable') then
        return
    end

    if key.code == playerSettings:get('cjKey') then
        core.sendGlobalEvent("cjDone", {})
        if types.Actor.isOnGround(self) and not types.Actor.isSwimming(self) then
            controls.overrideMovementControls(true)
            cjJump(count)
            self.controls.jump = true
        end
    end
end

local onAir = false
local jumpHeight = 0 
local jumpHeightBase = 0 

local function onUpdate()

    local isGrounded = types.Actor.isOnGround(self) or types.Actor.isSwimming(self)
    local isUncontrolledEnabled = playerSettings:get('cjEnableUncontrolledJump')

    if jumping then
        jumpHeight = 0 
        jumpHeightBase = self.position.z
    end
    --if onAir then
        jumpHeight = math.max(jumpHeight, self.position.z-jumpHeightBase)
    --end

    if jumping and not isGrounded then
        onAir = true
        --print("on air")

        if isUncontrolledEnabled then
            controls.overrideMovementControls(true)
            --print("uncontrolled jump")
        end
    end


    if jumping and not isGrounded then
        destroyTimerWindow()
        if not isUncontrolledEnabled then
            controls.overrideMovementControls(false)
        end

        local acrobaticsSkill = skills.acrobatics(self)
        -- print(acrobaticsSkill.damage)
        -- print(acrobaticsDamage)
        acrobaticsSkill.modifier = acrobaticsSkill.modifier - acrobaticsModifier
        acrobaticsSkill.damage = acrobaticsSkill.damage - acrobaticsDamage
        jumping = false
        acrobaticsDamage = 0
        acrobaticsModifier = 0
    end

    if onAir and isGrounded then
        --print("landing")

        --ui.showMessage("Jump height: "..string.format("%.2f", jumpHeight))
        --print("Jump height: "..jumpHeight)

        if isUncontrolledEnabled then
            controls.overrideMovementControls(false)
            --print("uncontrolled jump off")
        end

        if hasBonus then
            if playerSettings:get('cjBonusSound') then
                local isMale = NPCRecord.isMale
                if isMale then
                    ambient.playSoundFile('Sound/ControlledJumps/MaleChargedLanding.wav')
                else
                    ambient.playSoundFile('Sound/ControlledJumps/FemaleChargedLanding.wav')
                end
            end
            if not playerSettings:get('cjDontEatFatigue') then
                dynamic.fatigue(self).current = dynamic.fatigue(self).current / 2            
            end
        end
        hasBonus = false
        jumping = false
        onAir = false
    end
end

local function onJump()

    if playerSettings3:get('cjEnableViewJump') then
        local z = camera.viewportToWorldVector(util.vector2(0.5, 0.5)).z
        local percent
        if playerSettings3:get('cjViewJumpFromGround') then
            percent = (1+z)/2*100
        else
            if z < 0 then z = 0 end
            percent = z*100
        end
        cjJump(percent)
    elseif playerSettings2:get('cjEnableShort') then
        local key = playerSettings2:get('cjKeyShort')
        local trigger = (key == "Shift" and input.isShiftPressed() or key == "Ctrl" and input.isCtrlPressed() or key ==
                            "Alt" and input.isAltPressed())
        if trigger then
            local percent = playerSettings2:get('cjPercent')
            cjJump(percent)
        end
    end

    jumping = true
    --print("jump")
end

local function onInputAction(id)
    if id == input.ACTION.Jump then
        onJump()
    end
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onKeyRelease = onKeyRelease,
        onUpdate = onUpdate,
        onInputAction = onInputAction,

        onLoad = function(data)
            posX, posY = data.posX, data.posY
        end,
        onSave = function()
            return {
                posX = posX,
                posY = posY
            }
        end

    },
    eventHandlers = {
        cjCount = cjCount,
        cjJump = cjJump,
        destroyTimerWindow = destroyTimerWindow
    }

}
