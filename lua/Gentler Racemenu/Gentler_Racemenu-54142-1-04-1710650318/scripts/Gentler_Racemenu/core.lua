local self  = require('openmw.self')
local types = require('openmw.types')
local i_UI  = require('openmw.interfaces').UI
local ui    = require('openmw.ui')
local storage  = require('openmw.storage')
local async    = require('openmw.async')

local Compat = require('scripts.gentler_racemenu.data').Compat
local Dt     = require('scripts.gentler_racemenu.data').Dt
local Fn     = require('scripts.gentler_racemenu.func')
local Mui    = require('scripts.gentler_racemenu.modui')

local function get_val(not_table_or_func)   return not_table_or_func end

Fn.get_birthsigns()
Fn.get_races()
Fn.enable_compat_modules()

local exit_check = false

UiModeChanged = function(data)
  if donechargen then
    if data.newMode then table.insert(Dt.last3uimodes, 1, data.newMode) else table.insert(Dt.last3uimodes, 1, false) end
    Dt.last3uimodes[4] = nil
    if Fn.is_entering(data.newMode) then
			if Mui.getSetting('Migration_Mode') then return end
      Fn.set_data_stats()
    elseif Fn.is_exiting(data.oldMode,data.newMode) then
      -- Request onUpdate to do an exit check, since we may be simply switching to another racemenu window.
      Dt.exit_check = true
    end
  end
end

local function onUpdate()
  if donechargen then
    if not Dt.exit_check then return end
    if Fn.is_editmode(i_UI.getMode()) then
      switching = true
      Dt.exit_timer = 0
      Dt.exit_check = false
    elseif Dt.exit_timer < 9.99 then
      Dt.exit_timer = Dt.exit_timer + 1
    elseif Dt.exit_timer > 9.99 then
      Fn.set_openmw_stats()
      Dt.exit_timer = 0
      Dt.exit_check = false
    end
  elseif types.Player.isCharGenFinished(self) then
  donechargen = true
  end
end

local onInit = function()
	Mui.loadPreset('current')
end
local onSave = function()
	Mui.savePreset('current')
end
local onLoad = function(_)
	Mui.loadPreset('current')
  if not Mui.Settings_GRM_Options.section:get('Migration_Mode') then return end
	for k, v in pairs(storage.playerSection("GRM_Migration_Data"):asTable()) do
		Dt[k] = v
	end
  async:newUnsavableSimulationTimer(1, function()
    --if not Mui.Settings_GRM_Options.section:get('Migration_Mode') then return end
	  i_UI.setMode('ChargenClassReview') 
	end)
end

return {
  engineHandlers = {
    onUpdate = onUpdate,
    onInit   = onInit  ,
    onSave   = onSave  ,
    onLoad   = onLoad  ,
  },
  eventHandlers = {
    UiModeChanged = UiModeChanged,
		grm_itemAdded = function(item)
			if types.Weapon.record(item).id == 'grm_mwbolt' then
				Fn.applyMWBolt(item)
			end
		end,
    grm_startMigration = function(_)
			Fn.set_data_stats() -- dirty sandwitch, but it works
			local data = {}
			for _, key in ipairs{'pc_attributes', 'pc_skills', 'pc_dynamic', 'pc_level', 'pc_spells', 'pc_factions'} do
        data[key] = Dt[key]
			end
      storage.playerSection("GRM_Migration_Data"):reset(data)
      storage.playerSection("GRM_Migration_Data"):setLifeTime(storage.LIFE_TIME.Persistent)
			types.Player.sendMenuEvent(self, 'grm_saveAndQuit', {
				description = 'RaceMenu will open after a short delay and Migration Mode will end afterwards. Make sure you\'ve done your desired mod changes',
				slotname = 'GRM - Migration Mode Save',
			})
		  --Mui.setSetting('Migration_Mode', false)
		end
  }
}
