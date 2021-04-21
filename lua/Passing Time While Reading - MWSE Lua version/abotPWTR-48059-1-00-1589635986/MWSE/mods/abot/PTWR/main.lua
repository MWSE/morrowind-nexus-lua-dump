--[[
Passing Time While Reading
/abot
--]]

local lastMenuId
local enterTime

local function menuEnter(e)
	lastMenuId = e.menu.id
	enterTime = os.clock()
end

local function menuExit()
	if not lastMenuId then
		return
	end
	lastMenuId = nil
	local hoursPassed = (os.clock() - enterTime) / 3600
	local gameHour = tes3.getGlobal('GameHour')
	gameHour = gameHour + hoursPassed
	tes3.setGlobal('GameHour', gameHour)
end

event.register('menuEnter', menuEnter, { filter = 'MenuBook' })
event.register('menuExit', menuExit)