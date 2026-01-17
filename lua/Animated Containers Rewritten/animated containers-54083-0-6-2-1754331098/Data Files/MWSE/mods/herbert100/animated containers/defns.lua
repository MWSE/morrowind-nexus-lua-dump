---@class herbert.AC.defns
local defns = {
    mod_name = "Animated Containers",
    -- state of the container (i.e. closed, ..., open). higher numbers mean "more open"
    container_state = { closed = 1, closing = 2, opening = 3, open = 4 },

    auto_close = { never = 1, if_nonempty = 2, always = 3 },

    --- this was a terrible idea.
    ---@deprecated
    persistent_data_keys = { container_state = "CA_cs", blocked_by_immovable = "CA_bl" },

}

---@alias herbert.AC.defns.container_state
---|1 closed
---|2 closing
---|3 opening
---|4 open
---|`defns.container_state.closed` closed
---|`defns.container_state.closing` closing
---|`defns.container_state.opening` opening
---|`defns.container_state.open` open

---@alias herbert.AC.defns.auto_close
---|`defns.auto_close.never`
---|`defns.auto_close.if_nonempty`
---|`defns.auto_close.always`

return defns
