local lootList = {
    {
        baseId = "ring_denstagmer_unique",
        niche = {
            regions = {
                "West Gash Region"
            }
        },
		description = "Even the name Denstagmer is a mystery. All that is known of this Ring is that it may grant the user protection from certain elements.",
    },
    {
        baseId = "ring_mentor_unique",
        niche = {
            regions = {
                "Bitter Coast Region"
            }
        },
		description = "The High Wizard Carni Asron is said to have created this Ring for use by his young apprentices. It increases the wearer's intelligence and wisdom, thus making their use of magic more efficient.",
    },
    {
        baseId = "ring_phynaster_unique",
        niche = {
            regions = {
                "Sheogorad"
            }
        },
		description = "The Ring of Phynaster was made hundreds of years ago by a man who needed good defenses to survive his adventurous life. The Ring improves its wearer's overall resistance to poison, magicka, and shock.",		
    }
}
local Interop = require("mer.fishing")
event.register("initialized", function(e)
    for _, loot in ipairs(lootList) do
        loot.class = "loot"
        loot.rarity = "rare"
        loot.size = 0.5
        loot.speed = 50
        loot.difficulty = 20
        loot.totalPopulation = 1
        Interop.registerFishType(loot)
    end
end)