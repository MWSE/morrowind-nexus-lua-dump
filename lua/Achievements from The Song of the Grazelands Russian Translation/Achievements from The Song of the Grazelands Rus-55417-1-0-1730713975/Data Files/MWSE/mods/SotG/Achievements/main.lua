local sb_achievements = require("sb_achievements.interop")
local colours = {
		greenSotG  = { 63 / 255, 193 / 255, 55 / 255 },
		}

local function checkBook(e)
			if tes3.player.data.achievements.SotG_5 == false
				then
				if e.book.id == "KJS_song_grazelands" then SotGBook = true
				end
			end
		end

local function initializedcheckBook()
		SotGBook = false
		if tes3.player.data.achievements.SotG_5 == false
		then 
		event.register("bookGetText", checkBook)
		end
	  end
event.register(tes3.event.loaded, initializedcheckBook)

local function init()
	local iconPath = "Icons\\SotG\\"

	local cats = {
		main = sb_achievements.registerCategory("Главные задания"),
		side = sb_achievements.registerCategory("Побочные задания"),
		faction = sb_achievements.registerCategory("Задания фракций"),
		misc = sb_achievements.registerCategory("Разное")
	}

	sb_achievements.registerAchievement {
		id = "SotG_1",
		category = cats.side,
		condition = function()
			return tes3.getJournalIndex { id = "KJS_SotG_Deserters" } >= 30
		end,
		icon = iconPath .. "SotG_Deserters.tga",
		colour = colours.greenSotG,
		title = "Смерть Предателям", desc = "Совершите справедливую казнь дезертиров.",
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}
	
	sb_achievements.registerAchievement {
		id = "SotG_2",
		category = cats.side,
		condition = function()
			return tes3.getJournalIndex { id = "KJS_SotG_Pal" } >= 90
		end,
		icon = iconPath .. "SotG_Pal.tga",
		colour = colours.greenSotG,
		title = "Ох Уж Эти Ученые...", desc = "Помогите Эдуарду Вертьену решить его проблемы.",
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}
	
	sb_achievements.registerAchievement {
		id = "SotG_3",
		category = cats.side,
		condition = function()
			return tes3.getJournalIndex { id = "KJS_SotG_Mabrigash" } >= 60
		end,
		icon = iconPath .. "SotG_Mabrigash.tga",
		colour = colours.greenSotG,
		title = "Новые Друзья", desc = "Помогите Тахимса-Тии разобраться с ее заботами.",
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}
	
	sb_achievements.registerAchievement {
		id = "SotG_4",
		category = cats.side,
		condition = function()
			return tes3.getJournalIndex { id = "KJS_SotG_Vert" } >= 30
		end,
		icon = iconPath .. "SotG_Vert.tga",
		colour = colours.greenSotG,
		title = "Я Не Художник!", desc = "Не думаю, что кому-то захочется ему помогать.",
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}
	
	sb_achievements.registerAchievement {
		id = "SotG_5",
		category = cats.misc,
		condition = function()
			return SotGBook == true
		end,
		icon = iconPath .. "SotG_Song.tga",
		colour = colours.greenSotG,
		title = "Песнь Грейзленда", desc = "Прочтите Песнь Грейзленда.",
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

end

local function initializedCallback(e)
	init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
