local vfs = require("openmw.vfs")

local M = {}

for _, kf in ipairs { "xbase_anim", "xbase_anim_female", "xbase_animkna", "xargonian_swimkna" } do
	local groups = {}
	for file in vfs.pathsWithPrefix("scripts/DynamicAnimations/animations/"..kf.."/") do
		if file:find("%.lua$") then
			file = file:sub(1, -5)
			local i, j = file:find("/[^/]*$")
			local groupName = string.sub(file, i+1, j)
			file = string.gsub(file, "/", ".")
			local a = require(file)
			a.velocity = a.velocity or (a.loopDistance or 154) / (a.loopDuration or 1)
			groups[groupName] = a
		end
	end
	M[kf] = groups
end


return M
