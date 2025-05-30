local this = {}

this.defaultTrinketDistance = 1000
--Tent mappings for activating a misc item into activator
this.tentMiscToActiveMap = {
    --legacy tents
    ashfall_tent_test_misc = "ashfall_tent_test_active",
    ashfall_tent_misc = "ashfall_tent_active",
    ashfall_tent_ashl_misc = "ashfall_tent_ashl_active",
    ashfall_tent_canv_b_misc = "ashfall_tent_canv_b_active",

    --modular tents
    ashfall_tent_base_m = 'ashfall_tent_base_a',
    ashfall_tent_imp_m = 'ashfall_tent_imp_a',
    ashfall_tent_qual_m = 'ashfall_tent_qual_a',
    ashfall_tent_ashl_m = 'ashfall_tent_ashl_a',
    ashfall_tent_leather_m = 'ashfall_tent_leather_a',

}
this.tentActivetoMiscMap = {}
for miscId, activeId in pairs(this.tentMiscToActiveMap) do
    this.tentActivetoMiscMap[activeId] = miscId
end

this.coverToMeshMap = {
    ashfall_cov_canv = "ashfall\\tent\\cover_canv.nif",
    ashfall_cov_dark = "ashfall\\tent\\cover_dark.nif",
    ashfall_cov_thatch = "ashfall\\tent\\cover_thatch.nif",
    ashfall_cov_common = "ashfall\\tent\\cover_blue.nif",
    ashfall_cov_ashl = "ashfall\\tent\\cover_ashl.nif",
}

this.trinkets = {

    --Censer: Blight resistance
    ashfall_trinket_censer = {
        id = "ashfall_trinket_censer",
        description = "Острый аромат, исходящий от Курильницы, очищает воздух и обеспечивает защиту от Мора.",
        mesh = "ashfall\\tent\\trink_censer_a.nif",
        soundPath = nil,
        message = "Запах благовоний очищает воздух.",
        spell = {
            name = "Trinket: Censer",
            id = "ashfall_trinkspell_censer",
            effects = {
                { id = tes3.effect.resistBlightDisease, amount = 50 },
            }
        }
    },
    --Bouquet: Fatigue Regen
    ashfall_trinket_flower = {
        id = "ashfall_trinket_flower",
        description = "Этот простой букет Каменевки наполняет воздух бодрящим ароматом, который снимает усталость.",
        mesh = "ashfall\\tent\\trink_flower_a.nif",
        soundPath = nil,
        message = "Воздух наполняется сладким цветочным ароматом.",
        -- spell = {
        --     name = "Trinket: Stoneflower",
        --     id = "ashfall_trinkspell_flower",
        --     effects = {
        --         { id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.personality, amount = 10 }
        --     }
        -- }
        onCallback = function()
            event.trigger("Ashfall:ActivateBouquet")
        end,
        offCallback = function()
            event.trigger("Ashfall:DeactivateBouquet")
        end,
    },
    --Chimes: Health Regen
    ashfall_trinket_chimes = {
        id = "ashfall_trinket_chimes",
        description = "Успокаивающие звуки ветряных колокольчиков помогают отдохнуть и восстановить силы, оказывая легкий оздоровительный эффект.",
        mesh = "ashfall\\tent\\trink_chimes_a.nif",
        soundPath = "\\Fx\\envrn\\woodchimes.wav",
        effects = nil,
        onCallback = function()
            event.trigger("Ashfall:ActivateWindChimes")
        end,
        offCallback = function()
            event.trigger("Ashfall:DeactivateWindChimes")
        end,
    },

    --DreamCatcher: Magicka Regen
    ashfall_trinket_dream = {
        id = "ashfall_trinket_dream",
        description = "Ловец снов способствует регенерации магии, собирая окружающую магию из воздуха.",
        mesh = "ashfall\\tent\\trink_dream_a.nif",
        soundPath = nil,
        effects = nil,
        onCallback = function()
            event.trigger("Ashfall:ActivateDreamCatcher")
        end,
        offCallback = function()
            event.trigger("Ashfall:DeactivateDreamCatcher")
        end,
    },

    ashfall_trinket_tooth = {
        id = "ashfall_trinket_tooth",
        description = "Костяной оберег внушает страх окружающим животным, отпугивает их от палатки.",
        mesh = "ashfall\\tent\\trink_tooth_a.nif",
        soundPath = nil,
        message = "Животные разбегаются при виде костяного оберега.",
        effects = nil,
        onCallback = function()
            event.trigger("Ashfall:ActivateWard", { refType = tes3.objectType.creature })
        end,
        offCallback = function()
            event.trigger("Ashfall:DeactivateWard", { refType = tes3.objectType.creature })
        end,
    },
    ashfall_trinket_skull = {
        id = "ashfall_trinket_skull",
        description = "Оберег череп служит предостережением, находящимся поблизости, враждебным NPC , заставляет их прервать бой.",
        mesh = "ashfall\\tent\\trink_skull_a.nif",
        soundPath = nil,
        message = "Враги бегут при виде черепа.",
        effects = nil,
        onCallback = function()
            event.trigger("Ashfall:ActivateWard", { refType = tes3.objectType.npc })
        end,
        offCallback = function()
            event.trigger("Ashfall:DeactivateWard", { refType = tes3.objectType.npc })
        end,
    },
}

this.tempMultis = {
    legacy = 0.70,
    uncovered = 0.85,
    coverDefault = 0.7,
    --covers
    ashfall_cov_canv = 0.68,
    ashfall_cov_thatch = 0.72,
    ashfall_cov_ashl = 0.67,
    ashfall_cov_common = 0.73,
    --tents that come with covers
    ashfall_tent_imp_a = 0.80,
    ashfall_tent_qual_a = 0.8,
    ashfall_tent_base_m = 0.85,
    ashfall_tent_leather_m = 0.88
}

function this.getTrinketData(trinketId)
    return this.trinkets[trinketId:lower()]
end


this.lanternIds = {
    ["light_com_lantern_02"] = true,
    ["light_com_lantern_02_128"] = true,
    ["light_com_lantern_02_128_off"] = true,
    ["light_com_lantern_02_177"] = true,
    ["light_com_lantern_02_256"] = true,
    ["light_com_lantern_02_64"] = true,
    ["light_com_lantern_02_inf"] = true,
    ["light_com_lantern_02_off"] = true,
    ["light_com_lantern_01"] = true,
    ["light_com_lantern_01_128"] = true,
    ["light_com_lantern_01_256"] = true,
    ["light_com_lantern_01_77"] = true,
    ["light_com_lantern_01_off"] = true,
    ["light_de_lantern_14"] = true,
    ["light_de_lantern_11"] = true,
    ["light_de_lantern_10"] = true,
    ["light_de_lantern_10_128"] = true,
    ["light_de_lantern_07"] = true,
    ["light_de_lantern_07_128"] = true,
    ["light_de_lantern_07_warm"] = true,
    ["light_de_lantern_06"] = true,
    ["light_de_lantern_06_128"] = true,
    ["light_de_lantern_06_177"] = true,
    ["light_de_lantern_06_256"] = true,
    ["light_de_lantern_06_64"] = true,
    ["light_de_lantern_06a"] = true,
    ["light_de_lantern_05"] = true,
    ["light_de_lantern_05_128_carry"] = true,
    ["light_de_lantern_05_200"] = true,
    ["light_de_lantern_05_carry"] = true,
    ["light_de_lantern_02"] = true,
    ["light_de_lantern_02-128"] = true,
    ["light_de_lantern_02-177"] = true,
    ["light_de_lantern_02_128"] = true,
    ["light_de_lantern_02_256_blue"] = true,
    ["light_de_lantern_02_256_off"] = true,
    ["light_de_lantern_02_blue"] = true,
    ["light_de_lantern_01"] = true,
    ["light_de_lantern_01_128"] = true,
    ["light_de_lantern_01_177"] = true,
    ["light_de_lantern_01_77"] = true,
    ["light_de_lantern_01_off"] = true,
    ["light_de_lantern_01white"] = true,
    ["dx_l_ashl_lantern_01"] = true,
    ["dx_l_lant_crystal_01"] = true,
    ["dx_l_lant_crystal_02"] = true,
    ["dx_l_lant_paper_01"] = true,
}
return this