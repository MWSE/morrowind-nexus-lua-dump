local config = require("Place Stacks.config")
local util = require("Place Stacks.util")

local interop = {}

-- Returns `true` if the "Place Stacks" button is added to the ContentsMenu.
function interop.isButtonEnabled()
	return config.buttonEnabled
end

-- Returns `true` if the user has hold activate keybind to place stacks feature enabled.
function interop.isActivateEnabled()
	return config.activateEnabled
end

-- Returns `true` if the user has enabled place stacks hotkey.
function interop.isKeybindEnabled()
	return config.placeStacksOutOfMenu
end

-- Returns the current place stacks hotkey. Note that place stacks hotkey feature may still be disabled.
function interop.getPlaceStacksKeybind()
	return config.keybind
end

interop.transferStacks = util.transferStacks

return interop
