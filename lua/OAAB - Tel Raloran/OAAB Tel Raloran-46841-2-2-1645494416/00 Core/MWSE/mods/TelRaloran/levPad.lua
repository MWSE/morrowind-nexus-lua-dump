local maxHeightPerSec = 20
local maxLevDistance = 500
local maxLiftDistance = 100
local timeToMaxSpeed = 3
local maxLiftHeight = 2600

local padID = "_COR_LR_levitation_pad"

local lastRan
local timeEnteredPad
local levitating


local function addLevitation()
    levitating = true
    mwscript.addSpell{
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
    mwscript.removeSpell{
        reference = tes3.player,
        spell = "_COR_lev_spell"
    }
    mwscript.stopSound{
        sound = "forcefield"
    }
end

local function levitate(e)
    if tes3.menuMode() then return end 

    local levPad = tes3.getReference(padID)
    if not levPad then
        if levitating or levitating == nil then
            removeLevitation()
        end
        return
    end
        

    local now = tes3.getSimulationTimestamp() * 100
    --local now = tes3.getSimulationTimestamp()

    timeEnteredPad = timeEnteredPad or now

    if levPad then
        local levPos = tes3vector3.new(levPad.position.x, levPad.position.y, 1)
        local playerPos = tes3vector3.new(tes3.player.position.x, tes3.player.position.y, 1)

        local verticalDistance = tes3.player.position.z - levPad.position.z

        local distance = levPos:distance(playerPos)


        if distance < maxLiftDistance then
            local timeSinceEntered = math.clamp( (now - timeEnteredPad), 0, timeToMaxSpeed)
            local timeEnteredEffect = ( math.clamp(timeSinceEntered, 0, timeToMaxSpeed) / timeToMaxSpeed )
            local distanceUpEffect = ( math.clamp( (maxLiftHeight - verticalDistance), 0, ( maxLiftHeight - 1000 )) / maxLiftHeight )
            local distanceDownEffect = ( ( math.clamp( verticalDistance, 0, 1000) / 1000 ) )


            if tes3.getCameraVector().z > 0.25 then
                local heightPerSec = (
                    maxHeightPerSec * 
                    timeEnteredEffect * 
                    distanceUpEffect
                )
                tes3.player.position.z = tes3.player.position.z + heightPerSec

            elseif tes3.getCameraVector().z < -0.25 then
                local heightPerSec = (
                    maxHeightPerSec * 
                    timeEnteredEffect * 
                    distanceDownEffect
                )
                tes3.player.position.z = tes3.player.position.z - heightPerSec

            else
                timeEnteredPad = now
            end
        else
            timeEnteredPad = now
        end

        if distance < maxLevDistance then
            if not levitating then
                addLevitation()
            end
            return
        end
    end

    if levitating then
        removeLevitation()
    end
end

local function initialize(e)
    event.register("simulate", levitate)
end
event.register("initialized", initialize)