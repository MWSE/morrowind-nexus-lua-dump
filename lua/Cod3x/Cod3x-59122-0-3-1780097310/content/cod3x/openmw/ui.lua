---@meta

-- This file was mechanically drafted from files/lua_api/openmw/ui.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: menu|player

---Controls user interface.
---local ui = require('openmw.ui')
---@class openmw.ui
local ui = {}

---Alignment values (details depend on the specific property). For horizontal alignment the order is left to right, for vertical alignment the order is top to bottom.
---@class openmw.ui.ALIGNMENT
---@field Start any
---@field Center any
---@field End any
local ALIGNMENT = {}

---All available widget types
---@class openmw.ui.TYPE
---@field Widget any Base widget type
---@field Text any Display text
---@field TextEdit any Accepts user text input
---@field Window any Can be moved and resized by the user
---@field Image any Displays an image
---@field Flex any Aligns widgets in a row or column
---@field Container any Automatically wraps around its contents
local TYPE = {}

---Predefined colors for console output
---@class openmw.ui.CONSOLE_COLOR
---@field Default openmw.util.Color
---@field Error openmw.util.Color
---@field Success openmw.util.Color
---@field Info openmw.util.Color
local CONSOLE_COLOR = {}

---Table with settings page options, passed as an argument to ui.registerSettingsPage
---@class openmw.ui.SettingsPageOptions
---@field name string Name of the page, displayed in the list, used for search
---@field searchHints string Additional keywords used in search, not displayed anywhere
---@field element openmw.ui.Element The page's UI, which will be attached to the settings tab. The root widget has to have a fixed size. Set the `size` field in `props`, `relativeSize` is ignored.
local SettingsPageOptions = {}

---Layout
---@class openmw.ui.Layout
---@field type any Type of the widget, one of the values in #TYPE. Must match the type in #Template if both are present
---@field layer string Optional layout to display in. Only applies for the root widget. Note: if the #Element isn't attached to anything, it won't be visible!
---@field name string Optional name of the layout. Allows access by name from Content
---@field props table Optional table of widget properties
---@field events? table Optional table of event callbacks
---@field content? openmw.ui.Content Optional openmw.ui.Content of children layouts
---@field template? openmw.ui.Template Optional #Template
---@field external? table Optional table of external properties
---@field userData? any Arbitrary data for you to use, e. g. when receiving the layout in an event callback
local Layout = {}

---Template
---@class openmw.ui.Template
---@field props table
---@field content openmw.ui.Content
---@field type any One of the values in #TYPE, serves as the default value for the #Layout
local Template = {}

---@class openmw.ui.Layer
---@field name string Name of the layer
---@field size openmw.util.Vector2 Size of the layer in pixels
local Layer = {}

---Layers. Implements [iterables#List](iterables.html#List) of #Layer.
---ui.layers.insertAfter('HUD', 'NewLayer', { interactive = true })
---local fourthLayer = ui.layers[4]
---local windowsIndex = ui.layers.indexOf('Windows')
---for i, layer in ipairs(ui.layers) do
---end
---@class openmw.ui.Layers: table
local Layers = {}

---Content. An array-like container, which allows to reference elements by their name.
---Implements [iterables#List](iterables.html#List) of #Layout or #Element and [iterables#Map](iterables.html#Map) of #string to #Layout or #Element.
---local content = ui.content {
---}
----- bad idea!
----- content[1].name = 'otherInput'
----- do this instead:
---content.input = { name = 'otherInput' }
---local content = ui.content {
---}
----- allowed, but shifts all the items after it "up" the array
---content.display = nil
----- still no holes after this!
----- iterate over a Content
---for i = 1, #content do
---end
----- Note: layout names can collide with method names. Because of that you can't use a layout name such as "insert":
---local content = ui.content {
---}
---content.insert.content = ui.content {} -- fails here, content.insert is a function!
---@class openmw.ui.Content: table
local Content = {}

---Element. An element of the user interface
---@class openmw.ui.Element
local Element = {}

---Mouse event, passed as an argument to relevant UI events
---@class openmw.ui.MouseEvent
---@field position openmw.util.Vector2 Absolute position of the mouse cursor
---@field offset openmw.util.Vector2 Position of the mouse cursor relative to the widget
---@field button number Mouse button which triggered the event. Matches the arguments of openmw_input.input.isMouseButtonPressed (`nil` for none, 1 for left, 3 for right).
local MouseEvent = {}

---A texture ready to be used by UI widgets
---@class openmw.ui.TextureResource
local TextureResource = {}

---Table with arguments passed to ui.texture.
---@class openmw.ui.TextureResourceOptions
---@field path string Path to the texture file. Required
---@field offset? openmw.util.Vector2 Offset of this resource in the texture. (0, 0) by default
---@field size? openmw.util.Vector2 Size of the resource in the texture. (0, 0) by default. 0 means the whole texture size is used.
local TextureResourceOptions = {}

---Widget types
---@type openmw.ui.TYPE
ui.TYPE = nil

---Alignment values (left to right, top to bottom)
---@type openmw.ui.ALIGNMENT
ui.ALIGNMENT = nil

---Tools for working with layers
---@type openmw.ui.Layers
ui.layers = nil

---Shows given message at the bottom of the screen.
---};
---ui.showMessage("Hello world", params)
---@param msg string
---@param options? table An optional table with additional optional arguments. Can contain: * `showInDialogue` - If true, this message will only be shown in the dialogue window. If false, it will always be shown in a message box. When omitted, the message will be displayed in the dialogue window if it is open and will be shown at the bottom of the screen otherwise.
function ui.showMessage(msg, options) end

---Predefined colors for console output
---@type openmw.ui.CONSOLE_COLOR
ui.CONSOLE_COLOR = nil

---Print to the in-game console.
---@param msg string
---@param color openmw.util.Color
function ui.printToConsole(msg, color) end

---Set mode of the in-game console.
---The mode can be any string, by default is empty.
---If not empty, then the console doesn't handle mwscript commands and
---instead passes user input to Lua scripts via `onConsoleCommand` engine handler.
---@param mode string
function ui.setConsoleMode(mode) end

---Set selected object for console.
---@param obj openmw.Object
function ui.setConsoleSelectedObject(obj) end

---Returns the size of the OpenMW window in pixels as a 2D vector.
---@return openmw.util.Vector2
function ui.screenSize() end

---Converts a given table of tables into an openmw.ui.Content
---@param table table
---@return openmw.ui.Content
function ui.content(table) end

---Creates a UI element from the given layout table
---@param layout openmw.ui.Layout
---@param options? table Optional table, can take the following options: * `noWarnUnused` - if set to true this element will never generate warnings about unused properties.
---@return openmw.ui.Element
function ui.create(layout, options) end

---Adds a settings page to main menu setting's Scripts tab.
---@param page openmw.ui.SettingsPageOptions
function ui.registerSettingsPage(page) end

---Removes the settings page
---@param page openmw.ui.SettingsPageOptions must be the exact same table of options as the one passed to registerSettingsPage
function ui.removeSettingsPage(page) end

---Update all existing UI elements. Potentially extremely slow, so only call this when necessary, e. g. after overriding a template.
function ui.updateAll() end

---Index of the layer with the given name. Returns nil if the layer doesn't exist
---@param name string Name of the layer
---@return number|nil index
function Layers.indexOf(name) end

---Creates a layer and inserts it after another layer (shifts indexes of some other layers).
---@param afterName string Name of the layer after which the new layer will be inserted
---@param name string Name of the new layer
---@param options table Table with a boolean `interactive` field (default is true). Layers with interactive = false will ignore all mouse interactions.
function Layers.insertAfter(afterName, name, options) end

---Creates a layer and inserts it before another layer (shifts indexes of some other layers).
---@param beforeName string Name of the layer before which the new layer will be inserted
---@param name string Name of the new layer
---@param options table Table with a boolean `interactive` field (default is true). Layers with interactive = false will ignore all mouse interactions.
function Layers.insertBefore(beforeName, name, options) end

---Content also acts as a map of names to Layouts
---@param name string
---@return any
function Content:__index(name) end

---Puts the layout at given index by shifting all the elements after it
---@param index number
---@param layoutOrElement any
function Content:insert(index, layoutOrElement) end

---Adds the layout at the end of the Content
---(same as calling insert with `last index + 1`)
---@param layoutOrElement any
function Content:add(layoutOrElement) end

---Finds the index of the given layout. If it is not in the container, returns nil
---@param layoutOrElement any
---@return number|nil index
function Content:indexOf(layoutOrElement) end

---Refreshes the rendered element to match the current layout state.
---Refreshes positions and sizes, but not the layout of the child Elements.
---local child = ui.create {
---}
---local parent = ui.create {
---}
----- ...
---child.layout.props.text = 'child 2'
---parent.layout.content[2].props.text = 'parent 2'
---parent:update() -- will show 'parent 2', but 'child 1'
function Element:update() end

---Destroys the element
function Element:destroy() end

---Access or replace the element's layout
---  Note: Is reset to `nil` on `destroy`
---@type openmw.ui.Layout
Element.layout = nil

---Register a new texture resource. Can be used to manually atlas UI textures.
---local ui = require('openmw.ui')
---local vector2 = require('openmw.util').vector2
---local myAtlas = 'textures/my_atlas.dds' -- a 128x128 atlas
---local texture1 = ui.texture { -- texture in the top left corner of the atlas
---}
---local texture2 = ui.texture { -- texture in the top right corner of the atlas
---}
---@param options openmw.ui.TextureResourceOptions
---@return openmw.ui.TextureResource
function ui.texture(options) end

return ui
