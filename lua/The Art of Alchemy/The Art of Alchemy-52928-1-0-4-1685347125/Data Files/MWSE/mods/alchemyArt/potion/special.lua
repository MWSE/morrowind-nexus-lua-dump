local recipes = require("alchemyArt.potion.recipes")

local specialPotion = {}

local potionEffects = {
    effectId = {
        attributeId = {
            magnitude = 35,
            duration = 100
        }
    }
}

specialPotion.init = function ()
    for id , special in pairs(recipes) do
        if special.create then
            local newPotion = tes3.createObject{id = id, objectType = tes3.objectType.alchemy}
            newPotion.name = special.name
            newPotion.mesh = special.mesh or "m\\Misc_Potion_Exclusive_01.nif"
            newPotion.icon = special.icon or "m\\Tx_potion_exclusive_01.tga"
            newPotion.value = special.value or 2500
            newPotion.weight = special.weight or 2
            for i, effectTable in ipairs(special.effects) do
                newPotion.effects[i].id = effectTable.id
                newPotion.effects[i].min = effectTable.magnitude
                newPotion.effects[i].max = effectTable.magnitude
                newPotion.effects[i].duration = effectTable.duration or 0
                newPotion.effects[i].attribute = effectTable.attribute or -1
                newPotion.effects[i].skill = effectTable.skill or -1
            end
        end
    end
end

specialPotion.find = function(effectArray)
    for id , special in pairs(recipes) do
        local same = 0
        -- mwse.log(inspect(effectArray))
        -- mwse.log(inspect(special.effects))
        if #special.effects == #effectArray then
            for _, effectS in ipairs(special.effects) do
                for _, effectA in ipairs(effectArray) do
                    if effectA.id ~= effectS.id then
                    elseif effectA.attribute ~= effectS.attribute then
                    else
                        same = same + 1
                    end
                end
            end
            if same == #effectArray then
                return tes3.getObject(id)
            end
        end
    end
end

specialPotion.onEquip = function(e)
    if not recipes[e.item.id] then
        return

    end

    -- mwse.log("is in specialPotions")

    if not recipes[e.item.id].onConsumed then
        return
    end

    -- mwse.log("has onConsumed callback")


    recipes[e.item.id].onConsumed(e)

end

return specialPotion