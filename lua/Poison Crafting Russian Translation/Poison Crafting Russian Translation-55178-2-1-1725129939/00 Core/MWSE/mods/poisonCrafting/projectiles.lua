local this = {}

--- @class PoisonParams
--- @field weapon string
--- @field poison string

--- The object IDs of generated poison projectiles and their parameters.
--- @type table<string, PoisonParams>
this.storage = {}

--- Create a poison projectile for the given weapon and poison.
---
--- Poison projectiles are duplicates of existing projectiles with
--- unique IDs generated at runtime. The unique IDs are stored in the
--- storage table alongside the parameters used to create them.
---
--- The objects returned from this function are managed by the mod
--- and will be cleaned from the save file when appropriate. Other
--- mods should not rely on their permanence!
---
--- @param weapon tes3weapon
--- @param poison tes3alchemy
--- @return tes3weapon
function this.createPoisonProjectile(weapon, poison)
    --
    assert(weapon.isProjectile)
    assert(poison.objectType == tes3.objectType.alchemy)

    -- Ensure mod changes don't affect case.
    local weaponId = weapon.id:lower()
    local poisonId = poison.id:lower()

    -- Re-use an existing item if it exists.
    for id, source in pairs(this.storage) do
        if source.weapon == weaponId
            and source.poison == poisonId
        then
            return assert(tes3.getObject(id))
        end
    end

    -- Otherwise we create a temporary copy.
    local object = tes3.createObject{
        objectType = weapon.objectType,
        name = weapon.name,
        mesh = weapon.mesh,
        icon = weapon.icon,
        enchantment = weapon.enchantment,
        weight = weapon.weight,
        value = weapon.value,
        type = weapon.type,
        maxCondition = weapon.maxCondition,
        speed = weapon.speed,
        reach = weapon.reach,
        enchantCapacity = weapon.enchantCapacity,
        chopMin = weapon.chopMin,
        chopMax = weapon.chopMax,
        slashMin = weapon.slashMin,
        slashMax = weapon.slashMax,
        thrustMin = weapon.thrustMin,
        thrustMax = weapon.thrustMax,
        materialFlags = weapon.flags,
    }
    -- mwse.log('Created object "%s" for weapon "%s" with poison "%s"', object.id, weapon.id, poison.id)

    -- Make persistent so it can be found with getReference.
    object.persistent = true

    -- Add to poisons cache for reuse and/or later deletion.
    this.storage[object.id] = {weapon = weaponId, poison = poisonId}

    return object
end

--- Clean up poison projectiles that are no longer active.
local function onSave()
    -- do cleaning only if 72 hours have passed
    local cleanupDay = tes3.player.data.g7_poison_cleanupDay or 0
    local daysPassed = tes3.worldController.daysPassed.value
    if (daysPassed - cleanupDay) < 3 then
        return
    end
    tes3.player.data.g7_poison_cleanupDay = daysPassed

    -- the objects to be deleted from save file
    local deletions = {}

    -- select objects without active references
    for id in pairs(this.storage) do
        local obj = tes3.getObject(id)
        local ref = tes3.getReference(obj.id)
        if ref == nil then
            deletions[obj] = true
        else
            -- mwse.log('A reference of "%s" exists in cell "%s", it cannot be deleted', obj, ref.cell)
        end
    end
    if not next(deletions) then return end

    -- filter out currently active projectiles
    for _, projectile in pairs(tes3.worldController.mobController.projectileController.projectiles) do
        local obj = projectile.reference.object
        if obj then
            -- mwse.log('"%s" is an active projectile, it cannot be deleted', obj)
            deletions[obj] = nil
        end
    end
    if not next(deletions) then return end

    -- filter out objects stored in inventories
    for owner in tes3.iterateObjects{tes3.objectType.container, tes3.objectType.creature, tes3.objectType.npc} do
        if owner.isInstance
            and #owner.inventory ~= 0
        then
            for obj in pairs(deletions) do
                if owner.inventory:contains(obj) then
                    -- mwse.log('"%s" owns a copy of "%s", it cannot be deleted', owner, obj)
                    deletions[obj] = nil
                end
            end
        end
    end
    if not next(deletions) then return end

    -- the remaining objects are safe to delete
    for ob in pairs(deletions) do
        -- mwse.log("Deleting object %s ", ob.id)
        this.storage[ob.id] = nil
        assert(tes3.deleteObject(ob))
    end
end
event.register("save", onSave)

--- Update bindings and icons when a new save is loaded.
local function onLoaded(e)
    local t = tes3.player.data
    t.g7_poisons = t.g7_poisons or {}
    this.storage = t.g7_poisons
end
event.register("loaded", onLoaded)


return this
