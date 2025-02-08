--[[
    Register default fish types
]]
local common = require("mer.fishing.common")
local config = require("mer.fishing.config")
local logger = common.createLogger("Integrations - fishTypes")
local Interop = require("mer.fishing")

---@class Fishing.Integration.FishConfigs
---@field common Fishing.FishType.new.params[]
---@field uncommon Fishing.FishType.new.params[]
---@field rare Fishing.FishType.new.params[]
---@field legendary Fishing.FishType.new.params[]
local fishConfigs = {
    common = {
        {
            baseId = "mer_fish_trout",
            previewMesh = "mer_fishing\\f\\br_trout.nif",
            description = "Форель - пресноводная рыба, обитающая на мелководье рек и озер. Они активны на рассвете и в сумерках.",
            speed = 165,
            size = 1.2,
            difficulty = 25,
            class = "small",
            isBaitFish = true,
            habitat = {
                times = { "dawn", "dusk" },
                waterType = "freshwater",
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_mudcrab",
            previewMesh = "mer_fishing\\f\\mudcrab.nif",
            description = "Грязевой краб - распространенный вид крабов, способный маскироваться под небольшие камни. В то время как взрослые грязекрабы слишком велики, чтобы их могли поймать рыболовы, молодые особи, водящиеся на мелководье, хорошо ловятся.",
            speed = 50,
            heightAboveGround = 15,
            size = 1.4,
            difficulty = 15,
            class = "medium",
            habitat = {
                interiors = true,
                exteriors = true,
                maxDepth = 300,
            },
            harvestables = {
                {
                    id = "ingred_crab_meat_01",
                    min = 1,
                    max = 3,
                    isMeat = true,
                },
                {
                    id = "mer_crabshell",
                    min = 1,
                    max = 1,
                }
            }
        },
        {
            baseId = "mer_fish_bass",
            previewMesh = "mer_fishing\\f\\bass.nif",
            description = "Большеротый окунь - пресноводная рыба, обитающая в озерах, реках и прудах. Пользуется большой популярностью среди рыболовов-спортсменов за силу и впечатляющий боевой дух при ловле на крючок.",
            speed = 170,
            size = 1.5,
            difficulty = 30,
            class = "medium",
            habitat = {
                climates = {"temperate", "tropical"},
                waterType = "freshwater",
                minDepth = 100,
            },
            harvestables = {
                {
                    id = "mer_meat_bass",
                    min = 1,
                    max = 4,
                    isMeat = true,
                }
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_seabass",
            previewMesh = "mer_fishing\\f\\seabass.nif",
            description = "Морской окунь - это рыба, известная своими характерными черными полосами и агрессивным характером. Он часто встречается в прибрежных водах Вварденфелла.",
            speed = 180,
            size = 1.8,
            difficulty = 35,
            class = "medium",
            habitat = {
                climates = {"temperate", "tropical", "swamp"},
                waterType = "saltwater",
                times = { "day" },
            },
            harvestables = {
                {
                    id = "mer_meat_seabass",
                    min = 1,
                    max = 3,
                    isMeat = true,
                }
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_tuna",
            previewMesh = "mer_fishing\\f\\tuna.nif",
            description = "Тунец - крупная, быстро плавающая рыба, обитающая в открытом океане. Известный своей скоростью и силой, тунец является ценным уловом среди рыболовов. Он наиболее активен в дневное время.",
            speed = 240,
            size = 4.3,
            difficulty = 56,
            class = "large",
            habitat = {
                climates = {"temperate", "tropical", "swamp"},
                waterType = "saltwater",
                times = { "day" },
                minDepth = 250,
            },
            harvestables = {
                {
                    id = "mer_meat_tuna",
                    min = 4,
                    max = 7,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_goby",
            previewMesh = "mer_fishing\\f\\goby.nif",
            description = "Бычок - небольшая, пестрая рыбка, обитающая как в пресной, так и в морской среде в теплых регионах. Они активны в течение дня.",
            speed = 150,
            size = 1.1,
            difficulty = 20,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"temperate", "tropical"},
                times = { "day" },
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_salmon",
            previewMesh = "mer_fishing\\f\\salmon.nif",
            description = "Лосось - анадромная рыба, известная своим удивительным жизненным циклом: она выводится в пресноводных ручьях, мигрирует в океан, чтобы вырасти, и возвращается в пресную воду на нерест.",
            speed = 200,
            size = 2.1,
            difficulty = 40,
            class = "medium",
            habitat = {
                climates = {"temperate"},
                times = { "day" },
                minDepth = 100,
            },
            harvestables = {
                {
                    id = "mer_meat_salmon",
                    min = 1,
                    max = 3,
                    isMeat = true,
                }
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_slaughter_l",
            previewMesh = "mer_fishing\\f\\sfish_l.nif",
            description = "Рыба-убийца - грозный хищник, обитающий во всех водах Тамриэля. Хотя ее мясо не аппетитно, чешуя считается деликатесом.",
            speed = 180,
            size = 3.0,
            difficulty = 50,
            class = "large",
            habitat = {
                interiors = true,
                exteriors = true,
            },
            harvestables = {
                {
                    id = "ab_ingcrea_sfmeat_01",
                    min = 1,
                    max = 3,
                    isMeat = true,
                },
                {
                    id = "ingred_scales_01",
                    min = 2,
                    max = 4,
                }
            }
        },
        {
            baseId = "mer_fish_slaughter_sm",
            previewMesh = "mer_fishing\\f\\sfish_sm.nif",
            description = "Молодые особи рыбы-убийцы встречаются в водоемах по всему Тамриэлю. Даже в раннем возрасте они могут оказать энергичное сопротивление.",
            speed = 170,
            size = 1.1,
            difficulty = 25,
            class = "small",
            isBaitFish = true,
            habitat = {
                interiors = true,
                exteriors = true,
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_trigger",
            previewMesh = "mer_fishing\\f\\trigger.nif",
            description = "Спинорог - небольшая морская рыбка, известная своими яркими цветами и уникальной формой. Она водится в коралловых рифах и скалистых прибрежных районах и известна своими сильными челюстями и агрессивным характером.",
            speed = 190,
            size = 1.0,
            difficulty = 15,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"tropical", "swamp"},
                waterType = "saltwater",
                times = { "day" },
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_catfish",
            previewMesh = "mer_fishing\\f\\catfish.nif",
            description = "Сом - донная рыба, имеет на нижней челюсти колючки напоминающие кошачьи усы. Его можно встретить в болотах.",
            speed = 160,
            size = 1.0,
            difficulty = 31,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"swamp"},
                waterType = "freshwater",
                interiors = true,
                exteriors = true
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_sculpin",
            previewMesh = "mer_fishing\\f\\sculpin.nif",
            description = "Подкаменщик - небольшая рыба, обитающая как в пресной, так и соленой воде. Благодаря своим скромным размерам служит отличной приманкой для охоты на более крупную рыбу.",
            speed = 165,
            size = 1.0,
            difficulty = 22,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"temperate", "arctic"},
                times = { "day" },
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_cod",
            previewMesh = "mer_fishing\\f\\cod.nif",
            description = "Треска - это морская рыба среднего размера, обитающая в глубоких водах Внутреннего моря. Треска, известная своим восхитительным мясом, является ценным уловом как среди рыболовов, так и среди любителей кулинарии. Плотное белое мясо и мягкий вкус делают ее универсальным ингредиентом для различных блюд.",
            speed = 150,
            size = 1.5,
            difficulty = 42,
            class = "medium",
            harvestables = {
                {
                    id = "mer_meat_cod",
                    min = 1,
                    max = 3,
                    isMeat = true,
                }
            },
            habitat = {
                climates = {"temperate", "arctic", "tropical"},
                waterType = "saltwater",
                times = { "day" },
                minDepth = 200,
            },
            hangable = true,
        },
    },
    uncommon = {
        {
            baseId = "mer_fish_barracuda",
            previewMesh = "mer_fishing\\f\\barracuda.nif",
            description = "Барракуда - хищная рыба, известная своим устрашающим видом и агрессивным поведением. Хотя мясо взрослых барракуд съедобно, оно может быть ядовитым.",
            speed = 230,
            size = 1.8,
            difficulty = 60,
            class = "medium",
            habitat = {
                climates = {"tropical", "swamp"},
                waterType = "saltwater",
                minDepth = 200,
            },
            harvestables = {
                {
                    id = "mer_meat_barracuda",
                    min = 1,
                    max = 2,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_piranha",
            previewMesh = "mer_fishing\\f\\piranha.nif",
            description = "Пиранья — маленькая хищная рыбка, обитающая в пресных водах Вваррденфелла. Отличается острыми зубами и агрессивным поведением. Пиранья  — грозный хищник, вселяющий страх в сердца рыболовов.",
            speed = 185,
            size = 0.9,
            difficulty = 25,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"tropical"},
                waterType = "freshwater",
                interiors = true,
                exteriors = true,
                maxDepth = 300,
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_tambaqui",
            previewMesh = "mer_fishing\\f\\tambaqui.nif",
            description = "Тамбаки — крупная пресноводная рыба. Благодаря своим внушительным размерам и яркому внешнему виду будоражит воображение рыболовов, ищущих захватывающие испытания.",
            speed = 170,
            size = 2.0,
            difficulty = 43,
            class = "medium",
            habitat = {
                climates = {"tropical"},
                waterType = "freshwater",
                minDepth = 100,
            },
            harvestables = {
                {
                    id = "mer_meat_tambaqui",
                    min = 2,
                    max = 5,
                    isMeat = true,
                }
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_arowana",
            previewMesh = "mer_fishing\\f\\arowana.nif",
            description = "Арована, также известная как костяной язык, редкая рыба, обитающая в пресной воде. Обычно активны в светлое время суток.",
            speed = 175,
            size = 1.1,
            difficulty = 35,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"tropical"},
                waterType = "freshwater",
                times = {
                    "day"
                }
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_angelshark",
            previewMesh = "mer_fishing\\f\\angel.nif",
            description = "Ангельская акула - небольшой, но грозный вид акул, который можно встретить на морских мелководьях Тамриэля. Они наиболее активны ночью.",
            speed = 180,
            size = 2.1,
            class = "large",
            difficulty = 55,
            habitat = {
                climates = {"temperate", "tropical", "swamp"},
                waterType = "saltwater",
                times = { "night" },
                maxDepth = 400,
            },
            harvestables = {
                {
                    id = "mer_meat_angelshark",
                    min = 1,
                    max = 1,
                    isMeat = true,
                }
            },
            heightAboveGround = 40,
        },
        {
            baseId = "mer_fish_marrow",
            previewMesh = "mer_fishing\\f\\marrow.nif",
            description = "Кабачковая рыба – своеобразное существо с выпученными глазами и маслянистым красным телом. Редкость и уникальная среда обитания в пещерах делают ее настоящим открытием для любителей рыбалки. Помимо очаровательного внешнего вида, рыба-кабачок обладает мощными алхимическими свойствами, что делает ее востребованным экземпляром среди практикующих тайные искусства.",
            speed = 180,
            size = 1.8,
            difficulty = 70,
            class = "medium",
            habitat = {
                interiors = true,
                exteriors = false,
            },
            harvestables = {
                {
                    id = "mer_meat_marrow",
                    min = 2,
                    max = 4,
                    isMeat = true,
                },
            },
            hangable = true,
        },
    },
    rare = {
        {
            baseId = "mer_fish_sturgeon",
            previewMesh = "mer_fishing\\f\\sturgeon.nif",
            description = "Осетр - массивная, грозная рыба с длинным, гладким телом и характерным рядом костных пластин вдоль спины. Эти древние существа обитают в пресноводных водоемах, они впечатляют рыболовов своими размерами и силой.",
            speed = 200,
            size = 2.0,
            difficulty = 68,
            class = "large",
            habitat = {
                climates = {"temperate", "arctic"},
                waterType = "freshwater",
                minDepth = 300,
            },
            harvestables = {
                {
                    id = "ab_ingcrea_sturgeonmeat01",
                    min = 3,
                    max = 6,
                    isMeat = true,
                },
                {
                    id = "ab_ingcrea_sturgeonroe",
                    min = 0,
                    max = 1,
                }
            },
            requirements = function(_)
                return tes3.isModActive("OAAB_Data.esm")
            end
        },
        {
            baseId = "mer_fish_discus",
            previewMesh = "mer_fishing\\f\\discus.nif",
            description = "Дискус — привлекательная рыба яркой расцветки, обитающая в реках по всему Тамриэлю. Этот необычный вид придает нотку экзотической красоты водам, в которых обитает, что делает его желанной добычей для рыболовов, ищущих уникальные и привлекательные экземпляры.",
            speed = 170,
            size = 1.0,
            difficulty = 47,
            class = "small",
            isBaitFish = true,
            habitat = {
                climates = {"tropical"},
                waterType = "freshwater",
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_jelly",
            previewMesh = "mer_fishing\\f\\jellyfish.nif",
            description = "Нетч-медуза представляет собой личиночную форму взрослого нетча. Эти интригующие организмы обитают в глубоких океанах и появляются ночью.",
            speed = 100,
            size = 1.2,
            difficulty = 18,
            class = "medium",
            habitat = {
                minDepth = 200,
                waterType = "saltwater",
                times = {
                    "night"
                }
            },
        },

        {
            baseId = "mer_fish_copperscale",
            previewMesh = "mer_fishing\\f\\copper.nif",
            description = "Медночешуйчатая рыба, эксклюзивная для рек Аскадских островов. Ее чешуя пользуюется большим спросом у ремесленников и коллекционеров из-за ее декоративной ценности.",
            speed = 190,
            size = 2.2,
            difficulty = 65,
            class = "medium",
            habitat = {
                waterType = "freshwater",
                regions = {
                    "Ascadian Isles Region",
                }
            },
            harvestables = {
                {
                    id = "mer_ingred_copperscales",
                    min = 2,
                    max = 4,
                },
                {
                    id = "mer_meat_copper",
                    min = 1,
                    max = 2,
                    isMeat = true,
                }
            },
            hangable = true,
        },
        {
            baseId = "mer_fish_marlin",
            previewMesh = "mer_fishing\\f\\marlin.nif",
            description = "Вступить в битву с синим марлином — это свидетельство рыболовного мастерства. Эти мощные и решительные существа, обитающие в глубинах морских вод, окружающих Вварденфелл, демонстрируют силу, скорость и неукротимый дух. Обычно активны в светлое время суток.",
            speed = 260,
            size = 4.4,
            difficulty = 75,
            class = "large",
            habitat = {
                climates = {"temperate", "tropical"},
                waterType = "saltwater",
                minDepth = 300,
                times = { "day" },
            },
            harvestables = {
                {
                    id = "mer_trophy_marlin",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_snapper",
            previewMesh = "mer_fishing\\f\\snapper.nif",
            description = "Луциан, ночной обитатель морских вод Морровинда, имеет бледную кожу, светящуюся в лунном свете. Это редкий улов для рыбаков, но те, кто его попробовал, считают его мясо деликатесом.",
            speed = 190,
            size = 1.4,
            difficulty = 45,
            class = "medium",
            harvestables = {
                {
                    id = "mer_meat_snapper",
                    min = 2,
                    max = 4,
                    isMeat = true,
                }
            },
            habitat = {
                waterType = "saltwater",
                times = { "night" }
            },
            hangable = true,
        },
    },
    legendary = {

        {
            baseId = "mer_fish_shadowfin",
            previewMesh = "mer_fishing\\f\\shadowfin.nif",
            description = "Тенеплавник — загадочная и неуловимая рыба с полупрозрачным телом, которое легко сливается с окружающей средой. Этот вид, обитающий в загадочных реки Самси близ Гнисиса, выходит на охоту исключительно под покровом темноты, бросая вызов ценителям ночной рыбалки.",
            speed = 235,
            size = 1.8,
            difficulty = 77,
            class = "large",
            habitat = {
                times = {
                    "night"
                },
                locations = { "riverSamsi"}
            },
            harvestables = {
                {
                    id = "mer_meat_shadowfin",
                    min = 2,
                    max = 3,
                    isMeat = true,
                },
                {
                    id = "mer_trophy_shadowfin",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            },
            hangable = true,
            alphaSwitch = true,
        },
        {
            baseId = "mer_fish_ashclaw",
            previewMesh = "mer_fishing\\f\\ashclaw.nif",
            description = "Пепельный коготь — крупная и устрашающая рыба с когтеобразными плавниками, обитающая исключительно в озере Набия к северу от Сурана. Ее грозный внешний вид и хищный характер создают устрашающую ауру.",
            speed = 230,
            size = 3.4,
            difficulty = 80,
            class = "large",
            habitat = {
                locations = { "lakeNabia" },
            },
            harvestables = {
                {
                    id = "mer_meat_ashclaw",
                    min = 2,
                    max = 3,
                    isMeat = true,
                },
                {
                    id = "mer_ingred_ashlegs",
                    min = 1,
                    max = 2,
                },
                {
                    id = "mer_trophy_ashclaw",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_iskal",
            previewMesh = "mer_fishing\\f\\iskal.nif",
            description = "Искал - величественная рыба, украшенная ледяной синей чешуей и острыми как бритва шипами. Обитает в холодных водах Шигорада. Выживание в этих суровых условиях демонстрирует стойкость Искала, привлекая внимание рыболовов, ищущих опасные приключения.",
            speed = 245,
            size = 2.4,
            difficulty = 75,
            class = "large",
            habitat = {
                climates = {"arctic"},
            },
            harvestables = {
                {
                    id = "mer_trophy_iskal",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_swampmaw",
            previewMesh = "mer_fishing\\f\\swampmaw.nif",
            description = "Болотная пасть — это колоссальный угорь, скрывающийся в мутных болотах Горького Берега. Обладающая острыми зубами и ненасытным аппетитом, эта хищная рыба охотится на более мелкую рыбу и неосторожных путешественников, рискнувших подойти слишком близко к кромке воды. Огромные размеры и устрашающая репутация делают ее грозным противником для смелых рыболовов.",
            speed = 230,
            size = 3.5,
            difficulty = 90,
            class = "large",
            habitat = {
                climates = {"swamp"},
            },
            harvestables = {
                {
                    id = "mer_meat_swampmaw",
                    min = 3,
                    max = 6,
                    isMeat = true,
                },
                {
                    id = "mer_trophy_swampmaw",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_void",
            previewMesh = "mer_fishing\\f\\void.nif",
            description = "Молотилка Бездны, большая черная рыба с четырьмя огненно-красными глазами, обитает глубоко в подземных пещерах Вварденфелла. Ее темная окраска, напоминающая данмеров, заслужила прозвище «Проклятие Азуры». Этот неуловимый хищник питается пещерными существами и поджидает ничего не подозревающую добычу в самых темных уголках своего подземного царства. Его загадочное присутствие манит искателей приключений исследовать глубины и противостоять тайнам, скрывающимся внутри.",
            speed = 220,
            size = 3.4,
            difficulty = 85,
            class = "large",
            habitat = {
                interiors = true,
                exteriors = false,
            },
            harvestables = {
                {
                    id = "mer_trophy_void",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        },
        {
            baseId = "mer_fish_mega",
            previewMesh = "mer_fishing\\f\\megamax.nif",
            description = "Пестрая челюсть — это грозный океанический зверь, внушающий трепет всем, кто его видит. Обладая огромной челюстью, этот грозный хищник способен выследить даже крупную хищную рыбу. Он предпочитает кормиться в сумеречные часы рассвета и заката на Побережье Азуры, где алый цвет обеспечивает ему маскировку. Погоня за Пестрой челюстью требует от рыболовов предельной силы и умения, поскольку они стремятся покорить одно из самых грозных существ океана.",
            speed = 260,
            size = 4.5,
            difficulty = 95,
            class = "large",
            habitat = {
                waterType = "saltwater",
                regions = {
                    "Azura's Coast Region",
                },
                times = {
                    "dawn",
                    "dusk",
                },
            },
            harvestables = {
                {
                    id = "mer_trophy_megamax",
                    min = 1,
                    max = 1,
                    isTrophy = true,
                }
            }
        }
    }
}

local Ashfall = include("mer.ashfall.interop")
local function doRegister(fishConfig)
    local fishType = Interop.registerFishType(fishConfig)
    if Ashfall then
        local obj = fishType:getBaseObject()
        if obj ~= nil and obj.objectType == tes3.objectType.ingredient then
            logger:debug("Registering %s as meat", obj.id)
            Ashfall.registerFoods{
                [obj.id] = "meat"
            }
        end
    end
    if config.mcm.enableFishTooltips then
        local tooltipsComplete = include("Tooltips Complete.interop")
        if tooltipsComplete then
            if fishType:getBaseObject() then
                --tooltip showing rarity, class, and description
                tooltipsComplete.addTooltip(fishType:getBaseObject().id,  fishType.description)
            end
        end
    end
end

event.register("initialized", function (e)
    for rarity, fishList in pairs(fishConfigs) do
        for _, fish in ipairs(fishList) do
            fish.rarity = rarity
            logger:debug("Registering common fish %s", fish.baseId)
            doRegister(fish)
        end
    end
end)
