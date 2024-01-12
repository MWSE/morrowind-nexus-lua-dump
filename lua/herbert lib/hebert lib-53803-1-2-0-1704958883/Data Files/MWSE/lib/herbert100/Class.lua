local useful_functions = require("herbert100.useful_functions")


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
            if ts == true or ts == nil then
                if type(self[key]) == "string" then
                    str = sf('%s="%s"', key, self[key])
                else
                    str = sf('%s=%s', key, self[key])
                end
            else
                str = sf('%s=%s', key, ts(self[key]))
            end
            table.insert(field_strs, str)
        end
    end
    -- if no fields were provided, do the old print statement
    if next(field_strs) == nil then 
        -- records the fields weve already printed, so we dont have any repeats
        local found_keys = {"__secrets, __HCI", "new"}   ---@type table<string, boolean> 

        local ancestors = self:get_all_ancestors()
        --if this is being called on an object, we should print the object keys first
        -- we'll do this by putting the object at index -1, and then going from there
        local start_index = 0
        ---@diagnostic disable-next-line: undefined-field
        if self.__HCI then
            ancestors[-1] = self
            start_index = -1
        end
        for i=start_index, #ancestors do
            local cls = ancestors[i]
            for k,v in pairs(cls) do
                -- only parse keys we havent seen before
                if found_keys[k] then goto next_key end

                found_keys[k] = true    -- record that we've seen it, even if we're not going to add it

                -- if the value is a function, or if it's a string starting with "_", then we should skip it
                if type(v) == "function" or (type(k) == "string" and k:sub(1,1) == "_") then
                        goto next_key
                end
                -- 
                table.insert(field_strs, sf('%s=%s', k,v) )
                ::next_key::
            end
        end
    end

    
    return string.format("%s(%s)", 
        self.__secrets.name:gsub(" ", "_"),   -- replace spaces in class names with underscores
        table.concat(field_strs, ", ")      -- add all the key-value pairs, and separate them with a comma
    )
end



---@alias herbert.Class.id integer

---@class herbert.Field
---@field converter (table|fun(v):any)? converter for this field. this will be sent into the `converters` table
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

---@class herbert.Class.meta
---@field name string? the name of the class
---@field fields herbert.Field[] the fields of this class
---@field obj_metatable table? the metatable to be used by objects of the class. used to specify stuff like how objects should be printed or added together
---@field cls_metatable table? # the metatable to be used by the class. useful for specifying what happens when the class is called, or if it should be possible to add classes together
---@field init fun(self: table, ...)? # OPTIONAL: a function that will initialize objects, similiar to `__init__` in python.
---@field converters table<string, fun(any): any> # OPTIONAL: a table of the form {<class_field> : fun}. when a new object is created, the converters table is checked to convert any passed parameters to the appropriate values. this will only work if `init == nil`
---@field post_init fun(self: table)? # OPTIONAL: a function that will be run after a new object is initialized. similiar to `__post_init__` in Python dataclasses/attrs.


---@class herbert.Class.secrets : herbert.Class.meta
---@field id herbert.Class.id a unique identifier for the class
---@field fields herbert.Field[] the fields of this class
---@field new_obj_func new_obj_func_presets|fun() the way that new objects are made
---@field parents herbert.Class[] an array of all parent classes. the last index will be equal to `Class` (unless the class is `Class` itself). the class in question will also be in index 0, so that `cls.__secrets.parents[0] == cls`.


---@class herbert.Class.new.params : herbert.Class.meta, herbert.Field[]
---@field parents herbert.Class[]? a list of parent classes
---@field eq boolean? use the premade `__eq` method (overriden by inheritence)? Default: false
---@field comp boolean? use premade comparison methods (overriden by inheritence)? Default: true
---@field fields herbert.Field[]? the fields of this class
---@field new_obj_func (new_obj_func_presets|fun(...):herbert.Class)? specify how new objects are created. defaults to "obj_data_table".



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
                return self.new(useful_functions.table_concat(self, other))
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
        new_obj_func = "obj_data_table",
        parents = {},
    },
    --- check if an object is an instance of a class with the specified name
    ---@param obj herbert.Class an object
    ---@param cls herbert.Class the class to check
    ---@return boolean
    is_instance_of = function(obj, cls)
        ---@diagnostic disable-next-line: undefined-field
        if type(obj) ~= "table" or not obj.__HCI then return false end
        local ancestors = _CLASS_DB.all_ancestors_set[obj.__secrets.id]
        if ancestors ~= nil then
            return ancestors[obj.__secrets.id] == true
        end
        return false
    end,

    --- checks if `cls1` is a subclass of `cls2`.
    ---@param cls1 herbert.Class
    ---@param cls2 herbert.Class
    ---@return boolean
    is_subclass_of = function(cls1, cls2)
        if type(cls1) ~= "table" or not cls1.__secrets then return false end
        local ancestors = _CLASS_DB.all_ancestors_set[cls1.__secrets.id]
        if ancestors ~= nil then 
            return ancestors[cls2.__secrets.id] == true 
        end
        return false
    end,

    --- get the class that an object belongs to. If called on a class, it will simply return itself.
    ---@param obj herbert.Class
    ---@return herbert.Class
    get_class = function(obj) return obj.__secrets and obj.__secrets.parents[0] end,

}
local premade__eq = function(obj1,obj2)
    if obj1.__HCI ~= true or obj2.__HCI ~= true then
        error("Error: you can only compare objects with other objects.")
    end
    local cls = Class.get_class(obj1)
    if not cls or cls ~= Class.get_class(obj2) then
        error("Error: tried to compare objects belonging to different classes.")
    end
    for _, field in ipairs(cls.__secrets.fields) do
        if field.eq then
            if field.eq == true then
                if obj1[field[1]] ~= obj2[field[1]] then return false end
            else
                if field.eq(obj1[field[1]]) ~= field.eq(obj2[field[1]]) then return false end
            end
        end
    end
    

    return true
end

local premade__lt = function(obj1,obj2)
    if obj1.__HCI ~= true or obj2.__HCI ~= true then
        error("Error: you can only compare objects with other objects.")
    end
    local cls = Class.get_class(obj1)
    if not cls or cls ~= Class.get_class(obj2) then
        error("Error: tried to compare objects belonging to different classes.")
    end
    local val1, val2
    for _, field in ipairs(cls.__secrets.fields) do
        if field.comp then
            if field.comp == true then
                val1, val2 = obj1[field[1]], obj2[field[1]]
            else
                val1, val2 = field.comp(obj1[field[1]]), field.comp(obj2[field[1]])
            end
            if val1 ~= val2 then return val1 < val2 end
        end
    end
    

    -- return false
end

local premade__le = function(obj1,obj2)
    if obj1.__HCI ~= true or obj2.__HCI ~= true then
        error("Error: you can only compare objects with other objects.")
    end
    local cls = Class.get_class(obj1)
    if not cls or cls ~= Class.get_class(obj2) then
        error("Error: tried to compare objects belonging to different classes.")
    end
    local val1, val2
    for _, field in ipairs(cls.__secrets.fields) do
        if field.comp then
            if field.comp == true then
                val1, val2 = obj1[field[1]], obj2[field[1]]
            else
                val1, val2 = field.comp(obj1[field[1]]), field.comp(obj2[field[1]])
            end
            if val1 > val2 then return false end
        end
    end
    

    return true
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
    if type(field[1]) ~= "string" then
        error(string.format("Error making %ith field of Class \"%s\": this field has no name!", 
            field_index, cls_name
        ))
    end
    for _, field_param in ipairs{"comp", "eq", "tostring"} do
        local val = field[field_param] -- will be `comp`, `eq`, or `tostring`. we're doing it this way so we can print which one is being checked

        if not val or val == true or type(val) == "function" then goto next_field end
        if type(val) == "table" and getmetatable(val).__call then goto next_field end

        error(string.format("Error making field \"%s\" of Class \"%s\": \"%s\" must be either a boolean, function, or callable table.",
            field[1], cls_name, field_param
        ))

        ::next_field::
    end
end

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
---@param class_params herbert.Class.new.params? used to specify meta attributes of the class
---@param base table? the base for the class.
---@return herbert.Class cls newly created class
function Class.new(class_params, base)

    class_params = class_params or {}
    local cls = base or {}
    if cls.__secrets then
        local sc = cls.__secrets

        for _, key in ipairs{"obj_metatable", "cls_metatable", "converters", "fields"} do
            sc[key] = sc[key] or {}
            table.copymissing(sc[key], class_params[key] or {})
        end
        
        sc.new_obj_func = sc.new_obj_func or class_params.new_obj_func
        sc.init = sc.init or class_params.init
        sc.post_init = sc.post_init or class_params.post_init
        sc.name = sc.name or class_params.name
    else
        cls.__secrets = {
            obj_metatable = class_params.obj_metatable or {},
            cls_metatable = class_params.cls_metatable or {},
            converters = class_params.converters or {},
            init = class_params.init,
            post_init = class_params.post_init,
            name =  class_params.name,
            new_obj_func = class_params.new_obj_func,
            fields = class_params.fields or {} ---@type herbert.Field[]
        }
    end
    local secrets = cls.__secrets
    -- move all fields into `secrets.fields`. (since passing fields as array members to `class_params` is also supported)
    for _, field in ipairs(class_params) do
        table.insert(secrets.fields, field)
    end

    -- used to remove any fields that are invalid
    local bad_field_indices = {}

    -- move default values and converters to sensible places
    ---@param field herbert.Field
    for i, field in ipairs(secrets.fields) do
        local key = field[1]
        if key == "new" or key == "__secrets" or key == "__HCI" then
            table.insert(bad_field_indices,i)
        end
        -- move converters to the `converters` table
        if field.converter then
            secrets.converters[key] = field.converter
            field.converter = nil
        end
        -- move default values to `cls`.
        if field.default ~= nil then
            cls[key] = field.default
            field.default = nil
        end
        check_field_ok(secrets.name, i, field)
    end
    for _, index in ipairs(bad_field_indices) do
        table.remove(secrets.fields, index)
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
            for _, p_id in ipairs(class_params.parents) do
                if type(p_id) == 'table' then -- ignore things that aren't tables
                    -- if it's actually a class, then record this as a parent class.
                    if p_id.__secrets then
                        table.insert(parent_ids, p_id.__secrets.id)
                    else
                        -- it's not actually a parent_class, just a regular table, so don't record it as such. 
                        -- instead, copy over the values to the base class.
                        useful_functions.table_append(cls,p_id)
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
        
        local ancestors = Class.get_all_ancestors(cls)
        --note `#ancestors >= 1` since `Class` is always in `ancestors`

        -- make child classes look things up in parent classes, in order of inheritence
        if #ancestors == 1 then
            cls.__secrets.cls_metatable.__index = ancestors[1]
        else
            cls.__secrets.cls_metatable.__index = function(self, key)
                local v
                for _, ancestor in ipairs(ancestors) do
                    v = rawget(ancestor,key)
                    if v ~= nil then return v end
                end
            end
        end


        -- make child classes inherit `init`, `post_init`, `new obj_func` class parameters, if new ones werent specified.
        -- also copy over the `name` if a new one wasnt given.
        -- since `Class` is in `ancestors` (at the very end!), this also sets default values if they're missing.
        for _,k in ipairs{"init", "post_init", "new_obj_func", "name"} do
            for _, ancestor in ipairs(ancestors) do
                -- if one of these things has aleady been defined, skip the rest of the ancestors and move onto 
                -- the next property to inherit.
                -- we're checking before assining to make sure stuff doesn't get overwritten if it already exists
                if cls.__secrets[k] ~= nil then
                    break
                end
                -- this was missing, so copy it over from the ancestor. (it could be `nil` though, which is why we dont `break`.)
                cls.__secrets[k] = ancestor.__secrets[k]
            end
        end
        -- triple `for` loops may look scary, but in practice most of these tables are quite small.
        -- besides, class creation happens pretty rarely.

        -- make child classes inherit converters and metatables from ancestor classes
        -- since `Class` is in `ancestors`, this also sets default values if they're missing.
        for _, t in ipairs({"cls_metatable", "obj_metatable", "converters"}) do -- 
            for _, ancestor in ipairs(ancestors) do
                for k,v in pairs(ancestor.__secrets[t]) do
                    if cls.__secrets[t][k] == nil then
                        cls.__secrets[t][k] = v
                    end
                end
            end
        end
        local cls_fields = cls.__secrets.fields

        -- copy fields from ancestors
        for _, ancestor in ipairs(ancestors) do
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
            -- elseif field.comp == nil then 
            --     field.comp = false
            end
            if field.eq then
                use_eq = true
            -- elseif field.eq == nil then
            --     field.eq = false 
            end
            -- if field.tostring == nil then
            --     field.tostring = true 
            -- end
        end

        -- set `__eq` and `__lt` and `__lt`, if appropriate
        if use_eq then
            if cls.__secrets.obj_metatable.__eq == nil then
                cls.__secrets.obj_metatable.__eq = premade__eq
            end
        end
        if use_comp then
            if cls.__secrets.obj_metatable.__lt == nil then
                cls.__secrets.obj_metatable.__lt = premade__lt
            end
            if cls.__secrets.obj_metatable.__le == nil then
                cls.__secrets.obj_metatable.__le = premade__le
            end
        end

        
        -- make a table that holds all the classes parents
        cls.__secrets.parents = {[0] = cls} -- class itself should be at index 0
        -- iterate over the `id` of every direct parent and add it to `parents[i]`
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
    cls.__secrets.obj_metatable.__index = cls

    
    -- make the `cls.new` method that will be used to create new objects, depending on what the specified method was.
    if cls.__secrets.new_obj_func == "obj_data_table" then

        --- make a new object.
        ---@param obj_data herbert.Class?  -- fields of the object
        ---@param ... any passed to `init`
        ---@return herbert.Class obj
        function cls.new(obj_data, ...)
            ---@type herbert.Class
            local obj = obj_data or {}
            ---@diagnostic disable-next-line: inject-field
            obj.__HCI = true -- field that asserts this is a herbert class instance
            setmetatable(obj, cls.__secrets.obj_metatable)


            if cls.__secrets.init ~= nil then
                cls.__secrets.init(obj, ...)
            end
            for key, converter in pairs(cls.__secrets.converters) do
                obj[key] = converter(obj[key])
            end
            if cls.__secrets.post_init ~= nil then 
                cls.__secrets.post_init(obj)
            end
            return obj
        end
    elseif cls.__secrets.new_obj_func == "no_obj_data_table" then
       
        --- make a new object
        ---@param ... any passed to `init`
        ---@return herbert.Class obj
        function cls.new(...)
            ---@type herbert.Class
            ---@diagnostic disable-next-line: missing-fields
            local obj = {}
            ---@diagnostic disable-next-line: inject-field
            obj.__HCI = true -- field that asserts this is a herbert class instance
            setmetatable(obj, cls.__secrets.obj_metatable)


            if cls.__secrets.init ~= nil then
                cls.__secrets.init(obj, ...)
            end
            for field, converter in pairs(cls.__secrets.converters) do
                obj[field] = converter(obj[field])
            end
            if cls.__secrets.post_init ~= nil then 
                cls.__secrets.post_init(obj)
            end
            return obj
        end
    else
        -- if a `new_obj_func` was specified
        cls.new = function(...)
            -- do the specified `new_obj_func`, then do our usual stuff.
            local obj = cls.__secrets.new_obj_func(...)

            
            ---@diagnostic disable-next-line: inject-field
            obj.__HCI = true
            setmetatable(obj, cls.__secrets.obj_metatable)

            if cls.__secrets.init ~= nil then
                cls.__secrets.init(obj, ...)
            end
            for field, converter in pairs(cls.__secrets.converters) do
                obj[field] = converter(obj[field])
            end
            if cls.__secrets.post_init ~= nil then 
                cls.__secrets.post_init(obj)
            end
            return obj
        end
    end

    return cls
end
return Class

