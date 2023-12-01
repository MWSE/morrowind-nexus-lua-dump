local pathPrefix = "Clone.scripts.CloningAvatar"
local omw, core  = pcall(require, "openmw.core")
local _, async  = pcall(require, "openmw.async")
if omw then
    pathPrefix = "scripts.CloningAvatar"
end

local commonUtil = require(pathPrefix .. ".common.commonUtil")

local cloneRoomManager = {}

function cloneRoomManager.setObjStates(val,cell)
    local itemList = commonUtil.getObjectsInCell(cell)

    for index, obj in ipairs(itemList) do
        local cfile = commonUtil.getReferenceModId(obj)
        if cfile == "clone.esp" then
            local storedVal = commonUtil.getValueForRef(obj, "ZHAC_objectLevel")
            if storedVal ~= nil then
                
                commonUtil.setReferenceState(obj,storedVal == val)
            end
        end


    end


    
end
function cloneRoomManager.initRoom(cell)
    local itemList = commonUtil.getObjectsInCell(cell)

    for index, obj in ipairs(itemList) do
        local cfile = commonUtil.getReferenceModId(obj)
        if cfile == "clone.esp" and obj.position.x > 3971.333 and commonUtil.getRefRecordId(obj) ~= "in_velothismall_dj_01" then
            local xpos = obj.position.y
            local val = 0
            local xoffset = 0
            if xpos > 8000 then --farthest
                val = 1
                xoffset = 2624
            elseif xpos > 7168 then --second farthest
                val = 2
                xoffset = 1728
            elseif xpos > 6336 then --second closest
                val = 3
                xoffset = 861 
            elseif xpos > 5000 then --correct pos already
                val = 4
            end
            if val > 0 then
                if xoffset > 0 then
                    local newPos = commonUtil.getPosition(obj.position.x , obj.position.y- xoffset, obj.position.z)
                    commonUtil.setPosition(obj, newPos)
                end

                commonUtil.setValueForRef(obj, "ZHAC_objectLevel", val)
            end
        end
    end
    if omw then
        async:newUnsavableGameTimer(1, function()
            cloneRoomManager.setObjStates(1,cell)
         end
       )
    end
end
return cloneRoomManager