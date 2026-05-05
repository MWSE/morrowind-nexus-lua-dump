local world = require('openmw.world')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')

local maxHeightPerSec = 1000
local maxLevDistance = 470
local timeToMaxSpeed = 3
local maxLiftHeight = 2600

local padID = "_cor_lr_levitation_pad"

local timeEnteredPad
local levitating

local function addLevitation()
    levitating = true
    local player = world.players[1]
    types.Actor.spells(player):add('_COR_lev_spell')
    core.sound.playSound3d('forcefield', player, { loop = true, pitch = 1.2})
end

local function removeLevitation()
    levitating = false
    local player = world.players[1]
    types.Actor.spells(player):remove('_COR_lev_spell')
    core.sound.stopSound3d('forcefield', player)
end

local cachedLevPad

local function getLevPad()
    local cell = world.players[1].cell
    if not cell then return end
    if cell.id:lower() ~= "tel raloran" then return end
    if cachedLevPad and cachedLevPad:isValid() then
        return cachedLevPad
    end
    for _, static in ipairs(cell:getAll(types.Static)) do
        if static.recordId:lower() == padID then
            cachedLevPad = static
            return cachedLevPad
        end
    end
end

local function isNearLevPad(levPad)
    local player = world.players[1]
    local levPos = util.vector2(levPad.position.x, levPad.position.y)
    local playerPos = util.vector2(player.position.x, player.position.y)
    local distance = (levPos - playerPos):length()
    return distance < maxLevDistance
end

local function levitate(dt)
    if dt == 0 then return end

    local levPad = getLevPad()
    if not levPad then
        if levitating or levitating == nil then
            removeLevitation()
        end
        return
    end

    local player = world.players[1]
    if not player then return end

    local now = core.getSimulationTime()
    timeEnteredPad = timeEnteredPad or now

    if isNearLevPad(levPad) then
        local timeSinceEntered = util.clamp( (now - timeEnteredPad), 0, timeToMaxSpeed)
        local timeEnteredEffect = ( util.clamp(timeSinceEntered, 0, timeToMaxSpeed) / timeToMaxSpeed )
        local verticalDistance = player.position.z - levPad.position.z
        local distanceUpEffect = ( util.clamp( (maxLiftHeight - verticalDistance), 0, ( maxLiftHeight - 1000 )) / maxLiftHeight )
        local distanceDownEffect = ( ( util.clamp( verticalDistance, 0, 1000) / 1000 ) )

        local lookZ = -player.rotation:getPitch() / (math.pi / 2)
        local lookingUp = lookZ > 0.25
        local lookingDown = lookZ < -0.25
        if lookingUp then
            local heightPerSec = (
                maxHeightPerSec *
                timeEnteredEffect *
                distanceUpEffect
            )
            player:sendEvent("TelRaloran_LevPadCollisionCheck", { speed = heightPerSec, dt = dt })
        elseif lookingDown then
            local heightPerSec = (
                maxHeightPerSec *
                timeEnteredEffect *
                distanceDownEffect
            )
            player:sendEvent("TelRaloran_LevPadCollisionCheck", { speed = -heightPerSec, dt = dt })
        else
            timeEnteredPad = now
        end

        if not levitating then
            addLevitation()
        end
        return
    else
        timeEnteredPad = now
        if levitating then
            removeLevitation()
        end
    end
end

local function applyMovement(data)
    local vector = data.vector / data.dt
    local script = world.mwscript.getGlobalScript('_cor_levpad_movepc', world.players[1])
    script.variables.xmove = vector.x
    script.variables.ymove = vector.y
    script.variables.zmove = vector.z
end

return {
    engineHandlers = {
        onUpdate = levitate,
        onSave = function()
            return {
                timeEnteredPad = timeEnteredPad,
                levitating = levitating
            }
        end,
        onLoad = function(data)
            if data then
                timeEnteredPad = data.timeEnteredPad or timeEnteredPad
                levitating = data.levitating or levitating
            end
        end
    },
    eventHandlers = {
        TelRaloran_LevPadCollisionCheckResult = applyMovement
    }
}