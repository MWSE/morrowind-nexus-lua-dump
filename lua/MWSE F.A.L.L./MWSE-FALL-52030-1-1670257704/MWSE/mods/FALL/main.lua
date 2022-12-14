local function onJump(e)
    if e.mobile ~= tes3.mobilePlayer then
        return
    end
    local multiplier = e.mobile.fatigue.normalized
    if multiplier > 2 then
        multiplier = 2
    end
    if multiplier < 0.35 then
        multiplier = 0.35
    end
    e.velocity.z = e.velocity.z * multiplier
    e.velocity.x = e.velocity.x * multiplier
    e.velocity.y = e.velocity.y * multiplier
end
event.register(tes3.event.jump, onJump)