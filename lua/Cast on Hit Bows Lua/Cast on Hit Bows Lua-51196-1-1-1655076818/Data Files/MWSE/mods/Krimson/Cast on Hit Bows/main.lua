local config = mwse.loadConfig("Auto Harvest", {
    playerOnly = true,
    AOEDamage = true,
})

local function projectileHit(e)

    if config.playerOnly == false then

        if e.firingReference ~= tes3.player then

            return
        end
    end

    if e.firingWeapon.type == (tes3.weaponType.marksmanBow or tes3.weaponType.marksmanCrossbow) then

        if e.firingReference == e.target then

            return
        end

        local weapEnchant = e.firingWeapon.enchantment
        local equippedBow = tes3.getEquippedItem({ actor = e.firingReference, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanBow })
        local equippedXbow = tes3.getEquippedItem({ actor = e.firingReference, objectType = tes3.objectType.weapon, type = tes3.weaponType.marksmanCrossbow })
        local enchantCostBow
        local enchantCostXbow
        local projectileSpell
        local impactObject
        local radius = 0

        if weapEnchant == nil then

            return
        end

        if projectileSpell == nil then

            projectileSpell = tes3.createObject({ objectType = tes3.objectType.spell, effects = weapEnchant.effects })
        end

        if impactObject == nil then

            impactObject = tes3.createObject({ objectType = tes3.objectType.miscItem, id = "Krimson_impactObject", mesh = [[sve\sve_invisible_cube.nif]]})
        end

        if weapEnchant.castType == tes3.enchantmentType.onStrike or tes3.enchantmentType.onUse then

            if config.AOEDamage then

                for i = 1, #projectileSpell.effects do

                    local effectIndex = projectileSpell.effects[i]

                    if radius < effectIndex.radius then

                        radius = effectIndex.radius
                    end
                end

                if e.collisionPoint:distance(e.firingReference.position) <= radius * 22.1 then

                    local effectList = {}
                    local aoeSpell

                    for _, effect in pairs (projectileSpell.effects) do

                        if effect ~= nil then

                            if e.collisionPoint:distance(e.firingReference.position) <= effect.radius * 22.1 then

                                table.insert(effectList, effect)
                            end
                        end
                    end

                    if not table.empty(effectList) then

                        if aoeSpell == nil then

                            aoeSpell = tes3.createObject({ objectType = tes3.objectType.spell, effects = effectList })
                        end

                        for _, effect in pairs (aoeSpell.effects) do

                            if effect.radius > 0 then

                                effect.radius = 0
                            end
                        end

                        tes3.cast({ reference = e.firingReference, target = e.firingReference, spell = aoeSpell, instant = true, alwaysSucceeds = true })
                    end

                    if not table.empty(effectList) then

                        for i = 1, #effectList do

                            table.removevalue(effectList, i)
                        end
                    end
                end
            end

            if equippedBow then

                enchantCostBow = tes3.calculateChargeUse({ enchantment = e.firingWeapon.enchantment, mobile = e.firingReference.mobile })

                if equippedBow.itemData.charge >= weapEnchant.chargeCost then

                    equippedBow.itemData.charge = equippedBow.itemData.charge - enchantCostBow
                end
            end

            if equippedXbow then

                enchantCostXbow = tes3.calculateChargeUse({ enchantment = e.firingWeapon.enchantment, mobile = e.firingReference.mobile })

                if equippedXbow.itemData.charge >= weapEnchant.chargeCost then

                    equippedXbow.itemData.charge = equippedXbow.itemData.charge - enchantCostXbow
                end
            end

            local impactRef = tes3.createReference({ object = impactObject, position = e.collisionPoint, orientation = 0 })
            local impactTarget = impactRef or e.target
            tes3.cast({ reference = e.firingReference, target = impactTarget, spell = projectileSpell, instant = true, alwaysSucceeds = true })

            if impactRef then

                impactRef:disable()
            end

            if impactRef.diabled then

                impactRef:delete()
            end
        end
    end
end

local function registerConfig()

    local template = mwse.mcm.createTemplate("Cast on Hit Bows")
        template:saveOnClose("Cast on Hit Bows", config)
        template:register()

    local page = template:createSideBarPage({
        label = "Cast on Hit Bows",
        description = "Any arrow shot with any bow will now use the bows \"cast on strike\" or \"cast on use\" enchantment on what ever it hits.\n\nWill work with any mod added bows/arrows also.\n\nBows used by NPCs are also affected if that setting is turned on.\n\nBe careful of using AoE enchantments, they can hurt you too if the setting is turned on.\n\nGOD MODE WILL NOT STOP THE DAMAGE TO YOU!!!!!!\n\n",
    })

    local settings = page:createCategory("Cast on Hit Bows Settings\n\n\n")

    settings:createOnOffButton({
        label = "Enables NPCs using Cast on Hit Bows",
        description = "Turns on/off NPCs bows from being Cast on Hit.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "playerOnly", table = config }
    })

    local settings2 = page:createCategory("\n\n\n\n")

    settings2:createOnOffButton({
        label = "Enables AOE Damage to the attacker",
        description = "Turns on/off the attacker taking damage from \"Area of Effect\" enchantments shot from their bows when too close of what the arrow hits.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "AOEDamage", table = config }
    })
end

event.register("modConfigReady", registerConfig)

local function onInitialized()

    event.register("projectileHitActor", projectileHit)
    event.register("projectileHitObject", projectileHit)
    event.register("projectileHitTerrain", projectileHit)
    mwse.log("[Krimson] Cast on Hit Bows: Initialized")
end

event.register("initialized", onInitialized)