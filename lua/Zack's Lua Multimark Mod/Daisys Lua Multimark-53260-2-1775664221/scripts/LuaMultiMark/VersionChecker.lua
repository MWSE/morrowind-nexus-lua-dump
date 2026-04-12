local core = require("openmw.core")

local api = core.API_REVISION
local hasFile = core.contentFiles.has("LuaMultiMark.omwaddon")

local rev = 126
if api < rev or hasFile then
    print("No")
    local updated = api >= rev
    return {result = false, hasFile = hasFile,  updated = updated}
end

return{result = true, hasFile = false,  updated = true}

