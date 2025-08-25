--[[
	Mod: Modernized 1st Person Experience
	Author: rhjelte
	Version: 1.6
]]--

-- The addon bridge is to save down relevant values for addons to the mod to act on.
-- To see which values are currently saved down each frame the camera moves, please
-- check the mods main file. The function is called updateAddonBridge() and is called
-- both when a game is loaded, whenever the head bobbing updates and when settings are
-- changed

local addonBridge = {
    config = {},
    values = {}
}

return addonBridge