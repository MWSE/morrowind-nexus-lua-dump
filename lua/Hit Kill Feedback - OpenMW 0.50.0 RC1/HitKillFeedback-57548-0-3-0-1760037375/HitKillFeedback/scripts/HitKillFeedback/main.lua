local core = require('openmw.core')
local async = require('openmw.async')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require('openmw.self')
local types = require('openmw.types')
local events = require('scripts.HitKillFeedback.events')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local c = require('scripts.HitKillFeedback.constants')
local o = require('scripts.HitKillFeedback.settings').o
local sectionOLookup = require('scripts.HitKillFeedback.settings').sectionOLookup

local throt = require('scripts.HitKillFeedback.lib.myUtils').throt
local lerp = require('scripts.HitKillFeedback.lib.myUtils').lerp
local bounce_easing = require('scripts.HitKillFeedback.lib.myUtils').bounce_easing
local easeInExpo = require('scripts.HitKillFeedback.lib.myUtils').easeInExpo

local setDebugText = require('scripts.HitKillFeedback.lib.myUtils').setDebugText

core.sendGlobalEvent('SetSimulationTimeScale', 1)

local activeDamageNumbers = {}
local activeFeedbackText = {}
local activeSpellDMGNums = {}

local allWords = {}

local extraRoll = 0
local extraPitch = 0
local extraYaw = 0
-- local EXTRAS_LERP = 0.25
local EXTRAS_LERP = 0.000000001


local SIM_LERP = 1
-- local DMGNUMS_RADIUS = 0.1
local DMGNUMS_RADIUS = 0.2
local HIT_STOP = false
local dead = false

local tFuncs = {
        hitStop = {
                till = 0,
                set = false
        },
        nearby = {
                till = 0,
                set = false
        },
        spellDMG = {
                till = 0,
                set = false
        },
}

local colors = {
        white = util.color.hex('ffffff'),
        red = util.color.hex('ff5555'),
        green = util.color.hex('55ff55'),
        blue = util.color.hex('5555ff'),
        yellow = util.color.hex('ffff55'),
}

local function getSettings(sectionKey, key)
        if not sectionKey then return end
        o[sectionOLookup[sectionKey]].settings[key].value = storage.playerSection(sectionKey):get(key)
end

for _, props in pairs(o) do
        storage.playerSection(props.key):subscribe(async:callback(getSettings))
end

for _, props in pairs(o) do
        for key, _ in pairs(props.settings) do
                getSettings(props.key, key)
        end
end


local function makeDamageNumber(text, color)
        local angle = math.random() * 2 * math.pi
        local targetX = math.cos(angle) * DMGNUMS_RADIUS + 0.5
        local targetY = math.sin(angle) * DMGNUMS_RADIUS + 0.5


        local damageNumber = ui.create({
                layer = "HUD",
                template = I.MWUI.templates.textHeader,
                props = {
                        text = tostring(text),
                        textColor = color,
                        textSize = 5,
                        textShadow = true,
                        textShadowColor = util.color.hex('000000'),
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                        target = util.vector2(targetX, targetY),
                        timer = 0.1,
                },
        })

        table.insert(activeDamageNumbers, damageNumber)
end


local function makespellDMGNum(text, color)
        local damageNumber = ui.create({
                layer = "HUD",
                template = I.MWUI.templates.textHeader,
                props = {
                        text = tostring(text),
                        textColor = color,
                        textSize = 20,
                        textSizeStart = 20,
                        textShadow = true,
                        textShadowColor = util.color.hex('000000'),
                        relativePosition = util.vector2(0.3, 0.7),
                        anchor = util.vector2(0.5, 0.5),
                        targetY = 0.3,
                        alpha = 1,
                        timer = 0,
                },
        })

        table.insert(activeSpellDMGNums, damageNumber)
end

local function makeFeedbackText(text)
        local textEl = ui.create({
                layer = 'HUD',
                template = I.MWUI.templates.textHeader,
                props = {
                        text = text,
                        -- textColor = colors.white,
                        textSize = 20,
                        textShadow = true,
                        textShadowColor = util.color.hex('000000'),

                        -- align = ui.ALIGNMENT.Center,
                        -- arrange = ui.ALIGNMENT.Center,
                        alpha = 1,
                        timer = o.killMessage.settings.killMessageDuration.value,
                        size = util.vector2(100, 34),
                        relativePosition = util.vector2(0.5, 0.5),
                        targetY = 0,
                        anchor = util.vector2(0.5, 0),
                        -- horizontal = true,
                }
        })
        table.insert(activeFeedbackText, textEl)
end



local spellDMG = {}
local function getNearbyInfo()
        for i = 2, #nearby.actors do
                for _, spell in pairs(types.Actor.activeSpells(nearby.actors[i])) do
                        for _, effect in pairs(spell.effects) do
                                if c.badEffects[effect.id] and types.Player.objectIsInstance(spell.caster) then
                                        -- print('victim = ', nearby.actors[i])
                                        -- print('spell.caster = ', spell.caster)
                                        -- print('effect.id = ', effect.id)
                                        local text = effect.name ..
                                            ': ' .. tostring(util.round(effect.magnitudeThisFrame))
                                        table.insert(spellDMG, text)
                                        -- makeDamageNumber(text, colors.yellow)
                                end
                        end
                end
        end
end

--- min 0.2, max 0.5
-- local function getExtras(min, max)
--         return (math.random() > 0.5 and 1 or -1) * (min + math.random() * (max - min))
-- end

local function getExtras(value)
        return math.random() > 0.5 and value or -value
        -- return (math.random() > 0.5 and 1 or -1) * (min + math.random() * (max - min))
end



local target
local pos

local targetY
local posY
local function lerpDMGNUMS(dt)
        ---@type ui.Element
        for i, el in pairs(activeDamageNumbers) do
                target = el.layout.props.target
                pos = el.layout.props.relativePosition
                el.layout.props.relativePosition =
                    util.vector2(
                            lerp(pos.x, target.x, 0.2),
                            lerp(pos.y, target.y, 0.2))

                el.layout.props.timer = el.layout.props.timer + (core.getSimulationTimeScale() * dt)

                local t = el.layout.props.timer / o.damageNumbers.settings.damageNUMDuration.value

                el.layout.props.textSize = bounce_easing(-o.damageNumbers.settings.damageNUMSize.value, t) *
                    o.damageNumbers.settings.damageNUMSize.value

                el:update()

                if el.layout.props.textSize <= 5 then
                        table.remove(activeDamageNumbers, i)
                        el:destroy()
                end
        end

        for i, el in pairs(activeFeedbackText) do
                targetY = el.layout.props.targetY
                posY = el.layout.props.relativePosition.y
                -- posY = el.layout.props.position.y
                el.layout.props.relativePosition =
                    util.vector2(
                            0.5,
                            lerp(posY, targetY + (i - 1) / 32, 0.1)
                    )

                if el.layout.props.timer <= 0 then
                        el.layout.props.alpha = el.layout.props.alpha - dt

                        if el.layout.props.alpha <= 0 then
                                table.remove(activeFeedbackText, i)
                                el:destroy()
                        end
                else
                        el.layout.props.timer = el.layout.props.timer - dt
                end

                el:update()
        end

        for i, el in pairs(activeSpellDMGNums) do
                targetY = el.layout.props.targetY
                posY = el.layout.props.relativePosition.y
                el.layout.props.relativePosition =
                    util.vector2(0.3, lerp(posY, targetY, 0.15))
                -- el.layout.props.textSize = easeInExpo(el.layout.props.timer, el.layout.props.textSize, -0.005, 2)
                el.layout.props.textSize = easeInExpo(el.layout.props.timer, el.layout.props.textSizeStart, -0.005, 0.5)
                el.layout.props.timer = el.layout.props.timer + dt

                el:update()

                if el.layout.props.textSize < 5 then
                        table.remove(activeSpellDMGNums, i)
                        el:destroy()
                end
        end
end

return {
        engineHandlers = {
                onUpdate = function(dt)
                        -- setDebugText(core.getRealTime())
                        -- local dtext = 'dt:    ' .. tostring(dt) .. '\nRFD:  ' .. tostring(core.getRealFrameDuration())
                        -- setDebugText(dtext)
                        -- setDebugText('dt:', dt)
                        -- setDebugText('core.getRealFrameDuration():',core.getRealFrameDuration())

                        if core.isWorldPaused() then
                                return
                        end

                        if HIT_STOP then
                                throt(tFuncs.hitStop, o.hitStop.settings.hitStopDuration.value, function()
                                        HIT_STOP = false
                                        core.sendGlobalEvent('SetSimulationTimeScale', 1)
                                end)
                        end

                        if not HIT_STOP then
                                lerpDMGNUMS(dt)

                                -- if o.cameraShake.settings.enableCamShake.value and math.abs(extraYaw + extraRoll + extraPitch) > 0.01 then
                                if math.abs(extraYaw + extraRoll + extraPitch) > 0.01 then
                                        extraYaw = lerp(extraYaw, 0, EXTRAS_LERP)
                                        extraRoll = lerp(extraRoll, 0, EXTRAS_LERP)
                                        extraPitch = lerp(extraPitch, 0, EXTRAS_LERP)

                                        camera.setExtraYaw(extraYaw)
                                        camera.setExtraRoll(extraRoll)
                                        camera.setExtraPitch(extraPitch)
                                end

                                -- if not dead and core.getSimulationTimeScale() ~= 1 then
                                --         print('time scale set to ', 1)
                                --         core.sendGlobalEvent('SetSimulationTimeScale', 1)
                                -- end
                        end

                        if dead then
                                if SIM_LERP < 0.98 then
                                        SIM_LERP = SIM_LERP + dt / o.killSlowMotion.settings.slowMotionDuration.value
                                        core.sendGlobalEvent('SetSimulationTimeScale', SIM_LERP)
                                        -- setDebugText(SIM_LERP)
                                else
                                        SIM_LERP = 1
                                        core.sendGlobalEvent('SetSimulationTimeScale', 1)
                                        dead = false
                                end
                        end





                        if o.spellDMG.settings.enableSpellDamageNumbers.value then
                                throt(tFuncs.nearby, 1, getNearbyInfo)
                                throt(tFuncs.spellDMG, 0.11, function()
                                        if #spellDMG == 0 then return end

                                        if o.spellDMG.settings.enableSpellDMGSound.value then
                                                core.sound.playSoundFile3d("test.wav", self, {
                                                        volume = 0.7,
                                                        pitch = 1 + (math.random() - 0.5)
                                                })
                                        end

                                        makespellDMGNum(table.remove(spellDMG, 1), colors.yellow)
                                end)
                        end
                end
        },
        eventHandlers = {
                ---@param data AttackInfo
                [events.damageNumbers] = function(data)
                        -- local damageNumber

                        if data.successful then
                                if o.cameraShake.settings.enableCamShakeOnHit.value then
                                        -- local camShakeIntensity = o.cameraShake.settings.screenShakeIntensity.value
                                        extraYaw = getExtras(o.cameraShake.settings.camShakeYaw.value)
                                        extraRoll = getExtras(o.cameraShake.settings.camShakeRoll.value)
                                        extraPitch = getExtras(o.cameraShake.settings.camShakePitch.value)
                                end



                                if o.damageNumbers.settings.enableDamageNumbers.value then
                                        if data.damage.fatigue then
                                                local damage = util.round(data.damage.fatigue)
                                                makeDamageNumber(damage, colors.green)
                                        end
                                        if data.damage.health then
                                                local damage = util.round(data.damage.health)
                                                makeDamageNumber(damage, o.damageNumbers.settings.damageNUMColor.value)
                                        end
                                        if data.damage.magicka then
                                                local damage = util.round(data.damage.magicka)
                                                makeDamageNumber(damage, colors.blue)
                                        end
                                end


                                if types.Actor.stats.dynamic.health(data.victim).current <= 0 then
                                        if o.killMessage.settings.enableKillMessage.value then
                                                local name = data.victim.type.record(data.victim).name
                                                local str = o.killMessage.settings.killMessages.value
                                                allWords = {}
                                                -- for w in string.gmatch(str, "[^\n]+") do
                                                -- print('whole string = ', tostring(str))
                                                -- for w in string.gmatch(str, ".*\\n") do
                                                -- for w in string.gmatch(str, "\\n") do
                                                -- for w in string.gmatch(str, "[^,]+") do
                                                for w in string.gmatch(str, "[^/\n]+") do
                                                        -- print('w 1 = ', w)
                                                        w = string.gsub(w, '##', '#')
                                                        -- print('w no # = ', w)
                                                        w = string.gsub(w, 'ENEMY', name)
                                                        table.insert(allWords, w)
                                                end


                                                local random = allWords[math.random(1, #allWords)]

                                                -- print('random = ', random)
                                                makeFeedbackText(random)
                                        end

                                        if o.killSlowMotion.settings.enableKillSlow.value then
                                                dead = true
                                                SIM_LERP = o.killSlowMotion.settings.slowMotionScale.value
                                                core.sendGlobalEvent('SetSimulationTimeScale', SIM_LERP)
                                        end
                                else
                                        if o.hitStop.settings.enableHitStop.value and not HIT_STOP then
                                                HIT_STOP = true
                                                core.sendGlobalEvent('SetSimulationTimeScale', 0)
                                                -- types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Looking,
                                        end
                                end
                        else
                                makeDamageNumber('Miss', colors.white)
                        end
                end
        }
}
