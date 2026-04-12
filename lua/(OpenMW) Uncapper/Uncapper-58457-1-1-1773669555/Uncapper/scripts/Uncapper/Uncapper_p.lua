core = require('openmw.core')
self = require('openmw.self')
storage = require('openmw.storage')
types = require('openmw.types')
async = require('openmw.async')
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
ambient = require('openmw.ambient')
debug = require('openmw.debug')
vfs = require('openmw.vfs')
I = require("openmw.interfaces")
constants = require('scripts.omw.mwui.constants')
auxUi = require('openmw_aux.ui')
input = require('openmw.input')

MOD_NAME = "Uncapper"
SHOW_LEGACY_OPTION = false -- set to true to show the setting
USING_LEGACY_UNCAPPER = false -- tied to file size check:


-- Cache
stats = {}
statNames = {}
for _, rec in ipairs(core.stats.Attribute.records) do
	stats[rec.id] = types.NPC.stats.attributes[rec.id](self)
	statNames[rec.id] = rec.name
end
for _, rec in ipairs(core.stats.Skill.records) do
	stats[rec.id] = types.NPC.stats.skills[rec.id](self)
	statNames[rec.id] = rec.name
end
stats.level = types.Actor.stats.level(self)

local iLevelupTotal = core.getGMST("iLevelupTotal")

-- Debug
function dbg(...)
	if S_PrintDebug then
		print(...)
	end
end

-- Cap table
require("scripts.Uncapper.Uncapper_capTable")

-- Settings
require("scripts.Uncapper.Uncapper_settings")

-- Apply settings to cap table
applyCapsFromSettings()


-- Legacy uncapper
local function getFileSize(path)
	local f = vfs.open(path)
	if f then
		local size = f:seek("end")
		f:close()
		return size
	else
		return -1
	end
end
USING_LEGACY_UNCAPPER = USING_LEGACY_UNCAPPER or getFileSize("scripts/omw/playerskillhandlers.lua") ~= 7847 or core.API_REVISION <= 97

if USING_LEGACY_UNCAPPER then
	print("USING LEGACY UNCAPPER", getFileSize("scripts/omw/playerskillhandlers.lua"), core.API_REVISION)
else
	--print("Using the modern uncapper")
end

require("scripts.Uncapper.Uncapper_legacy")

require("scripts.Uncapper.levelup")



--------------------------------------------------------------- Attribute restore helpers ---------------------------------------------------------------

local function restoreAttributes()
	for id, diff in pairs(saveData.storedAttributes) do
		dbg(id, stats[id].base, "->", stats[id].base + diff)
		stats[id].base = stats[id].base + diff
	end
	saveData.storedAttributes = {}
end

--------------------------------------------------------------- UiModeChanged ---------------------------------------------------------------

local function UiModeChanged(data)
	if legacy_UiModeChanged then
		legacy_UiModeChanged(data)
	end
	
	-- attribute uncapper (TemporaryCap mode only)
	if S_AttributeUncapper and S_attributeUncapperMode == "TemporaryCap" then
		if data.oldMode == "Rest" then
			if stats.level.progress >= iLevelupTotal then
				local iLevelUp10Mult = core.getGMST('iLevelUp10Mult') or 10
				for _, rec in ipairs(core.stats.Attribute.records) do
					local currentBase = stats[rec.id].base
					local allowedGain = getAttrAllowedGain(rec.id)
					local effectiveCeiling = 100 - math.min(iLevelUp10Mult, allowedGain)
					if currentBase > effectiveCeiling then
						local diff = currentBase - effectiveCeiling
						saveData.storedAttributes[rec.id] = diff
						dbg(rec.id, stats[rec.id].base, "->", currentBase - diff)
						stats[rec.id].base = currentBase - diff
					end
				end
			end
			async:newUnsavableSimulationTimer(0, restoreAttributes)
		end
	end
end



--------------------------------------------------------------- StatsWindow progress bar ---------------------------------------------------------------

local function initStatsWindow()
	if not I.StatsWindow then return end
	local API = I.StatsWindow
	local C = API.Constants
	local BASE = API.Templates.BASE
	local STATS = API.Templates.STATS

	API.overrideTooltipBuilder('SKILL', function(params)
		local base = API.TooltipBuilders.ICON(params)
		local progress = params.progress or 0
		
		-- progress bar tooltip
		base.content[1].content.tooltip.content:add({
			name = 'progress',
			type = ui.TYPE.Flex,
			props = {
				arrange = ui.ALIGNMENT.Center,
			},
			external = {
				stretch = 1,
			},
			content = ui.content {
				BASE.padding(4),
				-- header
				{
					template = BASE.textHeader,
					props = {
						text = C.Strings.SKILL_PROGRESS,
						textSize = STATS.TEXT_SIZE,
					},
				},
				-- bar
				STATS.progressBar {
					value = progress * 100,
					maxValue = 100,
					size = util.vector2(200, STATS.LINE_HEIGHT),
					color = C.Colors.BAR_HEALTH,
				},
			},
		})
		
		return base
	end)
end
async:newUnsavableSimulationTimer(0.1, initStatsWindow)


--------------------------------------------------------------- Save / Load ---------------------------------------------------------------

local function onLoad(data)
	saveData = data or {}
	saveData.storedSkills = saveData.storedSkills or {}
	saveData.storedAttributes = saveData.storedAttributes or {}
end

local function onSave()
	return saveData
end

----------------------------------------------------
----------------------------------------------------
----------------------------------------------------



return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onControllerButtonPress = onLevelUpControllerButtonPress,
		onControllerButtonRelease = onLevelUpControllerButtonRelease,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		Uncapper_roundtrip = Uncapper_roundtrip,
		Uncapper_IVLRoundtrip = Uncapper_IVLRoundtrip,
	},
	interfaceName = "Uncapper",
	interface = {
		version = 3,
		isSkillUncapperEnabled = function()
			return S_enableSkillUncapper
		end,
		isSkillUncapperOverride = function()
			return S_enableSkillUncapper and not USING_LEGACY_UNCAPPER
		end,
		isXPMultEnabled = function()
			return S_enableXPMult
		end,
		getSkillMult = function(skillId)
			return _G["S_SKILL_MULT_"..skillId] or 1
		end,
		getGlobalXPMult = function()
			return S_globalXPMult
		end,
		getCatchUpSpeed = function()
			return S_CATCH_UP_SPEED
		end,
		getSkillSoftCap = function(skillId) 
			local cap = capTable[skillId]
			return cap and cap.softCap or 100
		end,
		getSkillXPMultAtSoftCap = function(skillId)
			local cap = capTable[skillId]
			return cap and cap.xpMultAtSoftCap or 1
		end,
		getSkillHardCap = function(skillId)
			local cap = capTable[skillId]
			return cap and cap.hardCap or math.huge
		end,
		getAttributeHardCap = function(attrId)
			local cap = capTable[attrId]
			return cap and cap.hardCap or math.huge
		end,
		isDebugEnabled = function()
			return S_PrintDebug
		end,
	},
}