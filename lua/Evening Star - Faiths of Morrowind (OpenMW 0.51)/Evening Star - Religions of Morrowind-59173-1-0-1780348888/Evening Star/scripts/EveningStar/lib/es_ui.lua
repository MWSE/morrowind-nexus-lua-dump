-- ------------------------------ Evening Star : deity ui + hud icon --------
-- the deity selection flow (wraps es_deity_ui), the sun's dusk hud deity
-- icon, the settings-refresh handler, and the rare shrine-activated event
-- echo. closes the deity ui on esc via its own ui-mode subscription.

local deityRecords = ES.DB.deities

local esDeityUi  = require('scripts.EveningStar.lib.es_deity_ui')
local esFavorBar = require('scripts.EveningStar.lib.es_favor_bar')

-- ------------------------------ tunables ----------------------------------

local FAVOR_START_ON_CHOOSE = 35
local TRIBUNAL_DEITY_IDS = { "vivec", "almalexia", "sothasil" } -- change prefixes to tt_

-- ------------------------------ state -------------------------------------

local deityIconWidget = nil
local lastDeityId     = nil

-- ------------------------------ deity choice ui ---------------------------
-- delegates to es_deity_ui (two-screen: selector + tenets). accept handler
-- sets the deity and seeds starting favor.

function ES.onDeityAccepted(deityId)
	local deity = deityRecords[deityId:lower()]
	if not deity or deity.stub then
		messageBox(2, string.format("%s is not yet implemented.", deity and deity.name or "That deity"))
		I.UI.setMode()
		return
	end
	-- remove the previous deity's spells before switching (deterministic from the
	-- record); updateAbilities then grants the new deity's pray power + spells.
	local spells = typesActorSpellsSelf
	local prev = ES.saveData.currentDeity and deityRecords[ES.saveData.currentDeity]
	if prev then
		local prevPray = "es_pray_"..prev.pantheonId.."_"..prev.id
		if core.magic.spells.records[prevPray] then spells:remove(prevPray) end
		for _, spellId in ipairs(prev.grantedSpells or {}) do
			if core.magic.spells.records[spellId] then spells:remove(spellId) end
		end
	end

	ES.saveData.currentDeity = deityId:lower()
	ES.saveData.favor = math.max(ES.saveData.favor or 0, FAVOR_START_ON_CHOOSE)
	ES.saveData.booksRead = ES.saveData.booksRead or {}
	ES.saveData.journalsCredited = ES.saveData.journalsCredited or {}
	ES.saveData.lastFavorGain = core.getGameTime()

	ES.lastDevotionLevel = nil
	ES.updateAbilities()
	ES.updateDeityIcon()
	messageBox(2, string.format("You have devoted yourself to %s, %s.", deity.name, deity.title or ""))
	ambient.playSound("skillraise")	
	G_columnsNeedUpdate = true
	I.UI.setMode()
end

function ES.openDeityChoice(initialDeityId)
	-- initialDeityId (shrine path): skips the selector and opens that deity's
	-- tenets directly; Cancel closes the UI. nil opens the selector first
	-- (first-sleep prompt / generic flow); Cancel there returns to selector.
	-- already worship this exact deity: nothing to switch to
	if initialDeityId and ES.saveData.currentDeity == initialDeityId then return end
	-- generic flow blocks once worshipping; the shrine path may switch deities
	if ES.saveData.currentDeity and not initialDeityId then
		local cur = deityRecords[ES.saveData.currentDeity]
		messageBox(3, string.format("You already worship %s.", cur and cur.name or "a deity"))
		return
	end
	esDeityUi.show{
		records        = deityRecords,
		deityIds       = TRIBUNAL_DEITY_IDS,
		borderStyle    = ES.S.BORDER_STYLE or "thin",
		borderColor    = ES.S.BORDER_COLOR,
		onAccept       = ES.onDeityAccepted,
		onCancel       = function() I.UI.setMode() end,
		initialDeityId = initialDeityId,
	}
	I.UI.setMode("Interface", { windows = {} })
end

-- ------------------------------ deity hud icon ----------------------------

function ES.destroyDeityIcon()
	if deityIconWidget then
		deityIconWidget:destroy()
		deityIconWidget = nil
	end
	if G_columnWidgets and G_columnWidgets.m_deity_icon then
		G_columnWidgets.m_deity_icon = nil
		G_columnsNeedUpdate = true
	end
end

function ES.updateDeityIcon()
	if not ES.S.TOGGLE_ENABLED or not ES.S.TOGGLE_SHOW_ICON or ES.S.ICON_DISPLAY == "Never" then
		ES.destroyDeityIcon()
		return
	end
	if not ES.saveData.currentDeity then
		ES.destroyDeityIcon()
		return
	end
	local deity = ES.getCurrentDeity()
	if not deity then
		ES.destroyDeityIcon()
		return
	end

	if not G_columnWidgets then G_columnWidgets = {} end
	local tex = getTexture("textures/SunsDusk/deities/"..deity.id..".png")

	if not deityIconWidget or lastDeityId ~= ES.saveData.currentDeity then
		ES.destroyDeityIcon()

		local bg = ES.S.ICON_BACKGROUND ~= "No Background" and {
			name = "es_icon_bg",
			type = ui.TYPE.Image,
			props = {
				resource = ES.S.ICON_BACKGROUND == "Classic"
					and getTexture("textures/SunsDusk/deities/BlankTexture.png")
					or tex,
				color = ES.S.ICON_BACKGROUND == "Classic" and ES.S.ICON_BACKGROUND_COLOR or util.color.rgb(0,0,0),
				relativeSize = v2(1, 1),
				relativePosition = ES.S.ICON_BACKGROUND == "Shadow" and v2(0.04, 0.027) or nil,
				alpha = 1,
			},
		} or {}

		local icon = {
			name = "es_icon",
			type = ui.TYPE.Image,
			props = {
				resource = tex,
				color = ES.S.ICON_COLOR,
				relativeSize = v2(1, 1),
				alpha = 1,
			},
		}

		deityIconWidget = ui.create{
			name = "m_deity_icon",
			type = ui.TYPE.Widget,
			props = { size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE) },
			userData = {
				order = "widget-deity",
			},
			content = ui.content { bg, icon },
		}

		G_columnWidgets.m_deity_icon = deityIconWidget
		lastDeityId = ES.saveData.currentDeity
		G_columnsNeedUpdate = true
	end

	-- tooltip
	local level = ES.getDevotionLevel(ES.saveData.favor or 0)
	local levelStr = level:sub(1,1):upper() .. level:sub(2)
	local tip = string.format("%s\n%s\nFavor: %.2f%% (%s)",
		deity.name, deity.title or "", ES.saveData.favor or 0, levelStr)
	addTooltip(deityIconWidget.layout, tip)
end

function ES.destroyDeityUi()
	esFavorBar.destroy()
	ES.destroyDeityIcon()
	esDeityUi.close()
	lastDeityId = nil
	ES.lastDevotionLevel = nil
end
table.insert(G_destroyHudJobs, ES.destroyDeityUi)

-- ------------------------------ settings refresh --------------------------

function ES.settingsChanged(sectionName, setting, oldValue)
	if setting == "TOGGLE_ENABLED" then
		if not ES.S.TOGGLE_ENABLED then
			ES.destroyDeityUi()
		else
			esFavorBar.update()
			ES.updateDeityIcon()
		end
	elseif setting and setting:find("ICON") then
		ES.destroyDeityIcon()
		ES.updateDeityIcon()
	elseif setting and setting:find("FAVOR_BAR") then
		esFavorBar.destroy()
		esFavorBar.update()
	end
end
table.insert(G_settingsChangedJobs, ES.settingsChanged)

-- ------------------------------ ui mode hook ------------------------------
-- close deity choice ui when mode is cleared externally (esc)

table.insert(G_UiModeChangedJobs, function(data)
	if not ES.S.TOGGLE_ENABLED then return end
	if esDeityUi.isOpen() and not data.newMode then
		esDeityUi.close()
	end
end)

-- post-frame icon refresh once UI templates are ready
table.insert(G_onLoadJobs, ES.updateDeityIcon)