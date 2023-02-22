local this = {}
this.mod = "Tea Merchants"
this.version = "1.3"
local summary = "This mod is an addon for Ashfall. It adds Tea Merchants in the game."
local config = require("JosephMcKean.teaMerchants.config")

local function modConfigReady()
	-- don't register the mcm if Tea Merchants.esp is not enabled 
	if tes3.isModActive("Tea Merchants.esp") then
		-- add a nice header 
		local template = mwse.mcm.createTemplate {
			name = this.mod,
			headerImagePath = "MWSE/mods/JosephMcKean/teaMerchants/MCMHeader.tga",
		}
		template:register()
		template:saveOnClose(this.mod, config)

		-- INFO PAGE
		local infoPage = template:createPage{ label = "Info" }
		infoPage:createInfo({ text = this.mod .. " v" .. this.version .. "\n" .. summary })
		-- tea facts
		infoPage:createHyperLink{
			text = "Some people like morning coffee. JosephMcKean likes morning tea.",
			url = "https://www.nexusmods.com/morrowind/mods/51656",
		}
		infoPage:createHyperLink{
			text = "JosephMcKean's morning staple is a Cha jau, Pu'er with condensed milk.",
			url = "https://www.nexusmods.com/morrowind/users/147999863?tab=user+files",
		}
		-- this is not really a fix. it's just a feature, but i like how "Barter Gold Fix" sounds 
		infoPage:createYesNoButton{
			label = "Barter Gold Fix (When enabled, Tea Merchant's barter gold will increase accordingly after a purchase " ..
			"but this will cause an exploit where the player may buy a bottle of tea for low price and sell it right back for higher. Default: On)",
			variable = mwse.mcm.createTableVariable { id = "barterGoldFix", table = config },
		}
		-- set logging level
		infoPage:createDropdown{
			label = "Log Level",
			description = "Set the logging level.",
			options = {
				{ label = "DEBUG", value = "DEBUG" },
				{ label = "INFO", value = "INFO" },
				{ label = "ERROR", value = "ERROR" },
				{ label = "NONE", value = "NONE" },
			},
			variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
			-- code that copied over from merlord's mod
			callback = function(self)
				for _, log in ipairs(require("JosephMcKean.teaMerchants.logging").loggers) do
					mwse.log("Setting %s to log level %s", log.name, self.variable.value)
					log:setLogLevel(self.variable.value)
				end
			end,
		}

		-- TEA MERCHANT LIST
		local function createMerchantList()
			local merchants = {}
			---@param obj tes3npc
			for obj in tes3.iterateObjects(tes3.objectType.npc) do
				-- Check if npc trades in ingredients
				if obj:tradesItemType(tes3.objectType.ingredient) then
					merchants[#merchants + 1] = obj.id:lower()
				end
			end
			table.sort(merchants)
			return merchants
		end
		-- white list any merchants that sell ingredients to offer tea services
		template:createExclusionsPage{
			label = "Tea Merchants List",
			description = "Move merchants into the left list to allow them to offer Hot Tea services.",
			variable = mwse.mcm.createTableVariable { id = "teaMerchants", table = config },
			leftListLabel = "Merchants who offer Hot Tea services",
			rightListLabel = "Merchants", -- technically merchants who trade in ingredients
			filters = { { label = "Merchants", callback = createMerchantList } },
		}
	end
end
event.register("modConfigReady", modConfigReady)

return this
