--[[
    Mod: Dahrk's Super-Sized Storage
	Author: Melchior Dahrk
--]]

local function initialized(e)
		for obj in tes3.iterateObjects(tes3.objectType.container) do
			obj.capacity = obj.capacity * 100
		end
        print("Initialized Dahrk's Super-Sized Storage")
    end

event.register("initialized", initialized)