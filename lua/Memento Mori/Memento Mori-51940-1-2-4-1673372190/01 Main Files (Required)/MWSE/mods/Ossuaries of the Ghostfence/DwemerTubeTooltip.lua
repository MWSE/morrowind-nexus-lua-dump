local function dwemerTubeTooltip(e)
    if e.object.id == "GG_dwemer_tube" then
        local block = e.tooltip:createBlock{}
        block.minWidth = 1
        block.maxWidth = 440
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = 4
        local label = (block:createLabel{
            id = tes3ui.registerID("GG_dwemer_tube_desc"),
            text = "Quest Item"
        })
        label.wrapText = true
    end
end
event.register("uiObjectTooltip", dwemerTubeTooltip)
