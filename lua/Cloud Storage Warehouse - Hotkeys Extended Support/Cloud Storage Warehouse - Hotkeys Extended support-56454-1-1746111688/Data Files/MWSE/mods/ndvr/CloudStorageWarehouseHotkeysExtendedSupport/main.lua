local originalDofile = dofile

dofile = function(path)
    -- override dofile function for tw.cws_blacklist call only
    if path == "tw.cws_blacklist" then
        local blacklist = {}

        -- get original blacklist
        local ok, result = pcall(originalDofile, path)
        if ok and type(result) == "table" then
            blacklist = result
        end

        -- add items from quickKeys from Hotkeys Extended mod
        local dataQuickKeys = tes3.player and tes3.player.data and tes3.player.data.quickKeys
        if dataQuickKeys then
            local types = { "quick_", "quick2", "quickH", "quickA", "quickA2", "quickAH", "quickB", "quickB2", "quickBH" }
            for i = 1, 10 do
                for _, t in ipairs(types) do
                    local entry = dataQuickKeys[t] and dataQuickKeys[t][i]
                    if entry and type(entry.id) == "string" and entry.id ~= "" and entry.id ~= "0" then
                        blacklist[entry.id] = true
                        --mwse.log("[Cloud Storage Warehouse - Hotkeys Extended Support] Added to blacklist: %s", entry.id)
                    end
                end
            end
        end

        return blacklist
    end

    -- in other cases return default dofile function
    return originalDofile(path)
end