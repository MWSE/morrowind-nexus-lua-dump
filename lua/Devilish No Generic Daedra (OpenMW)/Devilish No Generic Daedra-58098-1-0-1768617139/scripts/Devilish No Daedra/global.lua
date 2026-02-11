------------------------------------------------------------
-- GLOBAL DAEDRA REMOVAL HANDLER
------------------------------------------------------------

local function DaedraRemoveSelf(data)
    local obj = data.obj
    if not obj then return end
    if not obj:isValid() then return end

    obj:remove()
end

------------------------------------------------------------
-- RETURN
------------------------------------------------------------

return {
    eventHandlers = {
        DaedraRemoveSelf = DaedraRemoveSelf,
    }
}
