local this = {}
this.mod = "Торговцы чаем"
this.version = "1.4.1"
local summary = "Этот мод является дополнением для мода Пеплопад. Он добавляет в игру торговцев чаем."
local config = require("JosephMcKean.teaMerchants.config")

local LINKS_LIST = {
	{
		text = "Некоторые люди любят утренний кофе. JosephMcKean любит утренний чай.",
		url = "https://www.nexusmods.com/morrowind/mods/51656",
	},
	{
		text = "Утренний напиток JosephMcKean это Cha jau, Pu'er with condensed milk.",
		url = "https://www.nexusmods.com/morrowind/users/147999863?tab=user+files",
    },
}

local function addSideBar(component)
    local versionText = string.format(this.mod .. " Версия " .. this.version)
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = summary}

    local linksCategory = component.sidebar:createCategory("Ссылки:")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
end

local function modConfigReady()
	-- don't register the mcm if Tea Merchants.esp is not enabled 
	if tes3.isModActive("Tea Merchants.esp") then
		-- add a nice header 
		local template = mwse.mcm.createTemplate {
			name = this.mod,
			headerImagePath = "MWSE/mods/JosephMcKean/teaMerchants/MCMHeader.tga",
		}
		template:register()
		--template:saveOnClose(this.mod, config)
		template:saveOnClose("Tea Merchants", config)

		-- INFO PAGE
		--local infoPage = template:createPage{ label = "Информация" }
		--infoPage:createInfo({ text = this.mod .. " Версия:" .. this.version .. "\n" .. summary })
		local infoPage = template:createSideBarPage{ label = "Настройки" }
        addSideBar(infoPage)
		-- tea facts
		--infoPage:createHyperLink{
			--text = "Некоторые люди любят утренний кофе. JosephMcKean любит утренний чай.",
			--url = "https://www.nexusmods.com/morrowind/mods/51656",
		--}
		--infoPage:createHyperLink{
			--text = "Утренний напиток JosephMcKean это Cha jau, Pu'er with condensed milk.",
			--url = "https://www.nexusmods.com/morrowind/users/147999863?tab=user+files",
		--}
		-- this is not really a fix. it's just a feature, but i like how "Barter Gold Fix" sounds 
		infoPage:createYesNoButton{
			label = "Фикс золота торговца",
			description = "Когда эта функция включена, золото торговца чаем будет соответственно увеличиваться после покупки но это приведет к тому, что игрок может купить бутылку чая по низкой цене и тут же продать ее обратно по более высокой. По умолчанию: Вкл.",
			variable = mwse.mcm.createTableVariable { id = "barterGoldFix", table = config },
		}
		-- set logging level
		infoPage:createDropdown{
			label = "Log Level",
			description = "Установите уровень ведения журнала.",
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
			---@param npc tes3object
			for npc in tes3.iterateObjects(tes3.objectType.npc) do
				---@cast npc tes3npc
				-- Check if npc trades in ingredients
				if npc:tradesItemType(tes3.objectType.ingredient) then
					merchants[#merchants + 1] = npc.id:lower()
				end
			end
			table.sort(merchants)
			return merchants
		end
		-- white list any merchants that sell ingredients to offer tea services
		template:createExclusionsPage{
			label = "Список торговцев чаем",
			description = "Переместите торговцев в левый список, чтобы они могли предлагать горячий чай.",
			variable = mwse.mcm.createTableVariable { id = "teaMerchants", table = config },
			leftListLabel = "Торговцы, предлагающие горячий чай",
			rightListLabel = "Торговцы", -- technically merchants who trade in ingredients
			filters = { { label = "Торговцы", callback = createMerchantList } },
		}
	end
end
event.register("modConfigReady", modConfigReady)

return this
