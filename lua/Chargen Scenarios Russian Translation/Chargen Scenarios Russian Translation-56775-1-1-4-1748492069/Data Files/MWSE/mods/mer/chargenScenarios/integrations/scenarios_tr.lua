
local Scenario = require("mer.chargenScenarios.component.Scenario")
local itemPicks = require("mer.chargenScenarios.util.itemPicks")

---@type ChargenScenariosScenarioInput[]
local scenarios = {
    {
        id = "oldEbonheart",
        name = "Старый Эбенгард",
        description = "Вы только что сошли с корабля в Старом Эбенгарде.",
        journalEntry = "Мы уже прибыли в Старый Эбенгард. Как только сойду с корабля нужно прогуляться по городу и осмотреться.",
        location = { --Stepping off the boat in Old Ebonheart
            position = {60970, -144577, 341},
            orientation =1.41,
        },
        items = {
            itemPicks.gold(50),
            {
                id = "t_sc_mapindorillandsnorthwesttr",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Cm_Hat_04",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
    {
        id = "firewatchCollege",
        name = "Коллегия Фаервотча",
        description = "Вы будущий учиник Коллегии Фаервотча.",
        journalEntry = "Мне наконец-то удалось накопить достаточно денег, чтобы поступить в Коллегию Фаервотча. Мне нужно поговорить с Марилусом Арьюсом и решить, на какой курс записаться.",
        location =     { --Firewatch, College
            position = {5182, 3518, 12098},
            orientation =3.14,
            cellId = "Firewatch, College"
        },
        items = {
            itemPicks.gold(1500),
            {
                id = "TR_m1_FW_College_EnrollmentInfo",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "potion_t_bug_musk_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomExpensivePants,
            itemPicks.randomExpensiveShirt,
            itemPicks.randomExpensiveShoes,
        },
        onStart = function()
            local marilus = tes3.getReference("TR_m1_Marilus_Arjus")
            if marilus then
                local currentDisp = marilus.object.baseDisposition
                if currentDisp < 50 then
                    local change = 50 - currentDisp
                    tes3.modDisposition{
                        reference = marilus,
                        value = change
                    }
                end
            end
        end
    },
    {
        id = "dreynimSpa",
        name = "Курорт Дрейнима",
        description = "Вы отдыхаете на курорте Дрейнима.",
        journalEntry = "Я отдыхаю на курорте Дрейнима. Ванны здесь горячие, а напитки холодные.",
        location = {
            position = {240656, -176840, 709},
            orientation = 0,
        },
        items = {
            {
                id = "T_Com_Ep_Robe_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_ClothRed_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Soap_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "arrivingInNivalis",
        name = "Нивалис",
        description = "Вы только что прибыли в имперское поселение Нивалис.",
        journalEntry = "Мне наконец-то удалось добраться в имперское поселение Нивалис.",
        location = {
            position = {98094, 227955, 544},
            orientation = 90,
        },
        items = {
            {
                id = "fur_colovian_helm",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.gold(50),
            {

                id = "T_Imp_ColFur_Boots_01",
                count = 1,
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
        },
    },
    {
        id = "sadasPlantation",
        name = "Раб на плантации",
        description = "Вы - раб, работающий на плантации Садаса.",
        journalEntry = "Хозяин Садас приказал мне работать на его плантации. Мне нужно трудиться не поднимая головы.",
        location = {
            position = {291563, 144320, 424},
            orientation = 0,
        },
        items = {
            {
                id = "slave_bracer_right",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "pick_apprentice_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Farm_Pitchfork_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        requirements = {
            races = {"Argonian", "Khajiit"},
        },
    },
    {
        id = "teynCensus",
        name = "Имперская Канцелярия в Тэйне",
        description = "Вы проходите регистрацию в Имперской Канцелярии в Тэйне.",
        journalEntry = "Меня зарегистрировали в Имперской Канцелярии в Тэйне.",
        location = { --Teyn, Census and Excise Office
            position = {4321, 4372, 16322},
            orientation =3.13,
            cellId = "Teyn, Census and Excise Office"
        },
        items = {
            itemPicks.gold(75),
            {
                id = "T_IngFood_Bread_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "unwelcomeVisitor",
        name = "Незваный гость",
        description = "Вы забрели в Клуб Совета в Андотрене, чтобы сыграть партию в тридцать шесть. Вы чувствуете на себе пристальные взгляды завсегдатаев. Возможно, вам стоит уйти.",
        journalEntry = "Угораздило же меня забрести в Клуб Совета в Андотрене из за партии в тридцать шесть. Наверное, мне пора уходить.",
        location =  { --Andothren, Council Club
            position = {4102, 3970, 12295},
            orientation =0.02,
            cellId = "Andothren, Council Club"
        },
        items = {
            {
                id = "t_com_dice_01",
                count = 2,
                noDuplicates = true,
            },
            itemPicks.gold(100),
            {
                id = "iron dagger",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        time = 21,
        onStart = function()
            -- Lower the disposition of nearby NPCs to reflect their distrust
            for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
                if ref and ref.mobile then
                    tes3.modDisposition{
                        reference = ref,
                        value = -20
                    }
                end
            end
        end,
    },
    {
        id = "bakery",
        name = "Покупка свежего хлеба",
        description = "Вы зашли в местную пекарню, чтобы купить свежего хлеба.",
        journalEntry = "Моя прогулка завершилась посещением пекарни. Нужно посмотреть, что у них есть в наличии.",
        locations = {
            {
             --Vhul, Bakers' Hall
                name = "Вул",
                position = {111, 52, -126},
                orientation =2.86,
                cellId = "Vhul, Bakers' Hall"
            },
            { --Karthwasten, Lelena Aurtius: Baker
                name = "Картвастен",
                position = {-752, 74, 2},
                orientation =-0.14,
                cellId = "Karthwasten, Lelena Aurtius: Baker"
            },
            { --Old Ebonheart, Gul-Ei's Pantry
                name = "Старый Эбенгард",
                position = {4309, 4124, 15405},
                orientation =-1.62,
                cellId = "Old Ebonheart, Gul-Ei's Pantry"
            }
        },
        items = {
            itemPicks.gold(30),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "erothHermit",
        name = "Отшельник с Эрота",
        description = "Вы отшельник, живущий на острове Эрот. У вас мало вещей и нет друзей, но вас это вполне устраивает.",
        location ={ --Living as a hermit on Eroth Island
            position = {357102, -31316, 361},
            orientation =0.59,
        },
        items = {
            {
                id = "ashfall_bedroll",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },

    {
        id = "botheanFalls",
        name = "Паломничество к Боэтским водопадам",
        description = "Вы совершаете паломничество к Боэтским водопадам.",
        location =     { --Visiting the Boethian Falls
            position = {265250, 4529, 19},
            orientation =-2.48,
        },
        items = {
            {
                id = "T_IngFlor_BlackrosePetal_01",
                count = 1,
            },
            itemPicks.gold(50),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        journalEntry = "Мне удалось успешно добраться до Боэтских водопадов. Мне нужно найти святилище и преподнести черную розу, чтобы завершить паломничество.",
    },

    {
        id = "leftForDead",
        name = "Брошенный умирать",
        description = "Во время путешествия в Аммар на вас напали разбойники. Вас бросили умирать на обочине дороги.",
        journalEntry = "На меня напали разбойники. Мне нужно найти способ добраться до цивилизации.",
        location = { --Left for dead on the side of the road
            position = {195622, -74295, 478},
            orientation =-0.27,
        },
        onStart = function()
            tes3.setStatistic{
                reference = tes3.player,
                name = "health",
                current = 5,
            }
            tes3.playAnimation{
                reference=tes3.player,
                group=tes3.animationGroup.knockOut,
                startFlag = tes3.animationStartFlag.immediate,
                loopCount = 1
            }
        end
    },

    {
        id = "necromCatacombs",
        name = "Катакомбы Некрома",
        description = "Вы находитесь в Некроме и исследуете катакомбы под городом.",
        location = { --Necrom, Catacombs: First Chamber
            position = {134, 1287, -446},
            orientation =-3.09,
            cellId = "Necrom, Catacombs: First Chamber"
        },
        items = {
            itemPicks.gold(50),
            {
                id = "pick_apprentice_01",
                count = 1,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
        --equip torch
        onStart = function()
            tes3.equip{
                item = "light_com_torch_01_256",
                reference = tes3.player,
                addItem = true,
            }
        end,
    },

    {
        id = "akamoraTemple",
        name = "Храм Акаморы",
        description = "Вы находитесь в храме Акаморы и молитесь богам.",
        journalEntry = "Дорога привела меня в храм Акаморы.",
        location = { --Praying at the temple of Akamora
            position = {4544, 3322, 11970},
            orientation =-2.35,
            cellId = "Akamora, Temple"
        },
        items = {
            itemPicks.gold(50),
            {
                id = "bk_LivesOfTheSaints",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "common_robe_05",
                count = 1,
                noSlotDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "portTelvannis",
        name = "Порт Тельваннис",
        description = "Вы хотите попасть в порт Тельваннис. У вас есть Удостоверение Гостя, возможно, этого будет достаточно.",
        location = { --Seeking access into Port Telvannis
            position = {3589, 4561, 12289},
            orientation =0,
            cellId = "Port Telvannis, The Avenue"
        },
        topics = {
            "Удостоверение Гостя",
        },
        items = {
            itemPicks.gold(50),
            {
                id = "TR_m1_sc_T_hospitalitypapers",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },


    {
        id = "arrivedInAnvil",
        name = "Повозка в Анвил",
        description = "Вы только что прибыли в Анвил после долгого путешествия в повозке из Хал Садека.",
        journalEntry = "Мне удалось наконец-то добраться до Анвила после долгого путешествия на повозке из Хал Садека. Мне нужно поискать еду, питье и информацию о городе на ближайшей стоянке караванов.",
        location =  { --Anvil, Marina
            position = {-976885, -446000, 426},
            orientation =-1.39,
        },
        items = {
            itemPicks.gold(50),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "workingOnTheDocks",
        name = "Работник Доков Анвила",
        description = "Вы находитесь в доках Анвила в поисках работы.",
        journalEntry = "Я прибыл в доки Анвила. Стоит поговорить с Харагом гро-Уратагом, слышал, он тоже ищет работу.",
        location =     { --Anvil, Port Quarter
            position = {-993310, -449487, 193},
            orientation =-0.82,
        },
        items = {
            itemPicks.gold(15),
            {
                id = "T_Com_Mallet_01",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "misc_hook",
                count = 1,
                noDuplicates = true,
            },
            {
                id = "T_Com_Var_Harpoon_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "market",
        name = "Покупки на рынке",
        description = "Вы покупаете новую экипировку на уличном рынке в Мералаге",
        location = { --Browsing an Indoril open-air market
            position = {209924, -174964, 539},
            orientation =0.14,
        },
        items = {
            itemPicks.gold(100),
            {
                id = "T_IngFood_Bread_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },

    {
        location =     { --Getting directions at a waystation
            position = {4461, 3242, 12242},
            orientation =0.3,
            cellId = "Telvanni Waystation"
            --Notes: Start with guide to the sacred lands region
        },
        id = "waystation",
        name = "Путевая Станция Телванни",
        description = "Вы находитесь на Путевой Станции Телванни и ищете дорогу к священным землям.",
        items = {
            itemPicks.gold(50),
            itemPicks.robe,
            {
                id = "T_Sc_GuideToNecrom",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },

    {
        id = "astrologicalSociety",
        name = "Астрологическое Общество",
        description = "Вы - будущий член Имперского астрологического общества в Анвиле.",
        journalEntry = "Было непросто приехать в Имперское астрологическое общество в Анвиле. Мне следует поговорить с Саррией Кавиран о вступлении.",
        location = { --Anvil, Imperial Astrological Society
            position = {2311, 159, 17474},
            orientation =0.43,
            cellId = "Anvil, Imperial Astrological Society"
        },
        items = {
            {
                id = "t_com_spyglass01",
            },
            itemPicks.gold(40),
            {
                id = "T_IngFood_Bread_01",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },

    {
        id = "bountyHunter",
        name = "Охотник за головами",
        description = "Вы охотник за головами в Картвастене, которому поручено найти беглеца.",
        journalEntry = "Нужно поговорить с Хаднаром Белым Ветром о награде за Довику или узнать о других доступных заказах.",
        topics = { "Довика" },
        location =     { --Karthwasten, Guard Barracks
            position = {1300, -1302, 642},
            orientation =-1.72,
            cellId = "Karthwasten, Guard Barracks"
        },
        items = {
            itemPicks.gold(50),
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        },
    },
    {
        id = "houseOfMara",
        name = "Дом Мары",
        description = "Вы находитесь в Доме Мары в Драгонстаре, ищете наставления и мудрости.",
        journalEntry = "Мне наконец-то удалось добраться в Дом Мары в Драгонстаре. Нужно поговорить со жрицей Хелле.",
        location =     { --Dragonstar East, House of Mara
            position = {3844, 3965, 15738},
            orientation =1.6,
            cellId = "Dragonstar East, House of Mara"
        },
        items = {
            itemPicks.coinpurse,
            {
                id = "common_robe_05",
                count = 1,
                noSlotDuplicates = true,
            },
            {
                id = "bk_LivesOfTheSaints",
                count = 1,
                noDuplicates = true,
            },
            itemPicks.randomCommonPants,
            itemPicks.randomCommonShirt,
            itemPicks.randomCommonShoes,
        }
    },
}

for _, scenario in ipairs(scenarios) do
    if not scenario.requirements then
        scenario.requirements = {}
    end
    if not scenario.requirements.plugins then
        scenario.requirements.plugins = {}
    end
    table.insert(scenario.requirements.plugins, "TR_Mainland.esm")
    Scenario:register(scenario)
end
