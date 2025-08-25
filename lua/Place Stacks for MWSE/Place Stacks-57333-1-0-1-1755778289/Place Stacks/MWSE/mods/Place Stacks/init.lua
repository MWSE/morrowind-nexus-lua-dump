--[[

If you need to interoperate with this mod, include it as follows:

local placeStacks = include("Place Stacks")

if placeStacks and placeStacks.isButtonEnabled() then
	-- ...
end

--]]

local placeStacks = {}

placeStacks = require("Place Stacks.interop")

return placeStacks
