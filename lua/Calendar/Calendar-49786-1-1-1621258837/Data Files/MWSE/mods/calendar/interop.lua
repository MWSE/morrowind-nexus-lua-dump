--[[
    Calendar Interoperability
    You can use these functions to read and modify notes on a particular date. Each of them takes an argument, date, in the form of a table. It must have the following format:
    date ={
        year = year of the third era as integer or string,
        month = 0 to 11 as an integer or string,
        day = day of the month (1-31) as integer or string
    }
    Example of how to use
        local calendar = require(calendar.interop)
        local date = {year = 427, month = 7, day = 18}
        calendar.addNotetoDate(date, "Reminder: get cheese!")
        local message = calendar.removeNotefromDate(date)
        message = string.gsub(message, "cheese", "scuttle")
        calendar.addNotetoDate(date, message)

]]--
local this = {}
-- Takes a date (see above), and a string, and writes that string to that date. If there is a note already present, yours will be appeneded on a new line.
-- If you want more control, first removeNotefromDate, which returns the note, make your modifications, then use addNotetoDate to put it back.
-- For stability, non-string notes are converted to strings. Returns true if it completes
function this.addNotetoDate(date, note)
    if (tes3.player.data.JaceyS == nil) then
        tes3.player.data.JaceyS = {}
    end
    if (tes3.player.data.JaceyS.Calendar == nil) then
        tes3.player.data.JaceyS.Calendar = {}
    end
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)] == nil) then
        tes3.player.data.JaceyS.Calendar[tostring(date.year)] = {}
    end
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)] == nil) then
        tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)] = {}
    end
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.day)] ~= nil) then
        local priorNote = tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.day)]
        tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.day)] = priorNote .. "\n" .. note
    else
        tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.day)] = tostring(note)
    end
    return true
end

-- Tries to fetch a note from a given day. If it doesn't find it, it returns nil.
function this.getNoteFromDate(date)
    if (tes3.player.data.JaceyS == nil) then return nil end
    if (tes3.player.data.JaceyS.Calendar == nil) then return nil end
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)] == nil) then return nil end
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)] == nil) then return nil end
    return tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.day)]
end

-- Deletes a note from a given day. If it doesn't find a note on the specified date, it returns false.
-- If it does find a note, it deletes it and returns the note. This makes it useful if you want to delete part of a note, then return the rest via addNotetoDate()
function this.removeNotefromDate(date)
    if (tes3.player.data.JaceyS == nil) then return false end
    if (tes3.player.data.JaceyS.Calendar == nil) then return false end
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)] == nil) then return false end
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)] == nil) then return false end
    if (tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.day)] == nil) then return false end
    local priorNote = tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.day)]
    tes3.player.data.JaceyS.Calendar[tostring(date.year)][tostring(date.month)][tostring(date.day)] = nil
    return priorNote
end

return this