local this = {}
this.mod = "Tea Merchants"
this.version = "1.0"
local summary = "This mod is an addon for Ashfall. It adds Tea Merchants in the game."
local configPath = "teaMerchants"
this.config = mwse.loadConfig(configPath) or {
	logLevel = "INFO",
	teaMerchants = {
		["ajira"] = true, -- balmora, black anther/comberry/heather, in inventory
		["arrille"] = true, -- seyda neen, leveled lists, not in inventory
		["pierlette rostorard"] = true, -- sadrith mora, chokeweed/comberry/gold kanet, not in inventory
		["sedam omalen"] = true, -- ald velothi, leveled lists, not in inventory
	},
}

local function modConfigReady()
	local template = mwse.mcm.createTemplate { name = "Tea Merchants", headerImagePath = "textures/jsmk/MCMHeader.tga" }
	template:saveOnClose(configPath, this.config)
	template:register()
	local infoPage = template:createPage{ label = "Info" }
	infoPage:createInfo({ text = this.mod .. " v" .. this.version .. "\n" .. summary })
	infoPage:createHyperLink{
		text = "Some people like morning coffee. JosephMcKean likes morning tea.",
		url = "https://www.nexusmods.com/morrowind/mods/51656",
	}
	infoPage:createHyperLink{
		text = "JosephMcKean's morning staple is a Cha jau, Pu'er with condensed milk.",
		url = "https://www.nexusmods.com/morrowind/users/147999863?tab=user+files",
	}
	infoPage:createDropdown{
		label = "Log Level",
		description = "Set the logging level.",
		options = {
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable = mwse.mcm.createTableVariable { id = "logLevel", table = this.config },
	}
	template:createExclusionsPage{
		label = "Tea Merchants List",
		description = "Move merchants into the left list to allow them to offer Hot Tea services.",
		variable = mwse.mcm.createTableVariable { id = "teaMerchants", table = this.config },
		leftListLabel = "Merchants who offer Hot Tea services",
		rightListLabel = "Merchants",
		filters = {
			{
				label = "Merchants",
				callback = function()
					local merchants = {}
					for obj in tes3.iterateObjects(tes3.objectType.npc) do
						if not (obj.baseObject and obj.baseObject.id ~= obj.id) then
							-- Check if npc trades in ingredients
							if obj:tradesItemType(tes3.objectType.ingredient) then
								merchants[#merchants + 1] = (obj.baseObject or obj).id:lower()
							end
						end
					end
					table.sort(merchants)
					return merchants
				end,
			},
		},
	}
end

event.register("modConfigReady", modConfigReady)

return this
