local Formulas = {
    MORTAR = 0,
    ALEMBIC = 1,
    CALCINATOR = 2,
    RETORT = 3,

    fPotionStrengthMult = 0.5,
    fPotionT1DurMult = 0.5,
    fPotionT1MagMult = 1.5,
    iAlchemyMod = 2,
}


function Formulas.getRandom()
    return math.random()
end

function Formulas.getAlchemy(pid)
    return Players[pid].data.skills.Alchemy.base + Players[pid].data.skills.Alchemy.damage
end

function Formulas.getIntelligence(pid)
    return Players[pid].data.attributes.Intelligence.base + Players[pid].data.attributes.Intelligence.damage
end

function Formulas.getLuck(pid)
    return Players[pid].data.attributes.Luck.base + Players[pid].data.attributes.Luck.damage
end


function Formulas.makeAlchemyStatus(pid, apparatuses, ingredients)
    local status = {
        pid = pid,
        ingredients = ingredients
    }
    
    status.mortar = apparatuses[Formulas.MORTAR]
    status.alembic = apparatuses[Formulas.ALEMBIC]
    status.calcinator = apparatuses[Formulas.CALCINATOR]
    status.retort = apparatuses[Formulas.RETORT]

    status.alchemy = Formulas.getAlchemy(pid)
    status.intelligence = Formulas.getIntelligence(pid)
    status.luck = Formulas.getLuck(pid)

    status.potency = Formulas.getPotionPotency(status)

    status.weight = Formulas.getPotionWeight(status)
    
    status.icon = Formulas.getPotionIcon(status)
    
    status.model = Formulas.getPotionModel(status)
    
    status.value = Formulas.getPotionValue(status)
    
    return status
end

function Formulas.getPotionChance(status)
    return math.min(
        ( status.alchemy + 0.1 * (status.intelligence + status.luck) ) * 0.01,
        1
    )
end

function Formulas.getPotionPotency(status)
    local potency = status.alchemy + 0.1 * ( status.intelligence + status.luck )
    potency = potency * status.mortar * Formulas.fPotionStrengthMult

    return potency
end

function Formulas.getPotionValue(status)
    return Formulas.iAlchemyMod * status.potency
end


function Formulas.getPotionWeight(status)
    local total_weight = 0
    for _,ingredient in pairs(status.ingredients) do
        total_weight = total_weight + ingredient.weight
    end
    return (0.75 * total_weight + 0.35) / (0.5 + status.alembic)
end

function Formulas.getPotionIcon(status)
    local tier = math.floor(status.potency/18)
    if tier >= 4 then
        return "m\\tx_potion_exclusive_01.tga"
    elseif tier == 3 then
        return "m\\tx_potion_quality_01.tga"
    elseif tier == 2 then
        return "m\\tx_potion_standard_01.tga"
    elseif tier == 1 then
        return "m\\tx_potion_cheap_01.tga"
    end
    return "m\\tx_potion_bargain_01.tga"
end

function Formulas.getPotionModel(status)
    local tier = math.floor(status.potency / 18)
    if tier >= 4 then
        return "m\\misc_potion_exclusive_01.nif"
    elseif tier == 3 then
        return "m\\misc_potion_quality_01.nif"
    elseif tier == 2 then
        return "m\\misc_potion_standard_01.nif"
    elseif tier == 1 then
        return "m\\misc_potion_cheap_01.nif"
    end
    return "m\\misc_potion_bargain_01.nif"
end

local numericsLimit = 100
function Formulas.getPotionCount(status, ingredientCount)
    local n = ingredientCount
    if n > numericsLimit then
        local sum = 0
        local count = math.ceil(n / numericsLimit)
        while n > 0 do
            sum = sum + Formulas.getPotionCount(status, math.min(n, numericsLimit))
            n = n - numericsLimit
        end
        return sum
    end
    local roll = Formulas.getRandom()
    local p = Formulas.getPotionChance(status)
    if p == 0 then
        return 0
    end
    if p == 1 then
        return n
    end

    local total_probability = 0
    local probability = (1-p)^n
    local dp = 1

    for k = 0, n do
        total_probability = total_probability + probability
        if total_probability >= roll then
            return k
        end
        dp = ( (n - k) / (k + 1) ) * ( p / (1 - p) )
        probability = probability * dp
    end

    return n
end

function Formulas.getEffectMagnitude(status, effect)
    if not effect.hasMagnitude then
        return 0
    end

    local magnitude = status.potency / Formulas.fPotionT1MagMult / effect.cost

    if effect.negative then
        if status.alembic ~= 0 then
            if status.calcinator ~= 0 then
                magnitude = magnitude / ( status.alembic * 2 + status.calcinator * 3 )
            else
                magnitude = magnitude / ( status.alembic + 1 )
            end
        else
            magnitude = magnitude + status.calcinator
            if not effect.hasDuration then
                magnitude = magnitude*( status.calcinator + 0.5 ) - status.calcinator
            end
        end
    else
        local mod = status.calcinator + status.retort
        
        if status.calcinator ~= 0 and  status.retort ~= 0 then
            magnitude = magnitude  + mod + status.retort
            if not effect.hasDuration then
                magnitude = magnitude - ( mod / 3 ) - status.retort + 0.5
            end
        else
            magnitude = magnitude + mod
            if not effect.hasDuration then
                magnitude = magnitude * ( mod + 0.5 ) - mod
            end
        end
    end

    return magnitude
end

function Formulas.getEffectDuration(status, effect)
    if not effect.hasDuration then
        return 0
    end

    local duration = status.potency / Formulas.fPotionT1DurMult / effect.cost

    if effect.negative then
        if status.alembic ~= 0 then
            if status.calcinator ~= 0 then
                duration = duration / ( status.alembic * 2 + status.calcinator * 3 )
            else
                duration = duration / ( status.alembic + 1 )
            end
        else
            duration = duration + status.calcinator
            if not effect.hasMagnitude then
                duration = duration*(status.calcinator + 0.5) - status.calcinator
            end
        end
    else
        local mod = status.calcinator + status.retort
        
        if status.calcinator ~= 0 and  status.retort ~= 0 then
            duration = duration + mod + status.retort
            if not effect.hasMagnitude then
                duration = duration - ( mod / 3 ) - status.retort + 0.5
            end
        else
            duration = duration + mod
            if not effect.hasMagnitude then
                duration = duration * ( mod + 0.5 ) - mod
            end
        end
    end

    return duration
end

return Formulas