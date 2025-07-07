local I = require("openmw.interfaces")
local vfs = require('openmw.vfs')


tes3 = { event={} }
event = { register = function(_, fn)	fn()	end }
include = function(m)	return m == "SSQN.interop" and I.SSQN		end



for file in vfs.pathsWithPrefix("scripts/SSQN/interop/") do
	if file:find("%.lua$") then
		print("Loading interop "..file)
		file = string.sub(file, 1, -5)
		file = string.gsub(file, "/", ".")
		require(file)
	end
end



return
