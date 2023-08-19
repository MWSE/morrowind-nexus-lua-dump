
local self = require('openmw.self')
local types = require('openmw.types')

local guards = {  ["guard"]=1, ["buoyant armiger"]=1, ["ordinator"]=1, ["ordinator guard"]=1 }
local done = 0;

local function getRecord(obj)
    if obj.type and obj.type.record then
        return obj.type.record(obj)
    end
    return nil
end

local function onSave(obj)
    return { ["done"]=done }
end

local function onLoad(obj)
    if obj ~= nil then
        done = obj["done"];
    end
end

local function onActive()
    if self.type ~= types.Player and types.Actor.objectIsInstance(self) then
        local record = getRecord(self)
        if guards[record.class] == nil then
            return
        end
        if done < 0 then
            return
        end
        done = math.random(0, 101)

        if done < 25 then
            types.Actor.spells(self):add("etb_guard_wolf")
        elseif done < 35 then
            types.Actor.spells(self):add("etb_guard_bear")
        elseif done < 38 then
            types.Actor.spells(self):add("etb_guard_robot")
        end

        done = -1
    end
end


return {
    engineHandlers = {
        onActive = onActive,
        onSave = onSave,
        onLoad = onLoad,
    }
}

