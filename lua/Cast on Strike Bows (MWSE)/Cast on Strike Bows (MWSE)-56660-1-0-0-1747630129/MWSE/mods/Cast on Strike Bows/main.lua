local configName = "Cast on Strike Bows"

local config = mwse.loadConfig(configName, {
    enableForNpcs = true,
})

local impactObject

local function projectileHit(e)
    if config.enableForNpcs == false and e.firingReference ~= tes3.player then
        -- NPC fired projectile, but config says to ignore them
        return
    end

    if e.firingWeapon.type ~= tes3.weaponType.marksmanBow and e.firingWeapon.type ~=  tes3.weaponType.marksmanCrossbow then
        -- Prolly a throwing weapon
        return
    end

    if e.firingReference == e.target then
        -- Stop hitting yourself
        return
    end

    if e.firingWeapon.enchantment == nil then
        -- Weapon is not enchanted
        return
    end
    
    if e.firingReference.mobile.readiedWeapon and e.firingReference.mobile.readiedWeapon.object.id ~= e.firingWeapon.id then
        -- Actor put away their weapon or switched to a different one
        return
    end

    if e.firingWeapon.enchantment.castType ~= tes3.enchantmentType.onStrike then
        -- We only support "cast on strike" enchantments
        return
    end

    local impactRef

    if e.target == nil then
        -- Actor shot terrain; if any effect is AOE, spawn in temp target
        local hasRadius = false

        for i = 1, #e.firingWeapon.enchantment.effects do
            if e.firingWeapon.enchantment.effects[i].radius > 0 then
                hasRadius = true
            end
        end

        if impactObject == nil then
            impactObject = tes3.createObject({
                objectType = tes3.objectType.miscItem,
                id = "COSB_impactObject",
                mesh = [[sve\sve_invisible_cube.nif]],
            })
        end

        if hasRadius then
            impactRef = tes3.createReference({
                object = impactObject,
                position = e.collisionPoint,
                orientation = 0,
            })
        end
    end

    tes3.applyMagicSource({
        reference = e.firingReference,
        -- if both are nil, nothing happens
        target = impactRef or e.target,
        source = e.firingWeapon.enchantment,
        fromStack = e.firingReference.mobile.readiedWeapon,
    })

    if impactRef then
        impactRef:disable()
        impactRef:delete()
    end
end

local function registerConfig()

    local template = mwse.mcm.createTemplate(configName)

    template:saveOnClose(configName, config)
    template:register()

    local page = template:createSideBarPage({
        label = configName,
        description = "Any arrow shot with any bow will apply the bow's \"Cast on Strike\" enchantment on whatever it hits.",
    })

    local settings = page:createCategory("Cast on Strike Bows Settings\n\n\n")

    settings:createOnOffButton({
        label = "Enable for NPCs",
        variable = mwse.mcm.createTableVariable {id = "enableForNpcs", table = config}
    })
end

event.register("modConfigReady", registerConfig)

local function onInitialized()
    event.register("projectileHitActor", projectileHit)
    event.register("projectileHitObject", projectileHit)
    event.register("projectileHitTerrain", projectileHit)
    mwse.log("Cast on Strike Bows: Initialized")
end

event.register("initialized", onInitialized)