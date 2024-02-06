--[[
    Register default fish types
]]
local common = require("mer.fishing.common")
local config = require("mer.fishing.config")
local logger = common.createLogger("Integrations - fishTypes")
local Interop = require("mer.fishing")

---@class FIshing.Integration.FishConfigs
---@field common Fishing.FishType.new.params[]
---@field uncommon Fishing.FishType.new.params[]
---@field rare Fishing.FishType.new.params[]
---@field legendary Fishing.FishType.new.params[]
local fishConfigs = {
    common = {
        {
            baseId = "mer_fish_bass",
            previewMesh = "mer_fishing\\f\\bass.nif",
            description = "Большеротый окунь — хищная рыба среднего размера, широко распространенная в Морровинде. Рыболовов привлекает их впечатляющий боевой дух при ловле на крючок, но именно сочное мясо делает их действительно ценной добычей.",
            speed = 170,
            size = 2.0,
            difficulty = 30,
            class = "medium",
            niche = {
                minDepth = 200,
            },
            harvestables = {
                {
                    id = "mer_meat_bass",
                    min = 1,
                    max = 4,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_goby",
            previewMesh = "mer_fishing\\f\\goby.nif",
            description = "Бычок — маленькая рыбка, которую можно встретить по всему Морровинду в течение дня. Хотя ее размер может быть скромным, она служит отличной приманкой для более крупной добычи, что делает ее фаворитом среди опытных рыболовов.",
            speed = 150,
            size = 1.1,
            difficulty = 20,
            class = "small",
            isBaitFish = true,
            niche = {
                times = { "day" },
            },
        },
        {
            baseId = "mer_fish_salmon",
            previewMesh = "mer_fishing\\f\\salmon.nif",
            description = "Лосось — универсальная рыба, обитающая в океанах, озерах и реках Аскадианских островов и кормящаяся в течение дня. Благодаря своей замечательной способности ориентироваться в различных водоемах они представляют собой захватывающее испытание для рыболовов, ищущих достойный улов.",
            speed = 180,
            size = 1.4,
            difficulty = 40,
            class = "medium",
            niche = {
                regions = {
                    "Ascadian Isles Region",
                },
                times = { "day" },
            },
            harvestables = {
                {
                    id = "mer_meat_salmon",
                    min = 1,
                    max = 3,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_slaughter_l",
            previewMesh = "mer_fishing\\f\\sfish_l.nif",
            description = "Большая рыба-убийца — грозный водный хищник, обитающий на просторах Тамриэля. Вооруженная острыми зубами и спинным плавником, охватывающим все тело, эта агрессивная рыба вселяет страх в сердца тех, кто входит на ее территорию. Хотя ее мясо не аппетитно, чешуя считается деликатесом.",
            speed = 180,
            size = 3.0,
            difficulty = 50,
            class = "large",
            niche = {
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
            description = "Молодые особи рыбы-убийцы могут быть небольшого размера, но обладают удивительной выносливостью и упорством. Даже в раннем возрасте они могут показать энергичную борьбу при встрече с рыболовом.",
            speed = 170,
            size = 1.1,
            difficulty = 25,
            class = "small",
            isBaitFish = true,
            niche = {
                interiors = true,
                exteriors = true,
            },
        },
        {
            baseId = "mer_fish_trigger",
            previewMesh = "mer_fishing\\f\\trigger.nif",
            description = "Спинорог — небольшой тропический вид, часто встречающийся в лазурных водах побережья Азуры. Эти рыбы, известные своим агрессивным поведением и острыми зубами, демонстрируют захватывающее сочетание красоты и свирепости, привлекающее внимание рыболовов.",
            speed = 230,
            size = 1.0,
            difficulty = 15,
            class = "small",
            isBaitFish = true,
            niche = {
                regions = {
                    "Azura's Coast Region",
                },
                times = { "day" },
            },
        },
        {
            baseId = "mer_fish_catfish",
            previewMesh = "mer_fishing\\f\\catfish.nif",
            description = "Сом — небольшая придонная рыба, обитающая в болотах Горького Берега. Имеет на нижней челюсти одну или две пары характерных усиков. Активный ночной хищник. Днём предпочитает отлёживаться на ямах и в коряжнике. Несмотря на то, что сом не отличается агрессивностью, его способность выжить в сложных условиях делают его привлекательной целью для рыболовов, ищущих уникальный и вкусный улов.",
            speed = 160,
            size = 1.0,
            difficulty = 31,
            class = "small",
            isBaitFish = true,
            niche = {
                regions = {
                    "Bitter Coast Region",
                },
                interiors = true,
                exteriors = true
            },
        },
        {
            baseId = "mer_fish_sculpin",
            previewMesh = "mer_fishing\\f\\sculpin.nif",
            description = "Подкаменщик - небольшая рыба, обитающая как в пресной, так и соленой воде. Благодаря своим скромным размерам служит отличной приманкой для охоты на более крупную рыбу. Рыболовы ценят его универсальность и способность привлекать разнообразную промысловую рыбу.",
            speed = 165,
            size = 1.0,
            difficulty = 22,
            class = "small",
            isBaitFish = true,
            niche = {
                times = { "day" },
            },
        },
        {
            baseId = "mer_fish_cod",
            previewMesh = "mer_fishing\\f\\cod.nif",
            description = "Треска — рыба среднего размера, обитающая в более глубоких водах Внутреннего моря. Треска, известная своим восхитительным мясом, является ценной добычей как среди рыболовов, так и среди любителей кулинарии. Плотное белое мясо и мягкий вкус делают ее универсальным ингредиентом в различных блюдах. Погоня за треской представляет собой увлекательный вызов для рыболовов и обещает сытный обед, что делает ее излюбленной целью рыболовных экспедиций.",
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
            niche = {
                minDepth = 200,
                times = { "day" },
            },
        },
        {
            baseId = "mer_fish_snapper",
            previewMesh = "mer_fishing\\f\\snapper.nif",
            description = "Луциан, ночной обитатель вод Морровинда, имеет бледную кожу, светящуюся в лунном свете. Для рыболовов это редкий улов, но те, кто его попробовал, считают его мясо деликатесом.",
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
            niche = {
                minDepth = 200,
                times = {
                    "night"
                }
            },
        },
    },
    uncommon = {
        {
            baseId = "mer_fish_piranha",
            previewMesh = "mer_fishing\\f\\piranha.nif",
            description = "Пиранья — маленькая хищная рыбка, обитающая на мелководье Вваррденфелла. Отличается острыми зубами и агрессивным поведением. Пиранья  — грозный хищник, вселяющий страх в сердца рыболовов.",
            speed = 230,
            size = 0.9,
            difficulty = 25,
            class = "small",
            isBaitFish = true,
            niche = {
                interiors = true,
                exteriors = true,
                maxDepth = 300,
            }
        },
        {
            baseId = "mer_fish_tambaqui",
            previewMesh = "mer_fishing\\f\\tambaqui.nif",
            description = "Тамбаки — крупная тропическая рыба, обитающая вдоль восточного побережья Вварденфелла. Благодаря своим впечатляющим размерам и поразительному внешнему виду этот вид пленяет воображение рыболовов, ищущих захватывающие испытания.",
            speed = 170,
            size = 1.8,
            difficulty = 43,
            class = "medium",
            niche = {
                minDepth = 200,
                regions = {
                    "Grazelands Region",
                    "Azura's Coast Region",
                    "Molag Mar Region",
                }
            },
            harvestables = {
                {
                    id = "mer_meat_tambaqui",
                    min = 2,
                    max = 5,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_arowana",
            previewMesh = "mer_fishing\\f\\arowana.nif",
            description = "Арована, также известная как костистый язык, — редкая рыба, обитающая вдоль побережья Западного Нагорья. Эти неуловимые существа демонстрируют своеобразный способ питания, преимущественно активны в светлое время суток. Их редкость и загадочное поведение делают их очень популярной целью среди рыболовов.",
            speed = 175,
            size = 1.1,
            difficulty = 35,
            class = "small",
            isBaitFish = true,
            niche = {
                regions = {
                    "West Gash Region",
                },
                times = {
                    "day"
                }
            },
        },
        {
            baseId = "mer_fish_angelshark",
            previewMesh = "mer_fishing\\f\\angel.nif",
            description = "Ангельская акула — небольшой, но грозный вид акул, которую можно встретить в водах Вварденфелла. Несмотря на свои размеры, она обладает поразительной внешностью и впечатляющим набором навыков. Ангельская акула сочетает в себе скрытность и силу, что делает ее опытным хищником, способным быстро и эффективно поймать добычу.",
            speed = 180,
            size = 2.1,
            class = "large",
            difficulty = 55,
            niche = {
                times = { "day" },
            },
            harvestables = {
                {
                    id = "mer_meat_angelshark",
                    min = 1,
                    max = 1,
                    isMeat = true,
                }
            }
        },
        {
            baseId = "mer_fish_marrow",
            previewMesh = "mer_fishing\\f\\marrow.nif",
            description = "Кабачковая рыба – своеобразное существо с выпученными глазами и маслянистым красным телом. Редкость и уникальная среда обитания в пещерах делают ее настоящим открытием для любителей рыбалки. Помимо очаровательного внешнего вида, рыба-кабачок обладает мощными алхимическими свойствами, что делает ее востребованным экземпляром среди практикующих тайные искусства.",
            speed = 180,
            size = 1.8,
            difficulty = 70,
            class = "medium",
            niche = {
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
            }
        },
    },
    rare = {
        {
            baseId = "mer_fish_sturgeon",
            previewMesh = "mer_fishing\\f\\sturgeon.nif",
            description = "Осетр — массивная и грозная рыба с длинным гладким телом и характерным рядом костных пластин вдоль спины. Этих древних существ можно встретить как в пресноводных, так и в соленых водоемах, они впечатляют рыболовов своими размерами и силой. Хотя их мясо высоко ценится, именно икра с ее нежным и роскошным вкусом действительно делает осетра ценным деликатесом. Поимка и покорение осетра – свидетельство мастерства и упорства рыболова.",
            speed = 200,
            size = 2.0,
            difficulty = 68,
            class = "large",
            niche = {
                minDepth = 400,
                times = { "day" },
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
        },
        {
            baseId = "mer_fish_discus",
            previewMesh = "mer_fishing\\f\\discus.nif",
            description = "Дискус — привлекательная рыба яркой расцветки, обитающая в теплых регионах Морровинда. Этот необычный вид придает нотку экзотической красоты водам, которые он называет своим домом, что делает его желанной добычей для рыболовов, ищущих уникальные и привлекательные экземпляры.",
            speed = 200,
            size = 1.0,
            difficulty = 47,
            class = "small",
            isBaitFish = true,
            niche = {
                times = { "day" },
                regions = {
                    "Ascadian Isles Region",
                    "Azura's Coast Region",
                }
            },
        },
        {
            baseId = "mer_fish_jelly",
            previewMesh = "mer_fishing\\f\\jellyfish.nif",
            description = "Желейный нетч представляет собой личиночную форму взрослого нетча. Эти интригующие организмы обитают в глубоких водах и появляются ночью. Их присутствие представляет собой захватывающую встречу для рыболовов, которые ценят чудеса водных экосистем Морровинда.",
            speed = 100,
            size = 1.2,
            difficulty = 18,
            class = "medium",
            niche = {
                minDepth = 350,
                times = {
                    "night"
                }
            },
        },

        {
            baseId = "mer_fish_copperscale",
            previewMesh = "mer_fishing\\f\\copper.nif",
            description = "Медночешуйчатая рыба, эксклюзивная для Аскадских островов. Представляет собой рыбу, пользующуюся большим спросом благодаря чешуе, которую ценят ремесленники и коллекционеры из-за ее декоративной ценности.",
            speed = 200,
            size = 2.2,
            difficulty = 65,
            class = "medium",
            niche = {
                minDepth = 200,
                interiors = true,
                exterios = true,
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
            }
        },
        {
            baseId = "mer_fish_marlin",
            previewMesh = "mer_fishing\\f\\marlin.nif",
            description = "Вступить в битву с синим марлином — это свидетельство рыболовного мастерства. Эти мощные и решительные существа, обитающие в глубоких морских водах, окружающих Вварденфелл, демонстрируют силу, скорость и неукротимый дух. Ловля синего марлина требует как умения, так и физической силы, а залогом успеха является живая наживка.",
            speed = 230,
            size = 4.4,
            difficulty = 75,
            class = "large",
            niche = {
                minDepth = 500,
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
        }
    },
    legendary = {
        {
            baseId = "mer_fish_shadowfin",
            previewMesh = "mer_fishing\\f\\shadowfin.nif",
            description = "Тенеплавник — загадочная и неуловимая рыба с полупрозрачным телом, которое легко сливается с окружающей средой. Этот вид, обитающий в загадочных водах Западного Нагорья, выходит на охоту исключительно под покровом темноты, бросая вызов ценителям ночной рыбалки.",
            speed = 210,
            size = 1.8,
            difficulty = 77,
            class = "large",
            niche = {
                times = {
                    "night"
                },
                regions = {
                    "West Gash Region"
                },
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
            }
        },
        {
            baseId = "mer_fish_ashclaw",
            previewMesh = "mer_fishing\\f\\ashclaw.nif",
            description = "Пепельный коготь — крупная и устрашающая рыба с когтеобразными плавниками, обитающая в озере Набия и других водах Молаг-Амура. Грозный внешний вид и хищный характер создают ауру страха, привлекающую тех, кто осмелится потревожить ее суровую среду обитания.",
            speed = 200,
            size = 3.4,
            difficulty = 80,
            class = "large",
            niche = {
                regions = {
                    "Molag Mar Region",
                },
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
            speed = 230,
            size = 2.8,
            difficulty = 75,
            class = "large",
            niche = {
                regions = {
                    "Sheogorad",
                },
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
            speed = 200,
            size = 3.7,
            difficulty = 90,
            class = "large",
            niche = {

                regions = {
                    "Bitter Coast Region",
                },
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
            speed = 200,
            size = 3.5,
            difficulty = 85,
            class = "large",
            niche = {
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
            description = "Мегамаксилла, известная в народе как «Мегачелюсть», — это грозный океанический зверь, внушающий трепет всем, кто его видит. Обладая огромной челюстью, этот грозный хищник способен выследить даже крупную хищную рыбу. Он предпочитает кормиться в сумеречные часы рассвета и заката на Побережье Азуры, где алый цвет обеспечивает ему маскировку. Погоня за мегамаксиллом требует от рыболовов предельной силы и умения, поскольку они стремятся покорить одно из самых грозных существ океана.",
            speed = 210,
            size = 4.5,
            difficulty = 95,
            class = "large",
            niche = {
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
        if obj.objectType == tes3.objectType.ingredient then
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
