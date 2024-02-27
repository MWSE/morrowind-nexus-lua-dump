local self  = require('openmw.self')
local types = require('openmw.types')
local i_UI  = require('openmw.interfaces').UI
local ui    = require('openmw.ui')

-- TOOLS
local function get_val(not_table_or_func)   return not_table_or_func end

local Dt     = require('scripts.gentler_racemenu.data').Data
local Compat = require('scripts.gentler_racemenu.data').Compat
local Fn     = require('scripts.gentler_racemenu.func')



Fn.get_birthsigns()
Fn.enable_compat_modules()

local exit_check = false

UiModeChanged = function(data)
    if donechargen then
        if data.newMode then table.insert(Dt.last3uimodes, 1, data.newMode) else table.insert(Dt.last3uimodes, 1, false) end
        Dt.last3uimodes[4] = nil
        if Fn.is_entering(data.newMode) then
            Fn.set_data_stats()
        elseif Fn.is_exiting(data.oldMode,data.newMode) then
            -- Request onUpdate to do an exit check, since we may be simply switching to another racemenu window.
            Dt.exit_check = true
        end
    end
end

local function onUpdate()
    if donechargen then
        if Dt.exit_check then
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
        end
    elseif types.Player.isCharGenFinished(self) then
    donechargen = true
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
    }
}
