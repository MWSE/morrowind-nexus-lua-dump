local iconlist = require("SSQN.iconlist")
local interop = {}

function interop.registerQIcon(id,path)
    iconlist[id] = path
end

return interop