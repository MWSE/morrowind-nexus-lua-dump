local Door = require("openmw.types").Door

local this = {}


function this.destCell(ref)
    local res, dest = pcall(function ()
        return Door.destCell(ref)
    end)
    if res then return dest end
end


function this.destPosition(ref)
    local res, dest = pcall(function ()
        return Door.destPosition(ref)
    end)
    if res then return dest end
end


function this.destRotation(ref)
    local res, dest = pcall(function ()
        return Door.destRotation(ref)
    end)
    if res then return dest end
end


return this