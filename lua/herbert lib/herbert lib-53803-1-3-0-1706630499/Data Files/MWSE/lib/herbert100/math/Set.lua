local Class = require"herbert100.Class"


-- =============================================================================
-- define the base
-- =============================================================================
-- these methods will be useful when defining the object oriented parts later on

-- a class that handles various operations associated with sets
---@class herbert.Set : herbert.Class
---@field vals table<any, boolean> the actual values stored by the set
---@field n integer number of elements
---@field new fun(vals:herbert.Set|table, dont_copy: boolean?): herbert.Set
local Set = {}

--- iterate over the elements of the set
function Set:iter() 
    return next, self.vals 
end

-- returns a set that's a union of all these sets. does not modify inplace. is both a method and a function
---@param ... table|any
---@return herbert.Set
function Set.union(...)
    local vals, n = {}, 0

    for _, arg in ipairs{...} do
        -- if `arg` is an element
        if type(arg) ~= "table" then
            -- put it in the list of values
            if not vals[arg] then
                vals[arg] = true
                n = n + 1
            end
        -- if `arg` is already a set, we should iterate keys
        elseif Class.is_instance_of(arg, Set) then
            for v in arg() do
                if not vals[v] then
                    vals[v] = true
                    n = n + 1
                end
            end
        else -- we should iterate the values
            for _, v in ipairs(arg) do
                if not vals[v] then
                    vals[v] = true
                    n = n + 1
                end
            end
        end
    end
    return Set({vals=vals, n = n}, true)
end

-- returns an interection of various sets/tables/values. does not modify in place.
---@param set1 herbert.Set|table|any
---@param ... herbert.Set|table|any
---@return herbert.Set
function Set.intersection(set1, ...)
    -- first argument will play a special role, in order to improve time complexity
    local set = Set.new(set1, nil)

    -- now check other args
    local other_sets = {}
    for i, arg in ipairs{...} do
        if Class.is_instance_of(arg, Set) then
            other_sets[i] = arg
        elseif type(arg) == "table" then
            other_sets[i] = Set.new(arg)
        end
    end
    local bad_vals = {}
    -- for each value
    for set_val in set() do
        -- for each other set
        for _, other_set in ipairs(other_sets) do
            -- if we found a set that doesnt contain this value, mark it as a bad value
            if not other_set.vals[set_val] then
                table.insert(bad_vals, set_val)
                break
            end
        end
    end
    -- remove all the bad values
    set.n = set.n - #bad_vals
    for _, v in ipairs(bad_vals) do
        set.vals[v] = nil
    end
    return Set.new(set, true)
end

-- returns this set minus an arbitrary number of other sets. does not modify inplace
---@param set1 herbert.Set|table|any
---@param ... herbert.Set|table
---@return herbert.Set
function Set.minus(set1, ...)
    local set = Set.new(set1)
    local vals, n = set.vals, set.n
    for _, arg in ipairs{...} do
        -- if `arg` is a value

        if type(arg) ~= "table" then
            if vals[arg] then
                vals[arg] = nil 
                n = n - 1
            end
        -- `arg` is a set
        elseif Class.is_instance_of(arg, Set) then
            for v in arg() do 
                if vals[v] then
                    vals[v] = nil 
                    n = n - 1
                end
            end
        else -- `arg` is an array
            for _,v in ipairs(arg) do 
                if vals[v] then
                    vals[v] = nil 
                    n = n - 1
                end
            end
        end
    end
    set.n = n
    return Set.new(set, true)
end

--- is this a subset of another set
---@param set herbert.Set|table the potential superset
---@return boolean
function Set:is_subset_of(set)
    -- quickly check the cardinalities first
    if #self > #set then return false end -- make sure `#self <= #set`

    if not Class.is_instance_of(set,Set) then
        set = Set.new(set)
    end

    for v in self() do
        -- make sure `v` is also in `set`
        if not set:contains(v) then 
            return false 
        end
    end
    return true
end

--- is this set a proper subset of another set?
---@param set herbert.Set
---@return boolean
function Set:is_proper_subset_of(set)
    return #self < #set and self:is_subset_of(set)
end

--- does this set equal another set?
---@param set herbert.Set
---@return boolean
function Set:equals(set)
    -- in the finite setting, it's enough to check that the cardinalities are equal and one is a subset of the other
    return #self == #set and self:is_subset_of(set)
end



--- checks if various sets have a nonempty intersection. both a method and a function.
---@param ... herbert.Set|table
---@return boolean intersection_is_nonempty
function Set.intersects(...) 
    return Set.intersection(...):is_empty() 
end


-- insert a value into this set
---@param val any the value to insert
function Set:insert(val)
    if val ~= nil and not self.vals[val] then
        self.vals[val] = true
        self.n = self.n + 1
    end
end


--- makes a copy of this set
---@return herbert.Set
function Set:make_copy()
    return Set.new(self)
end

--- returns a list containing all of the values present in this `Set`.
--- @param sort nil|true|fun(a,b):boolean should the values be sorted?
---@return any[] vals list of values contained in this set
function Set:tolist(sort) 
    return table.keys(self.vals, sort) 
end




--- checks if the specified value is in this `Set`
---@param self herbert.Set
---@param value any -- the value to test for 
---@return boolean -- whether the value is in the set
function Set:contains(value)
    -- adding the `== true` so it returns `false` instead of `nil` when the `value` isnt present
    return value ~= nil and self.vals[value] == true 
end

--- is this a superset of another set
---@param set herbert.Set the potential superset
---@return boolean
function Set:is_supset_of(set) 
    return Set.is_subset_of(set,self) 
end

--- is this a superset of another set
---@param set herbert.Set the potential superset
---@return boolean
function Set:is_proper_supset_of(set) 
    return Set.is_proper_subset_of(set, self) 
end

--- checks if this set is empty
---@return boolean is_empty
function Set:is_empty() 
    return next(self.vals) == nil 
end

-- =============================================================================
-- extend base via `Class.lua`
-- =============================================================================
-- this will add all the various OOP functionalities to `Set`


Class.new({name="Set", 

    ---@param p herbert.Set|table|any
    ---@param dont_copy boolean?
    ---@return herbert.Set
    new_obj_func = function(p, dont_copy)
        if Class.is_instance_of(p, Set) then
            if dont_copy == true then
                return p
            else
                return {vals = table.copy(p.vals), n = p.n}
            end
        end
        -- make a new set
        local vals, n = {}, 0

        for _, v in ipairs(p) do
            if not vals[v] then
                vals[v] = true
                n = n + 1
            end
        end

        return {vals = vals, n = n}
    end,
        
    obj_metatable = {
        __tostring = function(self) 
            local strings = {}

            for v in self() do 
                table.insert(strings, tostring(v)) 
            end

            table.sort(strings, function (a, b)
                local m, n = #a, #b
                if m == n then return a < b end
                return m < n
            end)
            return string.format("{%s}",table.concat(strings, ", "))
        end,

        __len = function(self) return self.n end,
        __call = Set.iter,
        __pairs = Set.iter,

        __add = Set.union,
        __mul = Set.intersection,
        __sub = Set.minus,

        --- returns whether `self < set`
        ---@param self herbert.Set|any
        ---@param set herbert.Set
        __lt = function(self, set)
            if Class.is_instance_of(self, Set) then
                return self:is_proper_subset_of(set)
            else
                return set:contains(self)
            end
        end,

        --- returns whether `self < set`
        ---@param self herbert.Set|any
        ---@param set herbert.Set
        __le = function(self, set)
            if Class.is_instance_of(self, Set) then
                -- test if it's a proper subset
                return self:is_subset_of(set)
            else
                return set:contains(self)
            end
        end,

        __eq = Set.equals,
    }
}, Set) -- let `Class.new` talk to the base



return Set