local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

local function registerSpells()
    framework.spells.createBasicSpell({
        id = "OJ_EL_LightSelfTest",
        name = "Light - Self",
        effect = tes3.effect.magelight,
        range = tes3.effectRange.self,
        magickaCost = 1,
        duration = 10,
        min = 25,
        max = 25
    })
    framework.spells.createBasicSpell({
        id = "OJ_EL_LightSelfTest1",
        name = "Light - Self 1",
        effect = tes3.effect.magelight,
        range = tes3.effectRange.self,
        magickaCost = 1,
        duration = 10,
        min = 250,
        max = 250
    })
    
    framework.spells.createBasicSpell({
        id = "OJ_EL_LightTargetTest",
        name = "Light - Target",
        effect = tes3.effect.magelight,
        range = tes3.effectRange.target,
        magickaCost = 1,
        duration = 10,
        min = 25,
        max = 25,
        area = 2
    })
    framework.spells.createBasicSpell({
        id = "OJ_EL_LightTargetTest1",
        name = "Light - Target 1",
        effect = tes3.effect.magelight,
        range = tes3.effectRange.target,
        magickaCost = 1,
        duration = 10,
        min = 250,
        max = 250,
        area = 2
    })
end
event.register("MagickaExpanded:Register", registerSpells)
