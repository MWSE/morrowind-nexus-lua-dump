-- загружаем файл интеграции The Achievement Framework
local sb_achievements = require("sb_achievements.interop")
-- загружаем функциональный файл мода
local wData = require("Pirate.Wyrmhaven.WyrmData")
-- объявляем локальные переменные.
local pData
-- проверяем подключен ли мод Morrowind Achievement Collection.
local isActive = tes3.isLuaModActive("MAC")
if isActive == true then
    -- если да, то загружаем данные pData из этого мода.
    pData = include("MAC.playerData")
	else
	-- если нет то назначаем локальные значения цветов.
	pData = {
        colours = {
            bronze  = { 255 / 255, 140 / 255, 20 / 255 },
            silver  = { 200 / 255, 200 / 255, 255 / 255 },
            gold    = { 203 / 255, 190 / 255, 53 /255},
            plat    = { 200 / 255, 240 / 255, 200 / 255}
            }
        }
end
local i18n = mwse.loadTranslations("Pirate.Wyrmhaven")
-------------------------------------------------
local function init()
    -- указываем путь к папке с иконками для данного мода.
	local iconPath = "Icons\\Ach_Wyrm\\"
    -- регистрируем категории достижений. Нужно всегда регистрировать все категории, даже если в конкретном моде используется одна, чтобы не менялся порядок отображения категорий в окне персонажа, при подключении новых модов.
	local cats = {
		main = sb_achievements.registerCategory(i18n("Main Quest")),
		side = sb_achievements.registerCategory(i18n("Side Quest")),
		faction = sb_achievements.registerCategory(i18n("Faction")),
		misc = sb_achievements.registerCategory(i18n("Miscellaneous"))
	}
    -- настройки достижений.
	sb_achievements.registerAchievement {
		-- ID достижения, должно быть уникальным для каждого достижения.
		id = "Wyrm_Kyn_1",
		-- категория, к которой относится достижение.
		category = cats.faction,
		-- условие, которое должно выполняться, чтобы достижение открылось.
		condition = function()
			return tes3.getFaction("Knights of Kynareth").playerJoined
		end,
		-- имя иконки для данного достижения.
		icon = iconPath .. "Wyrm_Kyn_1.tga",
		-- цвет данного достижения.
		colour = pData.colours.bronze,
		-- название и описание достижения.
		title = i18n("Wyrm_Kyn_1.Name"), desc = i18n("Wyrm_Kyn_1.Desc"),
		-- настройка отображения описания неоткрытого достижения.
		configDesc = sb_achievements.configDesc.showDesc,
		-- настройка текста, отображаемого в описании неоткрытого достижения.
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_Laureloss_1",
		category = cats.faction,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_02_Laureloss" } == 100
		end,
		icon = iconPath .. "Wyrm_Kyn_Laureloss_1.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Kyn_Laureloss_1.Name"), desc = i18n("Wyrm_Kyn_Laureloss_1.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_Laureloss_2",
		category = cats.faction,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_02_Laureloss" } == 110
		end,
		icon = iconPath .. "Wyrm_Kyn_Laureloss_2.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Kyn_Laureloss_2.Name"), desc = i18n("Wyrm_Kyn_Laureloss_2.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_Witch_1",
		category = cats.faction,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_18_Witch" } == 100
		end,
		icon = iconPath .. "Wyrm_Kyn_Witch_1.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Kyn_Witch_1.Name"), desc = i18n("Wyrm_Kyn_Witch_1.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_Witch_2",
		category = cats.faction,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_18_Witch" } == 110
		end,
		icon = iconPath .. "Wyrm_Kyn_Witch_2.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Kyn_Witch_2.Name"), desc = i18n("Wyrm_Kyn_Witch_2.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_SirUldorCorpse",
		category = cats.faction,
        condition = function()
            local myData = wData.getData()
            if tes3.getJournalIndex { id = "WYRM_19_Chimeranyon" } >= 40
			    and (myData["EquipSirUldorCorpse"]) == 1 then
                event.unregister(tes3.event.equipped, wData.countSirUldorCorpse)
                return true
            end
		end,
		icon = iconPath .. "Wyrm_SirUldorCorpse.tga",
		colour = pData.colours.gold,
		title = i18n("Wyrm_SirUldorCorpse.Name"), desc = i18n("Wyrm_SirUldorCorpse.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_Baby_1",
		category = cats.faction,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_22_Baby" } == 30 or tes3.getJournalIndex { id = "WYRM_22_Baby" } == 40
		end,
		icon = iconPath .. "Wyrm_Kyn_Baby_1.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Kyn_Baby_1.Name"), desc = i18n("Wyrm_Kyn_Baby_1.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_Baby_2",
		category = cats.faction,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_22_Baby" } == 50
		end,
		icon = iconPath .. "Wyrm_Kyn_Baby_2.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Kyn_Baby_2.Name"), desc = i18n("Wyrm_Kyn_Baby_2.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_Council_1",
		category = cats.faction,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_25_Council" } == 100
		end,
		icon = iconPath .. "Wyrm_Kyn_Council_1.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Kyn_Council_1.Name"), desc = i18n("Wyrm_Kyn_Council_1.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_Council_2",
		category = cats.faction,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_25_Council" } >= 110
		end,
		icon = iconPath .. "Wyrm_Kyn_Council_2.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Kyn_Council_2.Name"), desc = i18n("Wyrm_Kyn_Council_2.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_2",
		category = cats.faction,
		condition = function()
			return tes3.getFaction("Knights of Kynareth").playerRank >= 8
		end,
		icon = iconPath .. "Wyrm_Kyn_2.tga",
		colour = pData.colours.silver,
		title = i18n("Wyrm_Kyn_2.Name"), desc = i18n("Wyrm_Kyn_2.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Kyn_3",
		category = cats.faction,
		condition = function()
			return tes3.getFaction("Knights of Kynareth").playerRank >= 9
		end,
		icon = iconPath .. "Wyrm_Kyn_3.tga",
		colour = pData.colours.silver,
		title = i18n("Wyrm_Kyn_3.Name"), desc = i18n("Wyrm_Kyn_3.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_Tower",
		category = cats.misc,
		condition = function()
			return tes3.getJournalIndex { id = "WYRM_00_EadricsTower" } >= 100
		end,
		icon = iconPath .. "Wyrm_Tower.tga",
		colour = wData.colours.BlueWyrm,
		title = i18n("Wyrm_Tower.Name"), desc = i18n("Wyrm_Tower.Desc"),
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_OneManBand",
		category = cats.misc,
        condition = function()
            local myData = wData.getData()
            if (myData["MusicalInstrumentsCount"]) == 3 then
                event.unregister(tes3.event.activate, wData.countMusicalInstr)
                return true
            end
		end,
		icon = iconPath .. "Wyrm_OneManBand.tga",
		colour = pData.colours.silver,
		title = i18n("Wyrm_OneManBand.Name"), desc = i18n("Wyrm_OneManBand.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_black_knight",
		category = cats.misc,
		condition = function()
			return wData.black_knight == true
		end,
		icon = iconPath .. "Wyrm_black_knight.tga",
		colour = pData.colours.gold,
		title = i18n("Wyrm_black_knight.Name"), desc = i18n("Wyrm_black_knight.Desc"),
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_GhostGalleon",
		category = cats.misc,
		condition = function()
			return wData.GhostGalleon == true
		end,
		icon = iconPath .. "Wyrm_GhostGalleon.tga",
		colour = pData.colours.gold,
		title = i18n("Wyrm_GhostGalleon.Name"), desc = i18n("Wyrm_GhostGalleon.Desc"),
		configDesc = sb_achievements.configDesc.groupHidden,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

	sb_achievements.registerAchievement {
		id = "Wyrm_cursed_ring",
		category = cats.misc,
		condition = function()
			return tes3.getItemCount({ reference = "player", item = "_WYRM_cursed_ring_magicka" }) >0
		end,
		icon = iconPath .. "Wyrm_cursed_ring.tga",
		colour = pData.colours.silver,
		title = i18n("Wyrm_cursed_ring.Name"), desc = i18n("Wyrm_cursed_ring.Desc"),
		configDesc = sb_achievements.configDesc.hideDesc,
		lockedDesc = sb_achievements.lockedMessage.steamKeepPlaying
	}

end
-- регистрируем функцию инициализации достижений.
local function initializedCallback(e)
	init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })
event.register(tes3.event.loaded, wData.initachieveWyrm)
