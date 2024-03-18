---@class herbert.table_ext
local tbl_ext = {}


-- =============================================================================
-- ARRAY STUFF
-- =============================================================================

-- this is just `table.values`, but with type hints
---@generic K, V
---@param tbl {[K] : V}
---@param sorter nil|boolean|(fun(a: V, b: V): (boolean|any))
---@return V[]
function tbl_ext.to_array(tbl, sorter)
	local arr = {}
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
	local arr = {}
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
function tbl_ext.combine(...) return tbl_ext.append({}, ...) end

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
---@generic K, V, R
--- @param tbl {[K] : V}
--- @param map (fun(v:V, ...): R) map to apply to values
--- @param ... any
---@return {[K] : R}
function tbl_ext.map(tbl, map, ...)
	local res = {}
	for k, v in pairs(tbl) do
		res[k] = map(v, ...)
	end
	return res
end

-- map (key, value) pairs in one table to another table
-- NOTE: function acts on BOTH keys and values
---@generic K, V, R
--- @param tbl {[K] : V}
--- @param map (fun(k: K, v:V, ...): R) map to apply to values
--- @param ... any
---@return {[K] : R}
function tbl_ext.map2(tbl, map, ...)
	local res = {}
	for k, v in pairs(tbl) do
		res[k] = map(k, v, ...)
	end
	return res
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
	return res
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
	return res
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
	return res
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
	return res
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


	return result
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
			v_max = v
        end
    end
    return v_max
end

-- -@param tbl table<K, T>|table<K, number>

--- sum all the values in a table. `tbl` does not need to be an array, and the values do not need to be numbers.
---@generic K, V, R
---@param tbl {[K] : V}
---@param get_val nil|fun(v:V, ...:any): R
---@return V|R
function tbl_ext.sum(tbl, get_val, ...)
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

--- sum all the values in a table. `tbl` does not need to be an array, and the values do not need to be numbers.
---@generic K, V, R
---@param tbl {[K] : V}
---@param get_val nil|fun(k:K, v:V, ...:any): R
---@param ... any additional values to pass to `get_val`
---@return V|R
function tbl_ext.sum2(tbl, get_val, ...)
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

--- take the product of all values in a table. `tbl` does not need to be an array, and the values do not need to be numbers.
---@generic K, T
---@param tbl {[K] : T}
---@return T
function tbl_ext.prod(tbl)
	local first_key, total = next(tbl)
	for _, v in next, tbl, first_key do
		total = total * v
	end
	return total
end

--- take the average of all values in an array. the entries in this array do not need to be numbers
---@generic T
---@param arr T[]
---@return T
function tbl_ext.avg(arr)
	return tbl_ext.sum(arr) / #arr
end

--- take the variance of all values in an array
---@generic T
---@param arr T[]
---@return T
function tbl_ext.variance(arr)

	local avg_val = tbl_ext.avg(arr)

	return tbl_ext.avg(tbl_ext.map(arr, function(v)
        return (v - avg_val)^2
	end))
end
--- allows you to combine values in a table using some function
---@generic K, V
---@param tbl {[K] : V}
---@param f fun(v: V, v: V, ...: any): V
---@param initial_arg V? first value to use when reducing things. if `nil`, then a random element of the table will be selected (via `next`)
---@param ... any additional arguments to pass to `f`
---@return V
function tbl_ext.reduce(tbl, f, initial_arg, ...)
	local first_key
	if initial_arg == nil then
		first_key, initial_arg = next(tbl)
	end
	for _, v in next, tbl, first_key do
		initial_arg = f(initial_arg, v, ...)
	end
	return initial_arg
end

--- allows you to combine values in a table using some function
---@generic K, V, R
---@param tbl {[K] : V}
---@param f fun(v: R, v: V, ...: any): R
---@param initial_arg R first value to use when reducing things. if `nil`, then a random element of the table will be selected (via `next`)
---@param ... any additional arguments to pass to `f`
---@return V
function tbl_ext.map_reduce(tbl, f, initial_arg, ...)
	for _,v in pairs(tbl) do
		initial_arg = f(initial_arg, v, ...)
	end
	return initial_arg
end

return tbl_ext