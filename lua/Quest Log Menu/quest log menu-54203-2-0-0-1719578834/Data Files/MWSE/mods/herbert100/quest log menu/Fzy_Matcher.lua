-- =============================================================================
-- `fzy_lua` - a lua implementation of fuzzy search
--	NOTE: I have made significant structural changes to this file, but the main
--  searching logic (i.e., the hard part of the code) is mostly unchanged from
--	https://github.com/swarn/fzy-lua/tree/main 
--	I claim no ownership over anything in this file.
--  I just restructured the code to better fit my use-case.
-- =============================================================================

-- The lua implementation of the fzy string matching algorithm

local SCORE_GAP_LEADING = -0.005
local SCORE_GAP_TRAILING = -0.005
local SCORE_GAP_INNER = -0.01
local SCORE_MATCH_CONSECUTIVE = 1.0
local SCORE_MATCH_SLASH = 0.9
local SCORE_MATCH_WORD = 0.8
local SCORE_MATCH_CAPITAL = 0.7
local SCORE_MATCH_DOT = 0.6
local SCORE_MAX = 5000 -- allow multipliers to be applied later
local SCORE_MIN = -math.huge
local MATCH_MAX_LENGTH = 1024

local log = Herbert_Logger()
log("fuzzy matcher reloaded")

---@type table<string, herbert.QLM.Fzy_Matcher>
local cache = {}
setmetatable(cache, {__mode='v'})
---@type table<string, herbert.QLM.Fzy_Matcher>
local cs_cache = {}
setmetatable(cs_cache, {__mode='v'})



local function is_lower(c) return string.match(c, "%l") end

local function is_upper(c) return string.match(c, "%u") end



---@class herbert.QLM.Fzy_Matcher
---@field needle string
---@field needle_chars string[]
---@field case_sensitive boolean
---@field needle_len integer
local Fzy_Matcher = {}

Fzy_Matcher.MAX_SCORE = SCORE_MAX
Fzy_Matcher.MIN_SCORE = SCORE_MIN

local Fzy_Matcher_meta = {__index = Fzy_Matcher}
Fzy_Matcher_meta.__tostring = function (self)
	return json.encode({needle = self.needle, case_sensitive = self.case_sensitive}) 
end

---@param needle string
---@param case_sensitive boolean?
---@return herbert.QLM.Fzy_Matcher
function Fzy_Matcher.new(needle, case_sensitive)

	local obj, cache_to_check

	if case_sensitive then
		cache_to_check = cs_cache
	else
		needle = needle:lower()
		cache_to_check = cache
	end

	obj = cache_to_check[needle]

	if obj then return obj end

    local needle_chars = {}
    for i = 1, needle:len() do
        needle_chars[i] = needle:sub(i, i)
    end

    obj = {
        needle = needle, 
        needle_chars = needle_chars, 
        needle_len = needle:len(), 
        case_sensitive = (case_sensitive == true),
    }
	setmetatable(obj, Fzy_Matcher_meta)

	cache_to_check[needle] = obj
	return obj
end

--- Check if `needle` is a subsequence of the `haystack`
-- Usually called before `score` or `positions`
---@param haystack string to search through
---@return boolean
function Fzy_Matcher:is_subsequence_of(haystack)
	if not self.case_sensitive then
		haystack = haystack:lower()
	end

	local pos = 0
    for _, char in ipairs(self.needle_chars) do
        pos = haystack:find(char, pos + 1, true)
        if not pos then 
			return false 
		end
    end
	return true
end

local MATCH_BONUS_CHARS = {
	["/"] = SCORE_MATCH_SLASH, ["\\"] = SCORE_MATCH_SLASH,
	["-"] = SCORE_MATCH_WORD, ["_"] = SCORE_MATCH_WORD, [" "] = SCORE_MATCH_WORD,
	["."] = SCORE_MATCH_DOT
}

--- Compute the locations where fzy matches a string.
--- Determine where each character of the `needle` is matched to the `haystack` in the optimal match.
---@param haystack string
---@return number score The same matching score returned by `fzy.score`.
---@return number[][]? D computation matrix. Only returned if not using the cachce.
---@return number[][]? M computation matrix. Only returned if not using the cachce.
function Fzy_Matcher:score(haystack)

	local needle_len = self.needle_len
	local haystack_len = haystack:len()
	
	-- try to exit early without doing any serious computing
    if needle_len   == 0
	or haystack_len == 0
	or haystack_len > MATCH_MAX_LENGTH
	or needle_len   > haystack_len
	then return SCORE_MIN end
    

	-- we need to do some stuff later that depends on the original haystack
	local raw_haystack = haystack

	if not self.case_sensitive then
		haystack = haystack:lower()
	end

	-- make sure `needle` is a subsequence of `haystack`
	-- if not, give it the minimum score
	local pos = 0
    for _, char in ipairs(self.needle_chars) do
        pos = haystack:find(char, pos + 1, true)
        if not pos then 
			return SCORE_MIN 
		end
    end

	

	-- is it a subsequence of the same length? then it's a perfect match
	if needle_len == haystack_len then 
		-- mark it as a perfect match 
		-- NOTE: this used to report `SCORE_MAX`, but that led to weird
		-- behavior when considering the `search.weights` subconfig.
		-- more specifically, random quests would shoot up to the top of the list
		-- just because you happened to perfectly match a quest topic
		-- but then adding a spacebar would make them fall back down again
		return needle_len 
	end
	-- if needle_len == haystack_len then 
	-- 	return SCORE_MAX 
	-- end

	-- calculate the "precompute bonus". this depends on the original haystack
	-- i.e., it's always case-sensitive
	local precompute_bonus = {}
	local last_char = "/"
	for i = 1, haystack_len do
		local char = raw_haystack:sub(i, i)
		precompute_bonus[i] = MATCH_BONUS_CHARS[last_char]
						or is_lower(last_char) and is_upper(char) and SCORE_MATCH_CAPITAL
						or 0

		last_char = char
	end
	
	local haystack_chars = {}
	for i = 1, haystack_len do
		haystack_chars[i] = haystack:sub(i, i)
	end

    ---@type number[][], number[][]
    local D, M = {}, {}

	local char_score
    for i, needle_char in ipairs(self.needle_chars) do
		D[i] = {}
		M[i] = {}

		local prev_score = SCORE_MIN
		local gap_score = (i == needle_len) and SCORE_GAP_TRAILING or SCORE_GAP_INNER

        for j, haystack_char in ipairs(haystack_chars) do
			if needle_char == haystack_char then
				if i == 1 then
					char_score = (j - 1) * SCORE_GAP_LEADING + precompute_bonus[j]
				elseif j > 1 then
					char_score = math.max(
						M[i - 1][j - 1] + precompute_bonus[j],
						D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE
					)
				else
					char_score = SCORE_MIN
				end

				D[i][j] = char_score
				prev_score = math.max(char_score, prev_score + gap_score)
				M[i][j] = prev_score
			else
				D[i][j] = SCORE_MIN
				prev_score = prev_score + gap_score
				M[i][j] = prev_score
			end
		end
	end
	return M[needle_len][haystack_len], D, M
end


--- Compute the locations where fzy matches a string.
--- Determine where each character of the `needle` is matched to the `haystack` in the optimal match.
---@param haystack string
---@return number score The same matching score returned by `fzy.score`.
---@return integer[] indices : `indices[n]` is the location of the `n`th character of `needle` in `haystack`.
function Fzy_Matcher:positions(haystack)


	local score, D, M = self:score(haystack)

	if score == SCORE_MIN or not D or not M then
		return score, {}
	end

	local needle_len = self.needle_len
	local haystack_len = string.len(haystack)


	if score == SCORE_MAX and needle_len == haystack_len then
		local consecutive = {}
		for i = 1, haystack_len do
			consecutive[i] = i
		end
		return score, consecutive
	end

	local positions = {} ---@type integer[]
	local match_required = false ---@type boolean
	local j = haystack_len
	for i = needle_len, 1, -1 do
		while j >= 1 do
			if D[i][j] ~= SCORE_MIN and (match_required or D[i][j] == M[i][j]) then
				match_required = (i ~= 1) and (j ~= 1) and (M[i][j] == D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE)
				positions[i] = j
				j = j - 1
				break
			else
				j = j - 1
			end
		end
	end

	return score, positions
end

---@class herbert.QLM.Fzy_Matcher.filter.result
---@field index integer index of string in `haystacks`
---@field positions integer[] list of indices of `haystack` that matched
---@field score integer score of the match

-- Apply `has_match` and `positions` to an array of haystacks.
---@param haystacks string[]|table<string, any>
---@return herbert.QLM.Fzy_Matcher.filter.result[] results An array with one entry per matching line
--	in `haystacks`, each entry giving the index of the line in `haystacks`
--	as well as the equivalent to the return value of `positions` for that
--	line.
function Fzy_Matcher:filter(haystacks)
	
	local results = {} ---@type herbert.QLM.Fzy_Matcher.filter.result[]

	for i, line in ipairs(haystacks) do
		local score, positions = self:positions(line)
		if score > SCORE_MIN then
			table.insert(results, {score=score, positions=positions, index=i})
		end
	end

	return results
end

-- Apply `has_match` and `score` to an array of haystacks.
---@param haystacks string[]|table<string, any>
---@return integer highest_score An array with one entry per matching line
--	in `haystacks`, each entry giving the index of the line in `haystacks`
--	as well as the equivalent to the return value of `positions` for that
--	line.
function Fzy_Matcher:get_highest_score(haystacks)

    local highest_score = SCORE_MIN
	local cur_score

	-- if we beat this number, it's very unlikely there's a better match in a later haystack
	-- so we should just return early
	-- this is mainly done to minimize I/O operations,
	-- because there's a chance that fetching the next haystack will involve an I/O operation
	-- local gold_star = self.needle_len - 0.3

	for _, line in ipairs(haystacks) do
		cur_score = self:score(line)
		if cur_score > highest_score then
			highest_score = cur_score
			-- TESTING
			-- if cur_score > gold_star then
			-- 	return cur_score
			-- end
		end
	end

	return highest_score
end


-- Check if any string in `haystacks` has a score higher than `threshold`
---@param haystacks string[]|table<string, any>
---@param threshold number the score to beat
---@return boolean success Did we beat the threshold?
function Fzy_Matcher:score_against_threshold(haystacks, threshold)
	for _, line in ipairs(haystacks) do
		if self:score(line) > threshold then return true end
	end

	return false
end

return Fzy_Matcher
