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
		if tes3.player.data.achievements.SotG_5 == false and not event.isRegistered("bookGetText", checkBook)
		then 
		event.register("bookGetText", checkBook)
		end
	  end
event.register(tes3.event.loaded, initializedcheckBook)

local function init()
	local iconPath = "Icons\\SotG\\"

	local cats = {
		main = sb_achievements.registerCategory("Main Quest"),
		side = sb_achievements.registerCategory("Side Quest"),
		faction = sb_achievements.registerCategory("Faction"),
		misc = sb_achievements.registerCategory("Miscellaneous")
	}

	sb_achievements.registerAchievement {
		id = "SotG_1",
		category = cats.side,
		condition = function()
			return tes3.getJournalIndex { id = "KJS_SotG_Deserters" } >= 30
		end,
		icon = iconPath .. "SotG_Deserters.tga",
		colour = colours.greenSotG,
		title = "Death to Traitors", desc = "Carry out a just execution of the deserters.",
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
		title = " Oh, Those Scientists...", desc = "Help Edouard Vertainne solve his problems.",
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
		title = "New Friends", desc = "Help Tahimsa-Ti deal with her worries.",
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
		title = "I'm Not an Artist!", desc = "I don't think anyone would want to help him.",
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
		title = "The Song of the Grazelands", desc = "Read the Song of the Grazelands",
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

end

local function initializedCallback(e)
	init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
