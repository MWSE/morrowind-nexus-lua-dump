local currentHealth = 0

local function resetHealth()
    if tes3.mobilePlayer.health.current > currentHealth then
        tes3.mobilePlayer.health.current = currentHealth + 1
        tes3.mobilePlayer:applyHealthDamage(1)
        print("Resting Doesn't Heal: Reset Health to: " .. currentHealth)
    end
    currentHealth = tes3.mobilePlayer.health.current
end

local function healthTimer()
    event.unregister("menuExit", healthTimer)
    timer.start{
        type = timer.real,
        duration = 1.0,
        callback = resetHealth
    }
end

local function onBedActivate(e)
    event.unregister("menuExit", healthTimer)
    local targetObject = e.target.object
    if targetObject.objectType == tes3.objectType.activator and
    targetObject.script and
    targetObject.script.id == "Bed_Standard" and 
    tes3.mobilePlayer then
        currentHealth = tes3.mobilePlayer.health.current
        print("Resting Doesn't Heal: Player Health is: " .. currentHealth)
        event.register("menuExit", healthTimer)
    end
end

local function init()
    print("Resting Doesn't Heal: Initialized")
    event.register(tes3.event.activate, onBedActivate)
end

event.register("initialized", init)