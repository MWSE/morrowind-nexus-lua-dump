local Class = require"herbert100.Class"

--- used internally to create new `Sets`. it copies the values stored in a `Set`
---@param set herbert.Set
---@return table vals the values of the set, copied into a new table
local function copy_values(set)
    local vals = {}
    for v,_ in pairs(set.vals) do
        vals[v] = true
    end
    return vals
end

---@class herbert.Set : herbert.Class
---@field vals table<any, boolean> the actual values stored by the set
local Set = {}; Set = Class({name="Set", 
    new_obj_func = function(tbl, ...)
        if tbl.__set then return tbl end


        local vals = {}
        for _,v in ipairs(tbl) do
            vals[v] = true
        end

        return {vals=vals, __set=true}
    end,
        
    obj_metatable = {
        __tostring = function(self) 
            local strings = { }

            for v in self() do
                table.insert(strings,tostring(v))
            end

            table.sort(strings,
                function (a, b)
                    local m,n = #a, #b
                    if m == n then return a < b end
                    return m < n
                end
            )

            return string.format("{%s}",table.concat(strings, ", "))
        
        end,

        __len = function(self) return #table.keys(self.vals) end,
        __call = function(self) return next, self.vals end,
        __add = function (self,other)
            -- make sure `self` is a `Set`
            if not self.__set then self, other = other, self end
            -- make sure `other` is a `table`
            if type(other) ~= "table"   then other = {other} end

            return self:union(other) -- return the union
        end,
        __pairs = function (self) return next, self.vals end,

        --- returns whether `self < set`
        ---@param self herbert.Set|any
        ---@param set herbert.Set
        __lt = function(self, set)
            if Class.is_instance_of(self,Set) then
                -- test if it's a proper subset
                return self:is_subset_of(set) and not set:minus(self):is_empty()
            else
                return set:contains(self)
            end
        end,

        __eq = function (self, set) return self:equals(set) end,

        __mul = function(self, other)
            -- make sure `self` is a `Set`
            if not self.__set then self, other = other, self end
            -- make sure `other` is a `table`
            if type(other) ~= "table"   then other = {other} end

            return self:intersection(other) -- return the intersection
        end,

        __sub = function (self, other)
            if not self.set then
                if type(self) == "table" then
                    -- `self` is not a set, but it is a table, and `other` is a `Set`
                    -- so, a set-minus makes sense
                    return other:minus(self)
                end
            else
                -- `self` is a set.
                if type(other) == "table" then
                    return self:minus(other)
                else
                    return self:minus({other})
                end
            end
        end,
        
    }
},Set)

-- setmetatable(Set, {__s})
---@param self herbert.Set
---@param ... table|any
---@return herbert.Set
function Set:union(...)
    local vals = copy_values(self)
    for _,tbl in ipairs{...} do
        if type(tbl) ~= "table" then
            vals[tbl] = true
        elseif tbl.__set == true then
            for v,_ in pairs(tbl.vals)  do vals[v] = true end
        else
            for _,v in ipairs(tbl)      do vals[v] = true end
        end
    end
    return Set{vals=vals,__set=true}
end

---@param ... herbert.Set|table
---@return herbert.Set
function Set:minus(...)
    local vals = copy_values(self); local obj = {vals=vals, __set=true}

    for _,tbl in ipairs{...} do
        if tbl.__set == true then
            for v in pairs(tbl.vals)  do vals[v] = nil end
        else
            for _,v in ipairs(tbl)      do vals[v] = nil end
        end
    end
    return Set(obj)
end

function Set:tolist(sort) return table.keys(self.vals,sort) end

---@param ... herbert.Set|table
---@return herbert.Set
function Set:intersection(...)
    local vals = copy_values(self); local obj = {vals=vals, __set=true}
    local other_vals_list = {}
    for i,tbl in ipairs{...} do
        if tbl.__set then 
            other_vals_list[i] = tbl.vals
        else
            -- if its not a set, make it one
            local other_vals = {}
            for _,v in ipairs(tbl) do other_vals[v] = true end
            other_vals_list[i] = other_vals
        end
    end

    for v in pairs(vals) do
        for _, other_vals in ipairs(other_vals_list) do
            if not other_vals[v] then
                vals[v] = nil
                break
            end
        end
    end
    return Set(obj)
end

--- checks if the specified value is in this `Set`
---@param self herbert.Set
---@param value any -- the value to test for 
---@return boolean -- whether the value is in the set
function Set:contains(value)
    ---@diagnostic disable-next-line: undefined-field
    return self.vals[value] == true -- adding the `== true` so it returns `false` instead of `nil` when the `value` isnt present
end

--- is this a subset of another set
---@param set herbert.Set the potential superset
---@return boolean
function Set:is_subset_of(set)
    -- for v in pairs(self.vals) do
    for v in self() do
        print("checking " .. tostring(v))
        if not set:contains(v) then return false end
    end
    return true
end

--- does this set equal another set?
---@param set herbert.Set
---@return boolean
function Set:equals(set)
    return self:is_subset_of(set) and self:is_supset_of(set)
end

--- returns whether the this `Set` intersects another `Set`
---@param set herbert.Set
function Set:intersects(set) return self:intersection(set):is_empty() end

--- is this a subset of another set
---@param set herbert.Set the potential subset
function Set:is_supset_of(set) return set:is_subset_of(self) end

function Set:is_empty() return next(self.vals) == nil end

--- iterate over the elements of the set
function Set:iter() return next, self.vals end





return Set