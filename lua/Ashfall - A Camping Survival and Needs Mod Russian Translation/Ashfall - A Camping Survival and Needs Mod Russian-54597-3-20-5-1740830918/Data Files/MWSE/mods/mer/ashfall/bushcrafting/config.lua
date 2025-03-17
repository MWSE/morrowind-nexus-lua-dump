---@class Ashfall.Bushcrafting.config
local this = {}
local tentConfig = require("mer.ashfall.items.tents.tentConfig")
local itemDescriptions = require("mer.ashfall.config.itemDescriptions")
local BedRoll = require("mer.ashfall.items.bedroll")
local WaterFilter = require("mer.ashfall.items.waterFilter")
local CrabPot = require("mer.ashfall.items.crabpot")
local WoodStack = require("mer.ashfall.items.woodStack")
local Workbench = require("mer.ashfall.items.workbench")
local Planter = require("mer.ashfall.items.planter.Planter")
local Material = require("CraftingFramework").Material
local config = require("mer.ashfall.config").config
local common = require("mer.ashfall.common.common")
local logger = common.createLogger("bushcraftingconfig")

---@type table<string, CraftingFramework.SkillRequirement.data>
this.survivalTiers = {
    beginner = { skill = "Bushcrafting", requirement = 10 },
    novice = { skill = "Bushcrafting", requirement = 20 },
    apprentice = { skill = "Bushcrafting", requirement = 30 },
    journeyman = { skill = "Bushcrafting", requirement = 40 },
    expert = { skill = "Bushcrafting", requirement = 60 },
    master = { skill = "Bushcrafting", requirement = 80 },
    grandmaster = { skill = "Bushcrafting", requirement = 100 },
}

---@class Ashfall.Bushcrafting.customrequirements
---@field outdoorsOnly CraftingFramework.CustomRequirement.data
---@field wildernessOnly CraftingFramework.CustomRequirement.data
---@field workbenchNearby CraftingFramework.CustomRequirement.data
this.customRequirements = {
    outdoorsOnly = {
        getLabel = function()
            return "Улица"
        end,
        check = function()
            local cell = tes3.player.cell
            local isOutdoors = (not cell.isInterior)
                or cell.behavesAsExterior
            local canCampIndoors = config.canCampIndoors
            if isOutdoors or canCampIndoors then
                return true
            else
                return false, "Для изготовления этого предмета вы должны находиться на открытом воздухе."
            end
        end
    },
    wildernessOnly = {
        getLabel = function()
            return "Дикая местность"
        end,
        check = function()
            local cell = tes3.player.cell
            local isWilderness = not cell.restingIsIllegal
            local canCampInSettlements = config.canCampInSettlements
            if isWilderness or canCampInSettlements then
                return true
            else
                return false, "Для изготовления этого предмета вы должны находиться за пределами городов/поселений."
            end
        end
    },
    workbenchNearby = {
        getLabel = function()
            return "Верстак"
        end,
        check = Workbench.isNearby
    }
}

---@type CraftingFramework.Tool.data[]
this.tools = {
    {
        id = "knife",
        name = "Нож",
        requirement = function(itemStack)
            return itemStack.object.objectType == tes3.objectType.weapon
            and itemStack.object.type == tes3.weaponType.shortBladeOneHand
        end,
    },
    {
        id = "chisel",
        name = "Долото",
        ids = {
            "ashfall_chisel_flint",
            "ab_misc_chiselcold",
            "ab_misc_chiselhot",
            "t_com_chisel_01",
            "t_com_chisel_02",
            "t_com_chisel_03",
        },
    },
    {
        id = "hammer",
        name = "Ремонтный молоток",
        requirement = function(itemStack)
            local isRepairItem = itemStack.object.objectType == tes3.objectType.repairItem
            local isHammer = itemStack.object.id:lower():find("hammer") ~= nil
            return isRepairItem and isHammer
        end,
    }
}


this.categories = {
    beds = "Кровати",
    containers = "Контейнеры",
    furniture = "Мебель",
    materials = "Материалы",
    other = "Другое",
    survival = "Выживание",
    structures = "Сооружения",
    equipment = "Экипировка",
    cutlery = "Столовые приборы",
    utensils = "Посуда",
    tools = "Инструменты",
    weapons = "Оружие",
    planters = "Клумбы"
}

this.tanningRacks = {
    "furn_ex_ashl_guarskin"
}

--Do common ingred ids first so they have priority
---@type table<string, craftingFrameworkMenuButtonData>
this.menuOptions = {
    tanningRackMenu = {
        text = "Использовать",
        callback = function()
            event.trigger("Ashfall:ActivateTanningRack")
        end
    },
    rename = {
        text = "Переименовать",
        ---@param e craftingFrameworkMenuButtonData.callbackParams`
        callback = function(e)
            local menuID = "RenameMenu"
            local menu = tes3ui.createMenu{ id = menuID, fixedFrame = true }
            menu.minWidth = 400
            menu.childAlignX = 0.5
            menu.childAlignY = 0
            menu.autoHeight = true
            local textField = mwse.mcm.createTextField(
                menu,
                {
                    label = string.format("Название %s:", e.reference.object.name),
                    variable = mwse.mcm.createTableVariable{
                        id = 'customName',
                        table = e.reference.data
                    },
                    callback = function()
                        e.reference.object.name = e.reference.data.customName
                        e.reference.modified = true
                        tes3ui.leaveMenuMode()
                        tes3ui.findMenu(menuID):destroy()
                        tes3.messageBox("Переименованно в %s", e.reference.data.customName)
                    end
                }
            )
            tes3ui.acquireTextInput(textField.elements.inputField)
            tes3ui.enterMenuMode(menuID)
        end
    },
    workbenchMenu = {
        text = "Использовать",
        callback = function()
            event.trigger("Ashfall:ActivateWorkbench")
        end
    },
    realisticRepair = {
        text = "Ремонт",
        showRequirements = function(e)
            --check realistic repair is installed
            local realisticRepair = include("mer.RealisticRepair.interop")
            return realisticRepair ~= nil
        end,
        enableRequirements = function()
            --check player has a repair tool
            ---@param stack tes3itemStack
            for _, stack in pairs(tes3.player.object.inventory) do
                if stack.object.objectType == tes3.objectType.repairItem then
                    return true
                end
            end
            return false
        end,
        ---@diagnostic disable-next-line: missing-fields
        tooltipDisabled = {
            text = "Вам нужен инструмент для ремонта предметов.",
        },
        callback = function(e)
            --Refactor Realistic Repair
        end
    }
}

---@type CraftingFramework.Material.data[]
this.materials = {
    {
        id = "sack",
        name = "Пустой мешок",
        ids = {
            "ashfall_sack_01"
        }
    },
    {
        id = "resin",
        name = "Смола",
        ids = {
            "ingred_resin_01",
            "ingred_shalk_resin_01",
            "t_ingcrea_beetleresin_01",
            "t_ingcrea_yethresin_01",
            "ab_ingflor_telvanniresin",
            "t_ingcrea_beetleresin_01",
            "t_ingcrea_yethresin_01",

        }
    },
    {
        id = "wood",
        name = "Дерево",
        ids = {"ashfall_firewood"}
    },
    {
        id = "stone",
        name = "Камень",
        ids = {"ashfall_stone"}
    },
    {
        id = "hide",
        name = "Шкура животного",
        ids = {
            "ingred_alit_hide_01",
            "ingred_guar_hide_01",
            "ingred_kagouti_hide_01",
            "ingred_netch_leather_01",
            "ingred_boar_leather",
            "ingred_scamp_skin_01",
        }
    },
    {
        id = "leather",
        name = "Кожа",
        ids = {
            "ashfall_leather",
        }
    },
    {
        id = "fibre",
        name = "Волокно",
        ids = { "ashfall_plant_fibre" }
    },
    {
        id = "rope",
        name = "Веревка",
        ids = {
            "ashfall_rope",
            "t_de_coiledrope_01",
        }
    },
    {
        --straw
        id = "straw",
        name = "Солома",
        ids = { "ashfall_straw" }
    },
    {
        id = "fabric",
        name = "Ткань",
        ids = {
            "ashfall_fabric",
            "misc_de_cloth10",
            "misc_de_cloth11",
            "t_com_clothbrown_01",
            "t_com_clothgreen_01",
            "t_com_clothplain_01",
            "t_com_clothplain_02",
            "t_com_clothpurple_01",
            "t_com_clothrag_01",
            "t_com_clothrag_02",
            "t_com_clothred_01",
            "t_com_clothyellow_01",
            "t_com_clothplain_01",
            "t_com_clothplainfolded_01",
            "t_com_clothgreenfolded_01",
            "t_com_clothredfolded_01",
            "t_com_clothred_01",
            "t_com_clothplain_01",
        }
    },
    {
        id = "flint",
        name = "Кремень",
        ids = {
            "ashfall_flint",
        },
    },
    {
        id = "fur",
        name = "Мех",
        ids = {
            "ingred_bear_pelt",
            "ingred_wolf_pelt",
        }
    },
    {
        id = "pillow",
        name = "Подушка",
        ids = {
            "ashfall_cush_crft_01",
            "ab_misc_depillowl_02",
            "misc_uni_pillow_02",
            "ab_misc_depillowl_02",
        }
    },
    {
        id = "coal",
        name = "Уголь",
        ids = {
            "ashfall_ingred_coal_01"
        }
    },
    {
        id = "netting",
        name = "Сеть",
        ids = {
            "ashfall_netting"
        }
    },
    {
        id = "raw_glass",
        name = "Стекло-сырец",
        ids = {
            "ingred_raw_glass_01"
        }
    },
    {
        id = "paper",
        name = "Бумага",
        ids = {
            "sc_paper plain",
        }
    },
}
this.ingredMaterials = {}
for name, ingredient in pairs(this.materials) do
    if ingredient.ids then
        for _, id in ipairs(ingredient.ids) do
            this.ingredMaterials[id] = name
        end
    end
end

---@class Ashfall.bushcrafting.recipeConfiguration
---@field commonFields? table
---@field beginner CraftingFramework.Recipe.data[]
---@field novice CraftingFramework.Recipe.data[]
---@field apprentice CraftingFramework.Recipe.data[]
---@field journeyman CraftingFramework.Recipe.data[]
---@field expert CraftingFramework.Recipe.data[]
---@field master CraftingFramework.Recipe.data[]

---@class Ashfall.bushcrafting.MenuActivator.data : CraftingFramework.MenuActivator.data
---@field recipes? Ashfall.bushcrafting.recipeConfiguration

---@class Ashfall.bushcrafting.MenuActivatorConfig
---@field menuActivator Ashfall.bushcrafting.MenuActivator.data
---@field recipeLists Ashfall.bushcrafting.recipeConfiguration[]

---@type Ashfall.bushcrafting.recipeConfiguration
local materialRecipes = {
    beginner = {
        {
            id = "bushcraft:ashfall_rope",
            craftableId = "ashfall_rope",
            description = itemDescriptions.ashfall_rope,
            materials = {
                { material = "fibre", count = 2 }
            },
            category = this.categories.materials,
            soundType = "rope",
        },

        {
            --Straw
            id = "bushcraft:ashfall_straw",
            craftableId = "ashfall_straw",
            description = itemDescriptions.ashfall_straw,
            materials = {
                { material = "fibre", count = 1 }
            },
            category = this.categories.materials,
            soundType = "straw",
        },
    },
    novice = {
        {
            id = "bushcraft:ashfall_fabric",
            craftableId = "ashfall_fabric",
            description = itemDescriptions.ashfall_fabric,
            materials = {
                { material = "fibre", count = 4 },
            },
            category = this.categories.materials,
            soundType = "fabric",
            rotationAxis = 'y',
        },
    },
    apprentice = {},
    journeyman = {
        {
            id = "bushcraft:ashfall_netting",
            craftableId = "ashfall_netting",
            description = "Сеть сплетенная из веревки.",
            materials = {
                { material = "rope", count = 2 },
            },
            rotationAxis = 'y',
            category = this.categories.materials,
            soundType = "rope",
        },
    },
    expert = {},
    master = {}
}

---@type Ashfall.bushcrafting.recipeConfiguration
local bushCraftingRecipes = {
    beginner = {
        {
            id = "bushcraft:ashfall_torch",
            craftableId = "ashfall_torch",
            description = itemDescriptions.ashfall_torch,
            materials = {
                { material = "resin", count = 1 },
                { material = "wood", count = 1 }
            },
            category = this.categories.other,
            soundType = "wood",
        },
        {
            id = "bushcraft:ashfall_torch_lrg",
            craftableId = "ashfall_torch_lrg",
            name = "Большой факел",
            description = "Большой факел для освещения вашего лагеря.",
            materials = {
                { material = "resin", count = 2 },
                { material = "wood", count = 2 }
            },
            category = this.categories.other,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            }
        },
        {
            id = "bushcraft:ashfall_strawbed_s",
            craftableId = "ashfall_strawbed_s",
            quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
            additionalMenuOptions = {
                BedRoll.buttons.sleep,
                BedRoll.buttons.layDown,
            },
            maxSteepness = 0,
            description = "Простая соломенная кровать. Не очень удобная, но это лучше, чем спать на земле.",
            materials = {
                { material = "straw", count = 10 },
                { material = "wood", count = 4 },
                { material = "rope", count = 1 },

            },
            category = this.categories.beds,
            soundType = "straw",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
        },
        {
            id = "bushcraft:ashfall_wood_stack",
            craftableId = "ashfall_wood_stack",
            description = "Деревянный каркас для хранения большого количества дров. Дрова, хранящиеся в ближайшем штабеле, можно использовать для ремесла.",
            materials = {
                { material = "wood", count = 10 }
            },
            category = this.categories.structures,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
            additionalMenuOptions = {
                WoodStack.buttons.addWood,
                WoodStack.buttons.takeWood,
            },
            destroyCallback = WoodStack.destroyCallback,
        },
        {
            --Lean To
            id = "bushcraft:ashfall_lean_to_01",
            craftableId = "ashfall_lean_to_01",
            description = "Простой навес обеспечивает небольшое укрытие от непогоды.",
            materials = {
                { material = "straw", count = 8 },
                { material = "rope", count = 1 },
                { material = "wood", count = 12 },
            },
            category = this.categories.structures,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            }
        },
        {
            id = "bushcraft:ashfall_knife_flint",
            craftableId = "ashfall_knife_flint",
            description = "Простой клинок из кремня. Пригодится для снятия шкуры с животных и сбора растительных волокон.\n\nПримечание: сломанные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "flint", count = 1 },
                { material = "wood", count = 1 },
            },
            category = this.categories.tools,
            soundType = "wood",
            recoverEquipmentMaterials = true,
        },
        {
            id = "bushcraft:ashfall_chisel_flint",
            craftableId = "ashfall_chisel_flint",
            description = "Экипируйте долото, чтобы активировать меню резьбы. \n\nПримечание: сломанные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "flint", count = 1 },
                { material = "wood", count = 1 },
            },
            category = this.categories.tools,
            soundType = "wood",
            recoverEquipmentMaterials = true,
        },
        {
            id = "bushcraft:ashfall_hammer_stone",
            craftableId = "ashfall_hammer_stone",
            description = "Молоток из камня. Можно использовать для долбления камня, а также для простого ремонта.  \n\nПримечание: сломанные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "stone", count = 1 },
                { material = "wood", count = 1 },
                { material = "rope", count = 1 },
            },
            category = this.categories.tools,
            soundType = "wood",
            recoverEquipmentMaterials = true,
            rotationAxis = 'y'
        },
        {
            id = "bushcraft:ashfall_pickaxe_flint",
            craftableId = "ashfall_pickaxe_flint",
            description = "Кирка из кремня. Можно использовать для добычи камня.\n\nПримечание: сломанные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "flint", count = 1 },
                { material = "wood", count = 1 },
                { material = "rope", count = 2 },
            },
            category = this.categories.tools,
            soundType = "wood",
            recoverEquipmentMaterials = true,
        },
        {
            id = "bushcraft:ashfall_woodaxe_flint",
            craftableId = "ashfall_woodaxe_flint",
            description = "Топор из кремня. Можно использовать для заготовки дров.\n\nПримечание: сломанные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "flint", count = 2 },
                { material = "wood", count = 1 },
                { material = "rope", count = 1 },
            },
            category = this.categories.tools,
            soundType = "wood",
            recoverEquipmentMaterials = true,
        },
    },
    novice = {
        {
            id = "bushcraft:AB_alc_HealBandage01",
            craftableId = "AB_alc_HealBandage01",
            description = "Повязка из ткани и смолы. Может использоваться для заживления небольших ран.",
            materials = {
                { material = "fabric", count = 1 },
                { material = "resin", count = 2 },
            },
            category = this.categories.survival,
            soundType = "fabric",
        },
        {
            id = "bushcraft:ashfall_planter_01",
            craftableId = "ashfall_planter_01",
            description = "Небольшая деревянная клумба для выращивания растений.",
            materials = {
                { material = "wood", count = 4 },
                { material = "rope", count = 2 },
            },
            category = this.categories.planters,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
            additionalMenuOptions = {
                Planter.buttons.harvest,
                Planter.buttons.plantSeed,
                Planter.buttons.water,
                Planter.buttons.removePlant,
            },
            placeCallback = Planter.placeCallback,
            positionCallback = Planter.placeCallback,
            destroyCallback = Planter.destroyCallback,
            maxSteepness = 15,
        },
        {
            id = "bushcraft:ashfall_planter_02",
            craftableId = "ashfall_planter_02",
            description = "Средняя деревянная клумба для выращивания растений.",
            materials = {
                { material = "wood", count = 6 },
                { material = "rope", count = 2 },
            },
            category = this.categories.planters,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
            additionalMenuOptions = {
                Planter.buttons.harvest,
                Planter.buttons.plantSeed,
                Planter.buttons.water,
                Planter.buttons.removePlant,
            },
            placeCallback = Planter.placeCallback,
            positionCallback = Planter.placeCallback,
            destroyCallback = Planter.destroyCallback,
            maxSteepness = 15,
        },
        {
            id = "bushcraft:ashfall_water_filter",
            craftableId = "ashfall_water_filter",
            description = "Фильтр для очистки воды, в котором используются растительные волокна и уголь.",
            materials = {
                { material = "fibre", count = 4 },
                { material = "coal", count = 4 },
                { material = "rope", count = 2 },
                { material = "wood", count = 3 },
                { material = "ashfall_bowl_01", count = 1}
            },
            category = this.categories.structures,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
            maxSteepness = 0,
            additionalMenuOptions = {
                WaterFilter.buttons.filterWater,
                WaterFilter.buttons.collectWater,
            }
        },
        {
            id = "bushcraft:ashfall_fab_cloak",
            craftableId = "ashfall_fab_cloak",
            previewMesh = "ashfall\\craft\\cloak_fab_preview.nif",
            description = itemDescriptions.ashfall_fab_cloak,
            materials = {
                { material = "fabric", count = 6 },
            },
            category = this.categories.equipment,
            soundType = "fabric",
            recoverEquipmentMaterials = true,
        },
        {
            id = "bushcraft:ashfall_strawhat",
            craftableId = "ashfall_strawhat",
            description = itemDescriptions.ashfall_strawhat,
            materials = {
                { material = "straw", count = 4 }
            },
            category = this.categories.equipment,
            soundType = "straw",
            recoverEquipmentMaterials = true,
            previewMesh = "ashfall\\craft\\strawhat.nif",
        },
        {
            --ashfall_cush_crft_01 cushion
            id = "bushcraft:ashfall_cush_crft_01",
            craftableId = "ashfall_cush_crft_01",
            description = itemDescriptions.ashfall_cush_crft_01,
            materials = {
                { material = "fabric", count = 2 },
                { material = "straw", count = 4 }
            },
            category = this.categories.other,
            soundType = "fabric",
        },
        {
            id = "bushcraft:ashfall_sack_01",
            craftableId = "ashfall_sack_01",
            placedObject = "ashfall_sack_c",
            description = itemDescriptions.ashfall_sack_01,
            materials = {
                { material = "rope", count = 1 },
                { material = "fabric", count = 2 },
            },
            category = this.categories.containers,
            soundType = "fabric",
            additionalMenuOptions = {
                this.menuOptions.rename
            },
            containerConfig = {
                capacity = 100,
                hasCollision = true,
                onCopyCreated = function(self, data)
                    logger:debug("Registering new sack as material: %s", data.copy.id)
                    Material:new{
                        id = "sack",
                        name = "Пустой мешок",
                        ids = { data.copy.id:lower() }
                    }
                    common.data.sacks[data.copy.id:lower()] = true
                end
            },
        },
        {
            id = "bushcraft:ashfall_rug_crft_01",
            craftableId = "ashfall_rug_crft_01",
            description = itemDescriptions.ashfall_rug_crft_01,
            materials = {
                { material = "fabric", count = 2 },
            },
            category = this.categories.other,
            soundType = "fabric",
            rotationAxis = 'y',
        },
        {
            id = "bushcraft:ashfall_spear_flint",
            craftableId = "ashfall_spear_flint",
            description = "Деревянное копье с кремневым наконечником. Пригодится для охоты.\n\nПримечание: сломанные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "flint", count = 1 },
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
            },
            category = this.categories.weapons,
            soundType = "wood",
            recoverEquipmentMaterials = true,
        },
        {
            id = "bushcraft:ashfall_walking_stick",
            craftableId = "ashfall_walking_stick",
            description = "Простая трость, которую можно держать в свободной руке или двумя руками как посох. При экипировке повышает навык атлетики. \n\nПримечание: сломанные инструменты и оружие можно разобрать на запчасти, экипировав их",
            materials = {
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
            },
            category = this.categories.weapons,
            soundType = "wood",
            recoverEquipmentMaterials = true,
            rotationAxis = 'y',
        },
        {
            id = "bushcraft:ashfall_bow_wood",
            craftableId = "ashfall_bow_wood",
            description = "Простой деревянный лук и колчан.\n\nПримечание: сломанные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "wood", count = 3 },
                { material = "rope", count = 3 },
            },
            category = this.categories.weapons,
            soundType = "wood",
            recoverEquipmentMaterials = true,
            previewScale = 1.2,
        },
        {
            id = "bushcraft:ashfall_arrow_flint",
            craftableId = "ashfall_arrow_flint",
            description = "Простая стрела с кремневым наконечником.",
            materials = {
                { material = "flint", count = 1 },
                { material = "wood", count = 1 },
            },
            category = this.categories.weapons,
            soundType = "wood",
            resultAmount = 10,
        },
        {
            id = "bushcraft:ashfall_table_sml_s",
            craftableId = "ashfall_table_sml_s",
            description = "Высокий, грубый деревянный стол",
            materials = {
                { material = "wood", count = 4 },
                { material = "rope", count = 2 }
            },
            category = this.categories.furniture,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
            scale = 1.1,
        },
        {
            id = "bushcraft:ashfall_table_sml_2_s",
            craftableId = "ashfall_table_sml_2_s",
            description = "Длинный, грубый деревянный стол",
            materials = {
                { material = "wood", count = 6 },
                { material = "rope", count = 2 }
            },
            category = this.categories.furniture,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
            scale = 1.3,
        },
    },
    apprentice = {
        {
            id = "bushcraft:ashfall_satchel_01",
            craftableId = "ashfall_satchel_01",
            description = itemDescriptions.ashfall_satchel_01,
            materials = {
                { material = "leather", count = 1 },
                { material = "fabric", count = 2 },
            },
            category = this.categories.containers,
            soundType = "fabric",
            additionalMenuOptions = {
                this.menuOptions.rename
            },
            containerConfig = {
                capacity = 100,
                weightModifier = 0.8,
                filter = "ingredients"
            },
        },
        {
            id = "bushcraft:ashfall_scrollbag_01",
            craftableId = "ashfall_scrollbag_01",
            description = itemDescriptions.ashfall_scrollbag_01,
            materials = {
                { material = "leather", count = 1 },
                { material = "fabric", count = 2 },
            },
            category = this.categories.containers,
            soundType = "fabric",
            additionalMenuOptions = {
                this.menuOptions.rename
            },
            containerConfig = {
                capacity = 50,
                weightModifier = 0.6,
                filter = "magicScrolls"
            },
        },
        {
            id = "bushcraft:ashfall_gem_pouch_01",
            craftableId = "ashfall_gem_pouch_01",
            description = itemDescriptions.ashfall_gem_pouch_01,
            materials = {
                { material = "rope", count = 1 },
                { material = "fabric", count = 2 },
            },
            category = this.categories.containers,
            soundType = "fabric",
            additionalMenuOptions = {
                this.menuOptions.rename
            },
            containerConfig = {
                capacity = 60,
                weightModifier = 0.8,
                filter = "soulGems"
            },
        },
        {
            id = "bushcraft:ashfall_trinket_box_01",
            craftableId = "ashfall_trinket_box_01",
            description = itemDescriptions.ashfall_trinket_box_01,
            materials = {
                { material = "straw", count = 5 },
                { material = "rope", count = 2 },
            },
            category = this.categories.containers,
            soundType = "straw",
            additionalMenuOptions = {
                this.menuOptions.rename
            },
            scale = 0.4,
            containerConfig = {
                capacity = 50,
                weightModifier = 0.6,
                filter = "jewelry",
            },
        },
        {
            --documents case
            id = "bushcraft:ashfall_notebook_01",
            craftableId = "ashfall_notebook_01",
            description = itemDescriptions.ashfall_notebook_01,
            materials = {
                { material = "leather", count = 2 },
                { material = "resin", count = 2 },
            },
            category = this.categories.containers,
            soundType = "leather",
            additionalMenuOptions = {
                this.menuOptions.rename
            },
            containerConfig = {
                capacity = 25,
                weightModifier = 0.5,
                filter = "nonMagicScrolls"
            },
        },
        {
            id = "bushcraft:ashfall_potion_box_01",
            craftableId = "ashfall_potion_box_01",
            description = itemDescriptions.ashfall_potion_box_01,
            materials = {
                { material = "wood", count = 4 },
            },
            category = this.categories.containers,
            soundType = "wood",
            additionalMenuOptions = {
                this.menuOptions.rename
            },
            containerConfig = {
                capacity = 50,
                weightModifier = 0.7,
                filter = "potions"
            },
            hasCollision = true,
        },
        {
            --workbench
            id = "bushcraft:ashfall_workbench_01",
            name = "Верстак",
            craftableId = "ashfall_workbench_01",
            description = itemDescriptions.ashfall_workbench_01,
            materials = {
                { material = "wood", count = 20 }
            },
            category = this.categories.structures,
            soundType = "wood",
            additionalMenuOptions = {
                this.menuOptions.workbenchMenu,
                --this.menuOptions.realisticRepair,
            }
        },
        {
            --bedroll
            id = "bushcraft:ashfall_bedroll",
            craftableId = "ashfall_bedroll",
            description = itemDescriptions.ashfall_bedroll,
            materials = {
                { material = "fabric", count = 4 },
                { material = "straw", count = 10 },
            },
            category = this.categories.beds,
            soundType = "fabric",
        },
        {
            --tanning rack
            id = "bushcraft:ashfall_tan_rack",
            craftableId = "ashfall_tan_rack",
            description = "Стойка для дубления шкур с целью получения кожи.",
            quickActivateCallback = function(_, e) this.menuOptions.tanningRackMenu.callback() end,
            additionalMenuOptions = {
                this.menuOptions.tanningRackMenu
            },
            materials = {
                { material = "wood", count = 4 },
                { material = "rope", count = 2 },
            },
            category = this.categories.structures,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
            craftedOnly = false,
        },
        {
            id = "bushcraft:ashfall_waterskin",
            craftableId = "ashfall_waterskin",
            description = itemDescriptions.ashfall_waterskin,
            materials = {
                { material = "leather", count = 1 },
                { material = "resin", count = 1 }
            },
            category = this.categories.other,
            soundType = "leather",
            rotationAxis = 'y',
        },
        {
            id = "bushcraft:ashfall_tent_leather_m",
            craftableId = "ashfall_tent_leather_m",
            description = itemDescriptions.ashfall_tent_leather_m,
            materials = {
                { material = "leather", count = 4 },
                { material = "wood", count = 6 },
                { material = "rope", count = 2 },
            },
            category = this.categories.survival,
            soundType = "leather",
            previewMesh = "ashfall\\tent\\tent_leather.nif"
        },
        {
            --Wicker backpack
            id = "bushcraft:ashfall_pack_07",
            craftableId = "ashfall_pack_07",
            description = itemDescriptions.ashfall_pack_07,
            materials = {
                { material = "wood", count = 3 },
                { material = "rope", count = 2 },
                { material = "straw", count = 10 },
            },
            category = this.categories.equipment,
            soundType = "straw",
            rotationAxis = 'x',
        },
        {
            id = "bushcraft:ashfall_chest_01_c",
            craftableId = "ashfall_chest_01_c",
            description = "Маленький деревянный сундук, который можно установить на землю и использовать в качестве хранилища.",
            materials = {
                { material = "wood", count = 6 },
                { material = "rope", count = 2 }
            },
            category = this.categories.containers,
            soundType = "wood",
            customRequirements = {
                this.customRequirements.wildernessOnly
            },
            additionalMenuOptions = {
                this.menuOptions.rename
            },
        },
        {
            id = "bushcraft:ashfall_shoji_lamp_01",
            craftableId = "ashfall_shoji_lamp_01",
            description = "Фонарь из бумаги и дерева.",
            materials = {
                { material = "wood", count = 2 },
                { material = "paper", count = 2 },
                { material = "resin", count = 1 }
            },
            category = this.categories.survival,
            soundType = "wood",
        }
    },
    journeyman = {
        {
            id = "bushcraft:ashfall_basket_01",
            craftableId = "ashfall_basket_01",
            description = "Маленькая плетеная корзина.",
            materials = {
                { material = "straw", count = 8 },
                { material = "rope", count = 1 }
            },
            category = this.categories.containers,
            soundType = "straw",
            additionalMenuOptions = {
                this.menuOptions.rename
            },
        },
        {
            id = "bushcraft:ashfall_tent_base_m",
            craftableId = "ashfall_tent_base_m",
            description = "Простая палатка из ткани",
            materials = {
                { material = "fabric", count = 4 },
                { material = "wood", count = 6 },
                { material = "rope", count = 2 },
            },
            category = this.categories.survival,
            soundType = "fabric",
            previewMesh = "ashfall\\tent\\tent_base.nif"
        },
        {
            id = "bushcraft:ashfall_cov_thatch",
            craftableId = "ashfall_cov_thatch",
            previewMesh = tentConfig.coverToMeshMap["ashfall_cov_thatch"],
            description = itemDescriptions.ashfall_cov_thatch,
            materials = {
                { material = "wood", count = 4 },
                { material = "rope", count = 1 },
                { material = "straw", count = 10 },
                { material = "leather", count = 2 },
            },
            category = this.categories.survival,
            soundType = "straw",
        },

        {
            id = "bushcraft:ashfall_pack_04",
            craftableId = "ashfall_pack_04",
            description = itemDescriptions.ashfall_pack_04,
            materials = {
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
                { material = "sack", count = 1 },
                { material = "leather", count = 1 },
                { material = "netting", count = 1 },
            },
            category = this.categories.equipment,
            soundType = "wood",
        },
        {
            id = "bushcraft:ashfall_crabpot_02_a",
            craftableId = "ashfall_crabpot_02_a",
            description = itemDescriptions.ashfall_crabpot_01_m,
            materials = {
                { material = "wood", count = 4 },
                { material = "rope", count = 1 },
                { material = "netting", count = 2 },
            },
            category = this.categories.structures,
            soundType = "wood",
            quickActivateCallback = function(_, e) CrabPot.buttons.collect.callback(e) end,
            additionalMenuOptions = {
                CrabPot.buttons.collect,
            },
            previewScale = 4,
            previewHeight = -80
        },
    },
    expert = {
        {
            id = "bushcraft:ashfall_cov_ashl",
            craftableId = "ashfall_cov_ashl",
            previewMesh = tentConfig.coverToMeshMap["ashfall_cov_ashl"],
            description = itemDescriptions.ashfall_cov_ashl,
            materials = {
                { material = "wood", count = 4 },
                { material = "rope", count = 1 },
                { material = "leather", count = 4 },
            },
            category = this.categories.survival,
            soundType = "leather",
        },
        {
            --Travellers pack
            id = "bushcraft:ashfall_pack_05",
            craftableId = "ashfall_pack_05",
            description = itemDescriptions.ashfall_pack_05,
            materials = {
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
                { material = "fabric", count = 4 },
                { material = "leather", count = 1 }
            },
            category = this.categories.equipment,
            soundType = "wood",
        },
    },
    master = {
        {
            --Nordic backpack
            id = "bushcraft:ashfall_pack_06",
            craftableId = "ashfall_pack_06",
            description = itemDescriptions.ashfall_pack_06,
            materials = {
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
                { material = "fabric", count = 2 },
                { material = "leather", count = 1 },
                { material = "fur", count = 2 }
            },
            category = this.categories.equipment,
            soundType = "wood",
        },
        {
            id = "bushcraft:ashfall_fur_cloak",
            craftableId = "ashfall_fur_cloak",
            previewMesh = "ashfall\\craft\\cloak_fur_preview.nif",
            description = itemDescriptions.ashfall_fur_cloak,
            materials = {
                { material = "fur", count = 4 },
            },
            category = this.categories.equipment,
            soundType = "fabric",
        },
        {
            id = "ashfall_knife_glass",
            description = "Простой нож из необработанного стекла. Пригодится для снятия шкур с животных и сбора растительных волокон.\n\nПримечание: сломанные самодельные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "raw_glass", count = 1 },
                { material = "wood", count = 1 },
                { material = "rope", count = 1 },
            },
            category = this.categories.tools,
            recoverEquipmentMaterials = true,
        },
        {
            id = "ashfall_woodaxe_glass",
            description = "Топор из необработанного стекла. Можно использовать для заготовки дров.\n\nПримечание: сломанные самодельные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "raw_glass", count = 2 },
                { material = "wood", count = 1 },
                { material = "rope", count = 1 },
            },
            category = this.categories.tools,
            recoverEquipmentMaterials = true,
        },
        {
            id = "ashfall_spear_glass",
            description = "Копье с наконечником из необработанного стекла. Пригодится для охоты.\n\nПримечание: сломанные самодельные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "raw_glass", count = 1 },
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
            },
            category = this.categories.weapons,
            recoverEquipmentMaterials = true,
        },
        {
            id = "ashfall_pickaxe_glass",
            description = "Кирка, сделанная из необработанного стекла. Можно использовать для добычи камня.\n\nПримечание: сломанные самодельные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "raw_glass", count = 1 },
                { material = "wood", count = 1 },
                { material = "rope", count = 2 },
            },
            category = this.categories.tools,
            recoverEquipmentMaterials = true,
        },
        {
            id = "ashfall_sword_glass",
            description = "Короткий меч из необработанного стекла. Хорошее легкое оружие с простой деревянной рукоятью.\n\nПримечание: сломанные самодельные инструменты и оружие можно разобрать на запчасти, экипировав их.",
            materials = {
                { material = "raw_glass", count = 2 },
                { material = "wood", count = 1 },
                { material = "rope", count = 1 },
            },
            category = this.categories.weapons,
            recoverEquipmentMaterials = true,
        },
    },
}

---@type Ashfall.bushcrafting.recipeConfiguration
local carvingRecipes = {
    beginner = {
        {
            id = "bushcraft:ashfall_bowl_01",
            craftableId = "ashfall_bowl_01",
            description = "Резная деревянная миска ручной работы. Можно использовать для хранения воды или тушеного мяса.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 5
                }
            },
            category = this.categories.cutlery,
            previewScale = 4,
            soundType = "carve",
        },
        {
            id = "bushcraft:ashfall_cup_01",
            craftableId = "ashfall_cup_01",
            description = "Деревянная чашка ручной работы. Можно использовать для хранения воды или чая.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 4
                }
            },
            category = this.categories.cutlery,
            previewScale = 4,
            soundType = "carve",
        },
        {
            id = "bushcraft:ashfall_wood_knife",
            craftableId = "ashfall_wood_knife",
            description = "Деревянный нож ручной работы.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 2
                }
            },
            category = this.categories.cutlery,
            rotationAxis = 'y',
            soundType = "carve",
        },
        {
            id = "bushcraft:ashfall_wood_fork",
            craftableId = "ashfall_wood_fork",
            description = "Деревянная вилка ручной работы.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 2
                }
            },
            category = this.categories.cutlery,
            rotationAxis = 'y',
            soundType = "carve",
        },
        {
            id = "bushcraft:ashfall_wood_spoon",
            craftableId = "ashfall_wood_spoon",
            description = "Деревянная ложка ручной работы.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 2
                }
            },
            category = this.categories.cutlery,
            rotationAxis = 'y',
            soundType = "carve",
        },
        {
            id = "bushcraft:ashfall_wood_plate",
            craftableId = "ashfall_wood_plate",
            description = "Деревянная тарелка ручной работы.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 4
                }
            },
            category = this.categories.cutlery,
            soundType = "carve",
        },
        {
            id = "bushcraft:ashfall_wood_ladle",
            craftableId = "ashfall_wood_ladle",
            description = "Деревянный ковш ручной работы. Используется с кастрюлей для приготовления тёшеного мяса.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 4
                }
            },
            category = this.categories.utensils,
            previewMesh = "ashfall\\craft\\wood_ladle_attach.nif",
            soundType = "carve",
        },
    },
    novice = {
        {
            id = "bushcraft:ashfall_cup_2",
            craftableId = "ashfall_cup_02",
            description = "Каменная чашка ручной работы. Можно использовать для хранения воды или чая.",
            materials = {
                { material = "stone", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 20
                },
                {
                    tool = "hammer",
                    conditionPerUse = 1
                }
            },
            category = this.categories.cutlery,
            previewScale = 4,
            soundType = "carve",
        },
        {
            id = "bushcraft:ashfall_bowl_02",
            craftableId = "ashfall_bowl_02",
            description = "Каменная чаша ручной работы. Ее можно использовать в качестве небольшого котелка и ставить на огонь для приготовления мяса.",
            materials = {
                { material = "stone", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 25
                },
                {
                    tool = "hammer",
                    conditionPerUse = 1
                }
            },
            category = this.categories.utensils,
            previewScale = 4,
            soundType = "carve",
        },
    },
    apprentice = {
        {
            id = "bushcraft:ashfall_mortar",
            craftableId = "ashfall_mortar",
            description = "Каменные ступка и пестик для простой алхимии.",
            materials = {
                { material = "stone", count = 2},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 30
                },
                {
                    tool = "hammer",
                    conditionPerUse = 1
                }
            },
            category = this.categories.equipment,
            soundType = "carve",
        },

        --Stone amulet
        {
            id = "bushcraft:ashfall_stone_amulet",
            craftableId = "ashfall_stone_am_01",
            description = "Амулет из камней и кремня.",
            materials = {
                { material = "stone", count = 1},
                { material = "flint", count = 1},
                { material = "fibre", count = 1}
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 10,
                },
            },
            category = this.categories.equipment,
            soundType = "carve",
        },
        {
            id = "bushcraft:ashfall_wood_ring_01",
            craftableId = "ashfall_wood_ring_01",
            description = "Деревянное кольцо ручной работы.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 10,
                },
            },
            category = this.categories.equipment,
            soundType = "carve",
        },
    },
    journeyman = {
        {
            id = "bushcraft:ashfall_stand_01",
            craftableId = "ashfall_stand_01",
            placedObject = "ashfall_stand_01_placed",
            description = "Элегантная деревянная подставка для демонстрации украшений и керамики.",
            materials = {
                { material = "wood", count = 4 },
                { material = "resin", count = 1 }
            },
            category = this.categories.furniture,
            soundType = "carve",
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 20
                }
            },
        },
    },
    expert = {
        {
            id = "bushcraft:ashfall_wood_ring_02",
            craftableId = "ashfall_wood_ring_02",
            description = "Деревянное кольцо с гравировкой.",
            materials = {
                { material = "wood", count = 1},
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 15,
                },
            },
            category = this.categories.equipment,
            soundType = "carve",
            progress = 10
        },

        --Engraved amulet
        {
            id = "bushcraft:ashfall_stone_amulet_02",
            craftableId = "ashfall_stone_am_02",
            description = "Каменный амулет с выгравированными рунами.",
            materials = {
                { material = "stone", count = 1},
                { material = "fibre", count = 1}
            },
            toolRequirements = {
                {
                    tool = "chisel",
                    conditionPerUse = 15,
                },
            },
            category = this.categories.equipment,
            soundType = "carve",
            progress = 15
        },
    },
    master = {},
}

---@type Ashfall.bushcrafting.recipeConfiguration
local tanningRackRecipes = {
    beginner = {
        {
            id = "bushcraft:ashfall_leather_hide",
            craftableId = "ashfall_leather",
            name = "Кожа (из шкуры)",
            description = itemDescriptions.ashfall_leather,
            materials = {
                { material = "hide", count = 1 }
            },
            soundType = "leather",
        },
        {
            id = "bushcraft:ashfall_leather_pelt",
            craftableId = "ashfall_leather",
            name = "Кожа (из меха)",
            description = itemDescriptions.ashfall_leather,
            materials = {
                { material = "fur", count = 1 }
            },
            soundType = "leather",
        },
    },
    novice = {},
    apprentice = {},
    journeyman = {},
    expert = {},
    master = {},
}

---@type Ashfall.bushcrafting.recipeConfiguration
local workbenchRecipes = {
    commonFields = {
        customRequirements = {
            this.customRequirements.wildernessOnly,
            this.customRequirements.workbenchNearby
        },
        knowledgeRequirement = this.customRequirements.workbenchNearby.check
    },
    beginner = {},
    novice = {},
    apprentice = {
        { --platform
            id = "bushcraft:ashfall_platform_01",
            craftableId = "ashfall_platform_01",
            name = "Деревянная платформа",
            description = "Деревянная платформа, которую можно поставить на землю.",
            materials = {
                { material = "wood", count = 8 },
                { material = "rope", count = 2 },
            },
            category = this.categories.structures,
            soundType = "wood",
            maxSteepness = 0,
        },
        {  --steps small
            id = "bushcraft:ashfall_steps_sm_01",
            craftableId = "ashfall_steps_sm_01",
            name = "Короткая лестница",
            description = "Короткая деревянная лестница",
            materials = {
                { material = "wood", count = 3 },
            },
            category = this.categories.structures,
            soundType = "wood",
            maxSteepness = 0,
        },
        {  --steps large
            id = "bushcraft:ashfall_steps_lrg_01",
            craftableId = "ashfall_steps_lrg_01",
            name = "Высокая лестница",
            description = "Высокая деревянная лестница",
            materials = {
                { material = "wood", count = 6 },
            },
            category = this.categories.structures,
            soundType = "wood",
            maxSteepness = 0,
        },
        {  --steps large
            id = "bushcraft:ashfall_overhang_01",
            craftableId = "ashfall_overhang_01",
            name = "Козырек",
            description = "Кожаный козырек, для защиты от дождя.",
            materials = {
                { material = "leather", count = 3 },
                { material = "wood", count = 5 },
                { material = "rope", count = 4 },
            },
            category = this.categories.structures,
            soundType = "wood",
            maxSteepness = 0,
        },
        {  --steps large
            id = "bushcraft:ashfall_screen_fabric",
            craftableId = "ashfall_screen_fabric",
            description = "Тканевая ширма.",
            materials = {
                { material = "fabric", count = 2 },
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
            },
            category = this.categories.structures,
            soundType = "fabric",
        },
        {  --fence
            id = "bushcraft:ashfall_fence_01",
            craftableId = "ashfall_fence_01",
            name = "Деревянный забор",
            description = "Прочный деревянный забор.",
            materials = {
                { material = "wood", count = 6 },
            },
            category = this.categories.structures,
            soundType = "wood",
            maxSteepness = 0.1
        },
    },
    journeyman = {
        {  --steps large
            id = "bushcraft:ashfall_screen_leather",
            craftableId = "ashfall_screen_leather",
            description = "Кожаная ширма.",
            materials = {
                { material = "leather", count = 2 },
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
            },
            category = this.categories.structures,
            soundType = "leather",
        },
        {
            id = "bushcraft:ashfall_chest_02",
            craftableId = "ashfall_chest_02",
            description = "Большой деревянный сундук, который можно установить на землю и использовать в качестве хранилища.",
            materials = {
                { material = "wood", count = 10 },
            },
            category = this.categories.containers,
            soundType = "wood",
            -- additionalMenuOptions = {
            --     this.menuOptions.rename
            -- },
        },
        {
            id = "bushcraft:ashfall_stool_01",
            name = "Маленький табурет",
            craftableId = "ashfall_stool_01",
            description = "Маленький деревянный табурет.",
            materials = {
                { material = "wood", count = 2 },
                { material = "rope", count = 1 }
            },
            category = this.categories.furniture,
            soundType = "wood",
        },
        {
            id = "bushcraft:ashfall_table_03",
            name = "Большой стол",
            craftableId = "ashfall_table_03",
            description = "Большой деревянный стол.",
            materials = {
                { material = "wood", count = 8 },
            },
            category = this.categories.furniture,
            soundType = "wood",
        },
        {
            id = "bushcraft:ashfall_hammock",
            craftableId = "ashfall_hammock",
            maxSteepness = 0,
            quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
            additionalMenuOptions = {
                BedRoll.buttons.sleep,
                BedRoll.buttons.layDown,
            },
            description = "Гамак для сна на открытом воздухе.",
            materials = {
                { material = "wood", count = 4 },
                { material = "rope", count = 1 },
                { material = "fabric", count = 4 },
                { material = "straw", count = 4 },
                { material = "pillow", count = 1 },
            },
            category = this.categories.beds,
            soundType = "wood",
        },
    },
    expert = {
        {
            id = "bushcraft:ashfall_dummy_01",
            craftableId = "ashfall_dummy_01",
            description = "Тренировочный манекен для отработки навыков ближнего боя.",
            materials = {
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
                { material = "fabric", count = 4 },
                { material = "straw", count = 6 }
            },
            category = this.categories.structures,
            maxSteepness = 0,
            soundType = "fabric",
        },
        {
            id = "bushcraft:ashfall_target_01",
            craftableId = "ashfall_target_01",
            description = "Мишень для стрельбы из лука",
            materials = {
                { material = "wood", count = 3 },
                { material = "rope", count = 2 },
                { material = "straw", count = 10 },
            },
            category = this.categories.structures,
            maxSteepness = 0,
            soundType = "straw",
        },
        {
            id = "bushcraft:ashfall_bed_fur",
            craftableId = "ashfall_bed_fur",
            maxSteepness = 0,
            quickActivateCallback = function(_, e) BedRoll.buttons.sleep.callback(e) end,
            additionalMenuOptions = {
                BedRoll.buttons.sleep,
                BedRoll.buttons.layDown,
            },
            description = "Крепкая кровать, застеленная теплыми мехами.",
            materials = {
                { material = "wood", count = 6 },
                { material = "rope", count = 1 },
                { material = "fabric", count = 2 },
                { material = "fur", count = 2 },
                { material = "pillow", count = 1 },
            },
            category = this.categories.beds,
            soundType = "wood",
        },
    },
    master = {
        {
            id =  "bushcraft:ashfall_cbroll_active",
            craftableId = "ashfall_cbroll_active",
            description = "Спальный мешок с чехлом, который обеспечивает защиту от непогоды во время сна.",
            additionalMenuOptions = {
                BedRoll.buttons.sleep,
                BedRoll.buttons.layDown,
            },
            maxSteepness = 0,
            materials = {
                { material = "straw", count = 4 },
                { material = "wood", count = 3 },
                { material = "rope", count = 2 },
                { material = "fabric", count = 4},
                { material = "leather", count = 2 },
            },
            category = this.categories.beds,
            soundType = "leather",
            previewScale = 1.25,
        },
    },
}


this.menuEvent = "Ashfall:ActivateBushcrafting"
this.tanningEvent = "Ashfall:ActivateTanningRack"
this.carvingEvent = "Ashfall:EquipChisel"
this.workbenchEvent = "Ashfall:ActivateWorkbench"
---@type table<string, Ashfall.bushcrafting.MenuActivatorConfig>
this.menuActivators = {
    bushcrafting = {
        menuActivator = {
            name = "Ремесло",
            type = "event",
            id = this.menuEvent,
            defaultFilter = "skill",
        },
        recipeLists = {
            bushCraftingRecipes,
            materialRecipes,
            workbenchRecipes
        }
    },
    tanningRack = {
        menuActivator = {
            name = "Дубильный станок",
            type = "event",
            id = this.tanningEvent,
            defaultFilter = "skill",
        },
        recipeLists = {
            tanningRackRecipes
        }
    },
    carving = {
        menuActivator = {
            name = "Долото",
            type = "event",
            id = this.carvingEvent,
            defaultFilter = "skill",
        },
        recipeLists = {
            carvingRecipes,
        }
    },
    workbench = {
        menuActivator = {
            name = "Верстак",
            type = "event",
            id = this.workbenchEvent,
            defaultFilter = "skill",
        },
        recipeLists = {
            workbenchRecipes,
            materialRecipes
        }
    }
}

return this