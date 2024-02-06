---@return niNode
return function()
    local menu = tes3ui.findMenu("MenuOptions")
    assert(menu, "No menu found!")
    local node = menu.sceneNode
    while node.parent do
        node = node.parent
    end
    return node
end
