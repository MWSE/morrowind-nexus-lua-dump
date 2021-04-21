local common = require("TeamVoluptuousVelks.FortifiedMolagMar.common")

local function onDamaged(e)
    if (e.mobile ~= tes3.mobilePlayer) then
        return
    end

    if (tes3.mobilePlayer.health.current / tes3.mobilePlayer.health.base < .05) then
        tes3.messageBox(common.data.messageBoxes.amuletDischarge)

        mwscript.removeItem({
            reference = tes3.player,
            item = common.data.objectIds.giftAmulet
        })

        tes3.modStatistic({
            reference = tes3.mobilePlayer,
            current = tes3.mobilePlayer.health.base - tes3.mobilePlayer.health.current,
            name = "health"
        })

        mwscript.addSpell({
            reference = tes3.player,
            spell = common.data.spellIds.amuletReflect
        })

        timer.start({
            duration = 60,
            iterations = 1,
            callback = function()
                mwscript.removeSpell({
                    reference = tes3.player,
                    spell = common.data.spellIds.amuletReflect
                })
            end
        })
    end
end


local function onUnequipped(e)
    if (e.reference ~= tes3.player) then
        return
    end

    if (e.item ~= tes3.getObject(common.data.objectIds.giftAmulet)) then
        return
    end

    event.unregister("damaged", onDamaged)
end

event.register("unequipped", onUnequipped)

local function onEquipped(e)
    if (e.reference ~= tes3.player) then
        return
    end

    if (e.item ~= tes3.getObject(common.data.objectIds.giftAmulet)) then
        return
    end

    event.register("damaged", onDamaged)
end

event.register("equipped", onEquipped)

local function onLoaded(e)
    mwscript.removeSpell({
        reference = tes3.player,
        spell = common.data.spellIds.amuletReflect
    })
    
    local hasAmuletEquipped = mwscript.hasItemEquipped({
        reference = tes3.player,
        item = common.data.objectIds.giftAmulet
    })

    if (hasAmuletEquipped == true) then
        event.register("damaged", onDamaged)
    end
end

event.register("loaded", onLoaded)