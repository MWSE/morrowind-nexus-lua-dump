--Credits to cdcooley for this script

local companionid = mwse.stack.popString()
local insert = mwse.stack.popShort()

local companions = tes3.player.data.multiMark.markedCompanions

if companionid ~= '' then
	if table.find(companions, companionid) then
		if insert < 1 then
			table.removevalue(companions, companionid)
		end
	else
		if insert > 0 then
			table.insert(companions, companionid)
		end
	end
end

mwse.stack.pushShort(0)