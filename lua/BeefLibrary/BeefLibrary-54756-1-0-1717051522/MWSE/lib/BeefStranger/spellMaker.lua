local spellMaker = {}
local logger = require("logging.logger")
local log = logger.new { name = "spellMaker", logLevel = "DEBUG", logToConsole = true, }
-- local bs = require("BeefStranger.functions")

function spellMaker.calculateEffectCost(spell)
    local totalCost = 0                      --Initialize totalCost to add too
    for i = 1, spell:getActiveEffectCount() do -- this line straight taken from magickaExpanded framework
        local effect = spell.effects[i] ---@type tes3effect set effect to for every id.effects[1-2-3-etc]
        if (effect ~= nil) then              --if effect is valid
            local minMag = effect.min or 0
            local maxMag = effect.max or 1
            local duration = effect.duration or 0
            local area = effect.radius or 1
            local baseEffectCost = effect.object.baseMagickaCost or 5
            local ranged = 1

            if effect.rangeType == tes3.effectRange.target then
                ranged = 1.5 -- Increase cost by 50% for target range effects
            end

            -- Calculate the cost of the effect. Formula from uesp is wrong. the end result has to be divided by 2 to match built in spells
            local cost = (((minMag + maxMag) * (duration + 1) + area) * (baseEffectCost / 40) * ranged) / 2
            totalCost = totalCost + cost
            -- log:debug("%s - min-%s max-%s dur-%s area-%s baseCost-%s range-%s totalCost-%s",effect ,minMag,maxMag,duration,area,baseEffectCost,ranged, totalCost)
        end
    end
    return totalCost
end


local function mergeTables(t1, t2)
    local t = {}
    for k, v in pairs(t1) do
        t[k] = v
    end
    for k, v in pairs(t2) do
        t[k] = v
    end
    return t
end

--- @class SpellParamsCreate
--- @field id string The unique identifier for the spell.
--- @field name string The name of the spell.
--- @field castType tes3.spellType? 'ability' | 'blight' | 'curse' | 'disease' | 'power' | 'spell'? Optional. Defaults to spell
--- @field alwaysSucceeds boolean? Optional. A flag that determines if casting the spell will always succeed. Defaults to false.
--- @field effect tes3.effect The effect ID from the tes3.effect table.
--- @field min? integer The minimum magnitude of the spell's effect.
--- @field max? integer Optional. The maximum magnitude of the spell's effect. Defaults to min.
--- @field duration? integer Optional. The duration of the spell's effect. Defaults to 0.
--- @field range tes3.effectRange? Optional. The range type of the spell. Must be 'self' for abilities. Defaults to 'self'.
--- @field radius integer? The radius of the effect in feet.
--- @field attribute tes3.attribute? Use for Fortify Attribute Spells. The attribute associated with this effect. Defaults to nil.
--- @field cost number? Optional. If not set spell Auto Calculates cost using vanilla Formula. The base magicka cost of this effect.
--- @field skill tes3.skill? Optional. The skill associated with this effect. Defaults to nil
--- @field autoCalc boolean? Optional. Defaults to falseDetermines if the magicka cost for the spell is autocalculated, and if the spell may be automatically assigned to NPCs if they are skillful enough to cast it.
--- @field sourceless boolean? Optional. Defaults to true. Sets the spell to sourceless
--- @field playerStart boolean? Optional. Defaults to false. A flag that determines if the spell may be assigned to the player at character generation if the player has enough skill to cast it.
--- @field effect2 tes3.effect? Optional. Add up to 8 effects. Add params for each effect. (duration2 = 15,)
--- @field effect3 tes3.effect? Optional. Add up to 8 effects. Add params for each effect. (duration3 = 15,) 
--- @field effect4 tes3.effect? Optional. Add up to 8 effects. Add params for each effect. (duration4 = 15,)
--- @field effect5 tes3.effect? Optional. Add up to 8 effects. Add params for each effect. (duration5 = 15,)
--- @field effect6 tes3.effect? Optional. Add up to 8 effects. Add params for each effect. (duration6 = 15,)
--- @field effect7 tes3.effect? Optional. Add up to 8 effects. Add params for each effect. (duration7 = 15,)
--- @field effect8 tes3.effect? Optional. Add up to 8 effects. Add params for each effect. (duration8 = 15,)
--- @field min2 integer? Optional up to min8. Defaults to first effects min. 
--- @field duration2? integer Optional up to duration8. Defaults to first effects duration.
--- @param params SpellParamsCreate The configuration table for the new spell.
--- @param addOnParam? table Optional. Useful if you are using a table to manage spells but want to add something to the spell after
function spellMaker.create(params, addOnParam)
    if addOnParam then
        params = mergeTables(params, addOnParam)
    end

    local spell = tes3.getObject(params.id) or tes3.createObject({ ---@type tes3spell
        objectType = tes3.objectType.spell, --Define objectType you're making
        id = params.id, 
        name = params.name,

        -- alwaysSucceeds = params.alwaysSucceeds or false, --Doesnt actually work here
        autoCalc = params.autoCalc or false, --audoCalc does cost calc, and adds to npcs if they have the skill
        castType = params.castType or tes3.spellType["spell"],
        playerStart = params.playerStart or false,
        sourceless = params.sourceless or true,

        -- Effects 1-8 | Effect1 = effect | Efect2 = effect2
        effects = {},
    })

    spell.alwaysSucceeds = params.alwaysSucceeds or false --has to be here

    --barely understand this, somehow cobbled together
    local effectKeyBase = "effect"                --set effectKey to just effect
    for i = 1, 8 do --for effect 1 - 8 do
        local effectKey = effectKeyBase .. (i == 1 and "" or i)
        if not params[effectKey] then
            break
        end

        local suffix = (i == 1 and "" or i)   --setup suffix for effect making, if i is 1 its blank, else its i, makes it skip 1 to make it nicer for simple spells
        local effect = spell.effects[i] or {} --set effect to the next spell.effects table or create one

        effect.id = params[effectKey]
        --Concatenate all params with the suffix number
        effect.attribute = params["attribute" .. suffix] or nil
        effect.duration = params["duration" .. suffix] or params.duration or 1
        effect.max = params["max" .. suffix] or params["min" .. suffix]
        effect.min = params["min" .. suffix] or 0
        effect.radius = params["radius" .. suffix] or 0
        effect.rangeType = params["range" .. suffix] or tes3.effectRange.self
        effect.skill = params["skill" .. suffix] or nil
        spell.magickaCost = params["cost".. suffix] or spellMaker.calculateEffectCost(spell) --cannot use just effect.cost its read only for some reason

        spell.effects[i] = effect
        i = i + 1                   -- raise i by 1
        effectKey = ("effect" .. i) --concatenates effect and the i, iteration its on
        
    end
    return spell
end

return spellMaker