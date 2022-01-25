--[[
This interop file enables other mods to register their own tes3uiElements as being configurable in HUD customizer.
If you register any element, make sure that it is a child of MenuMulti and has a unique ID. Elements in other parents will not be affected.
Generally speaking, you should only use this if compatibility issues occur. This works with most elements, but there are limitations.
HUD Customizer enlarges some blocks and parent containers and changes layouts to ensure that elements are freely movable.
Not all element blocks of MenuMulti have been completely freed of Morrowind's GUI tyranny and still have their original layouts and constraints.
This means that if you, for example, place something inside the health fillbar, it will react oddly or not at all to this.
Normally you shouldn't need to bother with this interop file if your element displays as wanted.
That means it is most likely a child of one of the untouched containers anyways and will work out of the box.
You can also include any other lua file of this mod if you require its functionality.
They are fully initialized by the time the MWSE 'initialized' event triggers.
Feel free to contact me if you encounter any issues with this.

The only function in this interop file is 'registerElement'. Documentation can be seen below.
Here is a simple example call:

local hudCustomizerInterop = include("seph.hudCustomizer.interop")
if hudCustomizerInterop then
	hudCustomizerInterop:registerElement("Ashfall:HUD_mainHUDBlock", "Ashfall", {positionX = 0.5, positionY = 0.0}, {position = true})
end

Additionally, events are available inside HUD customizer that get called every time an element has it's position, size or visibility updated.
HUD customizer changes the visiblity of elements by setting or removing their maxWidth and maxHeight properties, not the visible field.
These events can be used to fix any positioning problems that might occur for vanilla or modded elements.
The event IDs are 'seph.hudCustomizer:positionUpdated', 'seph.hudCustomizer:sizeUpdated' and 'seph.hudCustomizer:visibilityUpdated' respectively.
It passes the affected element as event data. The event can be filtered by the element's name (the same format as the 'name' parameter of 'registerElement' below).
Please keep in mind that not all vanilla elements may have valid IDs (Thanks, Todd!), so you may not be able to filter for those directly and have to check the attached element.

Here is a simple example that only logs the repositioned element's name:
event.register("seph.hudCustomizer:positionUpdated", function(e) mwse.log(e.element.name) end, {filter = "Ashfall:HUD_mainHUDBlock"})
--]]

local Module = require("seph.hudCustomizer.lib.module")

local interop = Module()

--- @class DefaultsTable : table
--- @field positionX number The default absolutePosAlignX of your element. This ranges from 0.0 to 1.0.
--- @field positionY number The default absolutePosAlignY of your element. This ranges from 0.0 to 1.0.
--- @field width number The default width of your element.
--- @field height number The default height of your element.
--- @field visible boolean The default visibility of your element.

--- @class OptionsTable : table
--- @field position boolean Determines if the user should be able to set the position of your element.
--- @field size boolean Determines if the user should be able to modify the width and height of your element.
--- @field visibility boolean Determines if the user should be able to modify the visibility of your element. This is done by modifying maxWidth/Height and not the visible flag of the element.

--- Registers an element to be configurable in HUD customizer. This should be called during the MWSE 'initalized' event.
--- HUD customizer automatically clears old config entries. If your element has not been registered in HUD customizer during initialization its config will get removed immediately.
--- This automatic cleanup functionality can be toggled on or off by the user.
--- @param name string This should be the string that you use to register the ID of your element inside your mod. This should not be the result of the tes3ui.registerID function.
--- @param displayName string This only affects the label of the config entry inside HUD customizer. Any string is fine here as long as users recognize it.
--- @param defaults DefaultsTable Optional. Defaults to an empty table. The default values for your element. These should closely reflect how your element would be placed without HUD customizer.
--- @param options OptionsTable Optional. Defaults to {position = true}. This determines which settings are available to the user.
function interop:registerElement(name, displayName, defaults, options)
	assert(type(name) == "string" and name ~= "", "name must be a non-empty string")
	assert(type(displayName) == "string" and displayName ~= "", "displayName must be a non-empty string")
	assert(defaults == nil or type(defaults) == "table", "defaults must be a table or nil")
	assert(options == nil or type(options) == "table", "options must be a table or nil")
	self.mod.config.current.mods[name] = self.mod.config.current.mods[name] or {}
	local modConfig = self.mod.config.current.mods[name]
	modConfig.name = displayName
	modConfig.options = options or {position = true}
	modConfig.defaults = defaults or {}
	modConfig.defaults.positionX = (modConfig.defaults.positionX or 0) * 1000
	modConfig.defaults.positionY = (modConfig.defaults.positionY or 0) * 1000
	modConfig.defaults.width = modConfig.defaults.width or 0
	modConfig.defaults.height = modConfig.defaults.height or 0
	modConfig.defaults.visible = modConfig.defaults.visible or true
	table.copymissing(modConfig, modConfig.defaults)
	modConfig.valid = true
	self.logger:info(string.format("Registered element '%s' with ID '%s'", displayName, name))
end

return interop