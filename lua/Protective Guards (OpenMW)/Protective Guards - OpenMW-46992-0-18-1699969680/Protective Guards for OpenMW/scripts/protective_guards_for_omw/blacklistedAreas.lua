-- case sensitive
-- only interior cells
-- some fights are legal eg. arena battles, Helseth Champion Quest, etc..
-- blacklist the cells where these fights occur
-- todo: use journal stages, script running checks for this
local blackList = {
    ["Vivec, Arena Pit"] = true, -- to prevent guards from interfering with battles in the arena
    ["Vivec, Palace of Vivec"] = true, -- prevents unwanted interference when battling a god
    ["Mournhold Temple: High Chapel"] = true, -- prevents unwanted interference when battling a god
    ["Mournhold, Royal Palace Throne Room"] = true -- to avoid spoiling intended and scripted event (karrod)
}

return blackList
