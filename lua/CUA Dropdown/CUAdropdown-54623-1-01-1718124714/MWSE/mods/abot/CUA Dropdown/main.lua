--[[
Makes MCM DropDown CUA (Common User Access) compliant
displaying in the dropdown list all the available options
(included the currently selected one)
]]
event.register('modConfigReady', function ()
	require('abot.CUA Dropdown.common')
end
, {priority = 100000, doOnce = true})