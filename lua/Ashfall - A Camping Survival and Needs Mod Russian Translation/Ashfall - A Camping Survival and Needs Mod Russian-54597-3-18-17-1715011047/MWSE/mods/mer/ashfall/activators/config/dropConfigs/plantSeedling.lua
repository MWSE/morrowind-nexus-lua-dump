
local common = require ("mer.ashfall.common.common")
local Planter = require("mer.ashfall.items.planter.Planter")
local Seedling = require("mer.ashfall.items.planter.Seedling")
return {
    dropText = function(target, item)
        return string.format("Посадить %s", item.name)
    end,
    canDrop = function(target, item)
        if not Seedling.isSeedling(item) then return false end
        local planter = Planter.new(target)
        if not planter then return false end
        if planter.seedlingId then return false, "Уже есть саженец" end
        return true
    end,
    onDrop = function(target, reference)
        local planter = Planter.new(target)
        if planter then
            planter:plantSeed(reference.object)
            local remaining = common.helper.reduceReferenceStack(reference, 1)
            if remaining > 0 then
                common.helper.pickUp(reference)
            end
        end
    end
}