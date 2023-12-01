local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local itemAdded = false
local function onActive()
    local class = types.NPC.record(self).class
    if(itemAdded) then
        return
    end
    if(class == "trader service") then
       core.sendGlobalEvent("addContainerCollection",self) 

    end
    itemAdded = true
end

local function onLoad(data)
itemAdded = data.itemAdded
end
local function onSave()
return {itemAdded = itemAdded}

end

return {
    engineHandlers = {onActive = onActive, onSave = onSave, onLoad = onLoad },
   -- eventHandlers = {CCCstartRename = CCCstartRename,}
}