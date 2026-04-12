local core = require("openmw.core")

---@param player any
---@param namespace string
---@param requiredPlugin string
---@param interface any
---@param minVersion number
---@param curVersion number
function CheckDependency(player, namespace, requiredPlugin, interface, minVersion, curVersion)
    local prefix = ("[%s] Dependency error: "):format(namespace)

    local checks = {
        {
            ok = core.contentFiles.has(requiredPlugin:lower()),
            msg = ("'%s' dependecy not found."):format(requiredPlugin)
        },
        {
            ok = interface ~= nil,
            msg = ("'%s' has to be loaded before this mod."):format(requiredPlugin)
        },
        {
            ok = curVersion >= minVersion,
            msg = ("'%s' version too low. Required %s, found %s.")
                :format(requiredPlugin, tostring(minVersion), tostring(curVersion))
        }
    }

    for _, c in ipairs(checks) do
        if not c.ok then
            player:sendEvent("ShowMessage", {
                message = prefix .. c.msg,
            })
            error(prefix .. c.msg)
        end
    end
end
