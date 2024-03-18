
-- In a player script
local storage  = require('openmw.storage')
local settings = require('openmw.interfaces').Settings
local async    = require('openmw.async')
local self  = require('openmw.self')
local ui       = require('openmw.ui')
local i_UI  = require('openmw.interfaces').UI

local Dt       = require('scripts.Gentler_Racemenu.data').Dt

local function num_range(min, max, step) -- " Why have I done this "
  if math.abs(step) < 0.0001 then print('GRM: step must not be between -0.0001 and 0.0001') return nil end
  local num_range = {}
  digits = {tostring(step):find('%.(%d*)')}
  if not digits[3] then digits[3] = '' end
  digits = '%.'..#tostring(digits[3])..'f'
  for i=min, max, step do table.insert(num_range, 0 + string.format(digits, tostring(i))) end
  return num_range
end

local function array_concat(array, ...)
  for _, t in ipairs({...}) do
    for _, v in ipairs(t) do table.insert(array, v) end
  end
  return array
end

local function makeKeyEnum(keys) local result = {} for _, key in ipairs(keys) do result[key] = true end return result end

local function edit_args(base, changes) for k, v in pairs(changes) do base[k] = v end return base end

local function get(svar) -- s in svar means serializable | Recursions WILL stack overflow :D
  if type(svar)  ~= 'table' then return svar
  else
    local deepcopy = {}
    for _key, _value in pairs(svar) do deepcopy[_key] = get(_value) end
    return deepcopy
  end
end

local Mui = {}

Mui.presets = {
	custom = {}, default = {
    Purge_Spells         = false,
    Force_Dynamic_Stats  = false,
		Keep_Stats_Unchanged = false,
		Respect_Caps         = false,
		Migration_Mode       = false,
		GRM_DEBUG = false,
	}
}

Mui.SKILLS_MAP = makeKeyEnum(Dt.SKILLS)
Mui.toggles = {
}

Mui.settingsGroups = {}
function addSettingsGroup(name)
	local groupid = "Settings_GRM_"..name
	Mui[groupid] = {}
	storage.playerSection(groupid):reset()
	table.insert(Mui.settingsGroups, groupid)
end

settings.registerPage {
  key         = 'grmconfig',
  l10n        = 'Gentler_Racemenu',
  name        = 'Gentler Racemenu',
  description = '',
}

addSettingsGroup('Options')
--Mui.Settings_GRM_options.args = {
--  Setting_Id = {l10n = 'Gentler_Racemenu', items = array_concat(), disabled = false},
--}
settings.registerGroup {
  key              = 'Settings_GRM_Options',
  name             = 'Options',
  page             = 'grmconfig',
  order            = 0,
  l10n             = 'Gentler_Racemenu',
  permanentStorage = false,
  settings         = {
    {
    key         = 'Keep_Stats_Unchanged',
    name        = 'Keep Stats Unchanged',
    description = 'Restore your stats as-is instead of accounting for racial and class bonuses.',
		renderer    = 'checkbox',
		default     = Mui.presets.default.Keep_Stats_Unchanged,
    },{
    key         = 'Respect_Caps',
    name        = 'Respect Vanilla Stat Cap',
    description = 'Clamp stats down to a max of 100 after applying race and class bonuses.\n A message will be printed to the console with the total amount of stats lost, so you can add them back to different skills/attributes (through console commands) if you so desire.',
		renderer    = 'checkbox',
		default     = Mui.presets.default.Respect_Caps,
    },{
    key         = 'Force_Dynamic_Stats',
    name        = 'Force MP and FP',
    description = 'Forcefully restore Magic and Stamina.\n On vanilla this is not necessary as they will recalculate themselves.\n Toggle this on if you have mods that apply custom formulas.\n HP is always restored regardless of this setting, as the vanilla formula doesn\'t handle it properly.',
  	renderer    = 'checkbox',
  	default     = Mui.presets.default.Force_Dynamic_Stats,
    },{
    key         = 'Purge_Spells',
    name        = 'Purge Spells',
    description = 'Remove all race and birthsign spells known by GRM from your character\'s spell list, instead of only the ones from your current load order.\n Enabling this may help you if you run into compatibility issues.',
  	renderer    = 'checkbox',
  	default     = Mui.presets.default.Purge_Spells,
    },{
    key         = 'Migration_Mode',
    name        = 'Enter Mod Migration Mode',
    description = 'Toggling this on will prepare your character for changing race/birthsign mods:\n 1 - Set this to yes and unpause the game.\n 2 - After a second the game will automatically save and quit.\n<| Go change your plugins. |>\n 3 - Open the game and load the Migration Save\n 4 - Stat Review will automatically pop up. Click [OK].\n 5 - If everything went well, your charactr is migrated!\n Check that your stats and spells are correct.\n 5.5 - If something failed, report it on the mod page so I can look into it.',
  	renderer    = 'checkbox',
  	default     = Mui.presets.default.Migration_Mode,
    },
  },
}

addSettingsGroup('DEBUG')
settings.registerGroup {
  key              = 'Settings_GRM_DEBUG',
  name             = 'Info & Debug',
  page             = 'grmconfig',
  order            = 1,
  l10n             = 'Gentler_Racemenu',
  permanentStorage = false,
  settings         = {
    {
    key         = 'GRM_DEBUG', name = 'Enable Debug Messages', renderer = 'checkbox', default = Mui.presets.default.GRM_DEBUG,
    description = 'Print debug info to the console.\n Toggle this on if you run into any issues, as it may help track the culprit.'
    },
  },
}

local function DEBUG(...)
	if Mui.getSetting('GRM_DEBUG') then print(...) end
end

--Mui.custom_groups = {
----toggle_h2h_str = true,
--}
--Mui.custom = function(group, key)
--	if key == 'toggle_h2h_str' then
--    local args   = Mui.Settings_GRM_physical.args
--		local ratio  = 'HandToHand_Strength'
--    if Mui[group].section:get(key) then
--      settings.updateRendererArgument(group, ratio, edit_args(args[ratio], {disabled = false}))
--    else
--      settings.updateRendererArgument(group, ratio, edit_args(args[ratio], {disabled = true}))
--    end
--  end
--end

Mui.update = async:callback(function(group,key)
	if key == nil then print(group..': nil key') end
  if (not group) or (not key) then return
	elseif key == 'Migration_Mode' then
    if Mui.Settings_GRM_Options.section:get('Migration_Mode') and i_UI.getMode() then
      async:newUnsavableSimulationTimer(1, function()
				-- We do this to give the player some breathing room, otherwise we'd quit instantly upon clicking the button.
				if storage.playerSection('Settings_GRM_Options'):get('Migration_Mode') then self:sendEvent('grm_startMigration', true) end
			end)
		end
--elseif Mui.custom_groups[key] then
--	Mui.custom(group, key)
  else
--  if type(Mui[group].section:get(key)) == 'number' then
--		if Mui.getSetting("GRM_DEBUG") then print(key..': '.. string.format('%.1f', Mui[group].section:get(key))) end
--  else
--    if Mui.getSetting("GRM_DEBUG") then print(key..': '..tostring(Mui[group].section:get(key))) end
--  end
  end
end)

Mui.GROUPS_MAP = {}
for _, groupid in ipairs(Mui.settingsGroups) do 
  Mui[groupid].section = storage.playerSection(groupid)
  Mui[groupid].section:subscribe(Mui.update)
	for key in pairs(Mui[groupid].section:asTable()) do 
		Mui.GROUPS_MAP[key] = Mui[groupid].section
	end
end

Mui.getSetting = function(settingid)
  return Mui.GROUPS_MAP[settingid]:get(settingid)
end

Mui.setSetting = function(settingid, val)
  Mui.GROUPS_MAP[settingid]:set(settingid, val)
end

Mui.savePreset = function(name)
  local preset = {}
  for _, groupid in ipairs (Mui.settingsGroups) do
		for k, v in pairs(Mui[groupid].section:asTable()) do
		  preset[k] = v
      if Mui.getSetting("GRM_DEBUG") then print('Saving... '..k..': '..tostring(v)) end
		end
  end
  storage.playerSection("GRM_Presets"):set(name, preset)
  storage.playerSection("GRM_Presets"):setLifeTime(storage.LIFE_TIME.Persistent)
end
Mui.loadPreset = function(name)
	local target_as_table = storage.playerSection("GRM_Presets"):asTable()[name]
	if target_as_table == nil then print("[Loading defaults]") target_as_table = Mui.presets.default end
  for _, groupid in ipairs(Mui.settingsGroups) do 
  	for k, v in pairs (Mui[groupid].section:asTable()) do
			if target_as_table[k] ~= nil then
        Mui[groupid].section:set(k, target_as_table[k])
				DEBUG('GRM - Loading ['..name..'] | '..k..' -> '..tostring(target_as_table[k]))
		  end
  	end
  end
end

return Mui
