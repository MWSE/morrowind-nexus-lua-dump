local ui = require("openmw.ui")
local util = require("openmw.util")

--
-- Style presets
--

local STYLES = {
    Compact = {
        edgePadding = 1,
        buttonPadding = 1,
        autoHideScrollBar = true,
    },
    Full = {
        edgePadding = 6,
        buttonPadding = 3,
        autoHideScrollBar = true,
    },
}

---
--- Style constants
---

--- Multiplier for scroll steps when using the mouse wheel.
local SCROLL_WHEEL_STEP_MULT = 3

--- Minimum height of the scrollbar handle.
local SCROLL_BAR_HANDLE_MIN_HEIGHT = 16

--- Width of the scrollbar track and up/down buttons.
local SCROLL_BAR_TRACK_WIDTH = 14

--- Inset of the up/down/handle textures from their borders.
local SCROLL_BAR_TEXTURE_INSET = 4

--- Horizontal gap between the list content and the scrollbar.
local SCROLL_BAR_CONTENT_GAP = 4

-- The native element inset from the builtin borders template. (???)
local VIEWPORT_BORDER_SIZE = 4
local VIEWPORT_INSET = VIEWPORT_BORDER_SIZE * 2

--
-- Derived constants
--

--- Bottom clearance so the down button clears the viewport border.
local SCROLL_BAR_BOTTOM_PAD = VIEWPORT_BORDER_SIZE

--- Bottom clearance for the scrollbar handle within the track border.
local SCROLL_BAR_HANDLE_CLEARANCE = VIEWPORT_BORDER_SIZE + 1

--- The width of the scrollbar handle.
local SCROLL_BAR_HANDLE_WIDTH = SCROLL_BAR_TRACK_WIDTH - SCROLL_BAR_TEXTURE_INSET - 1

--- The size of the up/down button widgets.
local SCROLL_BAR_BUTTON_SIZE = util.vector2(
    SCROLL_BAR_TRACK_WIDTH,
    SCROLL_BAR_TRACK_WIDTH
)

--- The size of the arrow texture inside each button.
local SCROLL_BUTTON_ICON_SIZE = util.vector2(
    SCROLL_BAR_TRACK_WIDTH - SCROLL_BAR_TEXTURE_INSET,
    SCROLL_BAR_TRACK_WIDTH - SCROLL_BAR_TEXTURE_INSET
)

--
-- Textures
--

local SCROLL_UP_TEXTURE = ui.texture({ path = "textures/omw_menu_scroll_up.dds" })
local SCROLL_DOWN_TEXTURE = ui.texture({ path = "textures/omw_menu_scroll_down.dds" })
local SCROLL_CENTER_TEXTURE = ui.texture({ path = "textures/omw_menu_scroll_center_v.dds" })


---@class Styles
local this = {
    SCROLL_WHEEL_STEP_MULT = SCROLL_WHEEL_STEP_MULT,
    SCROLL_BAR_BUTTON_SIZE = SCROLL_BAR_BUTTON_SIZE,
    SCROLL_BAR_HANDLE_WIDTH = SCROLL_BAR_HANDLE_WIDTH,
    SCROLL_BAR_TRACK_WIDTH = SCROLL_BAR_TRACK_WIDTH,
    SCROLL_HANDLE_MIN_HEIGHT = SCROLL_BAR_HANDLE_MIN_HEIGHT,
    SCROLL_BAR_HANDLE_CLEARANCE = SCROLL_BAR_HANDLE_CLEARANCE,
    SCROLL_BAR_BOTTOM_PAD = SCROLL_BAR_BOTTOM_PAD,
    SCROLL_UP_TEXTURE = SCROLL_UP_TEXTURE,
    SCROLL_DOWN_TEXTURE = SCROLL_DOWN_TEXTURE,
    SCROLL_CENTER_TEXTURE = SCROLL_CENTER_TEXTURE,
    SCROLL_BUTTON_ICON_SIZE = SCROLL_BUTTON_ICON_SIZE,
    VIEWPORT_BORDER_SIZE = VIEWPORT_BORDER_SIZE,
    VIEWPORT_INSET = VIEWPORT_INSET,
    STYLES = STYLES,
}


--- Compute derived style values from a style table.
---
---@param style table
---@return table
function this.resolve(style)
    return {
        edgePadding = style.edgePadding,
        buttonPaddingSize = util.vector2(0, style.buttonPadding),
        scrollBarPosition = util.vector2(
            -(SCROLL_BAR_TRACK_WIDTH + SCROLL_BAR_CONTENT_GAP + style.edgePadding),
            style.edgePadding
        ),
        autoHideScrollBar = style.autoHideScrollBar,
    }
end


return this
