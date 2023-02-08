markMenuId = tes3ui.registerID("WixUVRecallUV:MarkMenu")
recallMenuId = tes3ui.registerID("WixUVRecallUV:RecallMenu")
mRMenuId = tes3ui.registerID("WixUVRecallUV:RecallMenu")
speedMenuId = tes3ui.registerID("WixUVRecallUV:SpeedMenu")
speedInoutId = tes3ui.registerID("WixUVRecallUV:SpeedMenuInput")

local configPath = "WMultiMark.config"

local config = mwse.loadConfig("WmultiMark", {
    maxmslots = 15,
})

local function createtableVar(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}  
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("WmultiMark")
	template:saveOnClose("WmultiMark", config)
	
	
    local page = template:createPage()
    local categoryMain = page:createCategory("Settings")

								
	categoryMain:createSlider{ label = "Maximum Mark slots",
							variable = createtableVar("maxmslots"),
							min = 1,
							max = 50,
							jump = 1,
							defaultSetting = 15}
	
    mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)

function checkwmm()
    if tes3.player.data.WixUVRecall == nil then tes3.player.data.WixUVRecall = {} end
    if tes3.player.data.WixUVRecall.mslots == nil then tes3.player.data.WixUVRecall.mslots = {} end
    for i = #tes3.player.data.WixUVRecall.mslots, config.maxmslots do
            table.insert(tes3.player.data.WixUVRecall.mslots,{})
    end
    if tes3.player.data.WixUVRecall.lastrec == nil then tes3.player.data.WixUVRecall.lastrec = {} end
end

function createRecMenu()
    if (tes3ui.findMenu(recallMenuId) ~= nil) then
        return
    end
    local menu = tes3ui.createMenu{ id = recallMenuId, fixedFrame = true }
    menu.alpha = 1.0

    local input_label = menu:createLabel{ text = "Select Recall Slot" }
    input_label.borderBottom = 5
    --mwse.log(json.encode(tes3.player.data.WixUVRecall, {indent=true}))
    --mwse.log(json.encode(tes3.player.data.WixUVRecall.mslots, {indent=true}))
    --mwse.log(json.encode(tes3.player.data.WixUVRecall.mslots[1], {indent=true}))
    checkwmm()
    for i = 1,config.maxmslots do
        local button = menu:createButton{}
        button.autoWidth = true
        button.height = 30
        --#tes3.player.data.WixUVRecall.mslots <= i and 
        if(tes3.player.data.WixUVRecall.mslots[i].cellId ~= nil) then
            button.text = tes3.player.data.WixUVRecall.mslots[i].cellId
            button:register("mouseClick",function()
                --tes3.messageBox({ message = "Recalling to "..tes3.player.data.WixUVRecall.mslots[i].cellId.."  "..tostring(tes3.player.data.WixUVRecall.mslots[i].pos).."  "..tostring(tes3.player.data.WixUVRecall.mslots[i].ori) })
                local mplayer = tes3.mobilePlayer
                local cell = tes3.getPlayerCell()
                tes3.player.data.WixUVRecall.lastrec.cellId = cell.id
                local pos = {mplayer.position.x, mplayer.position.y, mplayer.position.z}
                local ori = {tes3.player.orientation.x, tes3.player.orientation.y, tes3.player.orientation.z}
                tes3.player.data.WixUVRecall.lastrec.pos = pos
                tes3.player.data.WixUVRecall.lastrec.ori = ori
                tes3.positionCell{reference=tes3.mobilePlayer, cell=tes3.player.data.WixUVRecall.mslots[i].cellId, position=tes3.player.data.WixUVRecall.mslots[i].pos, orientation=tes3.player.data.WixUVRecall.mslots[i].ori}          
                tes3ui.leaveMenuMode()
                menu:destroy()
            end)
        else
            button.text = "NotSet!"
            button:register("mouseClick",function()
                tes3.messageBox({ message = "No Mark cast for this slot yet!" })
                tes3ui.leaveMenuMode()
                menu:destroy()
            end)
        end
    end
    local input_label = menu:createLabel{ text = "last recall pos" }
    local buttonlastrec = menu:createButton{}
    if(tes3.player.data.WixUVRecall.lastrec.cellId ~= nil) then
        buttonlastrec.text = tes3.player.data.WixUVRecall.lastrec.cellId
    else
        buttonlastrec.text = "NotSet!"
    end
    buttonlastrec:register("mouseClick",function()
        if(tes3.player.data.WixUVRecall.lastrec.cellId ~= nil) then
            tes3.positionCell{reference=tes3.mobilePlayer, cell=tes3.player.data.WixUVRecall.lastrec.cellId, position=tes3.player.data.WixUVRecall.lastrec.pos, orientation=tes3.player.data.WixUVRecall.lastrec.ori} 
        else
            tes3.messageBox({ message = "No Mark cast for this slot yet!" })
        end
        tes3ui.leaveMenuMode()
        menu:destroy()
    end)
    local button_cancel = menu:createButton{ text = "Cancel"}
    button_cancel:register("mouseClick",function()
        tes3ui.leaveMenuMode()
        menu:destroy()
    end)
    menu:updateLayout()
    tes3ui.enterMenuMode(markMenuId)
end

function createMarkMenu()
    if (tes3ui.findMenu(markMenuId) ~= nil) then
        return
    end
    local menu = tes3ui.createMenu{ id = markMenuId, fixedFrame = true }
    menu.alpha = 1.0

    local input_label = menu:createLabel{ text = "Select Mark Slot" }
    input_label.borderBottom = 5

    checkwmm()


    for i = 1,config.maxmslots do
        local button = menu:createButton{}
        button.autoWidth = true
        button.height = 30
        button:register("mouseClick",function()
            local mplayer = tes3.mobilePlayer
            local cell = tes3.getPlayerCell()
            tes3.player.data.WixUVRecall.mslots[i].cellId = cell.id
            local pos = {mplayer.position.x, mplayer.position.y, mplayer.position.z}
            local ori = {tes3.player.orientation.x, tes3.player.orientation.y, tes3.player.orientation.z}
            tes3.player.data.WixUVRecall.mslots[i].pos = pos
            tes3.player.data.WixUVRecall.mslots[i].ori = ori
            --mwse.log(json.encode(tes3.player.data.WixUVRecall.mslots[i], {indent=true}))
            tes3ui.leaveMenuMode()
            menu:destroy()
        end)
        if(tes3.player.data.WixUVRecall.mslots[i].cellId ~= nil) then
            button.text = tes3.player.data.WixUVRecall.mslots[i].cellId
        else
            button.text = "NotSet!"
        end
    end
    local button_cancel = menu:createButton{ text = "Cancel" }
    button_cancel:register("mouseClick",function()
            tes3ui.leaveMenuMode()
            menu:destroy()
    end)
    menu:updateLayout()
    tes3ui.enterMenuMode(markMenuId)
end


function createMRMenu()
    if (tes3ui.findMenu(mRMenuId) ~= nil) then
        return
    end
    local menu = tes3ui.createMenu{ id = mRMenuId, fixedFrame = true }
    menu.alpha = 1.0

    local input_label = menu:createLabel{ text = "What would you like to do?" }
    input_label.borderBottom = 5

    checkwmm()
    local buttonMark = menu:createButton{ text = "Mark"}
    buttonMark:register("mouseClick",function()
        tes3ui.leaveMenuMode()
        menu:destroy()
        createMarkMenu()
    end)
    local buttonRecall = menu:createButton{ text = "Recall"}
    buttonRecall:register("mouseClick",function()
        tes3ui.leaveMenuMode()
        menu:destroy()
        createRecMenu()
    end)
    local button_cancel = menu:createButton{ text = "Cancel"}
    button_cancel:register("mouseClick",function()
        tes3ui.leaveMenuMode()
        menu:destroy()
    end)
    menu:updateLayout()
    tes3ui.enterMenuMode(mRMenuId)
end

function osSpellCasted(e)
    spell = e.source
    if(spell.id == "wmmark") then
        createMRMenu()
        --createMarkMenu()
    elseif (spell.id == "wmrec") then
        createRecMenu()
    elseif (spell.id == "wmmr") then
        createMRMenu()
    elseif (spell.id == "wspeeda") then
        --createSpeedMenu()
       -- mwse.log(e.source.id)
        --tes3ui.log(e.source.id)
    end

end
event.register("spellCasted", osSpellCasted)


    --tes3ui.logToConsole(e.sourceInstance.id)