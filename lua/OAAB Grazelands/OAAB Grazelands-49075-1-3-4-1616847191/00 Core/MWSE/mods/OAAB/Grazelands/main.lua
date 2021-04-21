local function registerEnchantments()
    if not tes3.isModActive("OAAB_Grazelands.ESP") then
        return
    end

    local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
    if (framework == nil) then
        local function warning()
            tes3.messageBox(
                "[OAAB Grazelands ERROR] Magicka Expanded framework is not installed!"
                .. " You will need to install it to use this mod."
            )
        end
        event.register("initialized", warning)
        event.register("loaded", warning)
        return
    end
    require("OAAB.Grazelands.effects.flawedSummonDaedrothEffect")

    framework.enchantments.createBasicEnchantment({
        id = "ABtv_w_Verminous_en",
        effect = tes3.effect.flawedSummonDaedroth,
        range = tes3.effectRange.self,
        duration = 45,
        chargeCost = 50,
        maxCharge = 100,
        castType = tes3.enchantmentType.onUse
    })
end
event.register("MagickaExpanded:Register", registerEnchantments)


local function onLoaded(e)
    if tes3.getJournalIndex{id="OAAB_TVos_HauntedLantern"} == 30 then
        e.mobile:equip{item="ABtv_light_AshlLanternGhost"}
    end
end


local function onInitializsed(e)
    if tes3.isModActive("OAAB_Grazelands.ESP") then
        event.register("loaded", onLoaded)
    end
end
event.register("initialized", onInitializsed)
