local core = require("openmw.core")
local calendar = require("openmw_aux.calendar")

local daysTo = function(month, day)
   local days = day
   for month=1, month-1 do
      days = days + calendar.daysInMonth(month)
   end
   return days
end

local secondsTo = function(month, day)
   return daysTo(month, day) * 24 * 60 * 60
end

local dateFromSeconds = function(seconds)
   local gameTimeDays = seconds / (24 * 60 * 60)
   local days = gameTimeDays % calendar.daysInYear
   for month = 1, 12 do
      local daysInMonth = calendar.daysInMonth(month)
      if days < daysInMonth then
         return month, days+1
      else
         days = days - daysInMonth
      end
   end
end

local calendarBeginDate = secondsTo(8, 14)

return function()
   local month, _ =
      dateFromSeconds(core.getGameTime() + calendarBeginDate)
   return month
end
