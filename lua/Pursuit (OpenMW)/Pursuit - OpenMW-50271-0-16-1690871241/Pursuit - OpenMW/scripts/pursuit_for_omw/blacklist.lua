-- the following actors will not pursue
-- lowercase record id
-- restart the game to for the changes to take effect, or reloadlua in the console
-- todo: blacklist UI ingame
local bl = {
    ["vivec_god"] = true,
    ["yagrum bagarn"] = true,
    ["almalexia"] = true,
    ["TR_m3_Hormidac Farralie"] = true,
    ["Almalexia_warrior"] = true,
    -- ["add_your_own_actor_id_here_to_blacklist_it"] = true,
}

local function handleLazy(t, key)
    for k, v in pairs(t) do
        if k:lower() == key then
            return v
        end
    end
end
return setmetatable(bl, {
    __index = handleLazy
})
