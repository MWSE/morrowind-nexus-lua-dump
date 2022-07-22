
local config = require("Sphagne.TieredSpellCasting.config")

local function saveConfig()
	mwse.saveConfig("Tired Spell Casting", config)
end

local easyMCMConfig = {
	name = "Tired Spell Casting",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "Mastery tiers for uncapped games",
					class = "OnOffButton",
					description = [[Caster mastery tiers based on skill levels
									
Mastery tiers for level capped games:
									Less than 15  : Initiate
									Less than 30  : Novice
									Less than 45  : Apprentice
									Less than 60  : Journeyman
									Less than 75  : Adept
									Less than 90  : Expert
									    Up to 100  : Master
									  Beyond that : Grand Master
									
Mastery tiers for level uncapped games:
									Less than 15  : Initiate
									Less than 30  : Novice
									Less than 50  : Apprentice
									Less than 75  : Journeyman
									Less than 100 : Adept
									Less than 125 : Expert
									Less than 150 : Master
									  Beyond that : Grand Master]],
					variable = {
						id = "levUncapped",
						class = "TableVariable",
						table = config,
					},
				},
				{
					label = "Casting chance penalty for higher spells",
					class = "OnOffButton",
					description = [[%33 casting chance penalty for each tier that the spell is beyond the caster's mastery tier
									
									This means casting spells more than two
									tiers beyond our mastery is impossible]],
					variable = {
						id = "penChanceHiTier",
						class = "TableVariable",
						table = config,
					},
				},
				{
					label = "Spell cost penalty for higher spells",
					class = "OnOffButton",
					description = [[%10 spell cost penalty for each tier that the spell is beyond the caster's mastery tier
									
									This means casting a spell two tiers
									beyond our mastery would cost %20 more]],
					variable = {
						id = "penCostHiTier",
						class = "TableVariable",
						table = config,
					},
				},
				{
					label = "Spell cost reduction for lower spells",
					class = "OnOffButton",
					description = [[%10 spell cost reduction for each tier that the spell is below the caster's mastery tier
									
									This means casting a spell two tiers
									below our mastery would cost %20 less]],
					variable = {
						id = "redCostLoTier",
						class = "TableVariable",
						table = config,
					},
				},
				{
					label = "Spell cost reduction for high mastery",
					class = "OnOffButton",
					description = [[Spell cost reduction when the caster reaches higher masteries
									
									%10 : Journeyman
									%20 : Adept
									%30 : Expert
									%40 : Master
									%50 : Grand Master]],
					variable = {
						id = "redCostHiMastery",
						class = "TableVariable",
						table = config,
					},
				},
				{
					label = "Gain experience on spell failure",
					class = "OnOffButton",
					description = [[Gain experience even when failing to cast a spell
									
									For lower tier spells, failure to
									cast a spell would grant us a higher
									percentage of the experience that we
									would gain on success, because we are
									still learning the basics]],
					variable = {
						id = "expFailure",
						class = "TableVariable",
						table = config,
					},
				},
			},
			sidebarComponents = {
				{
					label = "Mod Description",
					class = "Info",
					text = "This mod categorizes spells and casters into tiers and affects the spell casting game-play based on those tiers",
				},
			},
		},
	},
	onClose = saveConfig,
}

return easyMCMConfig
