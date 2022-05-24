---@param e uiActivatedEventData
event.register("uiActivated", function(e)
    local click = {}
    local trueRandom = {}
    local sub = e.element:findChild("MenuRaceSex_RaceList")
    local list = sub:findChild("PartScrollPane_pane")
    local sex = e.element:findChild("MenuRaceSex_ChangeSexbuttonBack")
    local face = e.element:findChild("MenuRaceSex_ChangeFacebuttonBack")
    local hair = e.element:findChild("MenuRaceSex_ChangeHairbuttonBack")
    for child in table.traverse(list.children) do
        if child.text and child.text ~= "" then
            table.insert(click, child)
        end
    end

    local random = list:createTextSelect{text = "Random"}
    random:register("mouseClick", function()
        local choice = table.choice(click)
        choice:triggerEvent(tes3.uiEvent.mouseClick)
        for i,v in ipairs(trueRandom) do
            table.insert(click, v)
            table.remove(trueRandom, i)
        end
        table.insert(trueRandom, choice)
        table.removevalue(click, choice)
        --timer.start({type = timer.real, duration = 0.3, callback = function()
            for _ = 0, math.random(0, 3) do
                sex:triggerEvent(tes3.uiEvent.mouseClick)
            end

            for _ = 0, math.random(1, 10) do
                face:triggerEvent(tes3.uiEvent.mouseClick)
            end

            for _ = 0, math.random(1, 10) do
                hair:triggerEvent(tes3.uiEvent.mouseClick)
            end
       -- end})
    end)
end, {filter = "MenuRaceSex"})