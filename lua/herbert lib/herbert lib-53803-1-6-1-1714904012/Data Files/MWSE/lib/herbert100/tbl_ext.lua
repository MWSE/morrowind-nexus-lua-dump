

-- -@class herbert.Extended_Table<K,V> : herbert.table_ext, {[K]: V}

---@class herbert.table_ext : table
---@overload fun(tbl): herbert.Extended_Table
local tbl_ext = {}


---@class herbert.Extended_Table : herbert.table_ext, table
---@operator add(herbert.Extended_Table|number): herbert.Extended_Table
---@operator sub(herbert.Extended_Table|number): herbert.Extended_Table
---@operator mul(herbert.Extended_Table|number): herbert.Extended_Table
---@operator div(herbert.Extended_Table|number): herbert.Extended_Table
---@operator pow(herbert.Extended_Table|number): herbert.Extended_Table

local tbl_ext_meta = {}

function tbl_ext_meta.__add(t1, t2)
	if getmetatable(t1) == tbl_ext_meta then
		if tbl_ext_meta == getmetatable(t2) then
			return tbl_ext.map2(t1, function(k, v, other) return other[k] and (v + other[k]) or v end, t2)
		end
		return tbl_ext.map(t1, function(v, other) return v + other end, t2)
	end
	return tbl_ext.map(t2, function(v, other) return other + v end, t1)
end

function tbl_ext_meta.__sub(t1, t2)
	if getmetatable(t1) == tbl_ext_meta then
		if tbl_ext_meta == getmetatable(t2) then
			return tbl_ext.map2(t1, function(k, v, other) return other[k] and (v - other[k]) or v end, t2)
		end

		return tbl_ext.map(t1, function (v, other) return v - other end, t2)

	end
	return tbl_ext.map(t2, function (v, other) return other - v end, t1)
end


function tbl_ext_meta.__mul(t1, t2)
	if getmetatable(t1) == tbl_ext_meta then
		if tbl_ext_meta == getmetatable(t2) then
			return tbl_ext.map2(t1, function(k, v, other) return other[k] and (v * other[k]) or v end, t2)
		end

		return tbl_ext.map(t1, function (v, other) return v * other end, t2)
	end
	return tbl_ext.map(t2, function (v, other) return other * v end, t1)
end

function tbl_ext_meta.__div(t1, t2)
	if getmetatable(t1) == tbl_ext_meta then
		if tbl_ext_meta == getmetatable(t2) then
			return tbl_ext.map2(t1, function(k, v, other) return other[k] and (v / other[k]) or v end, t2)
		end

		return tbl_ext.map(t1, function (v, other) return v / other end, t2)
	end
	return tbl_ext.map(t2, function (v, other) return other / v end, t1)
end


function tbl_ext_meta.__pow(t1, t2)
	if getmetatable(t1) == tbl_ext_meta then
		if tbl_ext_meta == getmetatable(t2) then
			return tbl_ext.map2(t1, function(k, v, other) return other[k] and (v ^ other[k]) or v end, t2)
		end

		return tbl_ext.map(t1, function (v, other) return v ^ other end, t2)
	end
	return tbl_ext.map(t2, function (v, other) return other ^ v end, t1)
end

tbl_ext_meta.__index = tbl_ext


tbl_ext.metatable = tbl_ext_meta

---@generic K, V
---@param tbl nil|table<K,V>
---@return herbert.Extended_Table|table<K,V>
function tbl_ext.new(tbl) return setmetatable(tbl or {}, tbl_ext.metatable) end

-- setmetatable(tbl_ext, {__call=tbl_ext.new, __index=table})
setmetatable(tbl_ext, {__call=function(_, ...)
	return tbl_ext.new(...)
end})


-- takes in a table and returns a table with the same keys, but with every entry set to a specified constant. defaults to `0`
-- preserves metatables, and gives the object the `Extended_Table` metatable if it has no metatable
---@generic K, C
---@param tbl nil|{[K]: any}
---@param const number|nil|C
---@return herbert.Extended_Table<K,C>
function tbl_ext.to_constant(tbl, const)
	return tbl_ext.map(tbl, function(_, v) return v end, const or 0)
end

-- takes in a table and returns a table with the same keys, but with every entry set to 0
-- preserves metatables, and gives the object the `Extended_Table` metatable if it has no metatable
---@generic K, T
---@param tbl nil|T|{[K]: any}
---@return T|herbert.Extended_Table<K,`0`>
function tbl_ext.zeros(tbl)
	return tbl_ext.to_constant(tbl)
end



--- takes in a table of pairs (k,v) and returns a table with pairs (k,k)
-- preserves metatables, and gives the object the `Extended_Table` metatable if it has no metatable
---@generic K, T
---@param tbl nil|T|{[K]: any}
---@return T|herbert.Extended_Table<K, K>
function tbl_ext.diagonal(tbl)
	return tbl_ext.map2(tbl, function(k) return k end)
end


--- takes in a table of pairs (k,v) and returns a table with pairs (k,k)
-- preserves metatables, and gives the object the `Extended_Table` metatable if it has no metatable
---@generic V, T
---@param tbl nil|T|{[any]: V}
---@return T|herbert.Extended_Table<V, V>
function tbl_ext.inv_diagonal(tbl)
	return tbl_ext.inv_map(tbl, function(v) return v end)
end

-- =============================================================================
-- ARRAY STUFF
-- =============================================================================
---@generic K,V 
--- insert a value in a table, using in `table.insert`
---@param arr herbert.Extended_Table<integer,V>|V[]
---@param index_or_val integer|V
---@param val_or_nil V|nil
function tbl_ext.insert(arr, index_or_val, val_or_nil)
	table.insert(arr, index_or_val, val_or_nil)
end


tbl_ext.insert = table.insert

-- this is just `table.values`, but with type hints
---@generic K, V, T
---@param tbl T|{[K] : V}
---@param sorter nil|boolean|(fun(a: V, b: V): (boolean|any))
---@return T|V[]
function tbl_ext.values(tbl, sorter)
	local arr = setmetatable({}, getmetatable(tbl) or tbl_ext.metatable)

	local i = 0
	for _, v in pairs(tbl) do
		i = i + 1
		arr[i] = v
	end
	if sorter then
		if sorter == true then
			table.sort(arr)
		else
			table.sort(arr, sorter)
		end
	end
	return arr
end


-- this is just `table.values`, but with type hints
---@generic K, V
---@param tbl {[K] : V}
---@param sorter nil|boolean|(fun(a: V, b: V): (boolean|any))
---@return V[]
function tbl_ext.to_array(tbl, sorter)
	local arr = setmetatable({}, getmetatable(tbl) or tbl_ext.metatable)

	local i = 0
	for _, v in pairs(tbl) do
		i = i + 1
		arr[i] = v
	end
	if sorter then
		if sorter == true then
			table.sort(arr)
		else
			table.sort(arr, sorter)
		end
	end
	return arr
end

tbl_ext.values = tbl_ext.to_array

-- this is just `table.keys`, but with type hints
---@generic K, V
---@param tbl {[K] : V}
---@param sorter nil|boolean|(fun(a: K, b: K): boolean|any)
---@return K[]
function tbl_ext.keys(tbl, sorter)
	local arr = setmetatable({}, getmetatable(tbl) or tbl_ext.metatable)
	local i = 0
	for k in pairs(tbl) do
		i = i + 1
		arr[i] = k
	end
	if sorter then
		if sorter == true then
			table.sort(arr)
		else
			table.sort(arr, sorter)
		end
	end
	return arr
end

-- wrapper for `sort` that also returns the table in question
---@generic K, V
---@param arr {[K] : V}
---@param sorter nil|(fun(a: V, b: V): boolean|any)
---@return K[]
function tbl_ext.sorted(arr, sorter)
	table.sort(arr, sorter)
	return arr
end

tbl_ext.sort = tbl_ext.sorted

-- sort an array by a given `map`, then returns the array
---@generic V, R, T
---@param arr T|V[]
---@param map fun(v: V): R
---@param cache boolean? should the values of `map` be cached? you probably don't want to use this as it will rarely give a performance improvement.
-- and will likely make performance worse
---@return T|V[]
function tbl_ext.sort_by_map(arr, map, cache)
	if cache then
		local tbl = tbl_ext.inv_map(arr, map)
		table.sort(arr, function(a, b) return tbl[a] < tbl[b] end)
		return arr
	end
	table.sort(arr, function(a, b) return map(a) < map(b) end)
	return arr
end

tbl_ext.sorted_by_map = tbl_ext.sort_by_map


-- =============================================================================
-- COMBINE THINGS
-- =============================================================================


-- append other tables to this table, and potentially overwrite stuff in `tbl`
---@param tbl table
---@param ... table
---@return table
function tbl_ext.append(tbl, ...)
	for _, t in ipairs{...} do
		for k,v in pairs(t) do
			tbl[k] = v
		end
	end
    return tbl
end

--- combines several tables. makes a new table (so no tables are altered)
---@param ... table
---@return table result of combining all tables
function tbl_ext.combine(...) return tbl_ext.append(setmetatable({},tbl_ext.metatable), ...) end

-- append other tables to this table, not copying over anything
---@param tbl table
---@param ... table
---@return table
function tbl_ext.append_missing(tbl, ...)
	for _, t in ipairs{...} do
		for k,v in pairs(t) do
			if tbl[k] == nil then
				tbl[k] = v
			end
		end
	end
    return tbl
end

-- invert a table
---@generic K, V
---@param tbl {[K]: V}
---@return {[V]: K}
function tbl_ext.invert(tbl) return table.invert(tbl) end

---@generic K, V
---@param tbl {[K]: V}
---@param key K
---@param default V
---@return V
function tbl_ext.getset(tbl, key, default)
	local v = tbl[key]
	if v == nil then
		tbl[key] = default
		return default
	end
	return v
end

-- =============================================================================
-- FUNCTIONAL PROGRAMMING STUFF
-- =============================================================================

--- apply a function to each value of a table. 
-- NOTE: function acts ONLY on values
---@generic K, V
--- @param tbl {[K] : V} to check
--- @param map (fun(v:V, ...): any) function to apply to each element of `tbl`
--- @param ... any additional arguments to pass to `map`
---@return nil
function tbl_ext.apply(tbl, map, ...)
	for k, v in pairs(tbl) do
		tbl[k] = map(v, ...)
	end
end

--- apply a function to each key, value pair of a table.
-- NOTE: function acts on BOTH keys and values
---@generic K, V
--- @param tbl {[K] : V} to check
--- @param map (fun(k: K, v:V, ...): any) function to apply to each element of `tbl`
--- @param ... any additional arguments to pass to `map`
---@return nil
function tbl_ext.apply2(tbl, map, ...)
	for k, v in pairs(tbl) do
		tbl[k] = map(k, v, ...)
	end
end

--- apply a function to every value of `tbl`, but don't modify `tbl` or make a new `table`
-- NOTE: function acts ONLY on values
---@generic K, V
--- @param tbl {[K] : V} to check
--- @param f (fun(v:V, ...): any) function to apply to each value in `tbl`
--- @param ... any additional arguments to pass to `f`
---@return nil
function tbl_ext.foreach(tbl, f, ...)
	for _, v in pairs(tbl) do
		f(v, ...)
	end
end

--- apply a function to every key, value pair of `tbl`, but don't modify `tbl` or make a new `table`
-- NOTE: function acts on BOTH keys and values
---@generic K, V
--- @param tbl {[K] : V} to check
--- @param f (fun(k: K, v:V, ...): any) function to apply to each key, value pair in `tbl`
--- @param ... any additional arguments to pass to `f`
---@return nil
function tbl_ext.foreach2(tbl, f, ...)
	for k, v in pairs(tbl) do
		f(k, v, ...)
	end
end

--- check if any value of a table satisfies a predicate. returns the first (key, value) pair to satisfy the predicate
-- NOTE: function acts ONLY on values
---@generic K, V
--- @param tbl {[K] : V} to check
--- @param pred (fun(v:V, ...): boolean|any) predicate to satisfy
--- @param ... any
---@return K?, V?
function tbl_ext.any(tbl, pred, ...)
	for k, v in pairs(tbl) do
		if pred(v, ...) then 
			return k, v
		end
	end
end

--- check if any (key, value) pair satisfies a predicate. returns the first (key, value) pair to satisfy the predicate
-- NOTE: function acts on BOTH keys and values
---@generic K, V
--- @param tbl {[K] : V} to check
--- @param pred (fun(k: K, v:V, ...): boolean|any) predicate to satisfy
--- @param ... any
---@return K?, V?
function tbl_ext.any2(tbl, pred, ...)
	for k, v in pairs(tbl) do
		if pred(k, v, ...) then 
			return k, v
		end
	end
end

-- checks if all (key, value) pairs of a table satisfy a specified predicate
-- NOTE: function acts ONLY on values
---@generic K, V
--- @param tbl {[K] : V} to check
--- @param pred (fun(v:V, ...): boolean|any) predicate to satisfy
--- @param ... any
---@return boolean
function tbl_ext.all(tbl, pred, ...)
	for _, v in pairs(tbl) do
		if not pred(v, ...) then 
			return false
		end
	end
	return true
end


-- checks if all values of a table satisfy a specified predicate
-- NOTE: function acts on BOTH keys and values
---@generic K, V
--- @param tbl {[K] : V} to check
--- @param pred (fun(k: K, v:V, ...): boolean|any) predicate to satisfy
--- @param ... any
---@return boolean
function tbl_ext.all2(tbl, pred, ...)
	for k, v in pairs(tbl) do
		if not pred(k, v, ...) then 
			return false
		end
	end
	return true
end

--- this will apply a function to all members of a table, and stop whenever the first value returns
-- something that isnt `nil` or `false`. 
-- NOTE: this function will return whatever the function returned, unlike `any`. this means it's slightly more expensive
-- NOTE: function acts ONLY on values
---@generic K, V, R
--- @param tbl {[K] : V} to check
--- @param f (fun(v:V, ...): ...: R) map to apply
--- @param ... any
---@return R ...
function tbl_ext.first(tbl, f, ...)
	local res
	for _, v in pairs(tbl) do
		res = {f(v, ...)}
		if res[1] then
			return table.unpack(res)
		end
	end
end

--- this will apply a function to all members of a table, and stop whenever the first value returns
-- something that isnt `nil` or `false`. 
-- NOTE: this function will return whatever the function returned, unlike `any`. this means it's slightly more expensive
-- NOTE: function acts on BOTH keys and values
---@generic K, V, R
--- @param tbl {[K] : V} to check
--- @param f (fun(k: K, v:V, ...): ...: R) map to apply
--- @param ... any
---@return R ...
function tbl_ext.first2(tbl, f, ...)
	local res
	for i, v in pairs(tbl) do
		res = {f(i, v, ...)}
		if res[1] then
			return table.unpack(res)
		end
	end
end

--- this will apply a function to all members of an array, and stop whenever the first value returns
-- something that isnt `nil` or `false`. 
-- NOTE: this function will return whatever the function returned, unlike `any`. this means it's slightly more expensive
-- NOTE: function acts ONLY on values
---@generic V, R
--- @param arr V[] to check
--- @param f (fun(v:V, ...): ...: R) predicate to satisfy
--- @param ... any
---@return R ...
function tbl_ext.first_array(arr, f, ...)
	local res
	for _, v in ipairs(arr) do
		res = {f(v, ...)}
		if res[1] then
			return table.unpack(res)
		end
	end
end

--- this will apply a function to all members of an array, and stop whenever the first value returns
-- something that isnt `nil` or `false`. 
-- NOTE: this function will return whatever the function returned, unlike `any`. this means it's slightly more expensive
-- NOTE: function acts on BOTH keys and values
---@generic V, R
--- @param arr V[] to check
--- @param f (fun(i: integer, v:V, ...): ...: R) map to apply
--- @param ... any
---@return R ...
function tbl_ext.first_array2(arr, f, ...)
	local res
	for i, v in ipairs(arr) do
		res = {f(i, v, ...)}
		if res[1] then
			return table.unpack(res)
		end
	end
end






-- map entries in one table to another table
-- NOTE: function acts ONLY on values
---@generic T, K, V, R
--- @param tbl T|{[K] : V}
--- @param map (fun(v:V, ...): R) map to apply to values
--- @param ... any
---@return T|{[K] : R}
function tbl_ext.map(tbl, map, ...)
	local res = {}
	for k, v in pairs(tbl) do
		res[k] = map(v, ...)
	end
	return setmetatable(res, getmetatable(tbl) or tbl_ext_meta)
end

-- map (key, value) pairs in one table to another table
-- NOTE: function acts on BOTH keys and values
---@generic T, K, V, R
--- @param tbl T|{[K] : V}
--- @param map (fun(k: K, v:V, ...): R) map to apply to values
--- @param ... any
---@return T|{[K] : R}
function tbl_ext.map2(tbl, map, ...)
	local res = {}
	for k, v in pairs(tbl) do
		res[k] = map(k, v, ...)
	end
	return setmetatable(res, getmetatable(tbl) or tbl_ext_meta)
end

-- this works like `tbl_ext.map`, except the resulting table will have `tbl[v] = f(v, ...)` instead of `tbl[k] = f(v, ...)`
-- NOTE: function acts ONLY on values
---@generic T, K, V, R
--- @param tbl T|{[K] : V}
--- @param map (fun(v:V, ...): R) map to apply to values
--- @param ... any
---@return T|{[V] : R}
function tbl_ext.inv_map(tbl, map, ...)
	local res = {}
	for _, v in pairs(tbl) do
		res[v] = map(v, ...)
	end
	return setmetatable(res, getmetatable(tbl) or tbl_ext_meta)
end

-- this works like `tbl_ext.map2`, except the resulting table will have `tbl[v] = f(k, v, ...)` instead of `tbl[k] = f(k, v, ...)`
-- NOTE: function acts on BOTH keys and values
---@generic T, K, V, R
--- @param tbl T|{[K] : V}
--- @param map (fun(k: K, v:V, ...): R) map to apply to values
--- @param ... any
---@return T|{[V] : R}
function tbl_ext.inv_map2(tbl, map, ...)
	local res = {}
	for k, v in pairs(tbl) do
		res[v] = map(k, v, ...)
	end
	return setmetatable(res, getmetatable(tbl) or tbl_ext_meta)
end


-- filter a table by a predicate
-- NOTE: function acts ONLY on values
---@generic K, V
--- @param tbl {[K] : V}
--- @param pred (fun(v:V, ...): boolean|any) predicate to satisfy
--- @param ... any
---@return {[K] : V}
function tbl_ext.filter(tbl, pred, ...)
	local res = {}
	for k, v in pairs(tbl) do
        if pred(v, ...) then   
            res[k] = v
        end
	end
	return setmetatable(res, getmetatable(tbl) or tbl_ext_meta)
end

-- filter a table by a predicate
-- NOTE: function acts on BOTH keys and values
---@generic K, V
--- @param tbl {[K] : V}
--- @param pred (fun(k: K, v:V, ...): boolean|any) predicate to satisfy
--- @param ... any
---@return {[K] : V}
function tbl_ext.filter2(tbl, pred, ...)
	local res = {}
	for k, v in pairs(tbl) do
        if pred(k, v, ...) then   
            res[k] = v
        end
	end
	return setmetatable(res, getmetatable(tbl) or tbl_ext_meta)
end

-- filter an array by a predicate
-- NOTE: function acts ONLY on values
---@generic T
--- @param arr T[]
--- @param pred (fun(v:T, ...): boolean|any) predicate to satisfy
--- @param ... any
---@return T[]
function tbl_ext.filter_array(arr, pred, ...)
	local res = {}
	for i, v in ipairs(arr) do
        if pred(v, ...) then
            table.insert(res, v)
        end
	end
	return setmetatable(res, getmetatable(arr) or tbl_ext_meta)
end

-- filter an array by a predicate
-- NOTE: function acts on BOTH keys and values
---@generic T
--- @param arr T[]
--- @param pred (fun(i: integer, v:T, ...): boolean|any) predicate to satisfy
--- @param ... any
---@return T[]
function tbl_ext.filter_array2(arr, pred, ...)
	local res = {}
	for i, v in ipairs(arr) do
        if pred(i, v, ...) then
            table.insert(res, v)
        end
	end
	return setmetatable(res, getmetatable(arr) or tbl_ext_meta)
end


-- functional programming stuff



--- generate a subarray, consisting of only the selected indices
---@generic T
---@param arr T[] to splice
---@param start_index integer? index to start at. defaults to 1. can be negative. negative indices will be wrapped. so `0 == #arr`, `-1 == #arr - 1`, etc.
---@param end_index integer? index to end at. defaults to `#tbl`. can be negative. negative indices will be wrapped. so `0 == #arr`, `-1 == #arr - 1`, etc.
---@param step integer? normal meaning. defaults to 1. can be negative.
---@return T[]
function tbl_ext.splice(arr, start_index, end_index, step)
	local result = {}
	local n = #arr
	-- default value hell
    if start_index then
        start_index = 1 + (start_index - 1) % n -- wrap indices

        if end_index then -- yes start, yes end
            end_index = 1 + (end_index - 1) % n -- wrap indices

            -- make sure step is +-1, depending on if `start < end`
            if not step then 
                if start_index <= end_index then
                    step = 1
                else
                    step = -1
                end
            end

        else -- yes start index, no end_index

            -- make sure the `end_index = 1` if `step < 0`
            if step then
                if step > 0 then
                    end_index = n
                else
                    end_index = 1
                end
            else
                end_index = n
                step = step or 1
            end
        end
    else -- no start index
        if end_index then -- no start, yes end
            end_index = 1 + (end_index - 1) % n -- wrap indices
            if not step then
                if start_index < end_index then
                    step = 1
                else
                    step = -1
                end
            end
        else -- no start index, no end index
            start_index = 1
            end_index = n
            step = step or 1
        end
    end

    
    -- =========================================================================
    -- ACTUAL CODE
    -- =========================================================================

    local offset -- stupid lua offset because they insist on starting indices at 1
    if step > 0 then
        -- lowest index will be with `i == start_index`, and this should get sent to `1`
        offset = - start_index + 1
    else
        -- need to find the smallest integer `k >= end` where `k == start + step * i`
        -- i.e., 
        --      `start + step * i >= end`
        -- then 
        -- `step * i >= end - start`
        -- `i <= (end - start) / step`      (since `step` < 0)
        -- then `i == floor( (end - start) / step )
        -- i.e., want the largest integer `i <= floor( (end - start) / step)
        local i = math.floor( (end_index - start_index) / step )

        local k = start_index + step * i -- this will be the smallest value reached by the loop
        offset = - k + 1
    end
    for k=start_index, end_index, step do
        -- lowest index will be with `k == i`, and this should get sent to `1`
        result[k + offset] = arr[k]
    end


	return setmetatable(result, getmetatable(arr) or tbl_ext_meta)
end


-- =============================================================================
-- MATH
-- =============================================================================

-- get the minimum element in a table
---@generic K, V
---@param tbl {[K] : V} to check
---@param get_comp_val (nil|fun(v: V, ...): any) recipe for getting the value used in comparisons
-- if a function, then the elements of `t` will be mapped by that function, and the return values will be compared
---@param ... any arguments to pass to `get_comp_val`
---@return V? v_max
function tbl_ext.min(tbl, get_comp_val, ...)
	-- set `kmin` and `vmin` to be the first entries of `t`
	local first_key, v_min = next(tbl)
	-- return now if `t` is empty
	if not first_key then return end


	get_comp_val = get_comp_val or function(v) return v end
    
    local v_cv
    local v_min_cv = get_comp_val(v_min, ...)


	-- iterate throguh `t`, starting at `kmin`
	for _, v in next, tbl, first_key do
        v_cv = get_comp_val(v, ...)
        if v_cv < v_min_cv then
			v_min_cv = v_cv
			v_min = v
        end
	end
	return v_min
end

-- get the maximum element in a table
---@generic K, V
--- @param tbl {[K] : V} to check
---@param get_comp_val (nil|fun(v: V, ...): any) recipe for getting the value used in comparisons
-- if a function, then the elements of `t` will be mapped by that function, and the return values will be compared
---@param ... any arguments to pass to `get_comp_val`
---@return V? v_max
function tbl_ext.max(tbl, get_comp_val, ...)
    -- set `kmin` and `vmin` to be the first entries of `t`
    local first_key, v_max = next(tbl)
    -- return now if `t` is empty
    if not first_key then return end

	get_comp_val = get_comp_val or function(v) return v end
    
    local v_cv
    local v_max_cv = get_comp_val(v_max, ...)


    -- iterate throguh `t`, starting at `kmin`
    for _, v in next, tbl, first_key do
        v_cv = get_comp_val(v, ...)
        if v_cv > v_max_cv then
			v_max_cv = v_cv
			v_max = v
        end
    end
    return v_max
end





-- get the maximum element in a table
---@generic T, K, V
---@param tbl T|{[K] : V} to check
---@param low V new low value
---@param high V new high value
---@param get_comp_val (nil|fun(v: V, ...): any) recipe for getting the value used in comparisons
-- if a function, then the elements of `t` will be mapped by that function, and the return values will be compared
---@param ... any arguments to pass to `get_comp_val`
---@return T|{[K] : V}
function tbl_ext.remap(tbl, low, high, get_comp_val, ...)
	local min = tbl_ext.min(tbl, get_comp_val, ...)
	local max = tbl_ext.max(tbl, get_comp_val, ...)
	return tbl_ext.map(tbl, function(v)
		return math.remap(v, min, max, low, high)
	end)
end


tbl_ext.norms = {}


-- multiply everything in a table by a value
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param c R
---@return T|{[K] : V}
function tbl_ext.mul(tbl, c)
	return tbl_ext.map(tbl, function(v) return c * v end)
end

-- divide everything in a table by a value
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param c R
---@return T|{[K] : V}
function tbl_ext.div(tbl, c)
	return tbl_ext.map(tbl, function(v) return v/c end)
end

-- add a value to everything in a table
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param c R
---@return T|{[K] : V}
function tbl_ext.add(tbl, c)
	return tbl_ext.map(tbl, function(v) return v + c end)
end

-- subtract a value from each element in a table
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param c R
---@return T|{[K] : V}
function tbl_ext.sub(tbl, c)
	return tbl_ext.map(tbl, function(v) return v - c end)
end

-- exponentiate everything in a table
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param c R
---@return T|{[K] : V}
function tbl_ext.pow(tbl, c)
	return tbl_ext.map(tbl, function(v) return v^c end)
end

do -- sum and prod. these are way more complicated because userdata needs to be handled differently
	-- and im naively over-optimizing

--- sum all the values in a table. `tbl` does not need to be an array, and the values do not need to be numbers.
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param get_val nil|fun(v:V, ...:any): R
---@return T|V|R
function tbl_ext.sum(tbl, get_val, ...)
	if type(tbl) ~= "userdata" then
		local first_key, total = next(tbl)
		if get_val then
			total = get_val(total, ...)
			for _, v in next, tbl, first_key do
				total = total + get_val(v, ...)
			end
		else
			for _, v in next, tbl, first_key do
				total = total + v
			end
		end
		return total
	end
	
	local total
	if get_val then
		---@diagnostic disable-next-line: param-type-mismatch
		for _, v in pairs(tbl) do ---@diagnostic disable-next-line: param-type-mismatch
			if total == nil then
				total = get_val(v, ...)
			else
				total = total + get_val(v, ...)
			end
		end
	else
		---@diagnostic disable-next-line: param-type-mismatch
		for _, v in pairs(tbl) do ---@diagnostic disable-next-line: param-type-mismatch
			if total == nil then
				total = v
			else
				total = total + v
			end
		end
	end
	return total
end

--- sum all the values in a table. `tbl` does not need to be an array, and the values do not need to be numbers.
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param get_val nil|fun(k:K, v:V, ...:any): R
---@return T|V|R
function tbl_ext.sum2(tbl, get_val, ...)
	if type(tbl) ~= "userdata" then
		local first_key, total = next(tbl)
		if get_val then
			total = get_val(first_key, total, ...)
			for k, v in next, tbl, first_key do
				total = total + get_val(k, v, ...)
			end
		else
			for _, v in next, tbl, first_key do
				total = total + v
			end
		end
		return total
	end

	local total
	if get_val then
		---@diagnostic disable-next-line: param-type-mismatch
		for k, v in pairs(tbl) do ---@diagnostic disable-next-line: param-type-mismatch
			if total == nil then
				total = get_val(k, v, ...)
			else
				total = total + get_val(k, v, ...)
			end
		end
	else
		---@diagnostic disable-next-line: param-type-mismatch
		for _, v in pairs(tbl) do ---@diagnostic disable-next-line: param-type-mismatch
			if total == nil then
				total = v
			else
				total = total + v
			end
		end
	end
	return total
end

--- multiply all the values in a table. `tbl` does not need to be an array, and the values do not need to be numbers.
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param get_val nil|fun(v:V, ...:any): R
---@return T|V|R
function tbl_ext.prod(tbl, get_val, ...)
	if type(tbl) ~= "userdata" then
		local first_key, total = next(tbl)
		if get_val then
			total = get_val(total, ...)
			for _, v in next, tbl, first_key do
				total = total * get_val(v, ...)
			end
		else
			for _, v in next, tbl, first_key do
				total = total * v
			end
		end
		return total
	end
	
	local total
	if get_val then
		---@diagnostic disable-next-line: param-type-mismatch
		for _, v in pairs(tbl) do ---@diagnostic disable-next-line: param-type-mismatch
			if total == nil then
				total = get_val(v, ...)
			else
				total = total * get_val(v, ...)
			end
		end
	else
		---@diagnostic disable-next-line: param-type-mismatch
		for _, v in pairs(tbl) do ---@diagnostic disable-next-line: param-type-mismatch
			if total == nil then
				total = v
			else
				total = total * v
			end
		end
	end
	return total
end

--- multiply all the values in a table. `tbl` does not need to be an array, and the values do not need to be numbers.
---@generic T, K, V, R
---@param tbl T|{[K] : V}
---@param get_val nil|fun(k:K, v:V, ...:any): R
---@return T|V|R
function tbl_ext.prod2(tbl, get_val, ...)
	if type(tbl) ~= "userdata" then
		local first_key, total = next(tbl)
		if get_val then
			total = get_val(first_key, total, ...)
			for k, v in next, tbl, first_key do
				total = total * get_val(k, v, ...)
			end
		else
			for _, v in next, tbl, first_key do
				total = total * v
			end
		end
		return total
	end

	local total
	if get_val then
		---@diagnostic disable-next-line: param-type-mismatch
		for k, v in pairs(tbl) do ---@diagnostic disable-next-line: param-type-mismatch
			if total == nil then
				total = get_val(k, v, ...)
			else
				total = total * get_val(k, v, ...)
			end
		end
	else
		---@diagnostic disable-next-line: param-type-mismatch
		for _, v in pairs(tbl) do ---@diagnostic disable-next-line: param-type-mismatch
			if total == nil then
				total = v
			else
				total = total * v
			end
		end
	end
	return total
end

end

--- take the average of all values in an array. the entries in this array do not need to be numbers
---@generic T, K, V
---@param arr T|{[K]:V}
---@param size integer? the size of the table. if not provided, `table.size` will be called. you have been warned
---@return T|V
function tbl_ext.avg(arr, size)
	-- mwse.log("calculating average of %s", json.encode(arr))
	return tbl_ext.sum(arr) / (size or table.size(arr))
end

local function variance_map(val, avg_val) 
	return (val - avg_val)^2 
end

--- take the variance of all values in an array
---@generic T, K, V
---@param size integer? the size of the table. if not provided, `table.size` will be called. you have been warned
---@param arr T|{[K]:V}
---@return T|V
function tbl_ext.variance(arr, size)
	-- mwse.log("calculating variance of %s", json.encode(arr))

	size = size or table.size(arr)
	return tbl_ext.avg(
		tbl_ext.map(
			arr, 					-- tbl
			variance_map,			-- map
			tbl_ext.avg(arr, size)	-- extra arg
		), 
		size
	)
end

tbl_ext.var = tbl_ext.variance


--- take the standard deviation of all values in an array
---@generic T
---@param size integer? the size of the table. if not provided, `table.size` will be called. you have been warned
---@param arr T|table<any, number>
---@return T|number
function tbl_ext.std_dev(arr, size) return math.sqrt(tbl_ext.var(arr, size)) end

--- allows you to combine values in a table using some function
---@generic T, K, V
---@param tbl T|{[K] : V}
---@param f fun(acc_val: V, v: V, ...: any): V
---@param initial_arg V first value to use when reducing things. if `nil`, then a random element of the table will be selected (via `next`)
---@param ... any additional arguments to pass to `f`
---@return T|V
function tbl_ext.reduce(tbl, f, initial_arg, ...)
	for _, v in pairs(tbl) do
		initial_arg = f(initial_arg, v, ...)
	end
	return initial_arg
end

--- allows you to combine values in a table using some function
---@generic T, K, V
---@param tbl T|{[K] : V}
---@param f fun(acc_val: V, k: K, v: V, ...: any): V
---@param initial_arg V first value to use when reducing things. if `nil`, then a random element of the table will be selected (via `next`)
---@param ... any additional arguments to pass to `f`
---@return T|V
function tbl_ext.reduce2(tbl, f, initial_arg, ...)
	for k , v in pairs(tbl) do
		initial_arg = f(initial_arg, k, v, ...)
	end
	return initial_arg
end


--- recursively get the keys in a table
---@generic K, V
---@param tbl {[K]: V}
---@param key string|K
---@return V|nil
function tbl_ext.recursive_get(tbl, key)
	if type(key) ~= "string" then return tbl[key] end
	-- mwse.log("doing recursive get on key = %q", key)
    for k in key:gmatch("[^%.]+") do
		-- mwse.log("doing tbl = tbl[%q]", k)
        tbl = tbl[k]
        if not tbl then return end
    end

    return tbl
end

--- recursively get the keys in a table
---@generic K, V, D
---@param tbl {[K]: V}
---@param key string|K
---@param default_value D? should missing entries be created? default: true
---@return V|D|nil
function tbl_ext.recursive_getset(tbl, key, default_value)
	if type(key) ~= "string" then return table.getset(tbl, key, default_value) end

	local keys = key:split("%.")
	-- mwse.log("key = %s, keys = %s", key, json.encode(keys))
	for i=1, #keys-1 do
		-- mwse.log("tbl = table.getset(tbl, %q, {})", keys[i])
		tbl = table.getset(tbl, keys[i], {})
	end
	-- mwse.log("table.getset(tbl, %q, %s)", keys[#keys], default_value)
	return table.getset(tbl, keys[#keys], default_value)
end


return tbl_ext