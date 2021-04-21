local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

local function charge()
    common.debug("Artifact: Charging Artifact.")

    local damage = tes3.mobilePlayer.health.current * .20
    tes3.mobilePlayer:applyHealthDamage(damage)

    tes3.player.data.fortifiedMolarMar.artifactCharged = true

    local equipped = mwscript.hasItemEquipped({
        reference = tes3.player,
        item = common.data.objectIds.artifactDischargedRing
    })

    mwscript.removeItem({
        reference = tes3.player,
        item = common.data.objectIds.artifactDischargedRing
    })
    if (equipped == true) then
        mwscript.addItem({
            reference = tes3.player,
            item = common.data.objectIds.artifactChargedRing,
            count = 1
        })
        mwscript.equip({
            reference = tes3.player,
            item = common.data.objectIds.artifactChargedRing
        })
    else
        mwscript.addItem({
            reference = tes3.player,
            item = common.data.objectIds.artifactChargedRing,
            count = 1
        })
    end
end

local function discharge()
    common.debug("Artifact: Discharging Artifact.")
    
    tes3.player.data.fortifiedMolarMar.artifactCharged = false

    local equipped = mwscript.hasItemEquipped({
        reference = tes3.player,
        item = common.data.objectIds.artifactChargedRing
    })

    mwscript.removeItem({
        reference = tes3.player,
        item = common.data.objectIds.artifactChargedRing
    })
    if (equipped == true) then
        mwscript.addItem({
            reference = tes3.player,
            item = common.data.objectIds.artifactDischargedRing,
            count = 1
        })
        mwscript.equip({
            reference = tes3.player,
            item = common.data.objectIds.artifactDischargedRing
        })
    else
        mwscript.addItem({
            reference = tes3.player,
            item = common.data.objectIds.artifactDischargedRing,
            count = 1
        })
    end
end

local function onArtifactEnchantmentCasted(e)
    if (e.caster ~= tes3.player) then
        return
    end
    
    if (e.source.id == common.data.enchantmentIds.slowTime) then
        common.debug("Artifact: Enchantment casted.")
        discharge()
    end
end
event.register("magicCasted", onArtifactEnchantmentCasted)

local function castAlterSpell()
    common.debug("Artifact: Casting alter spell.")

    local damage = tes3.mobilePlayer.health.current * .03
    tes3.mobilePlayer:applyHealthDamage(damage)
    
    local alter = tes3.getReference(common.data.objectIds.artifactShrine)
    tes3.cast({
        reference = alter,
        target = tes3.player,
        spell = common.data.spellIds.slowTimeShrine
    })
end

local function onShrineActivate(e)
    if (e.target.object.id ~= common.data.objectIds.artifactShrine) then
        return
    end

    common.debug("Artifact: Shrine Activated.")

    local dischargedArtifactCount = mwscript.getItemCount({
        reference = tes3.player,
        item = common.data.objectIds.artifactDischargedRing
    })

    if (dischargedArtifactCount > 0) then
        tes3.messageBox({
            message = common.data.messageBoxes.artifactShrineWithDischargedArtifact,
            buttons = { "Pray at the shrine", "Recharge Artifact", "Cancel"},
            callback = function(e)
                if (e ~= nil) then
                    if (e.button == 0) then
                        castAlterSpell()
                    elseif (e.button == 1) then
                        charge()
                    else
                        return
                    end
                end
            end
        })
    else
        tes3.messageBox({
            message = common.data.messageBoxes.artifactShrineNoDischargedArtifact,
            buttons = { "Pray at the shrine", "Cancel"},
            callback = function(e)
                if (e ~= nil) then
                    if (e.button == 0) then
                        castAlterSpell()
                    else
                        return
                    end
                end
            end
        })
    end
end
event.register("activate", onShrineActivate)