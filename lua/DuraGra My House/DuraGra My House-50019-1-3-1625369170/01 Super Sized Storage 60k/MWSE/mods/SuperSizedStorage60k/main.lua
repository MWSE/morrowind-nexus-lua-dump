--[[
    Mod: Dahrk's Super-Sized Storage
	Author: Melchior Dahrk
	60K version Booze
--]]

local function initialized(e)

		for obj in tes3.iterateObjects(tes3.objectType.container) do

			if (obj.capacity > 0) then
				obj.capacity = 60000
			end
		end

	mwse.log("Initialized Dahrk's Super-Sized Storage 60K")
end

event.register("initialized", initialized)
