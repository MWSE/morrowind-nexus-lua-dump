--- @type table<string, Class>[] Contains every registered class indexed by its name.
local classes = {}

--- @class Class A class represents a table that can be instantiated and inherit fields from other tables.
local Class = {}

--- Checks if a given value is a class. This does not include instances.
--- @param value any The value to check.
--- @return boolean
function Class.isClass(value)
    if type(value) == "table" then
        local metatable = getmetatable(value)
        return metatable ~= nil and metatable.class and classes[metatable.name] == value
    end
    return false
end

--- Checks if a given value is an instance of any class.
--- @param value any The value to check.
--- @return boolean
function Class.isInstance(value)
    if type(value) == "table" then
        local metatable = getmetatable(value)
        return metatable ~= nil and metatable.isInstance and Class.isClass(metatable.class)
    end
    return false
end

--- Gets this class or the class of this instance.
--- @return Class
function Class:getClass()
    return getmetatable(self).class
end

--- Gets the class name of this class or the class of this instance.
--- @return string
function Class:getClassName()
    return getmetatable(self).name
end

--- Gets the parent class of this class or the class of this instance.
--- @return Class
function Class:getParentClass()
    return getmetatable(self).parent
end

--- Checks if this class or the class of this instance inherits from a given class.
--- @param class Class The class to check for.
--- @return boolean
function Class:isSubclassOf(class)
    assert(Class.isClass(class), "class must be a Class")
    local current = self:getParentClass()
    while current ~= nil do
        if current == class then
            return true
        else
            current = current:getParentClass()
        end
    end
    return false
end

--- Checks if a given value is an instance of this class or one of its parents. Can not be called on an instance.
--- @param value any The value to check.
--- @return boolean
function Class:isClassOf(value)
    assert(not self:isInstance(), "function is not valid for instances")
    return Class.isInstance(value) and value:isInstanceOf(self:getClass())
end

--- Checks if this instance is or inherits from a given class or one of its parents. Can only be called on an instance.
--- @param class Class The class to check for.
--- @return boolean
function Class:isInstanceOf(class)
    assert(self:isInstance(), "function is only valid for instances")
    assert(Class.isClass(class), "class must be a Class")
    return self:getClass() == class or self:getClass():isSubclassOf(class)
end

--- Initializes the fields of the instance after being created. Can be overriden to provide functionality.
function Class:initialize() end

--- Creates a new instance of this class. Can not be called on an instance.
--- @param data? table Optional. Default: {}. The data used to initialize the instance's fields.
--- @return table
function Class:new(data)
    assert(not self:isInstance(), "function is not valid for instances")
    assert(data == nil or type(data) == "table", "data must be a table or nil")
    data = data or {}
    local instance = {}
    setmetatable(instance,
        {
            class = self:getClass(),
            name = self:getClassName(),
            parent = self:getParentClass(),
            isInstance = true,
            __index = self:getClass(),
            __newindex =
                function(_, index, value)
                    rawset(instance, index, value)
                end,
            __tostring =
                function()
                    return string.format("Instance: %s", self:getClass():getClassName())
                end
        }
    )
    instance:initialize()
    for key, value in pairs(data) do
        instance[key] = value
    end
    return instance
end

--- Creates a new class.
--- @param name table The name of the new class. If possible this should be a unique identifier and reflect in which package the class has been created.
--- @param parent? table Optional. Default: Class. The parent class of the new class.
--- @return table
local function createClass(_, name, parent)
    parent = parent or Class
    assert(type(name) == "string" and name ~= "", "name must be a non-empty string")
    assert(classes[name] == nil, string.format("Class '%s' already exists", name))
    assert(Class.isClass(parent), "parent must be a Class")
    local class = {}
    setmetatable(class,
        {
            class = class,
            name = name,
            parent = parent,
            isInstance = false,
            __index = parent,
            __newindex =
                function(_, index, value)
                    rawset(class, index, value)
                end,
            __tostring =
                function()
                    return string.format("Class: %s", class:getClassName())
                end,
            __call =
                function(_, ...)
                    return class:new(...)
                end
        }
    )
    classes[name] = class
    return class
end

setmetatable(Class,
    {
        class = Class,
        name = "Class",
        parent = nil,
        __call = createClass
    }
)

classes["Class"] = Class

return Class