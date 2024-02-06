---@class herbert.AC.defns
local defns = {
    mod_name = "Animated Containers",
    -- state of the container (i.e. closed, ..., open). higher numbers mean "more open"
    container_state = {
        closed = 1,
        closing = 2,
        opening = 3,
        open = 4,
    },

    persistent_data_keys = {
        container_state = "CA_cs",
        blocked_by_immovable = "CA_bl",
    }

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


return defns