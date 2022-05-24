local ek_bdc_FistDuelActive = assert(tes3.findGlobal("ek_bdc_FistDuelActive"))

local function forceGreeting()
    tes3.runLegacyScript{command = "ForceGreeting"}
end

--- Detect if player cheats in the duel by using alchemy items.
---
local function onEquipped(e)
    if e.reference ~= tes3.player then
        return
    end

    if ek_bdc_FistDuelActive.value == 0 then
        return
    end

    if e.item.objectType == tes3.objectType.alchemy then
        tes3.setJournalIndex{id="ek_bdc_FargothRing", index=32}
        forceGreeting()
    end
end
event.register("equip", onEquipped, { priority = -100 })


--- Detect if player cheats in the duel by casting spells.
---
local function onSpellCasted(e)
    if e.caster ~= tes3.player then
        return
    end

    if ek_bdc_FistDuelActive.value == 0 then
        return
    end

    -- casting spells is cheating
    tes3.setJournalIndex{id="ek_bdc_FargothRing", index=32}
    forceGreeting()
end
event.register("spellCasted", onSpellCasted, { priority = -100 })


--- Detect if player cheats in the duel by using weapons.
---
local function onDamaged(e)
    if e.attackerReference ~= tes3.player then
        return
    end

    if ek_bdc_FistDuelActive.value == 0 then
        return
    end

    -- using weapons is cheating
    if e.source == tes3.damageSource.attack then
        if e.attacker.readiedWeapon ~= nil then
            tes3.setJournalIndex{id="ek_bdc_FargothRing", index=32}
            forceGreeting()
        end
    end
end
event.register("damaged", onDamaged, { priority = -100 })
