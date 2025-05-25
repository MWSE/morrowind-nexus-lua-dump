local cl_op = {

menu = nil,
scroll = nil,
clog = nil,

sendMessageToCLog = function(msg)
    if not menu then menu = tes3ui.findMenu("bsCombatLog") end
    if not scroll then scroll = menu:findChild("scroll") end
    if not clog then clog = scroll:findChild("clog") end

    local label = clog:createLabel{id = "spell_recog", text = msg }
    label.color = {0.941, 0.38, 0.38}
    menu:updateLayout()                                    ---Update Layout
    scroll.widget.positionY = scroll.widget.positionY + 25 ---Scroll down 25
    scroll.widget:contentsChanged()     
    end
}

return cl_op