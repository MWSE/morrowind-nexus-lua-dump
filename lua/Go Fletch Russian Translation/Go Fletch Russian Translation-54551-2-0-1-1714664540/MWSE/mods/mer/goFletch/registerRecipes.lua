
local Recipes = require("mer.goFletch.recipes")
local CraftingFramework = include("CraftingFramework")
---------------------------------------------------------
--Handler
---------------------------------------------------------

local function registerRecipe(ammo, material, enchantment)
    local skill = "fletching"
    local skillValue = ammo.skillReq + material.skillReq
    local resultID = ammo.id .. material.id
    local itemReqs = {}

    local description = ammo.description .. " из " .. material.description

    for _, item in ipairs(material.ingredients) do
        table.insert(itemReqs, {
            material = item.id,
            count = item.count
        })
    end
    --If Ashfall is installed, add a piechttps://youtu.be/Mhxzv2x9Aeke of wood to the material requirements
    if include("mer.ashfall.bushcrafting") and ammo.handler == "arrows" then
        table.insert(itemReqs, {
            material = "wood",
            count = 1
        })
    end

    if enchantment then
        description = description .. ", " .. enchantment.description
        skillValue = skillValue + enchantment.skillReq
        resultID = resultID .. enchantment.id
        for _, item in ipairs(enchantment.ingredients) do
            table.insert(itemReqs, {
                material = item.id,
                count = item.count
            })
        end
    end
    description = description .. "."

    local recipe = {
        id = resultID,
        description = description,
        materials = itemReqs,
        skillRequirements = {
            { skill = skill, requirement = skillValue }
        },
        category = ammo.handler,
        resultAmount = ammo.craftCount,
    }

    return recipe
end

local fletchingKitRecipe
local function getOrCreateFletchingKitRecipe()
    if not fletchingKitRecipe then
        --Register Fletching Kit as a bushcrafting recipe
        fletchingKitRecipe = CraftingFramework.Recipe:new({
            id = "mer_fletch_kit",
            placedObject = "mer_fletch_kit_active",
            description = "Набор для оперения позволяет создавать стрелы, болты и дротики.",
            materials = {
                { material = "wood", count = 2 },
                { material = "rope", count = 1 },
            },
            additionalMenuOptions = {
                {
                    text = "Оперение",
                    callback = function(e)
                        event.trigger("GoFletch:ActivateFletchingKit")
                    end
                }
            },
            skillRequirements = {
                { skill = "Bushcrafting", requirement = 40 }
            },
            soundType = "wood",
            category = "Инструменты",
        })
    end
    return fletchingKitRecipe
end


local function registerRecipes()
    mwse.log("registering recipes for Fletching")
    if not CraftingFramework then
        --ERROR: CraftingFramework not found
        return
    end
    --Create recipe list
    local recipeList = {}
    for _, ammo in pairs(Recipes.ammoTypes) do
        for _, material in pairs(Recipes.materials) do
            local recipe = registerRecipe(ammo, material)
            table.insert(recipeList, recipe)
            for _, enchantment in pairs(Recipes.enchantments) do
                local recipe = registerRecipe(ammo, material, enchantment)
                table.insert(recipeList, recipe)
            end
        end
    end

    --register the fletching kit as a MenuActivator
    mwse.log("Registering Fletching Kit")
    CraftingFramework.MenuActivator:new{
        id = "mer_fletch_kit",
        type = "equip",
        recipes = recipeList,
        defaultSort = "skill",
        defaultFilter = "skill",
        defaultShowCategories = true
    }
    CraftingFramework.MenuActivator:new{
        name = "Набор для оперения",
        id = "GoFletch:ActivateFletchingKit",
        type = "event",
        recipes = recipeList,
        defaultSort = "skill",
        defaultFilter = "skill",
        defaultShowCategories = true
    }

    --We need to create the recipe even if Bushcrafting isn't enabled,
    --so it gets the menu options when activated
    getOrCreateFletchingKitRecipe()
end

---@param e MenuActivatorRegisteredEvent
local function registerAshfallRecipes(e)
    mwse.log("=================================================Registering fletching kit")
    local bushcraftingActivator = e.menuActivator
    if bushcraftingActivator then
        local fletchingKitRecipe = getOrCreateFletchingKitRecipe()
        mwse.log("Found menuActivator, adding recipe: %s", fletchingKitRecipe)
        bushcraftingActivator:addRecipe(fletchingKitRecipe)
    end
end
event.register("Ashfall:ActivateBushcrafting:Registered", registerAshfallRecipes)

return registerRecipes
