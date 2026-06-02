local this = {}

local function utf8_chars(str)
    local chars = {}
    for _, c in utf8.codes(str) do
        table.insert(chars, utf8.char(c))
    end
    return chars
end

local function utf8_levenshtein(s, t)
    local s_chars = utf8_chars(s)
    local t_chars = utf8_chars(t)
    local m, n = #s_chars, #t_chars
    local d = {}

    for i = 0, m do
        d[i] = {}
        d[i][0] = i
    end
    for j = 0, n do
        d[0][j] = j
    end

    for i = 1, m do
        for j = 1, n do
            local cost = (s_chars[i] == t_chars[j]) and 0 or 1
            d[i][j] = math.min(
                d[i-1][j] + 1,
                d[i][j-1] + 1,
                d[i-1][j-1] + cost
            )
        end
    end
    return d[m][n]
end

-- Bounded Levenshtein: returns distance or math.huge if > maxDist
local function utf8_levenshtein_bounded(s, t, maxDist)
    local s_chars = utf8_chars(s)
    local t_chars = utf8_chars(t)
    local m, n = #s_chars, #t_chars

    -- Quick length check
    if math.abs(m - n) > maxDist then
        return math.huge
    end

    -- Use two rows instead of full matrix for memory efficiency
    local prev = {}
    local curr = {}

    for j = 0, n do
        prev[j] = j
    end

    for i = 1, m do
        curr[0] = i
        local rowMin = curr[0]

        for j = 1, n do
            local cost = (s_chars[i] == t_chars[j]) and 0 or 1
            curr[j] = math.min(
                prev[j] + 1,
                curr[j-1] + 1,
                prev[j-1] + cost
            )
            if curr[j] < rowMin then
                rowMin = curr[j]
            end
        end

        -- Early termination: if minimum in row > maxDist, no solution possible
        if rowMin > maxDist then
            return math.huge
        end

        -- Swap rows
        prev, curr = curr, prev
    end

    return prev[n]
end


local function get_3_codes(str)
    local c1, c2, c3
    local len = 0
    for pos, code in utf8.codes(str) do
        len = len + 1
        if len == 1 then c1 = code
        elseif len == 2 then c2 = code
        elseif len == 3 then c3 = code
        else break end
    end
    return len, c1, c2, c3
end

local function min3(a, b, c)
    if a < b then
        return a < c and a or c
    else
        return b < c and b or c
    end
end


--- max 3 characters
function this.utf8_levenshtein_short(s, t)
    if s == t then return 0 end

    local slen, s1, s2, s3 = get_3_codes(s)
    local tlen, t1, t2, t3 = get_3_codes(t)

    if slen == 0 then return tlen end
    if tlen == 0 then return slen end

    local d00 = 0
    local d01 = 1
    local d02 = 2
    local d03 = 3

    local cost11 = (s1 == t1) and 0 or 1
    local d11 = min3(d01 + 1, 1 + 1, d00 + cost11)

    local d12, d13
    if tlen >= 2 then
        local cost12 = (s1 == t2) and 0 or 1
        d12 = min3(d02 + 1, d11 + 1, d01 + cost12)
        if tlen >= 3 then
            local cost13 = (s1 == t3) and 0 or 1
            d13 = min3(d03 + 1, d12 + 1, d02 + cost13)
        end
    end
    if slen == 1 then return tlen == 1 and d11 or (tlen == 2 and d12 or d13) end

    local cost21 = (s2 == t1) and 0 or 1
    local d21 = min3(d11 + 1, 2 + 1, 1 + cost21)

    local d22, d23
    if tlen >= 2 then
        local cost22 = (s2 == t2) and 0 or 1
        d22 = min3(d12 + 1, d21 + 1, d11 + cost22)
        if tlen >= 3 then
            local cost23 = (s2 == t3) and 0 or 1
            d23 = min3(d13 + 1, d22 + 1, d12 + cost23)
        end
    end
    if slen == 2 then return tlen == 1 and d21 or (tlen == 2 and d22 or d23) end

    local cost31 = (s3 == t1) and 0 or 1
    local d31 = min3(d21 + 1, 3 + 1, 2 + cost31)

    local d32, d33
    if tlen >= 2 then
        local cost32 = (s3 == t2) and 0 or 1
        d32 = min3(d22 + 1, d31 + 1, d21 + cost32)
        if tlen >= 3 then
            local cost33 = (s3 == t3) and 0 or 1
            d33 = min3(d23 + 1, d32 + 1, d22 + cost33)
        end
    end

    return tlen == 1 and d31 or (tlen == 2 and d32 or d33)
end


this.utf8_levenshtein = utf8_levenshtein
this.utf8_levenshtein_bounded = utf8_levenshtein_bounded


return this