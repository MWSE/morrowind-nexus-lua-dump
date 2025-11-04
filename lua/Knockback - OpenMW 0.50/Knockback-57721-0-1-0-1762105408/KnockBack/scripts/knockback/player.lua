local myUtil = require('scripts.knockback.util')
local async = require('openmw.async')
local util = require('openmw.util')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local self = require('openmw.self')
local input = require('openmw.input')
local core = require('openmw.core')
local o = require('scripts.knockback.settingsObject').o

local storage = require('openmw.storage')
local MOD_NAME = 'Knockback'
local prefix = 'SettingsPlayer'
local sectionKey = prefix .. MOD_NAME

local mySection = storage.playerSection(sectionKey)

local function getSettings(keyForSection, key)
        o[key].value = mySection:get(key)
        core.sendGlobalEvent('SET_SETTINGS_VALUE', { key = key, value = mySection:get(key) })
end

mySection:subscribe(async:callback(getSettings))

for i, _ in pairs(o) do
        o[i].value = mySection:get(i)
        core.sendGlobalEvent('SET_SETTINGS_VALUE', { key = i, value = mySection:get(i) })
end

local function spawnVFX(pos)
        local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.FrostDamage]
        local model = types.Static.records[effect.areaStatic].model
        core.sendGlobalEvent('SpawnVfx', { model = model, position = pos })
end

local tx
local ty
local tz

local colType = util.bitOr(
        nearby.COLLISION_TYPE.World,
        nearby.COLLISION_TYPE.HeightMap,
        nearby.COLLISION_TYPE.Door
)

local currObject

local radius = 40

local function castTestRay()
        local angle = self.rotation:getYaw()
        local pitch = self.rotation:getPitch()

        local magnitude = 1000

        tx = math.cos(angle) * math.cos(pitch)
        ty = math.sin(angle) * math.cos(pitch)
        tz = math.sin(-pitch)


        local target = camera.getPosition() + util.vector3(ty, tx, tz) * magnitude

        for i = 2, 20 do
                -- local pos = camera.getPosition() + util.vector3(ty, tx, tz) * i * 50
                local pos = camera.getPosition() + util.vector3(ty, tx, tz) * i * 50
                spawnVFX(pos)
        end


        ---@type RayCastingResult
        local res = nearby.castRay(camera.getPosition(), target, {
                collisionType = colType,
                radius = radius,
        })


        if res.hit then
                currObject = res.hitObject

                local normalTarget = res.hitPos + res.hitNormal * 500

                for i = 1, 20 do
                        local pos = res.hitPos + res.hitNormal * i * 25
                        spawnVFX(pos)
                end

                ---@type RayCastingResult
                local normalRes = nearby.castRay(res.hitPos, normalTarget, {
                        collisionType = colType,
                        radius = radius,
                })
        else
                currObject = nil
        end
end


local debugTexts = {}
local function getPositions()
        debugTexts = {}
        for i = 2, #nearby.actors do
                local actor = nearby.actors[i]
                local x = actor.position.x
                local y = actor.position.y
                local z = actor.position.z

                -- local text = string.format('%s | %.1f %.1f %.1f', actor.recordId, x, y, z)
                local dist = (self.position - actor.position):length()
                -- local z = actor.position.z
                local text = string.format('%s | %.1f %.2f', actor.recordId, dist, z)
                table.insert(debugTexts, text)
        end

        local allTexts = table.concat(debugTexts, '\n')
        myUtil.setDebugText(allTexts)
end
return {
        engineHandlers = {

                -- onUpdate = function(dt)
                -- if input.isKeyPressed(input.KEY.X) then
                -- end
                -- end,
        }
}
