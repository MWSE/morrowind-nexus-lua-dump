local id = {main = {}, go = {}, add = {}, del = {}}
local pfx = "tele:"
local sf = string.format
--local reg = tes3ui.registerID

function reg(name) return (tes3ui.registerID(pfx .. name)) end

id.add.backBtn = reg("AM_Back")
id.add.exitBtn = reg("AM_Exit")
id.add.input = reg("AM_Input")
id.add.menu = reg("AddMenu")
id.add.okBtn = reg("AM_Ok")

id.del.backBtn = reg("DM_Back")
id.del.exitBtn = reg("DM_Exit")
id.del.menu = reg("DelMenu")
id.del.scroll = reg("DM_Pane")

id.go.backBtn = reg("GM_Back")
id.go.exitBtn = reg("GM_Exit")
id.go.menu = reg("GoMenu")
id.go.scroll = reg("GM_Pane")

id.main.addMarkBtn = reg("MM_AddMark")
id.main.delMarkBtn = reg("MM_DelMark")
id.main.exitBtn = reg("MM_Exit")
id.main.goBtn = reg("MM_Teleport")
id.main.menu = reg("MainMenu")






return id
