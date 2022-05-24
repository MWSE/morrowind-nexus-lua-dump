local mod = { name = "Elemental Projectile Hits", ver = "1.2"}
local poisonMesh
local frostMesh
local shockMesh
local fireMesh

local function onProjectileHit(e)

    if e.firingWeapon == nil then
        return
    end

    local effects = e.mobile
        and e.mobile.reference
        and e.mobile.reference.object
        and e.mobile.reference.object.enchantment
        and e.mobile.reference.object.enchantment.effects

    if effects == nil then
        return
    end

    local fire = false
    local poison = false
    local frost = false
    local shock = false
    for _,effect in pairs(effects) do
        if effect.id == tes3.effect.fireDamage then
            fire = true
        elseif effect.id == tes3.effect.poison then
            poison = true
        elseif effect.id == tes3.effect.shockDamage then
            shock = true
        elseif effect.id == tes3.effect.frostDamage then
            frost = true
        end
    end

    if fire and (e.collisionPoint or e.target) then
        local boom = tes3.createReference({object = fireMesh, scale = .5, position = e.collisionPoint, cell = tes3.getPlayerCell()})
        tes3.playSound({sound = "destruction hit", reference = e.mobile, loop = false})
        local objectHandle = tes3.makeSafeObjectHandle(boom)
        timer.start({
            duration = 10,
            callback = function()
                if objectHandle:valid() then
                    objectHandle:getObject():delete()
                end
            end})
    end

    if poison and (e.collisionPoint or e.target) then
        local boom = tes3.createReference({object = poisonMesh, scale = .5, position = e.collisionPoint, cell = tes3.getPlayerCell()})
        tes3.playSound({sound = "destruction hit", reference = e.mobile, loop = false})
        local objectHandle = tes3.makeSafeObjectHandle(boom)
        timer.start({
            duration = 10,
            callback = function()
                if objectHandle:valid() then
                    objectHandle:getObject():delete()
                end
            end})
    end

    if frost and (e.collisionPoint or e.target) then
        local boom = tes3.createReference({object = frostMesh, scale = .5, position = e.collisionPoint, cell = tes3.getPlayerCell()})
        tes3.playSound({sound = "destruction hit", reference = e.mobile, loop = false})
        local objectHandle = tes3.makeSafeObjectHandle(boom)
        timer.start({
            duration = 10,
            callback = function()
                if objectHandle:valid() then
                    objectHandle:getObject():delete()
                end
            end})
    end

    if shock and (e.collisionPoint or e.target) then
        local boom = tes3.createReference({object = shockMesh, scale = .5, position = e.collisionPoint, cell = tes3.getActiveCells()})
        tes3.playSound({sound = "destruction hit", reference = e.mobile, loop = false})
        local objectHandle = tes3.makeSafeObjectHandle(boom)
        timer.start({
            duration = 10,
            callback = function()
                if objectHandle:valid() then
                    objectHandle:getObject():delete()
                end
            end})
    end
end

event.register("initialized", function()
event.register("projectileHitObject", onProjectileHit)
event.register("projectileHitTerrain", onProjectileHit)
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")

poisonMesh = tes3.createObject({
    objectType = tes3.objectType.static,
    id = "spa_light_poison",
    mesh = "Spammer\\Light_Poison.nif"
})

frostMesh = tes3.createObject({
    objectType = tes3.objectType.static,
    id = "spa_light_frost",
    mesh = "Spammer\\Light_Frost.nif"
})

shockMesh = tes3.createObject({
    objectType = tes3.objectType.static,
    id = "spa_light_shock",
    mesh = "Spammer\\Light_Shock.nif"
})

fireMesh = tes3.createObject({
    objectType = tes3.objectType.static,
    id = "spa_light_fire",
    mesh = "Spammer\\Light_Fire.nif"
})

end)


