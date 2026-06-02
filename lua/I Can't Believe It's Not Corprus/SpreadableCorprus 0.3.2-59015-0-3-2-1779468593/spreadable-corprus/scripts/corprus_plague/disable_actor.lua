local M = {}

-- MW Disable only. No teleport (re-enables disabled refs), remove, or kill.
function M.disable(actor)
    if not actor or not actor:isValid() then
        return
    end
    if actor.contentFile then
        actor.enabled = false
    else
        pcall(function()
            actor:remove()
        end)
    end
end

return M
