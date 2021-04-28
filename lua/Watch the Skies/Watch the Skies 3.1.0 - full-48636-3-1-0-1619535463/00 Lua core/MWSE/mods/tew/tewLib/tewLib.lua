local this = {}

function this.isOpenPlaza(cell)
    if not cell then return false end
    if not cell.behavesAsExterior then
        return false
    else
        if (string.find(cell.name:lower(), "plaza") and string.find(cell.name:lower(), "vivec"))
        or (string.find(cell.name:lower(), "plaza") and string.find(cell.name:lower(), "molag mar"))
        or (string.find(cell.name:lower(), "arena pit") and string.find(cell.name:lower(), "vivec")) then
            return true
        else
            return false
        end
    end
end

function this.getObjects(cell, objectType, stringArray)
    local objectArray={}
    for obj in cell:iterateReferences(objectType) do
        for _, pattern in pairs(stringArray) do
            if string.find(obj.object.id:lower(), pattern) then
                table.insert(objectArray, obj)
            end
        end
    end
    return objectArray
end

function this.getObjectsStartsWith(cell, objectType, stringArray)
    local objectArray={}
    for obj in cell:iterateReferences(objectType) do
        for _, pattern in pairs(stringArray) do
            if string.startswith(obj.object.id:lower(), pattern) then
                table.insert(objectArray, obj)
            end
        end
    end
    return objectArray
end

function this.getDistance(v0, v1)
    local dx=v1.x-v0.x
    local dy=v1.y-v0.y
    local dz=v1.z-v0.z
    return math.sqrt(dx*dx+dy*dy+dz*dz)
end

function this.findWholeWords(string, pattern)
    return string.find(string, "%f[%a]"..pattern.."%f[%A]")
end

return this