-- Check Magicka Expanded framework.
local common = require("OperatorJack.MagickaExpanded.common")

local function createGeneralCategory(template)
    local page = template:createPage{
        label = "Настройки",
    }

	page:createInfo{
		text = "Эти функции добавляют все заклинания и книги заклинаний, используемые в рамках Magicka Expanded.\nИспользуются для тестирования и предварительного просмотра заклинаний."
	}
	page:createButton{
		buttonText = "Добавить все заклинания",
		callback = function()
			if (tes3.player ~= nil) then
				common.addTestSpellsToPlayer()
				tes3.messageBox("[Расширенная магия] Игроку добавлены все загруженные на данный момент заклинания.")
				common.info("Игроку добавлены все загруженные на данный момент заклинания.")
			end
		end,
		inGameOnly = true,
	}
	page:createButton{
		buttonText = "Добавить все тома и гримуары",
		callback = function()
			if (tes3.player ~= nil) then
				local tomes = require("OperatorJack.MagickaExpanded.classes.tomes")
				local grimoires = require("OperatorJack.MagickaExpanded.classes.grimoires")
				tomes.addTomesToPlayer()
				grimoires.addGrimoiresToPlayer()
				tes3.messageBox("[Расширенная магия] Игроку добавлены все загруженные на данный момент книги заклинаний.")
				common.info("Added all currently loaded spellbooks to player.")
			end
		end,
		inGameOnly = true,
	}
	page:createInfo{
		text = "\nЭта функция увеличивает Магию на 5000 и устанавливает Интеллект, Силу воли и шесть магических навыков, связанных с заклинаниями, на 100."
	}
	page:createButton{
		buttonText = "Повышение магии и магических навыков",
		callback = function()
			if (tes3.player ~= nil) then
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					attribute = 1,
					current = 100
				})
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					attribute = 2,
					current = 100
				})
				--fuck me, fuck lua scripting and fuck this particular chunk of code
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					name = "magicka",
					value = 5000
				})
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					skill = 11,
					current = 100
				})
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					skill = 10,
					current = 100
				})
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					skill = 15,
					current = 100
				})
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					skill = 13,
					current = 100
				})
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					skill = 12,
					current = 100
				})
				tes3.setStatistic({
					reference = tes3.mobilePlayer,
					skill = 14,
					current = 100
				})
				tes3.messageBox("[Расширенная магия] Увеличены магические атрибуты и навыки игрока.")
				common.info("Увеличены магические атрибуты и навыки игрока.")
			end
		end,
		inGameOnly = true,
	}
end

local template = mwse.mcm.createTemplate("Расширенная магия")
--template:saveOnClose("Magicka Expanded", config) :: Currently no config, just debug functions.

createGeneralCategory(template)

mwse.mcm.register(template)