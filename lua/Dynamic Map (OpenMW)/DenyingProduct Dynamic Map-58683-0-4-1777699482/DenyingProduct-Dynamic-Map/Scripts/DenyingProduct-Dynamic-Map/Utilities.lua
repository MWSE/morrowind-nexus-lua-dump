local Utilities = {}

function Utilities.wrapWords(text, maxLen)

    -- split on space or any words longer than MaxLen. make an exception to not split if the remaining part is 2 characters or less to avoid orphaned letters.
    local words = {}
    for w in text:gmatch("%S+") do
        while #w > maxLen do
            local part = w:sub(1, maxLen - 1)
            w = w:sub(maxLen)
            if #w <= 2 then
                part = part .. w
                w = ""
            else
                part = part .. "-"
            end
            table.insert(words, part)
        end
        table.insert(words, w)
    end

    -- POP array and build lines
    local result = {}
    local line = ""
    while #words > 0 do
        local word = table.remove(words, 1) 
        if line == "" then
            line = word
        elseif #line + 1 + #word <= maxLen then
            line = line .. " " .. word
        else
            table.insert(result, line)
            line = word
        end
    end

    -- push last line
    if line ~= "" then
        table.insert(result, line)
    end
    return table.concat(result, "\n")

end

function Utilities.getTextSize(mergeCount,zoom)
    -- normal single cell markers
    local textsize = 5
    -- increase size based on merge count (more merged cells = bigger text)
    if(mergeCount > 1) then textsize = 12 end
    if(mergeCount >= 3) then textsize = 16 end
    if(mergeCount >= 5) then textsize = 20 end
    if(zoom == 1) then
        if(mergeCount > 1) then textsize = 15 end
        if(mergeCount >= 3) then textsize = 20 end
        if(mergeCount >= 5) then textsize = 20 end
    end
    if(zoom == 0.5) then
        if(mergeCount > 1) then textsize = 0 end
        if(mergeCount >= 3) then textsize = 30 end
        if(mergeCount >= 5) then textsize = 30 end
        if(mergeCount >= 6) then textsize = 45 end
    end
    if(zoom == 0.25) then
        if(mergeCount > 1) then textsize = 0 end
        if(mergeCount >= 3) then textsize = 0 end
        if(mergeCount >= 5) then textsize = 40 end
        if(mergeCount >= 6) then textsize = 75 end
    end
    return textsize 
end

return Utilities