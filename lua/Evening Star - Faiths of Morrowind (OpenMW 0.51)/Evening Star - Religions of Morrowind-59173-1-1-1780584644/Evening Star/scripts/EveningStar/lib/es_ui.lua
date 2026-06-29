-- ------------------------------ Evening Star : deity ui --------------------
-- the deity selection flow (wraps es_deity_ui), the settings-refresh handler, and the ui-mode
-- hook that closes the deity ui on esc. the sun's dusk hud icon lives in es_sd_widget.

local deityRecords = ES.DB.deities

local esDeityUi  = require('scripts.EveningStar.lib.es_deity_ui')
local esFavorBar = require('scripts.EveningStar.lib.es_favor_bar')

-- ------------------------------ tunables ----------------------------------

local FAVOR_START_ON_CHOOSE = 35 -- first deity
local FAVOR_START_SUBSEQUENT = 20 -- every deity after the first
local TRIBUNAL_DEITY_IDS = { "vivec", "almalexia", "sothasil" } -- change prefixes to tt_

-- ------------------------------ deity choice ui ---------------------------
-- delegates to es_deity_ui; worship is multi-deity, capped by ES.S.MAX_DEITIES

local function addDeity(deityId)
	deityId = deityId:lower()
	local startFavor = #ES.saveData.activeDeities == 0
		and FAVOR_START_ON_CHOOSE
		or FAVOR_START_SUBSEQUENT
	ES.saveData.deities[deityId] = {
		favor                = startFavor,
		devotionLevel        = 0,
		currentGift1         = nil,
		lastFavorGain        = core.getGameTime(),
		lastShrinePrayerTime = nil,
		shrinePrayerStreak   = nil,
		lastWorldInteraction = nil,
		mothersGraceReadyAt  = nil,
		booksRead            = {},
		journalsCredited     = {},
	}
	table.insert(ES.saveData.activeDeities, deityId)
	ES.lastDevotionLevel[deityId] = nil
	
	ES.updateAbilities()
	ES.updateDeityIcon()
	local deity = deityRecords[deityId]
	messageBox(2, string.format("You have devoted yourself to %s, %s.", deity.name, deity.title or ""))
	ambient.playSound("skillraise")
	G_columnsNeedUpdate = true
end

-- drop wipes the deity record; re-adopting later starts fresh
local function dropDeity(deityId)
	deityId = deityId:lower()
	local deity = deityRecords[deityId]
	local spells = typesActorSpellsSelf
	if deity then
		local prayId = "es_pray_"..deity.pantheonId.."_"..deity.id
		if core.magic.spells.records[prayId] then spells:remove(prayId) end
		for _, spellId in ipairs(deity.grantedSpells or {}) do
			if core.magic.spells.records[spellId] then spells:remove(spellId) end
		end
		if deity.gift_1 and core.magic.spells.records[deity.gift_1] then spells:remove(deity.gift_1) end
		if deity.gift_3 and core.magic.spells.records[deity.gift_3] then spells:remove(deity.gift_3) end
	end
	
	ES.saveData.deities[deityId] = nil
	for i, id in ipairs(ES.saveData.activeDeities) do
		if id == deityId then
			table.remove(ES.saveData.activeDeities, i)
			break
		end
	end
	ES.lastDevotionLevel[deityId] = nil
	
	ES.updateAbilities()
	ES.updateDeityIcon()
	G_columnsNeedUpdate = true
end

function ES.onDeityAccepted(deityId)
	deityId = deityId:lower()
	local deity = deityRecords[deityId]
	if not deity or deity.stub then
		messageBox(2, string.format("%s is not yet implemented.", deity and deity.name or "That deity"))
		I.UI.setMode()
		return
	end
	
	if ES.saveData.deities[deityId] then
		messageBox(3, string.format("You already worship %s.", deity.name))
		I.UI.setMode()
		return
	end
	
	local maxDeities = math.max(1, math.floor(tonumber(ES.S.MAX_DEITIES) or 1))
	if #ES.saveData.activeDeities >= maxDeities then
		-- single deity to drop: no real choice, swap it out without the drop screen
		if #ES.saveData.activeDeities == 1 then
			dropDeity(ES.saveData.activeDeities[1])
			addDeity(deityId)
			I.UI.setMode()
			return
		end
		-- slots full: pick one to abandon; pass favor + tier so the screen can label
		local active = {}
		for _, id in ipairs(ES.saveData.activeDeities) do
			local st = ES.saveData.deities[id]
			active[#active + 1] = {
				id    = id,
				favor = st and st.favor or 0,
				tier  = ES.DEVOTION_NAMES[ES.getDevotionLevel(id)],
			}
		end
		esDeityUi.showDropChoice{
			records     = deityRecords,
			active      = active,
			pendingId   = deityId,
			borderStyle = ES.S.BORDER_STYLE or "thin",
			borderColor = ES.S.BORDER_COLOR or util.color.rgb(1, 1, 1),
			onDrop      = function(droppedId)
				dropDeity(droppedId)
				addDeity(deityId)
				I.UI.setMode()
			end,
			onCancel    = function() I.UI.setMode() end,
		}
		return
	end
	
	addDeity(deityId)
	I.UI.setMode()
end

function ES.openDeityChoice(initialDeityId)
	-- initialDeityId (shrine path) skips the selector and opens that deity's tenets;
	-- nil opens the selector. the accept handler enforces the cap (drop dialogue).
	if type(initialDeityId) == "string" then
		initialDeityId = initialDeityId:lower()
		if ES.saveData.deities[initialDeityId] then return end
	else
		initialDeityId = nil
	end
	local available = {}
	for _, deityId in ipairs(TRIBUNAL_DEITY_IDS) do
		if not ES.saveData.deities[deityId] then
			available[#available + 1] = deityId
		end
	end
	if not initialDeityId and #available == 0 then
		messageBox(3, "You already worship every deity you can.")
		return
	end
	-- one-deity mode: accepting any new deity abandons the current one; hint at it
	local replaceWarning = nil
	local maxDeities = math.max(1, math.floor(tonumber(ES.S.MAX_DEITIES) or 1))
	if maxDeities == 1 and ES.saveData.activeDeities[1] then
		local current = deityRecords[ES.saveData.activeDeities[1]]
		if current then
			replaceWarning = string.format("Accepting will abandon your devotion to %s.", current.name)
		end
	end
	esDeityUi.show{
		records        = deityRecords,
		deityIds       = available,
		borderStyle    = ES.S.BORDER_STYLE or "thin",
		borderColor    = ES.S.BORDER_COLOR or util.color.rgb(1, 1, 1),
		onAccept       = ES.onDeityAccepted,
		onCancel       = function() I.UI.setMode() end,
		initialDeityId = initialDeityId,
		replaceWarning = replaceWarning,
	}
	I.UI.setMode("Interface", { windows = {} })
end

function ES.destroyDeityUi()
	esFavorBar.destroy()
	ES.destroyDeityIcon()
	esDeityUi.close()
	ES.lastDevotionLevel = {}
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
		if setting == "FAVOR_BAR_COLOR" then
			esFavorBar.preview(3)
		else
			esFavorBar.update()
		end
	elseif setting == "PRAYER_POWER" then
		ES.updateAbilities()
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