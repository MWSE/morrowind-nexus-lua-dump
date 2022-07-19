
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
					label = "Level uncapped game settings",
					class = "OnOffButton",
					description = [[Level capped mastery tiers for skill levels:
									Less than 15  : Initiate
									Less than 30  : Novice
									Less than 45  : Apprentice
									Less than 60  : Journeyman
									Less than 75  : Adept
									Less than 90  : Expert
									    Up to 100  : Master
									  Beyond that : Grand Master
									
Level uncapped mastery tiers for skill levels:
									Less than 15  : Initiate
									Less than 30  : Novice
									Less than 50  : Apprentice
									Less than 75  : Journeyman
									Less than 100 : Adept
									Less than 125 : Expert
									Less than 150 : Master
									  Beyond that : Grand Master]],
					variable = {
						id = "uncapped",
						class = "TableVariable",
						table = config,
					},
				},
				{
					label = "Casting chance penalty",
					class = "OnOffButton",
					description = [[Casting chance penalty:
									%33 casting chance penalty for each tier
									
									This means casting spells more than two
									tiers beyond our mastery is impossible
									
									
Spell cost penalty:
									%10 spell cost penalty for each tier
									
									This means casting a spell two tiers
									beyond our mastery would cost %20 more]],
					variable = {
						id = "penChance",
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
