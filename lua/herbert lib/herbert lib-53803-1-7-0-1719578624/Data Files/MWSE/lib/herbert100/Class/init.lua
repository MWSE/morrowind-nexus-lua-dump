-- default tostring method that prints all non-secret, nonfunction field entries of `obj`, along with any default values inherited
-- from parent classes.
--- make a string representing this object
---@param self herbert.Class
---@return string
local premade__tostring = function(self)
    -- a list of strings, all of the form "k=v", where `k` is a field of `obj` (or an ancestor of `obj`) with value `v`
    local field_strs = {}   ---@type string[] 

    local sf, fields = string.format, self.__secrets.fields 
    for _, field in ipairs(fields) do
        local ts = field.tostring
        if ts ~= false then
            local key = field[1]
            local str
            if type(key) == "number" then
                if ts == true or ts == nil then 
                    if type(self[key]) == "string" then
                        str = sf("%q", self[key])
                    else
                        str = tostring(self[key])
                    end
                else
                    str = ts(self[key])
                end
            else
                if ts == true or ts == nil then
                    if type(self[key]) == "string" then
                        str = sf('%s=%q', key, self[key])
                    else
                        str = sf('%s=%s', key, self[key])
                    end
                else
                    str = sf('%s=%s', key, ts(self[key]))
                end
            end
            table.insert(field_strs, str)
        end
    end
    
    return string.format("%s(%s)", 
        self.__secrets.name:gsub(" ", "_"),   -- replace spaces in class names with underscores
        table.concat(field_strs, ", ")      -- add all the key-value pairs, and separate them with a comma
    )
end



---@alias herbert.Class.id integer

---@class herbert.Field
---@field converter nil|table|fun(v):any converter for this field. this will be sent into the `converters` table
---@field factory nil|fun(self:table|herbert.Class):any used to generate new values for this field, if none were provided
---@field tostring (boolean|table|fun(v):(string|number))?
--- controls how the default `Class` `__tostring` method works for this field. (this only matters if you aren't overriding `__tostring`).
--- if `true`, the normal `tostring` function will be called on the field
--- if `false`, this field will not be included in this class's `__tostring` method.
--- if a `function`, then that function will be called on the field, and the output will be printed in the class `__tostring` method.
--- Default: `true`
---@field eq (boolean|table|fun(v):any)?
--- controls how the default `Class` `__eq` method works for this field. (this only matters if you aren't overriding `__eq`).
--- if `true`, the normal `__eq` function will be called on the field
--- if `false`, this field will not be evaluated when using the default `__eq` method
--- if a `function`, then that function will be called on the field, and the output will be used in the class `__eq` method.
--- Default: `true`
---@field comp (boolean|table|fun(v):any)? should this be used in the default `comp` methods?
--- controls how the default `Class` `__lt` and `__le` methods work for this field. (this only matters if you aren't overriding `__lt` and/or `__le`).
--- if `true`, the normal `__lt/__le` function will be called on the field
--- if `false`, this field will not be evaluated when using the default `__lt/__le` method
--- if a `function`, then that function will be called on the field, and the output will be used in the class `__lt/__le` method.
--- Default: `true`
---@field default any default value for this field



---@class herbert.Class.new.params : herbert.Field[]
---@field name string? the name of the class
---@field parents herbert.Class[]? a list of parent classes
---@field fields herbert.Field[]? the fields of this class
---@field obj_metatable metatable? the metatable to be used by objects of the class. used to specify stuff like how objects should be printed or added together
---@field cls_metatable metatable? # the metatable to be used by the class. useful for specifying what happens when the class is called, or if it should be possible to add classes together
---@field init fun(self: table, ...)? # OPTIONAL: a function that will initialize objects, similiar to `__init__` in python.
---@field post_init fun(self: table)? # OPTIONAL: a function that will be run after a new object is initialized. similiar to `__post_init__` in Python dataclasses/attrs.
---@field obj_index nil|table|fun(self, key):any implement custom index metamethod behavior
---@field cls_index nil|table|fun(self, key):any implement custom index metamethod behavior
---@field new_obj_func nil|new_obj_func_presets|fun(...):(herbert.Class|boolean|nil) specify how new objects are created. defaults to "obj_data_table".

---@class herbert.Class.secrets : herbert.Class.new.params
---@field fields herbert.Field[] the fields of this class
---@field id herbert.Class.id a unique identifier for the class
---@field ancestors herbert.Class[]
---@field parents herbert.Class[] an array of all parent classes. 
--- the last index will be equal to `Class` (unless the class is `Class` itself). 
--- the class in question will also be in index 0, so that `cls.__secrets.parents[0] == cls`.
---@field name string the name of the class
---@field obj_metatable metatable the metatable to be used by objects of the class. used to specify stuff like how objects should be printed or added together
---@field cls_metatable metatable # the metatable to be used by the class. useful for specifying what happens when the class is called, or if it should be possible to add classes together

-- metatable used by `secret_class_info`. just ensures the `id` and `parents` fields cannot be changed.
local secrets_metatable = {
    __newindex = function(t, k, v)
        if k ~= "_id" and k ~= "parents" then
            rawset(t, k, v)
        end
    end
}

-- table holding a bunch of useful backend stuff. DO NOT TOUCH
local _CLASS_DB = {
    -- all direct parents of this class. does not include itself or `Class`
    direct_parents = {}, ---@type table<herbert.Class.id, herbert.Class.id[]> 

    --[[table with keys equal to `herbert.Class.id`s, with `all_ancestors_set[cls_id][a_id] == true` 
        if `a_id` is an ancestor of `cls_id`   (where the `id`s denote the `herbert.Class.id`s of the classes in question).

        *) this should never be used directly by users. instead, its meant to be a backend for more user-friendly functionality. 
        *) instead of using `all_ancestors_set`, you should use `is_instance_of`, or `get_all_ancestors`, 
            both of which depend on `all_ancestors_set`.
    ]]
    all_ancestors_set = {[0] = {[0] = true}},   ---@type table<herbert.Class.id, table<herbert.Class.id, boolean>>  
    classes = {} ---@type table<herbert.Class.id, herbert.Class>                                -- table that holds all classes
}



---@class herbert.Class
---@field __secrets herbert.Class.secrets  holds internal data. dont touch this unless you know what youre doing.
local Class = {
    __secrets = {name = "Class", -- also the default name given to all classes that dont write their own
        ancestors = {},
        fields = {},
        -- all of the things defined here in `obj_metatable` and `cls_metatable` will be overriden by subclasses, where applicable.
        -- these just provide some default functionality to avoid having to write repetitive code.

        obj_metatable = {
            --create default `__concat` and `__tostring` methods

            --[[ this allows the creation of new objects by concatenating them with a table that specifies override values of new keys.
                *) for example:
                    *) lets say we have an object `obj` of a class (called `cls`), and `obj` has fields `a = 1, b=2, c=3`.
                    *) we can create a new object by typing `obj2 = obj .. {b=4}`.
                    *) `obj2` will be a different object (ie we dont chane anything in `obj`), and
                    *) `obj` will have fields `a = 1, b =4, c = 3`.
            ]]
            __concat = function(self, other)
                local t = {}
                for _, tbl in ipairs{self, other} do
                    for k,v in pairs(tbl) do
                        t[k] = v
                    end
                end
                return self.new(t)
            end,
            __tostring = premade__tostring
        },
        
        cls_metatable = {
            --[[allows creating new objects by writing `obj = cls(...)` instead of `obj = cls.new(...)`
                
                *) if `new_obj_func == "obj_data_table" (the default), then this lets you write 
                        `obj = cls({obj_data}, ...)`, 
                    where `obj_data` is added immediately to `obj` (but possibly changed by `post_init` or converters), and 
                    `...` is passed to the class `init` method.
            ]]
            __call = function(self, ...) return self.new(...) end, 

            __tostring = premade__tostring
        },
        id = 0,
        converters = {},
        factories = {},
        new_obj_func = "obj_data_table",
        parents = {},
    },
    --- check if an object is an instance of a class with the specified name
    ---@param obj herbert.Class|any an object
    ---@param cls herbert.Class the class to check
    ---@return boolean
    is_instance_of = function(obj, cls)
        -- objects won't have a `__secrets` field but will retrieve it from the `__index` metamethod
        -- so the `rawget(obj, "__secrets")` thing will make sure that `obj` is an object and not a class
        if type(obj) ~= "table" or rawget(obj, "__secrets") ~= nil then return false end
        local obj_secrets = obj.__secrets
        if not obj_secrets or not obj_secrets.id then return false end

        -- all the ancestor classes of this object
        local obj_ancestors = _CLASS_DB.all_ancestors_set[obj_secrets.id]

        -- make sure theres information about the ancestors of this object
        -- and that `cls` is an ancestor of `obj`
        return obj_ancestors and obj_ancestors[cls.__secrets.id]
            or false
        -- if obj_ancestors ~= nil then
        --     -- return true if `cls` is in the set of all ancestors of `obj`
        --     return obj_ancestors[cls.__secrets.id] == true
        -- end
        -- return false
    end,

    --- checks if `cls1` is a subclass of `cls2`.
    ---@param cls1 herbert.Class|any
    ---@param cls2 herbert.Class
    ---@return boolean
    is_subclass_of = function(cls1, cls2)
        if type(cls1) ~= "table" then return false end
        local sc1 = rawget(cls1, "__secrets")
        if not sc1 then return false end

        local cls1_ancestors = _CLASS_DB.all_ancestors_set[sc1.id]

        return cls1_ancestors and cls1_ancestors[cls2.__secrets.id] 
            or false
    end,

    --- You can pass a class, object, or string.
    -- if you passed a string, the class with the corresponding name will be returned.
    -- if you pass an object, the class that object belongs to will be returned.
    -- if you pass a class, that class will be returned.
    ---@param obj_or_class_name herbert.Class|string
    ---@return herbert.Class?
    get_class = function(obj_or_class_name) 
        if type(obj_or_class_name) ~= "string" then
            return obj_or_class_name.__secrets and obj_or_class_name.__secrets.parents[0] 
        end
        for _, cls in pairs(_CLASS_DB.classes) do
            if cls.__secrets.name == obj_or_class_name then
                return cls
            end
        end
    end,

}

---@param obj1 herbert.Class
---@param obj2 herbert.Class
local premade__eq = function(obj1, obj2)
    if rawequal(obj1, obj2) then return true end
    local sc1, sc2 = obj1.__secrets, obj2.__secrets
    -- make sure they both belong to the same class 
    if sc1 == nil or sc2 == nil or sc1.parents[0] ~= sc2.parents[0] then return false end
    -- make sure they're both objects or both classes
    if rawget(obj1, "__secrets") ~= rawget(obj2, "__secrets") then return false end

    for _, field in ipairs(sc1.fields) do
        if field.eq == true then
            if obj1[field[1]] ~= obj2[field[1]] then return false end
        elseif field.eq then
            if field.eq(obj1[field[1]]) ~= field.eq(obj2[field[1]]) then return false end
        end
    end
    return true
end

local function raw_lt(obj1, obj2, fields)
    -- mwse.log("in class compare! comparing:\n\tobj1 = %s\n\tobj2 = %s", obj1, obj2)
    for _, field in ipairs(fields) do
        if field.comp then
            local v1 = obj1[field[1]]
            local v2 = obj2[field[1]]
            if field.comp ~= true then
                v1 = field.comp(v1)
                v2 = field.comp(v2)
            end
            
            if v1 ~= v2 then
                -- mwse.log("\t%s ~= %s\n\t\treturning %s", v1, v2, v1 < v2)
                return v1 < v2
            end
            -- mwse.log("\t%s == %s\n\t\tnot returning", v1, v2)
        end
    end
    -- mwse.log("\treturning true!")

    return false
end


local function get_fields(obj1, obj2)
    local sc1, sc2 = obj1.__secrets, obj2.__secrets
    -- make sure they both belong to the same class 
    if sc1 == nil or sc2 == nil or sc1.id == nil or sc2.id == nil then return false end
    -- make sure they're both objects or both classes
    local cls1_ancestors = _CLASS_DB.all_ancestors_set[sc1.id]
    local cls2_ancestors = _CLASS_DB.all_ancestors_set[sc2.id]
    if not cls1_ancestors or not cls2_ancestors then return false end

    -- if `cls2` is an ancestor of `cls1`, compare using `cls2` fields
    -- if `cls1` is an ancestor of `cls2`, compare using `cls1` fields
    return cls1_ancestors[sc2.id] and sc2.fields 
        or cls2_ancestors[sc1.id] and sc1.fields
end
---@param obj1 herbert.Class
---@param obj2 herbert.Class
local premade__lt = function(obj1,obj2)
    local fields = get_fields(obj1, obj2)

    if not fields then return false end
    return raw_lt(obj1, obj2, fields)
end

---@param obj1 herbert.Class
---@param obj2 herbert.Class
local premade__le = function(obj1, obj2)
    local fields = get_fields(obj1, obj2)

    if not fields then return false end
    return not raw_lt(obj2, obj1, fields)

    -- local sc1, sc2 = obj1.__secrets, obj2.__secrets
    -- -- make sure they both belong to the same class 
    -- if sc1 == nil or sc2 == nil or sc1.id == nil or sc2.id == nil then return false end
    -- -- make sure they're both objects or both classes
    -- local cls1_ancestors = _CLASS_DB.all_ancestors_set[sc1.id]
    -- local cls2_ancestors = _CLASS_DB.all_ancestors_set[sc2.id]
    -- if not cls1_ancestors or not cls2_ancestors then return false end

    -- -- if `cls2` is an ancestor of `cls1`, compare using `cls2` fields
    -- -- if `cls1` is an ancestor of `cls2`, compare using `cls1` fields
    -- local fields = cls1_ancestors[sc2.id] and sc2.fields 
    --             or cls2_ancestors[sc1.id] and sc1.fields

    -- if not fields then return false end
    -- -- local val1, val2
    -- for _, field in ipairs(fields) do
    --     if field.comp == true then
    --         if obj1[field[1]] > obj2[field[1]] then return false end
    --         -- val1, val2 = obj1[field[1]], obj2[field[1]]
    --         -- if val1 ~= val2 then return val1 < val2 end

    --     elseif field.comp then
    --         if field.comp(obj1[field[1]]) > field.comp(obj2[field[1]]) then return false end

    --         -- val1, val2 = field.comp(obj1[field[1]]), field.comp(obj2[field[1]])
    --         -- if val1 ~= val2 then return val1 < val2 end
    --     end
    -- end
    -- -- return false
    -- return true
end

---@param self herbert.Class
local function cls_index(self, key)
    local v
    if self.__secrets.cls_index then
        v = self.__secrets.cls_index(self, key)
        if v ~= nil then return v end
    end
    for _, ancestor in ipairs(self.__secrets.ancestors) do
        v = rawget(ancestor, key)
        if v ~= nil then return v end
    end
end






Class.__secrets.parents[0] = Class
_CLASS_DB.classes[0] = Class

setmetatable(Class.__secrets, secrets_metatable)
setmetatable(Class, Class.__secrets.cls_metatable)

--- recursively build a list of all ancestors of the class with the given `herbert.Class.id`
---@param id herbert.Class.id
---@return herbert.Class.id[] -- list of super classes
local function _get__all_ancestors_helper(id)
    local ancestors = {}        ---@type herbert.Class.id[] records the `herbert.Class.id`s of all ancestors of the passed `id`; built recursively. 
    local ancestors_set = {}    ---@type table<herbert.Class.id, boolean> keeps track of whether weve seen an ancestor before, so we can check in constant time 
    
    -- for each parent
    for _,p_id in ipairs(_CLASS_DB.direct_parents[id]) do

        -- check if that parent has already been recorded.
        if not ancestors_set[p_id] then

            -- if we haven't seen it before, add it to the list of parents, and then recursively add its ancestors to the list.
            ancestors[#ancestors+1] = p_id
            ancestors_set[p_id] = true
            local parent_ancestors = _get__all_ancestors_helper(p_id)
            -- for each of this parents ancestors,
            for _, p_a_id in ipairs(parent_ancestors) do
                -- if this is our first time seeing this ancestor, add it to the list and record that weve seen it
                if not ancestors_set[p_a_id] then 
                    ancestors[#ancestors+1] = p_a_id
                    ancestors_set[p_a_id] = true
                end
            end
        end
    end
    return ancestors
end

--[[build a list of all ancestors of the given class, with `ancestors[0] == cls` and `ancestors[#ancestors] == Class`.
    *) this ensures that `cls` is ignored when iterating over `ancestors` using `ipairs`, but we can still programmatically access it.
        *) were adding `Class` at the end, in this step, because it should be at the bottom of the "inheritence lattice".
        *) this is also part of the justification for using a helper function: 
            we can do all our recursion, and _then_ add `cls` and `Class` at the end.
        
        *) the reason is that all Classes should inherit from class, but they `Class` should _always_ be overridden by 
            user created classes. 
            *) this is done so that all Classes have some barebones functionality specified by `Class`, but they are free to override it as desired.
            *) here's an example of what would happen if `Class` was added normally by the 
            recursive ancestor builder:
            *) lets say were building the ancestors of a class if `Child` with two parents: `Parent1`, `Parent2`
            *) we would first look at `Parent1`, then look at all of its parents and find `Class`, 
                then we would add all of the functionality implemented by `Class`, 
                taking care to not overwrite anything defined by `Child` or `Parent1`
            *) we would then look at `Parent2`, taking care to not overwrite anything defined by `Child`, `Parent1`, or `Class` (!!)
            *) so yeah, that's the problem.
]]

-- build a list of all ancestors of the given class, with `ancestors[0] == cls` and `ancestors[#ancestors] == Class`
---@param cls herbert.Class the class to get all the ancestors of
---@return herbert.Class[] ancestors an array of all this classes ancestors
function Class.get_all_ancestors(cls)
    local id = cls.__secrets.id
    local ancestors = {}   ---@type herbert.Class[] a list of all ancestors. we will be returning this.

    --[[ the `_get__all_ancestors_helper` function does the heavy lifting, 
        now all we have to do is convert the `herbert.Class.id`s into actual Classes.
    ]]--
    local ancestor_ids = _get__all_ancestors_helper(id) 
    
    for i, ancestor_id in ipairs(ancestor_ids) do
        ancestors[i] = _CLASS_DB.classes[ancestor_id]
    end
    ancestors[0] = _CLASS_DB.classes[id] -- were doing this instead of adding `cls` because it could be an object that's calling this method
    ancestors[#ancestors+1] = Class
    -- table.insert(ancestors, Class)
    return ancestors
end

--- just like it is in python
---@param cls herbert.Class
function Class.super(cls)
    return cls.__secrets.parents[1]
end

-- this specifies how new objects are created. best left ignored unless you know what youre doing.
---@alias new_obj_func_presets
---| "obj_data_table" `cls.new(obj_data, ...)`, where `obj_data` is a table with values for objects, and `...` is passed to `init`,  and ignored if `init` is not defined
---| "no_obj_data_table" `cls.new(...)`, where `...` is passed to `init`, and ignored if `init` is not defined.

--- make sure a field is okay (runs during class creation)
---@param cls_name string name of the class
---@param field_index integer index of the field
---@param field herbert.Field
local function check_field_ok(cls_name, field_index, field)
    if type(field[1]) == nil then
        error(string.format("Error making %ith field of Class \"%s\": this field has no name!", 
            field_index, cls_name
        ))
    else
        local ftype = type(field[1])
        if ftype ~= "number" and ftype ~= "string" then
            error(string.format("Error making %ith field of Class \"%s\": field names must be strings or numbers. \z
                instead, this field is a %s", 
                field_index, cls_name, ftype
            ))
        end
    end
    for _, field_param in ipairs{"comp", "eq", "tostring"} do
        local val = field[field_param] -- will be `comp`, `eq`, or `tostring`. we're doing it this way so we can print which one is being checked

        if not val 
        or val == true 
        or type(val) == "function" 
        or type(val) == "table" and getmetatable(val).__call then 
                goto next_field 
            end

        error(string.format("Error making field %q of Class %q: %q must be either a boolean, function, or callable table.",
            field[1], cls_name, field_param
        ))

        ::next_field::
    end
end

-- =============================================================================
-- CREATE A NEW CLASS
-- =============================================================================

-- this is the meat of the file

--[[## create a new `Class`.

for the remainder of the documentation, let `cls = Class.new(class_params, base)`
- `class_params` and `base` (along with everything inside of them), are entirely optional.

`base` is simply the base of the class to create, ie any functions, default field values, etc.
- it is modified inplace, so `base == Class.new(class_params, base)`.
- if not provided, a new table will be created and then returned by `Class.new`.
- anything that could be defined in `base` can also be defined after class creation, with no loss of functionality.

`class_params` allows you to specify the:
- `name` of the class being created.
    - this is mainly used to print `cls` (and any objects of it), no actual functionality is gained by doing so.
    - after `cls` is created, it can be accessed via `cls.__secrets.name`.

- `parents`: a list of parent `Class`es, in order of decreasing priority (entries earlier in the list are inherited from first).
    - `cls` will inherit functionality from all parents listed in this list.
        - this includes inheriting all the `class_params` passed to parent classses
        - `cls` will also inherit any functionality from all ancestors of each parent class.
        - of course, functionality of parent classes will be overwritten by child classes.

    - it is also possible to pass `table`s (that arent `Class`es) here. (but this is not ideal, so probably dont do this)
        - doing so will add default field/function definitions from those tables to the class being created (except for meta functionality).
        - all `table`s will be inherited from BEFORE all `Class`es. 
            - so if you pass something like `parents={parent_cls, tbl}`, then `tbl` will be inherited from BEFORE `parent_cls`.

- `obj_metatable`: table of metamethods that should be used by objects of `cls`. (inherited from parent classes).
    - useful for specifying things like how objects should be added, multiplied, etc.
    - also lets you specify what happens when you try to call an object like a function, if the `__call` method is defined here.
    - default `__concat` and `__tostring` methods are defined by `Class`, but these will be overwritten if new ones are provided here.
        - the `__concat` method allows you to create new objects from existing objects by concatenating a table to an object: the syntax is 
            - `obj2 = obj1 .. {field1 = new_value1, field2 = new_value2, ...}
            - this will create a new object (`obj2`) with every field set to the same value as `obj1`, except for the overwritten fields (`field1, field2, ...`).
        

- `cls_metatable`: table of metamethods to be used by `cls` itself. (inherited from parent classes). 
    - useful for defining what happens when you call an object, and other stuff like that.
    - default `__call` and `__tostring` methods are specified
        - the `__call` method lets you create new objects by typing `cls(...)` instead of `cls.new(...)`.

- the `init` method, called on object creation.
    - useful for passing objects that influence how the fields of a class are created, but shouldn't be stored in objects.

- `post_init` method: called after all other object creation logic is done.
    - useful for setting field values that depend on other fields

- `converters` table: this is a `table` of the form `<field_name, func>, where
    - newly created objects "sanitize" passed values by calling the specified functions.
    - for example, if we pass `converters={a = tonumber}`, then 
        the `tonumber` function will be called on the field `a` whenever new objects are created.

- `new_obj_func`: specifies the syntax for creating new objects. 
    - default options are:
        - `obj_data_table`: new objects are created by typing 
                `obj = cls.new({obj_data}, ...)`, 
            where 
                - {obj_data} is the base of the object (i.e. we edit {obj_data} inplace so that `obj == {obj_data})
                - the variable arguments `...` are passed to the specified `init` method, if it exists.

        - `no_obj_data_table`: new objects are created by typing 
                `obj = cls.new(...)`, 
            where 
                - the variable arguments `...` are passed to the specified `init` method, if it exists.

after object creation, `cls` will will have a new field called `__secrets`, which contains the:
- `name` of `cls`,
- `init` and `post_init` functions (if specified),
- `converters` table,
- `obj_metatable` and `cls_metatable` (along with any methods inhertied by parent classes),
- `parents` list (with any tables removed), and additionally:
    - `cls == cls.__secrets.parents[0]` and `Class = cls.__secrets.parents[<LAST_ENTRY>]`

additionally, it will have some new functions:
- `cls:is_subclass_of(other_cls)`: a function that checks if a class is a subclass of another class (checks all ancestors)
- `cls:get_all_ancestors()`: a function that returns a list of all ancestors of `cls`, and additionally
    - `cls` itself is in index 0, and `Class` is the final entry.

new objects will have access to the function:
- `obj:is_instance_of(some_class)`, which will return true if the object is an instance of that class.

should any of those class or object functions be redefined by the implementation, they can also be called by typing
`Class.is_instance_of(obj, some_class)`, etc.
]]
---@generic C : herbert.Class
---@param class_params herbert.Class.new.params? used to specify meta attributes of the class
---@param base C? the base for the class.
---@return herbert.Class C newly created class
function Class.new(class_params, base)

    class_params = class_params or {}

    local cls = base or {}

    cls.__secrets = cls.__secrets or {}

    ---@type herbert.Class.secrets
    local secrets = cls.__secrets


    for _, k in ipairs{"name", "init", "post_init", "new_obj_func", "obj_index", "cls_index"} do
        if class_params[k] ~= nil then
            secrets[k] = class_params[k]
        end
    end

    for _, key in ipairs{"obj_metatable", "cls_metatable", "converters", "fields", "factories"} do
        secrets[key] = secrets[key] or {}
        if class_params[key] then
            table.copymissing(secrets[key], class_params[key])
        end
    end

    local fields = secrets.fields
    -- move all fields into `secrets.fields`. (since passing fields as array members to `class_params` is also supported)

    for _, field in ipairs(class_params) do
        table.insert(fields, field)
    end

    -- looping in reverse lets this be done in one loop
    -- remove any invalid fields
    for i = #fields, 1, -1 do
        local key = fields[i][1]

        if key == "new" or key == "__secrets" then
            table.remove(fields, i)
        end
    end
    
    do -- sanitize fields 

        for k, v in pairs(class_params.converters or {}) do
            local field
            for _, f in ipairs(class_params.fields) do
                if f[1] == k then
                    field = f
                    break
                end
            end
            if field then
                field.converter = field.converter or v
            end
            if not field then
                table.insert(class_params.fields, {k, converter=v})
            end
        end
        for k, v in pairs(class_params.factories or {}) do
            local field
            for _, f in ipairs(class_params.fields) do
                if f[1] == k then
                    field = f
                    break
                end
            end
            if field then
                field.factory = field.factory or v
            end
            if not field then
                table.insert(class_params.fields, {k, factory=v})
            end
        end


        local ever_encountered_str_key = false
        -- move default values and converters to sensible places
        ---@param field herbert.Field
        for i, field in ipairs(fields) do
            local key = field[1]
            ever_encountered_str_key = ever_encountered_str_key or type(key) == "string"
            -- `key` is allowed to be `nil`, so long as we've never encountered a string before
            -- (i.e., all numeric entries must appear before all `string` entries. any numeric entries showing up after must manually specify the field number)
            if key == nil then 
                if ever_encountered_str_key then
                    error(string.format("%ith field has no key. this is only allowed if you've never named a field before.", i))
                else
                    field[1] = i
                    key = i
                end
            end
            -- move default values to `cls`.
            if field.default ~= nil then
                cls[key] = field.default
                field.default = nil
            end

            check_field_ok(secrets.name, i, field)
        end
    end
    
    -- use fancy new tricks to get the name of the class
    if not secrets.name then
        local info = require("herbert100.utils").get_mod_info(1)
        if info then
            local filename = info.lua_parts[#info.lua_parts]
            if filename == "main.lua" or filename == "init.lua" then
                filename = info.lua_parts[#info.lua_parts - 1]
            end
            secrets.name = table.concat{
                info.mod_name:gsub("(%w)[^%s_]*[%s_]*", string.upper), -- prefix
                ".",
                filename:sub(1,1):upper(),
                (filename:sub(2, -5):gsub("[_%s]+(%w)", function(w) return "_" .. w:upper() end)), -- parentheses stop multiple returns
            }
        end
    end


    do -- bookkeeping stuff to make sure the backend works (boring!)

        -- very advanced formula that guarantees each class has a unique identifier
        local cls_id = #_CLASS_DB.classes + 1
        cls.__secrets.id = cls_id
        _CLASS_DB.classes[cls_id] = cls
        _CLASS_DB.direct_parents[cls_id] = {}
        _CLASS_DB.all_ancestors_set[cls_id] = {[cls_id] = true, [Class.__secrets.id] = true}

        -- add parents to database
        if class_params.parents then

            local parent_ids = _CLASS_DB.direct_parents[cls_id]
            for _, parent in ipairs(class_params.parents) do
                if type(parent) == 'table' then -- ignore things that aren't tables
                    -- if it's actually a class, then record this as a parent class.
                    if parent.__secrets then
                        table.insert(parent_ids, parent.__secrets.id)
                    else
                        -- it's not actually a parent_class, just a regular table, so don't record it as such. 
                        -- instead, copy over the values to the base class.
                        table.copymissing(cls, parent)
                    end
                end
            end

            local all_ancestors_set = _CLASS_DB.all_ancestors_set[cls_id]

            -- for every ancestor of `cls_id`, add all of its ancestors to the `all_ancestors_set`
            for _, ancestor_id in ipairs(_get__all_ancestors_helper(cls_id)) do
                all_ancestors_set[ancestor_id] = true
            end
        end

        
        
    end


    do -- copy over things from ancestors 
        
        --note `#ancestors >= 1` since `Class` is always in `ancestors`
        secrets.ancestors = Class.get_all_ancestors(cls)
        


        -- make child classes inherit `init`, `post_init`, `new obj_func` class parameters, if new ones werent specified.
        -- also copy over the `name` if a new one wasnt given.
        -- since `Class` is in `ancestors` (at the very end!), this also sets default values if they're missing.
        for _, k in ipairs{"init", "post_init", "new_obj_func", "name", "obj_index", "cls_index"} do
            for _, ancestor in ipairs(secrets.ancestors) do
                -- if one of these things has aleady been defined, skip the rest of the ancestors and move onto 
                -- the next property to inherit.
                -- we're checking before assigning to make sure stuff doesn't get overwritten if it already exists
                if secrets[k] ~= nil then
                    break
                end
                -- this was missing, so copy it over from the ancestor. (it could be `nil` though, which is why we dont `break`.)
                secrets[k] = ancestor.__secrets[k]
            end
        end
        -- triple `for` loops may look scary, but in practice most of these tables are quite small.
        -- besides, class creation happens pretty rarely.

        -- make child classes inherit converters and metatables from ancestor classes
        -- since `Class` is in `ancestors`, this also sets default values if they're missing.
        for _, t in ipairs({"cls_metatable", "obj_metatable"}) do
            for _, ancestor in ipairs(secrets.ancestors) do
                for k, v in pairs(ancestor.__secrets[t]) do
                    if secrets[t][k] == nil then
                        secrets[t][k] = v
                    end
                end
            end
        end
        secrets.cls_metatable.__index = cls_index
        local cls_fields = cls.__secrets.fields

        -- copy fields from ancestors
        do
            -- for each ancestor
            for _, ancestor in ipairs(secrets.ancestors) do
                -- for each field of this ancestor
                ---@param ancestor_field herbert.Field
                for _, ancestor_field in ipairs(ancestor.__secrets.fields) do
                    local key = ancestor_field[1]
                    -- check if the subclass has a field with this key
                    local cls_field_index
                    for i, field in ipairs(cls_fields) do
                        if field[1] == key then
                            cls_field_index = i
                            break
                        end
                    end
                    -- if `cls` has a field with this key, add the values from the ancestor. otherwise, add this field directly
                    if cls_field_index then
                        table.copymissing(cls_fields[cls_field_index], ancestor_field)
                    else
                        table.insert(cls_fields, ancestor_field)
                    end
                end
            end
            -- these keep track of whether we've seen any `fields` with `eq` or `__lt` being specified.
            -- if we have, then we will add the premade `comp` and `eq` metamethods (assuming no `__lt`, `__le`, or `__eq` methods have been specified)
            local use_comp, use_eq

            -- initialize field paramters to default values. we do this now so that `nil` values get inherited by ancestors
            ---@param field herbert.Field
            for _, field in ipairs(cls_fields) do
                if field.comp then
                    use_comp = true
                end
                if field.eq then
                    use_eq = true
                end
            end

            -- set `__eq` and `__lt` and `__lt`, if appropriate
            local obj_metatable = cls.__secrets.obj_metatable
            if use_eq then
                if obj_metatable.__eq == nil then
                    obj_metatable.__eq = premade__eq
                end
            end

            if use_comp then
                if obj_metatable.__lt == nil then
                    obj_metatable.__lt = premade__lt
                end
                if obj_metatable.__le == nil then
                    obj_metatable.__le = premade__le
                end
            end
        end

        
        -- make a table that holds all the classes parents
        cls.__secrets.parents = {[0] = cls} -- class itself should be at index 0
        -- iterate over the `id` of every direct parent and add the corresponding class to `parents[i]`
        for i, id in ipairs(_CLASS_DB.direct_parents[cls.__secrets.id]) do
            cls.__secrets.parents[i] = _CLASS_DB.classes[id]
        end
        cls.__secrets.parents[#cls.__secrets.parents+1] = Class -- `Class` should be at the end

        --[[ past this point, there is no good reason for the classes `id`, `new_obj_func`, or `parents` fields to change. 
            *) if any of those things do change, some core functionality could be broken.
            *) so, we set the cls.__secrets metatable to make sure those things dont change (unless the user is very persistent, i suppose)
        ]]
        setmetatable(cls.__secrets, secrets_metatable)

        -- update the class metatable
        setmetatable(cls, cls.__secrets.cls_metatable)
    end
    
    
    

    --[[ objects lookup missing fields in the class.
        since weve told classes to lookup missing fields in their ancestor classes, this also has the effect of 
        telling objects to lookup missing fields in all ancestors of this object.
    ]]
    do -- set obj __index
        if secrets.obj_index then
            secrets.obj_metatable.__index = function(self, key)
                local v = secrets.obj_index(self, key)
                if v ~= nil then return v end
                return cls[key]
            end
        else
            secrets.obj_metatable.__index = cls
        end
    end

    class_params = nil
    
    -- make the `cls.new` method that will be used to create new objects, depending on what the specified method was.
    if secrets.new_obj_func == "obj_data_table" then

        --- make a new object.
        ---@param obj_data herbert.Class?  -- fields of the object
        ---@param ... any passed to `init`
        ---@return herbert.Class obj
        function cls.new(obj_data, ...)
            ---@type herbert.Class
            local obj = obj_data or {}
            if getmetatable(obj) == secrets.obj_metatable then return obj end

            setmetatable(obj, secrets.obj_metatable)


            if secrets.init ~= nil then
                secrets.init(obj, ...)
            end

            local k, conv, fac
            for _, field in ipairs(fields) do
                k, conv, fac = field[1], field.converter, field.factory
                if conv and rawget(obj, k) ~= nil then
                    obj[k] = conv(obj[k])
                end
                if fac and rawget(obj, k) == nil then
                    obj[k] = fac(obj)
                end
            end

            if secrets.post_init ~= nil then 
                secrets.post_init(obj)
            end
            return obj
        end
    elseif secrets.new_obj_func == "no_obj_data_table" then
       
        --- make a new object
        ---@param ... any passed to `init`
        ---@return herbert.Class obj
        function cls.new(...)
            ---@type herbert.Class
            ---@diagnostic disable-next-line: missing-fields
            local obj = {}
            setmetatable(obj, secrets.obj_metatable)

            if secrets.init ~= nil then
                secrets.init(obj, ...)
            end
            local k, conv, fac
            for _, field in ipairs(fields) do
                k, conv, fac = field[1], field.converter, field.factory
                if conv and rawget(obj, k) ~= nil then
                    obj[k] = conv(obj[k])
                end
                if fac and rawget(obj, k) == nil then
                    obj[k] = fac(obj)
                end
            end
            if secrets.post_init ~= nil then 
                secrets.post_init(obj)
            end
            return obj
        end
    else
        -- if a `new_obj_func` was specified
        cls.new = function(...)
            -- do the specified `new_obj_func`, then do our usual stuff.
            local obj = secrets.new_obj_func(...)

            if type(obj) ~= "table" then return obj end


            setmetatable(obj, secrets.obj_metatable)

            if secrets.init ~= nil then
                secrets.init(obj, ...)
            end
            
            local k, conv, fac
            for _, field in ipairs(fields) do
                k, conv, fac = field[1], field.converter, field.factory
                if conv and rawget(obj, k) ~= nil then
                    obj[k] = conv(obj[k])
                end
                if fac and rawget(obj, k) == nil then
                    obj[k] = fac(obj)
                end
            end
            if secrets.post_init ~= nil then 
                secrets.post_init(obj)
            end

            return obj
        end
    end

    return cls
end

return Class


---@alias herbert.Class.metatable<T> {__unm: (fun(self: T): T), __add: (fun(a: T|any, b:T|any): T), __sub: (fun(a: T|any, b:T|any): T), __mul: (fun(a: T|any, b:T|any): T), __div: (fun(a: T|any, b:T|any): T), __mod: (fun(a: T|any, b:T|any): T), __pow: (fun(a: T|any, b:T|any): T), __concat: (fun(a: T|any, b:T|any): T), __tostring: (fun(self: T): string), __tojson: (fun(self: T): string), __call: (fun(self: T, ...): ...), __eq: (fun(a: T|any, b:T|any): boolean), __lt: (fun(a: T|any, b:T|any): boolean), __le: (fun(a: T|any, b:T|any): boolean),}