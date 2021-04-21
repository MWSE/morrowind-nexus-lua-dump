--[[

TIME FLIES v1.0
by CptJoker

31/05/18

]]--

local newTime = 0
local theTime = 0
local hoursWaited = 0
local daysWaited = 0
local monthsWaited = 0
local yearsWaited = 0
local lastID = 0
local newHour
local newDay
local newMonth
local newYear
local monthsInYear = 12

local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 30, 31, 31 }

local function tempusFugit(e)

	if (e.menuMode) then
		lastID = e.menu.id
		if (e.menu.id == -590) or (e.menu.id == -161) then
			return
		else
			theTime = os.clock()
			--tes3.messageBox{message="Taking time"}
		end
	else
		if (lastID == -590) or (lastID == -161) then
			return
		else
			newTime = os.clock()
			hoursWaited = (newTime - theTime) / 3600 * (tes3.getGlobal("timescale"))
			
			if tes3.hasCodePatchFeature(4) then
				monthsInYear = 12
			else
				monthsInYear = 11
			end
			
			if (hoursWaited > 24 ) then
				daysWaited = math.floor(hoursWaited / 24)
				hoursWaited = hoursWaited % 24
				
				if (daysWaited > daysInMonth[tes3.getGlobal("Month")+1]) then
					monthsWaited = math.floor(daysWaited / daysInMonth[tes3.getGlobal("Month")+1])
					daysWaited = daysWaited % daysInMonth[tes3.getGlobal("Month")+1]
					
					if (monthsWaited > monthsInYear) then
						yearsWaited = math.floor(monthsWaited / monthsInYear)
						monthsWaited = monthsWaited % monthsInYear
					end
				end
			end
			
			newHour = tes3.getGlobal("GameHour")
			newDay = tes3.getGlobal("Day")
			newMonth = tes3.getGlobal("Month")
			newYear = tes3.getGlobal("Year")
			
			if (hoursWaited + newHour > 24) then
				newHour = newHour + hoursWaited - 24
				newDay = newDay + 1
			else
				newHour = newHour + hoursWaited
			end
			
			if (daysWaited + newDay > daysInMonth[newMonth+1]) then
				newDay = newDay + daysWaited - daysInMonth[newMonth+1]
				newMonth = newMonth + 1
			else
				newDay = newDay + daysWaited
			end
			
			if (monthsWaited + newMonth > 12) then
				newMonth = newMonth + monthsWaited - 12
				newYear = newYear + 1 -- HAPPY NEW YEAR!!! LOL
			else
				newMonth = newMonth + monthsWaited
			end
			
			tes3.setGlobal("GameHour", newHour)
			tes3.setGlobal("Day", newDay)
			tes3.setGlobal("Month", newMonth)
			tes3.setGlobal("Year", newYear)
			--tes3.messageBox({ message = string.format("Time added %.2f hours, %.0f days, %.0f months, %.0f years", hoursWaited, daysWaited, monthsWaited, yearsWaited) })
			--tes3.messageBox({ message = string.format("New date %.2f, %.0f / %.0f / %.0f year", newHour, newDay, newMonth, newYear) })
			--tes3.messageBox({ message = string.format("Added from ID %d", lastID) })
		end
	end
end
event.register("menuEnter", tempusFugit)
event.register("menuExit", tempusFugit)