local this = {}

this.cookedMulti = 2.0
this.burntMulti = 0.8

function this.getFoodType(obj)
    local foodType =  this.ingredTypes[obj.id:lower()]
    -- if not foodType and obj.objectType == tes3.objectType.ingredient then
    --     foodType = this.type.misc
    -- end
    return foodType
end



--Handles special case for pre-cooked meat
function this.getFoodTypeResolveMeat(obj)

    local foodType = this.getFoodType(obj)
    if foodType == this.type.cookedMeat then
        foodType = this.type.meat
    end
    return foodType
end

function this.getNutrition(obj)
    return this.nutrition[this.getFoodType(obj)]
end

function this.getNutritionForFoodType(foodType)
    return this.nutrition[foodType]
end

function this.getGrillValues(obj)
    return this.grillValues[this.getFoodType(obj)]
end

function this.getGrillValuesForFoodType(foodType)
    return this.grillValues[foodType]
end

function this.getStewBuffForId(obj)
    return this.stewBuffs[this.getFoodType(obj)]
end

function this.getStewBuffForFoodType(foodType)
    if foodType == this.type.cookedMeat then
        foodType = this.type.meat
    end
    return this.stewBuffs[foodType]
end

function this.getStewBuffList()
    return this.stewBuffs
end

function this.getFoodData(obj, resolveMeat)
    local foodType = resolveMeat and this.getFoodTypeResolveMeat(obj) or this.getFoodType(obj)
    if not foodType then return nil end
    return {
        foodType = foodType,
        nutrition = this.getNutritionForFoodType(foodType),
        grillValues = this.getGrillValuesForFoodType(foodType),
        stewBuff = this.getStewBuffForFoodType(foodType)
    }
end

function this.isStewNotSoup(stewLevels)
    local isStew = false
    for stewType, _ in pairs(stewLevels) do
        local data = this.getStewBuffForFoodType(stewType)
        if data.notSoup then isStew = true end
    end
    return isStew
end

function this.addFood(id, foodType)
    this.ingredTypes[id:lower()] = this.type[foodType]
end

this.type = {
    meat = "Мясо",
    cookedMeat = "Мясо (приготовленное)",
    egg = "Яйцо",
    vegetable = "Овощ",
    mushroom = "Гриб",
    seasoning = "Приправа",
    herb = "Растение",
    fruit = "Фрукты",
    food = "Пища",
    misc = nil
}


this.stewBuffs = {
    [this.type.meat] = {
        notSoup = true,
        stewNutrition = 1.0,
        min = 10, max = 30,
        id = "ashfall_stew_hearty",
        tooltip = "Сытное мясное рагу, которое укрепит ваше здоровье.",
        ingredTooltip = "Увеличение здоровья."
    }, -- fortify health
    [this.type.vegetable] = {
        notSoup = true,
        stewNutrition = 0.9,
        min = 10, max = 30,
        id = "ashfall_stew_nutritious",
        tooltip = "Питательное овощное рагу, которое снимет усталость.",
        ingredTooltip = "Увеличение запаса сил."
    }, --fortify fatigue
    [this.type.mushroom] = {
        notSoup = true,
        stewNutrition = 0.8,
        min = 10, max = 25,
        id = "ashfall_stew_chunky",
        tooltip = "Густое грибное рагу, повышающее вашу магию.",
        ingredTooltip = "Увеличение магии."
    }, --fortify magicka
    [this.type.seasoning] = {
        notSoup = false,
        stewNutrition = 0.3,
        min = 5, max = 20,
        id = "ashfall_stew_tasty",
        tooltip = "Вкусный суп с приправами, который увеличивает вашу ловкость.",
        ingredTooltip = "Улучшение ловкости."
    }, --fortify agility
    [this.type.herb] = {
        notSoup = false,
        stewNutrition = 0.4,
        min = 5, max = 20,
        id = "ashfall_stew_aromatic",
        tooltip = "Ароматный суп, богатый травами, который увеличит вашу привлекательность.",
        ingredTooltip = "Улучшение привлекательности"
        } -- fortify personality
}

--min: fully cooked multi at lowest cooking skill
--max fully cooked multi at highest cooking skill
this.grillValues = {
    [this.type.meat] = { min = 1.4, max = 1.7 },
    [this.type.egg] = { min = 1.4, max = 1.7 },
    [this.type.vegetable] = { min = 1.4, max = 1.7 },
    [this.type.mushroom] = { min = 1.4, max = 1.7 },
}

--Nutrition at weight==1.0
this.nutrition = {
    [this.type.meat] = 12,
    [this.type.cookedMeat] = (12 * this.grillValues[this.type.meat].min),
    [this.type.egg] = 10,
    [this.type.vegetable] = 10,
    [this.type.mushroom] = 8,
    [this.type.seasoning] = 5,
    [this.type.herb] = 5,
    [this.type.food] = 25,
    --[this.type.misc] = 0,
}

this.ingredTypes = {}

return this