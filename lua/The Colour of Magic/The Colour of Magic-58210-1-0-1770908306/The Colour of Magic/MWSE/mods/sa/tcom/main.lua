
--- @param e loadedEventData
local function loadedCallback(e)
    local object = tes3.createObject({
    objectType = tes3.objectType.static,
    id = "sa_trail",
    mesh = "sa\\trail.nif",
    getIfExists = true,
})
end
event.register(tes3.event.loaded, loadedCallback)

local activeVfx = {}

event.register("mobileActivated", function(e)
    if e.reference.id ~= "VFX_DestructBolt" then
        return
    end

    -- remove vanilla fireball (for testing)
    --e.reference.sceneNode:detachAllChildren()

    -- attach new vfx
    activeVfx[e.reference] = tes3.createVisualEffect({
        reference = e.reference,
        object = "sa_trail",
        lifespan = 4
    })
end)

event.register("projectileExpire", function(e)
    local vfx = activeVfx[e.mobile.reference]
    if vfx then
        vfx.target = nil
    end
end)