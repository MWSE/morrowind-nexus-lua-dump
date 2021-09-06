
local common = require("mer.theGuarWhisperer.common")
local animalController = require("mer.theGuarWhisperer.animalController")

local function isBall(reference)
    return string.lower(reference.object.id) == common.ballId
end

local function guarFollow(ball)
    for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        local animal = animalController.getAnimal(actor.reference)
        if animal then
            animal:moveToAction(ball, "fetch")
            return
        end
    end
end

local function placeBall(ref, position)
    local ball = tes3.createReference{
        object = ref.object,
        position = position,
        orientation =  {0,0,0},
        cell = ref.cell or tes3.player.cell,
    }

    local ray = tes3.rayTest{
        position = position,
        direction = tes3vector3.new(0, 0, -1)
    }
    if ray and ray.intersection then
        ball.position = {
            ray.intersection.x,
            ray.intersection.y,
            ray.intersection.z + 7
        }
    end

    guarFollow(ball)
end


local function onHitActor(e)
    if isBall(e.mobile.reference) then
        -- placeBall(e.mobile.reference, e.target.position)
        return false
    end
end

local function onHitObject(e)
    if isBall(e.mobile.reference) then
        -- local dt = tes3.worldController.deltaTime
        -- local embedPos = e.collisionPoint + e.velocity * (0.65 * dt)
        -- placeBall(e.mobile.reference, embedPos)
        return false
    end
end

local function onHitTerrain(e)
    if isBall(e.mobile.reference) then
        -- local dt = tes3.worldController.deltaTime
        -- local embedPos = e.position + e.velocity * (0.4 * dt)
        -- embedPos = { embedPos.x, embedPos.y, embedPos.z + 5}
        -- placeBall(e.mobile.reference, embedPos)
        return false
    end
end


local function onProjectileExpire(e)
    if isBall(e.mobile.reference) then
        local position = {
            e.mobile.reference.position.x,
            e.mobile.reference.position.y,
            e.mobile.reference.position.z + 15
        }
        placeBall(e.mobile.reference, position)
    end
end

event.register("projectileHitActor", onHitActor, {priority = 100 })
event.register("projectileHitObject", onHitObject, {priority = 100 })
event.register("projectileHitTerrain", onHitTerrain, {priority = 100 })

event.register("projectileExpire", onProjectileExpire)