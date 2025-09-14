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


this.utf8_levenshtein = utf8_levenshtein


return this