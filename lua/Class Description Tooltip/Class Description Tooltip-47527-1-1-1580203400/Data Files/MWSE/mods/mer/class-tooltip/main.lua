--[[
    This mod restores the class description tooltip in the 
    Choose Class menu in Chargen.
]]

local function updateClassTooltip(e)
    local classImage = e.element:findChild(tes3ui.registerID("MenuChooseClass_description"))
    classImage:register("help", function()
        local class =  tes3.player.object.class
        local tooltipMenu = tes3ui.createTooltipMenu()

        local outerBlock = tooltipMenu:createBlock()
        outerBlock.width = 452
        outerBlock.autoHeight = true
        outerBlock.flowDirection = "top_to_bottom"
        outerBlock.childAlignX = 0.5
        outerBlock.borderAllSides = 6

        --Class Name header
        local header = outerBlock:createLabel({ text = class.name })
        header.color = tes3ui.getPalette("header_color")
        header.borderBottom = 4

        --Class Description
        local description = outerBlock:createLabel({ text = class.description })
        description.wrapText = true
        description.autoHeight = true
        description.borderBottom = 4

        --Specialization, formatted as "Specialisation: Stealth"
        local specName = tes3.specializationName[class.specialization]
        local specNameCapital = (
            string.upper(string.sub(specName, 1, 1)) ..
            string.sub(specName, 2)
        )
        outerBlock:createLabel{ 
            text = tes3.findGMST(tes3.gmst.sChooseClassMenu1).value .. " " .. specNameCapital
        }
    end)
end
event.register("uiActivated", updateClassTooltip, { filter = "MenuChooseClass"})


-- local function updateRaceTooltip(e)
--     local raceImage = e.element:findChild(tes3ui.registerID("MenuRaceSex_Head"))
--     raceImage:register("help", function()
--         local race =  tes3.player.object.race
--         local tooltipMenu = tes3ui.createTooltipMenu()

--         local outerBlock = tooltipMenu:createBlock()
--         outerBlock.width = 452
--         outerBlock.autoHeight = true
--         outerBlock.flowDirection = "top_to_bottom"
--         outerBlock.childAlignX = 0.5
--         outerBlock.borderAllSides = 6

--         --Class Name header
--         local header = outerBlock:createLabel({ text = race.id})
--         header.color = tes3ui.getPalette("header_color")
--         header.borderBottom = 4

--         --race Description
--         local description = outerBlock:createLabel({ text = race.description })
--         description.wrapText = true
--         description.autoHeight = true
--         description.borderBottom = 4

--     end)
-- end
-- event.register("uiActivated", updateRaceTooltip, { filter = "MenuRaceSex"})