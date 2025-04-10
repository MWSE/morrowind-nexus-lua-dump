local socket = require("socket")

local common = {}

--- A convenience function for accessing 'socket.gettime()'. Returns the time in seconds, relative to the origin of the universe.
--- @return number
function common.getTime()
    return socket.gettime()
end

return common