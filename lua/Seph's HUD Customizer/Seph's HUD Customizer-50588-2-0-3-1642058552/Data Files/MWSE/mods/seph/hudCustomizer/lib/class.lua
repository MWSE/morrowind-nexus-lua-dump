--- @class Class A class represents a table that can be instantiated and inherit fields from other tables.
--- @field __class Class Internal field to store the class.
--- @field __parentClass Class Internal field to store the parent class.
local Class = {}

Class.__class = Class
Class.__parentClass = nil

--- Gets the class.
--- @return Class
function Class:getClass()
    return self.__class
end

--- Gets the parent class of this class.
--- @return Class
function Class:getParentClass()
    return self.__parentClass
end

--- Checks if this is or inherits from a given class.
--- @param class Class The class to check for.
--- @return boolean
function Class:isClass(class)
    assert(type(class) == "table" and class.getClass and class:getClass() ~= nil, "class must be a Class")
    local current = self:getClass()
    while current ~= nil do
        if current == class then
            return true
        else
            current = current:getParentClass()
        end
    end
    return false
end

--- Checks if a given value is or inherits from this class.
--- @param value any The value to check.
--- @return boolean
function Class:isClassOf(value)
    if value ~= nil and type(value) == "table" and value.isClass then
        return value:isClass(self)
    end
    return false
end

--- Creates a new instance of this class.
--- @param data table Optional. Defaults to an empty table. The data used to initialize the instance's fields.
--- @return table
function Class:new(data)
    assert(data == nil or type(data) == "table", "data must be a table or nil")
    local instance = data or {}
    setmetatable(instance, {
        __index = self:getClass(),
        __newindex =
            function(_, key, value)
                rawset(instance, key, value)
            end
    })
    for index, value in pairs(self:getClass()) do
        if type(value) == "table" and not string.startswith(index, "__") then
            instance[index] = table.deepcopy(value)
        end
    end
    return instance
end

--- Creates a new instance of this class with the same data.
--- @return table
function Class:copy()
    local instance = self:new()
    table.copy(self, instance)
    return instance
end

setmetatable(Class, {
    __call =
        function(_, parent)
            parent = parent or Class
            assert(type(parent) == "table" and parent.getClass and parent:getClass() ~= nil, "parent must be a Class")
            local class = {}
            class.__class = class
            class.__parentClass = parent
            setmetatable(class, {
                __index = parent,
                __newindex =
                    function(_, key, value)
                        rawset(class, key, value)
                    end,
                __call =
                    function(_, ...)
                        return class:new(...)
                    end
            })
            return class
        end
})

return Class