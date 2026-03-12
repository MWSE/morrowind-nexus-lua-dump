local pool = {}
local poolmt = { __index = pool }

function pool.create(newObject, poolSize)
    poolSize = poolSize or 16
    assert(newObject, "A function that returns new objects for the pool is required.")

    local freeObjects = {}
    for _ = 1, poolSize do
        table.insert(freeObjects, newObject())
    end

    return setmetatable({
            freeObjects = freeObjects,
            newObject = newObject
        },
        poolmt
    )
end

function pool:obtain()
    return #self.freeObjects == 0 and self.newObject() or table.remove(self.freeObjects)
end

function pool:free(obj)
    assert(obj, "An object to be freed must be passed.")

    table.insert(self.freeObjects, obj)
    if obj.reset then obj.reset() end
end

function pool:clear()
    for k in pairs(self.freeObjects) do
        self.freeObjects[k] = nil
    end
end

return pool
