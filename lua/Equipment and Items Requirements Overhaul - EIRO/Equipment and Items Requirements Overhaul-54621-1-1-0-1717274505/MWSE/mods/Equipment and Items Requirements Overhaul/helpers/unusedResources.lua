local function printEffectDetails(effect)
    mwse.log("All Enchant Effect Details:")
    mwse.log("Attribute: %s", effect.attribute and tostring(effect.attribute) or "nil")
    mwse.log("Cost: %s", effect.cost)
    mwse.log("Duration: %s", effect.duration)
    mwse.log("Effect ID: %s", effect.id)
    mwse.log("Max Magnitude: %s", effect.max)
    mwse.log("Min Magnitude: %s", effect.min)
    mwse.log("Effect Object: %s", effect.object and effect.object.id or "nil")
    mwse.log("Radius: %s", effect.radius)
    mwse.log("Range Type: [0 = self, 1 = Touch, 2 = Target] %s", effect.rangeType)
    mwse.log("Skill: %s", effect.skill and tostring(effect.skill) or "nil")
end

return printEffectDetails
