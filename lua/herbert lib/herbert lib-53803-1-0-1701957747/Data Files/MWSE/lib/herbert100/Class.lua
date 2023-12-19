local useful_functions = require("herbert100.useful_functions")


---@alias CLASS_ID integer


---@class class_meta_info 
---@field name string? the name of the class
---@field obj_metatable table? the metatable to be used by objects of the class. used to specify stuff like how objects should be printed or added together
---@field cls_metatable table? # the metatable to be used by the class. useful for specifying what happens when the class is called, or if it should be possible to add classes together
---@field init fun(self: table, ...)? # OPTIONAL: a function that will initialize objects, similiar to `__init__` in python.
---@field converters table<string, fun(any): any> # OPTIONAL: a table of the form {<class_field> : fun}. when a new object is created, the converters table is checked to convert any passed parameters to the appropriate values. this will only work if `init == nil`
---@field post_init fun(self: table)? # OPTIONAL: a function that will be run after a new object is initialized. similiar to `__post_init__` in Python dataclasses/attrs.


---@class secret_class_info : class_meta_info
---@field id CLASS_ID a unique identifier for the class
---@field new_obj_func new_obj_func_presets|fun()   the way that 
---@field parents Class[] an array of all parent classes. the last index will be equal to `Class` (unless the class is `Class` itself). the class in question will also be in index 0, so that `cls.__secrets.parents[0] == cls`.


---@class new_class_params : class_meta_info
---@field parents Class[]? a list of parent classes
---@field new_obj_func (new_obj_func_presets|fun(...):Class)? specify how new objects are created. defaults to "obj_data_table".



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
    direct_parents = {}, ---@type table<CLASS_ID, CLASS_ID[]> 

    --[[table with keys equal to `CLASS_ID`s, with `all_ancestors_set[cls_id][a_id] == true` 
        if `a_id` is an ancestor of `cls_id`   (where the `id`s denote the `CLASS_ID`s of the classes in question).

        *) this should never be used directly by users. instead, its meant to be a backend for more user-friendly functionality. 
        *) instead of using `all_ancestors_set`, you should use `is_instance_of`, or `get_all_ancestors`, 
            both of which depend on `all_ancestors_set`.
    ]]
    all_ancestors_set = {[0] = {[0] = true}},   ---@type table<CLASS_ID, table<CLASS_ID, boolean>>  
    classes = {} ---@type table<CLASS_ID, Class>                                -- table that holds all classes
}



---@class Class
---@field __secrets secret_class_info  holds internal data. dont touch this unless you know what youre doing.
local Class = {
    __secrets = {name = "Class", -- also the default name given to all classes that dont write their own

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
            -- default tostring method that prints all non-secret, nonfunction field entries of `obj`, along with any default values inherited
            -- from parent classes.
            --- make a string representing this object
            ---@param obj Class
            ---@return string
            __tostring = function(obj)
                -- a list of strings, all of the form "k=v", where `k` is a field of `obj` (or an ancestor of `obj`) with value `v`

                local field_strs = {}   ---@type string[] 
                -- records the fields weve already printed, so we dont have any repeats
                local found_keys = {}   ---@type table<string, boolean> 

                local ancestors = obj:get_all_ancestors()
                -- set `obj` as the -1st ancestor of itself so that we can do everything in one for loop.
                ancestors[-1] = obj
                for i=-1, #ancestors do
                    local cls = ancestors[i]
                    for k,v in pairs(cls) do
                        if not found_keys[k] then 
                            found_keys[k] = true    -- record that we've seen it, even if we're not going to add it

                            -- dont add the key if weve already seen it before, or if it starts with "_" (and thus denotes a hidden field)
                            if type(v) ~= "function" and k:byte(1) ~= string.byte("_") then
                                field_strs[#field_strs+1] = table.concat({tostring(k), tostring(v)}, "=")
                            end
                        end
                    end
                end
                return string.format("%s(%s)", 
                    obj.__secrets.name:gsub(" ", "_"),   -- replace spaces in class names with underscores
                    table.concat(field_strs, ", ")      -- add all the key-value pairs, and separate them with a comma
                )
            end,
        },
        
        cls_metatable = {
            --[[allows creating new objects by writing `obj = cls(...)` instead of `obj = cls.new(...)`
                
                *) if `new_obj_func == "obj_data_table" (the default), then this lets you write 
                        `obj = cls({obj_data}, ...)`, 
                    where `obj_data` is added immediately to `obj` (but possibly changed by `post_init` or converters), and 
                    `...` is passed to the class `init` method.
            ]]
            __call = function(self, ...) return self.new(...) end, 

            -- this is the same as the object `__tostring`, except we dont add `obj` to the list of ancestors (because it doesnt exist)
            __tostring = function(obj)
                local field_strs = {}   ---@type string[] 
                local found_keys = {}   ---@type table<string, boolean> 

                local ancestors = obj:get_all_ancestors()
                for i=0, #ancestors do
                    local cls = ancestors[i]
                    for k,v in pairs(cls) do
                        -- dont add the key if weve already seen it before, or if it starts with "_" (and thus denotes a hidden field)
                        if not found_keys[k] then 
                            found_keys[k] = true    -- record that we've seen it, even if we're not going to add it
                            if type(v) ~= "function" and k:byte(1) ~= string.byte("_") then
                                field_strs[#field_strs+1] = table.concat({tostring(k), tostring(v)}, "=")
                            end
                        end
                    end
                end
                return string.format("%s(%s)", 
                    obj.__secrets.name:gsub(" ", "_"),  -- replace spaces in class names with underscores
                    table.concat(field_strs, ", ")      -- add all the key-value pairs, and separate them with a comma
                )
            end,
        },
        id = 0,
        converters = {},
        new_obj_func = "obj_data_table",
        parents = {},
    },
    --- check if an object is an instance of a class with the specified name
    ---@param obj Class an object
    ---@param cls Class the class to check
    ---@return boolean
    is_instance_of = function(obj, cls)
        ---@diagnostic disable-next-line: undefined-field
        return obj.__HCI == true and _CLASS_DB.all_ancestors_set[obj.__secrets.id][cls.__secrets.id] == true
    end,

    --- checks if `cls1` is a subclass of `cls2`.
    ---@param cls1 Class
    ---@param cls2 Class
    ---@return boolean
    is_subclass_of = function(cls1, cls2)
        return _CLASS_DB.all_ancestors_set[cls1.__secrets.id][cls2.__secrets.id] == true
    end,

    --- get the class that an object belongs to. If called on a class, it will simply return itself.
    ---@param obj Class
    ---@return Class
    get_class = function(obj) return obj.__secrets.parents[0] end,


}
Class.__secrets.parents[0] = Class
_CLASS_DB.classes[0] = Class

setmetatable(Class.__secrets, secrets_metatable)
setmetatable(Class, Class.__secrets.cls_metatable)

--- recursively build a list of all ancestors of the class with the given `CLASS_ID`
---@param id CLASS_ID
---@return CLASS_ID[] -- list of super classes
local function _get__all_ancestors_helper(id)
    local ancestors = {}        ---@type CLASS_ID[] records the `CLASS_ID`s of all ancestors of the passed `id`; built recursively. 
    local ancestors_set = {}    ---@type table<CLASS_ID, boolean> keeps track of whether weve seen an ancestor before, so we can check in constant time 
    
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
---@param cls Class the class to get all the ancestors of
---@return Class[] ancestors an array of all this classes ancestors
function Class.get_all_ancestors(cls)
    local id = cls.__secrets.id
    local ancestors = {}   ---@type Class[] a list of all ancestors. we will be returning this.

    --[[ the `_get__all_ancestors_helper` function does the heavy lifting, 
        now all we have to do is convert the `CLASS_ID`s into actual Classes.
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

-- this specifies how new objects are created. best left ignored unless you know what youre doing.
---@alias new_obj_func_presets
---| "obj_data_table" `cls.new(obj_data, ...)`, where `obj_data` is a table with values for objects, and `...` is passed to `init`,  and ignored if `init` is not defined
---| "no_obj_data_table" `cls.new(...)`, where `...` is passed to `init`, and ignored if `init` is not defined.



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
---@param class_params new_class_params? used to specify meta attributes of the class
---@param base table? the base for the class.
---@return Class cls newly created class
function Class.new(class_params, base)

    class_params = class_params or {}
    local cls = base or {}
    if cls.__secrets then
        local sc = cls.__secrets
        if sc.obj_metatable then
            useful_functions.table_append(sc.obj_metatable, class_params.obj_metatable)
        else
            sc.obj_metatable = class_params.obj_metatable or {}
        end

        if sc.cls_metatable then
            useful_functions.table_append(sc.cls_metatable, class_params.cls_metatable)
        else
            sc.cls_metatable = class_params.cls_metatable or {}
        end

        if sc.converters then
            useful_functions.table_append(sc.converters, class_params.converters)
        else
            sc.converters = class_params.converters or {}
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
            new_obj_func = class_params.new_obj_func
        }
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
            for _,p_id in ipairs(class_params.parents) do
                if type(p_id) == 'table' then
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

    
    local ancestors = Class.get_all_ancestors(cls)


    do -- copy over things from ancestors 
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
        for _,k in ipairs({"init", "post_init", "new_obj_func", "name"}) do
            for _, ancestor in ipairs(ancestors) do
                -- if one of these things has aleady been defined, skip the rest of the ancestors and move onto 
                -- the next property to inherit
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
        for _,t in ipairs({"cls_metatable", "obj_metatable", "converters"}) do
            for _, ancestor in ipairs(ancestors) do
                for k,v in pairs(ancestor.__secrets[t]) do
                    if cls.__secrets[t][k] == nil then
                        cls.__secrets[t][k] = v
                    end
                end
            end
        end
        
        -- make a table that holds all the classes parents
        local direct_parent_ids = _CLASS_DB.direct_parents[cls.__secrets.id]
        cls.__secrets.parents = {}
        for i, id in ipairs(direct_parent_ids) do
            cls.__secrets.parents[i] = _CLASS_DB.classes[id]
        end
        cls.__secrets.parents[0] = cls -- class itself should be at index 0
        cls.__secrets.parents[#cls.__secrets.parents+1] = Class -- `Class` should be at the end

        --[[ past this point, there is no good reason for the classes `id`, `new_obj_func`, or `parents` fields to change. 
            *) if any of those things do change, some core functionality could be broken.
            *) so, we set the cls.__secrets metatable to make sure those things dont change (unless the user is very persistent, i suppose)
        ]]
        setmetatable(cls.__secrets, secrets_metatable)
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
        ---@param obj_data Class?  -- fields of the object
        ---@param ... any passed to `init`
        ---@return Class obj
        function cls.new(obj_data, ...)
            ---@type Class
            local obj = obj_data or {}
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
    elseif cls.__secrets.new_obj_func == "no_obj_data_table" then
       
        --- make a new object
        ---@param ... any passed to `init`
        ---@return Class obj
        function cls.new(...)
            ---@type Class
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

