
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
---@param e objectCreatedEventData
event.register("objectCreated", function(e)
    if e.copiedFrom and FishingRod.isFishingRod(e.copiedFrom) then
        local rodConfig = FishingRod.getConfig(e.copiedFrom.id)
        FishingRod.register{
            id = e.object.id,
            quality = rodConfig.quality
        }
    end
end)

local Drip = include("mer.drip")
if not Drip then return end
local SkillsModule = include("SkillsModule")
if not SkillsModule then return end

Drip.registerWeapon("mer_fishing_pole_01")
Drip.registerModifier{
    id = "fishing_angler",
    prefix = "Angler's",
    valueMulti = 1.5,
    description = "Increases fishing skill by 10 points.",
    isValidObject = function(self, object)
        return FishingRod.isFishingRod(object)
    end
}
SkillsModule.registerFortifyEffect{
    id = "drip_angler",
    skill = "fishing",
    callback = function()
        local equippedRod = FishingRod.getEquipped()
        if not equippedRod then return end
        local modifiers = Drip.Modifier.getObjectModifiers(equippedRod.item)
        if not modifiers then return end
        for _, modifier in ipairs(modifiers) do
            if modifier.prefix == "Angler's" then
                return 10
            end
        end
    end
}
