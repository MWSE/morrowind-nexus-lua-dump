local core = require('openmw.core')
local input = require('openmw.input')
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
local o = require('scripts.HitKillFeedback.settings').o
local sectionOLookup = require('scripts.HitKillFeedback.settings').sectionOLookup

local throt = require('scripts.HitKillFeedback.lib.myUtils').throt
local lerp = require('scripts.HitKillFeedback.lib.myUtils').lerp

local flux = require('scripts.HitKillFeedback.lib.flux')

local setDebugText = require('scripts.HitKillFeedback.lib.myUtils').setDebugText

local c = require('scripts.HitKillFeedback.constants').c
local UpdateColors = require('scripts.HitKillFeedback.constants').UpdateColors



core.sendGlobalEvent('SetSimulationTimeScale', 1)


local damageEffects = c.damageEffects
local effectColor = c.effectColor
local elemental = c.elemental



---@class AttackInfo2 : AttackInfo
---@field victim GameObject

local camRots = {
        extraYaw = 0,
        extraRoll = 0,
        extraPitch = 0
}

---@type ui.Element[]
local activeFeedbackText = {}

local allWords = {}

local SIM_LERP = 1
local DMGNUMS_RADIUS = 0.2
local SPELL_DMGNUMS_RADIUS = 0.2
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
        temp = {}
}

local function getSettings(sectionKey, key)
        if not sectionKey then return end
        o[sectionOLookup[sectionKey]].settings[key].value = storage.playerSection(sectionKey):get(key)


        UpdateColors(o.damageColors.settings)
end

for _, props in pairs(o) do
        storage.playerSection(props.key):subscribe(async:callback(getSettings))
end


for _, props in pairs(o) do
        for key, _ in pairs(props.settings) do
                getSettings(props.key, key)
        end
end

UpdateColors(o.damageColors.settings)



local function addTweens(obj, targetX, targetY)
        flux.to(obj.layout.userData, o.damageNumbers.settings.damageNUMDuration.value, {
                currX = targetX,
                currY = targetY,
        })
            :ease(flux.easeTable.cubicout)
            :onupdate(function()
                    obj.layout.props.relativePosition = util.vector2(
                            obj.layout.userData.currX,
                            obj.layout.userData.currY)
                    --     obj:update()
            end)
        --     :oncomplete(function()
        --             obj:destroy()
        --     end)

        flux.to(obj.layout.userData, o.damageNumbers.settings.damageNUMDuration.value / 2, {
                currSize = o.damageNumbers.settings.damageNUMSize.value * 2
                -- currSize = 38
        })
        --     :ease(flux.easeTable.backout)
            :ease(flux.easeTable.expoout)
            :onupdate(function()
                    obj.layout.props.textSize = obj.layout.userData.currSize
                    obj:update()
            end)

            :oncomplete(function()
                    flux.to(obj.layout.userData, o.damageNumbers.settings.damageNUMDuration.value / 2 + 0.05, {
                            -- flux.to(obj.layout.userData, 0.5, {
                            currSize = 1
                    })
                        :ease(flux.easeTable.linear)
                        :onupdate(function()
                                obj.layout.props.textSize = obj.layout.userData.currSize
                                obj:update()
                        end)

                        :oncomplete(function()
                                obj:destroy()
                        end)
            end)
end

local function getNormalDMGTarget()
        -- local angle = math.random() * math.pi / 2 + math.pi / 4
        local angle = math.random() * -math.pi / 2 - math.pi / 4
        return math.cos(angle) * DMGNUMS_RADIUS + 0.5, math.sin(angle) * DMGNUMS_RADIUS + 0.5
end

-- local targetX
-- local targetY

local function makeDamageNumber(text)
        local targetX, targetY = getNormalDMGTarget()

        local dmgNum = ui.create({
                layer = "HUD",
                template = I.MWUI.templates.textHeader,
                userData = {
                        currX = 0.5,
                        currY = 0.5,
                        -- currSize = o.damageNumbers.settings.damageNUMSize.value,
                        currSize = 1,
                },
                props = {
                        text = tostring(text),
                        -- textSize = o.damageNumbers.settings.damageNUMSize.value,
                        textSize = 1,
                        textShadow = true,
                        textShadowColor = util.color.hex('000000'),
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                },
        })

        addTweens(dmgNum, targetX, targetY)
end

local function addSpellDmgTweens(obj, targetX, targetY)
        --- SHOULD END FIRST
        flux.to(obj.layout.userData, o.spellDMG.settings.spellDamageNUMDuration.value, {
                -- flux.to(obj.layout.userData, 1, {
                currX = targetX,
                currY = targetY,
        })
            :ease(flux.easeTable.linear)
            :onupdate(function()
                    obj.layout.props.relativePosition = util.vector2(
                            obj.layout.userData.currX,
                            obj.layout.userData.currY)
                    obj:update()
            end)
            :oncomplete(function()
                    flux.to(obj.layout.userData, 0.3, { currSize = 1 })
                        :ease(flux.easeTable.linear)
                        :onupdate(function()
                                obj.layout.props.textSize = obj.layout.userData.currSize
                                obj:update()
                        end)
                        :oncomplete(function()
                                obj:destroy()
                        end)
            end)

        flux.to(obj.layout.userData, o.spellDMG.settings.spellDamageNUMDuration.value, {
                currSize = o.spellDMG.settings.spellDamageNUMSize.value,
                -- currSize = 30,
        })
            :ease(flux.easeTable.expoout)
            :onupdate(function()
                    obj.layout.props.textSize = obj.layout.userData.currSize
            end)
end

local function getSpellDMGTarget(angle)
        return math.cos(angle) * SPELL_DMGNUMS_RADIUS + 0.5, math.sin(angle) * SPELL_DMGNUMS_RADIUS + 0.5
end

local function makeSpellDMGNumber(text, angle)
        local targetX, targetY = getSpellDMGTarget(angle)

        local dmgNum = ui.create({
                layer = "HUD",
                template = I.MWUI.templates.textHeader,
                userData = {
                        currX = 0.5,
                        currY = 0.5,
                        currSize = 1,
                },
                props = {
                        text = tostring(text),
                        textSize = 1,
                        textShadow = true,
                        textShadowColor = util.color.hex('000000'),
                        relativePosition = util.vector2(0.5, 0.5),
                        anchor = util.vector2(0.5, 0.5),
                },
        })

        addSpellDmgTweens(dmgNum, targetX, targetY)
end

-- local SPELL_X = 0.2
-- local SPELL_Y = 0.7

local TEXT_Y = 0.5
local function makeFeedbackText(text)
        local el = ui.create({
                layer = 'HUD',
                template = I.MWUI.templates.textHeader,
                userData = {
                        currY = TEXT_Y,
                        currAlpha = 1,
                        index = 1,
                },
                props = {
                        text = text,
                        textSize = 20,
                        textShadow = true,
                        textShadowColor = util.color.hex('000000'),
                        alpha = 1,
                        timer = o.killMessage.settings.killMessageDuration.value,
                        size = util.vector2(100, 34),
                        relativePosition = util.vector2(0.5, TEXT_Y),
                        anchor = util.vector2(0.5, 0),
                }
        })

        table.insert(activeFeedbackText, el)

        flux.to(el.layout.userData, 0.5, { currAlpha = 0 })
            :delay(o.killMessage.settings.killMessageDuration.value)
            :oncomplete(function()
                    table.remove(activeFeedbackText, 1):destroy()
            end)
end

local spellDTexts = {}
local effectTextColor
local function getNearbyInfo()
        spellDTexts = { {} }
        for i = 2, #nearby.actors do
                if types.Actor.isDead(nearby.actors[i]) then goto continue end


                local spells = types.Actor.activeSpells(nearby.actors[i])
                for _, v in pairs(spells) do
                        if v.caster.type ~= types.Player then goto continue end
                        print(v.caster.type)


                        ---@type ActiveSpellEffect[]
                        local effects = v.effects


                        if #spellDTexts[#spellDTexts] ~= 0 then
                                table.insert(spellDTexts, {})
                        end

                        ---@param activeEffect ActiveSpellEffect
                        for _, activeEffect in pairs(effects) do
                                if not damageEffects[activeEffect.id] or activeEffect.magnitudeThisFrame <= 0 then
                                        goto continue
                                end

                                effectTextColor = effectColor[activeEffect.id]

                                local text = string.format('#%s%s', effectTextColor,
                                        math.ceil(activeEffect.magnitudeThisFrame))

                                table.insert(spellDTexts[#spellDTexts], text)


                                ::continue::
                        end
                        ::continue::
                end
                ::continue::
        end

        for i, _ in pairs(spellDTexts) do
                if #spellDTexts[i] == 0 then
                        table.remove(spellDTexts, i)
                end
        end
end


local function getExtras(value)
        return math.random() > 0.5 and value or -value
end

local shakeMaxCount = 2
local shakeCount

local function endShake(t)
        flux.to(camRots, t, {

                extraPitch = 0,
                extraYaw = 0,
        }):onupdate(function()
                camera.setExtraPitch(camRots.extraPitch)
                camera.setExtraYaw(camRots.extraYaw)
        end)
end

local function rot(intensity)
        if math.random() > 0.5 then
                return math.random() / 50 + intensity
        else
                return -math.random() / 50 - intensity
        end
end

local function camShake(intensity, duration)
        flux.to(camRots, duration, {
                extraPitch = rot(intensity),
                extraYaw = rot(intensity),
        }):onupdate(function()
                camera.setExtraPitch(camRots.extraPitch)
                camera.setExtraYaw(camRots.extraYaw)
        end):oncomplete(function()
                if shakeCount > 0 then
                        shakeCount = shakeCount - 1
                        camShake(intensity, duration)
                else
                        endShake(duration)
                end
        end)
end

local FBT_Y
local textEL
local effectFound = false


-- local names = {}
-- for i, v in pairs(c.effectColor) do
--         table.insert(names, i)
-- end

-- local firstColors = {
--         'absorbhealth',
--         'absorbfatigue',
-- }

return {
        engineHandlers = {
                onUpdate = function(dt)
                        -- if input.isKeyPressed(input.KEY.Z) then
                        --         local firstColor = c.effectColor[firstColors[math.random(1, 2)]]
                        --         makeDamageNumber('#' .. firstColor .. tostring(math.random(1, 9)))
                        --         throt(tFuncs.temp, 0.13, function()
                        --                 for i = 1, 5 do
                        --                         local angle = ((i - 1) / 4) * math.pi / 2 + math.pi / 4
                        --                         local color = c.effectColor[names[math.random(1, #names)]]
                        --                         -- print(color)
                        --                         makeSpellDMGNumber('#' .. color .. tostring(math.random(1, 9)), angle)
                        --                 end
                        --         end)
                        -- end
                        -- setDebugText(#nearby.actors)

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
                                flux.update(dt)

                                for i = 1, #activeFeedbackText do
                                        textEL = activeFeedbackText[i]
                                        FBT_Y = (i - 1) / 30
                                        textEL.layout.props.relativePosition = util.vector2(0.5,
                                                lerp(textEL.layout.props.relativePosition.y, FBT_Y, 0.001))
                                        textEL.layout.props.alpha = textEL.layout.userData.currAlpha
                                        textEL:update()
                                end
                        end

                        if dead then
                                if SIM_LERP < 0.98 then
                                        SIM_LERP = SIM_LERP + dt / o.killSlowMotion.settings.slowMotionDuration.value
                                        core.sendGlobalEvent('SetSimulationTimeScale', SIM_LERP)
                                else
                                        SIM_LERP = 1
                                        core.sendGlobalEvent('SetSimulationTimeScale', 1)
                                        dead = false
                                end
                        end

                        if o.spellDMG.settings.enableSpellDamageNumbers.value then
                                throt(tFuncs.nearby, 1, getNearbyInfo)
                                throt(tFuncs.spellDMG, 0.13, function()
                                        if #spellDTexts == 0 then return end



                                        for i, numList in pairs(spellDTexts) do
                                                if #numList ~= 0 then
                                                        effectFound = true
                                                        local angle = (math.pi / 2 + math.pi / 4) * i / #spellDTexts
                                                        local text = table.remove(numList)
                                                        makeSpellDMGNumber(text, angle)
                                                end
                                        end



                                        if o.spellDMG.settings.enableSpellDMGSound.value then
                                                if effectFound then
                                                        effectFound = false
                                                        core.sound.playSoundFile3d("SpellDMG.wav", self, {
                                                                volume = 1,
                                                                pitch = 1 + (math.random() / 2)
                                                        })
                                                end
                                        end
                                end)
                        end
                end
        },
        eventHandlers = {
                ---@param data AttackInfo2
                [events.damageNumbers] = function(data)
                        if data.successful then
                                if o.damageNumbers.settings.enableDamageNumbers.value then
                                        if data.damage.health then
                                                local text = string.format('#%s%s',
                                                        c.effectColor.damagehealth,
                                                        math.ceil(data.damage.health))
                                                makeDamageNumber(text)
                                        end
                                        if data.damage.fatigue then
                                                local text = string.format('#%s%s',
                                                        c.effectColor.damagefatigue,
                                                        math.ceil(data.damage.fatigue))
                                                makeDamageNumber(text)
                                        end
                                        if data.damage.magicka then
                                                local text = string.format('#%s%s',
                                                        c.effectColor.damagemagicka,
                                                        math.ceil(data.damage.magicka))
                                                makeDamageNumber(text)
                                        end
                                end

                                if types.Actor.stats.dynamic.health(data.victim).current <= 0 then
                                        -- ################
                                        -- On Kill
                                        -- ################

                                        if o.cameraShake.settings.enableCamShakeOnKill.value then
                                                shakeCount = shakeMaxCount
                                                local t = o.cameraShake.settings.camShakeDuration.value /
                                                    (shakeMaxCount + 1)
                                                camShake(o.cameraShake.settings.camShakeIntensity.value, t)
                                        end

                                        if o.killMessage.settings.enableKillMessage.value then
                                                local name = data.victim.type.record(data.victim).name
                                                local str = o.killMessage.settings.killMessages.value
                                                allWords = {}

                                                for w in string.gmatch(str, "[^/\n]+") do
                                                        w = string.gsub(w, '##', '#')
                                                        w = string.gsub(w, 'ENEMY', name)
                                                        table.insert(allWords, w)
                                                end

                                                local random = allWords[math.random(1, #allWords)]

                                                makeFeedbackText(random)
                                        end

                                        if o.killSlowMotion.settings.enableKillSlow.value then
                                                dead = true
                                                SIM_LERP = o.killSlowMotion.settings.slowMotionScale.value
                                                core.sendGlobalEvent('SetSimulationTimeScale', SIM_LERP)
                                        end
                                else
                                        -- ################
                                        -- On Hit
                                        -- ################

                                        if o.cameraShake.settings.enableCamShakeOnHit.value then
                                                shakeCount = shakeMaxCount
                                                local t = o.cameraShake.settings.camShakeDuration.value /
                                                    (shakeMaxCount + 1)
                                                camShake(o.cameraShake.settings.camShakeIntensity.value, t)
                                        end

                                        if o.hitStop.settings.enableHitStop.value and not HIT_STOP then
                                                HIT_STOP = true
                                                core.sendGlobalEvent('SetSimulationTimeScale', 0)
                                        end
                                end
                        else
                                local text = string.format('#%sMiss', c.effectColor.miss)
                                makeDamageNumber(text)
                        end
                end
        }
}
