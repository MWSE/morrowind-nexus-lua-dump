local ui = require("openmw.ui").showMessage
local self = require("openmw.self")
local aux = require("openmw_aux.util")


local cellname
local text = {
"You have committed a shameful crime. You are now a wanted criminal in %s!!",
"You have committed a disgraceful crime in %s. You are now a wanted criminal!!",
"The city of %s despises you. Leave the town and settle your crime elsewhere!!",
"The town of %s detests you. Leave the town and settle your crime elsewhere!!"
}



local function spitmessage()
	if not cellname then return end
    if self.cell.name:match(cellname) then
        ui(string.format(text[math.random(#text)], cellname))
    end
	cellname = nil
end



local function notify(data)
	cellname = unpack(data)
    cellname = cellname:match("[^,]+")
end


aux.runEveryNSeconds(
    12,
    spitmessage
)

return {
    engineHandlers = {
        onLoad = function()
            aux.runEveryNSeconds(
                12,
                spitmessage
            )
        end
    },
    eventHandlers = {
        ProtectiveGuards_notifications_eqnx = notify
    }
}
