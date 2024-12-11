local maxHeightPerSec = 20
local maxLevDistance = 470
local timeToMaxSpeed = 3
local maxLiftHeight = 2600

local padID = "_cor_lr_levitation_pad"

local timeEnteredPad
local levitating

local function addLevitation()
    levitating = true
    tes3.addSpell{
        reference = tes3.player,
        spell = "_COR_lev_spell"
    }
    tes3.playSound{
        sound = "forcefield",
        loop = true,
        pitch = 1.2
    }
end

local function removeLevitation()
    levitating = false
    tes3.removeSpell{
        reference = tes3.player,
        spell = "_COR_lev_spell"
    }
    tes3.removeSound{
        sound = "forcefield"
    }
end

---@type mwseSafeObjectHandle
local safeLevPad

---@return tes3reference|nil
local function getLevPad()
    local cell = tes3.player.cell
    if not cell then return end
    if cell.id:lower() ~= "tel raloran" then return end
    if safeLevPad and safeLevPad:valid() then
        return safeLevPad:getObject()
    end
    for reference in cell:iterateReferences(tes3.objectType.static) do
        if reference.id:lower() == padID then
            safeLevPad = tes3.makeSafeObjectHandle(reference)
            return reference
        end
    end
end


---@return boolean
local function isNearLevPad(levPad)
    local levPos = tes3vector2.new(levPad.position.x, levPad.position.y)
    local playerPos = tes3vector2.new(tes3.player.position.x, tes3.player.position.y)

    local distance = levPos:distance(playerPos)
    return distance < maxLevDistance
end

local function levitate(e)
    if tes3.menuMode() then return end
    if not tes3.player then return end

    local levPad = getLevPad()
    if not levPad then
        if levitating or levitating == nil then
            removeLevitation()
        end
        return
    end

    local now = tes3.getSimulationTimestamp() * 100
    --local now = tes3.getSimulationTimestamp()

    timeEnteredPad = timeEnteredPad or now


    if isNearLevPad(levPad) then
        local timeSinceEntered = math.clamp( (now - timeEnteredPad), 0, timeToMaxSpeed)
        local timeEnteredEffect = ( math.clamp(timeSinceEntered, 0, timeToMaxSpeed) / timeToMaxSpeed )
        local verticalDistance = tes3.player.position.z - levPad.position.z
        local distanceUpEffect = ( math.clamp( (maxLiftHeight - verticalDistance), 0, ( maxLiftHeight - 1000 )) / maxLiftHeight )
        local distanceDownEffect = ( ( math.clamp( verticalDistance, 0, 1000) / 1000 ) )

        local lookZ = tes3.getCameraVector().z
        local lookingUp = lookZ > 0.25
        local lookingDown = lookZ < -0.25
        if lookingUp then
            local heightPerSec = (
                maxHeightPerSec *
                timeEnteredEffect *
                distanceUpEffect
            )
            tes3.player.position.z = tes3.player.position.z + heightPerSec
        elseif lookingDown then
            local heightPerSec = (
                maxHeightPerSec *
                timeEnteredEffect *
                distanceDownEffect
            )
            tes3.player.position.z = tes3.player.position.z - heightPerSec
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

event.register("simulate", levitate)
