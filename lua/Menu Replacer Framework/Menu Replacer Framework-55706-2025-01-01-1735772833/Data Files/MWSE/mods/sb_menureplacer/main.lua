local menu = json.loadfile("mods\\sb_menureplacer\\sb_menu.json")

mwse.log(json.encode(menu))

local function GetKey(key)
    return key == "newgame" and "NewGame" or key == "loadgame" and "LoadGame" or key == "options" and "Options" or key == "modconfig" and "ModConfig" or key == "credits" and "Credits" or key == "exitgame" and "ExitGame"
end

--- @param e uiActivatedEventData
local function uiOptionsActivatedCallback(e)
    if (tes3.player == nil) then
        local w, h = tes3ui.getViewportSize()
        
        e.element.autoWidth = false
        e.element.autoHeight = false
        e.element.width = w
        e.element.height = h
        if (e.newlyCreated and menu["UseTitle"]) then
            local logo = e.element:createImage{path = menu["Logo"]["Image"]}
            if (w > menu["Logo"]["MinScale"]) then
                logo.imageScaleX = menu["Logo"]["Scale"] * (menu["Logo"]["MinScale"] / w)
                logo.imageScaleY = menu["Logo"]["Scale"] * (menu["Logo"]["MinScale"] / w)
            end
            if (menu["Logo"]["IgnoreLayoutX"]) then
                logo.positionX = menu["Logo"]["PositionX"]
            else
                logo.absolutePosAlignX = menu["Logo"]["AbsolutePosAlignX"]
            end
            if (menu["Logo"]["IgnoreLayoutY"]) then
                logo.positionY = menu["Logo"]["PositionY"]
            else
                logo.absolutePosAlignY = menu["Logo"]["AbsolutePosAlignY"]
            end
            logo.ignoreLayoutX = menu["Logo"]["IgnoreLayoutX"]
            logo.ignoreLayoutY = menu["Logo"]["IgnoreLayoutY"]
            logo.consumeMouseEvents = false
        end
        local content = e.element:getContentElement().children[1]
        if (menu["Options"]["IgnoreLayoutX"]) then
            content.positionX = menu["Options"]["PositionX"]
        else
            content.absolutePosAlignX = menu["Options"]["AbsolutePosAlignX"]
        end
        if (menu["Options"]["IgnoreLayoutY"]) then
            content.positionY = menu["Options"]["PositionY"]
        else
            content.absolutePosAlignY = menu["Options"]["AbsolutePosAlignY"]
        end
        content.ignoreLayoutX = menu["Options"]["IgnoreLayoutX"]
        content.ignoreLayoutY = menu["Options"]["IgnoreLayoutY"]
        ---@param element tes3uiElement
        for _, element in ipairs(content.children) do
            local contentPath = element.name:find("_New") and "newgame" or
                element.name:find("_Load") and "loadgame" or
                element.name:find("_Options") and "options" or
                element.name:find("_MCM") and "modconfig" or
                element.name:find("_Credits") and "credits" or
                element.name:find("_Exit") and "exitgame"
            if (contentPath) then
                element.autoWidth = true
                element.autoHeight = true
                element.borderLeft, element.borderTop, element.borderRight, element.borderBottom = menu["Options"][GetKey(contentPath)]["Border"]:gmatch("([0-9]+)")
                for i = 1, 3 do
                    element.children[i].width = menu["Options"][GetKey(contentPath)]["Width"]
                    element.children[i].height = menu["Options"][GetKey(contentPath)]["Height"]
                    if (i == 2) then
                        element.children[i].contentPath = menu["Options"][GetKey(contentPath)]["ImageOver"]
                    else
                        element.children[i].contentPath = menu["Options"][GetKey(contentPath)]["Image"]
                    end
                end
            end
        end

        e.element:updateLayout()

        if (menu["CursorImage"] and menu["CursorImage"] ~= "") then
            timer.start{ type = timer.real, duration = 0.1, persist = false, callback = function()
                local topMostNode = e.element.sceneNode
                while topMostNode.parent do
                    topMostNode = topMostNode.parent
                end
                local cursor = topMostNode:getObjectByName("cursor")
                local texturingProperty = cursor.texturingProperty
                local map = texturingProperty.baseMap
                local texture = niSourceTexture.createFromPath(menu["CursorImage"])
                map.texture = texture
                cursor:updateProperties()
            end }
        end
    end
end

event.register(tes3.event.uiActivated, uiOptionsActivatedCallback, { filter = "MenuOptions" })

if (menu["CursorImage"] and menu["CursorImage"] ~= "") then
    --- @param e loadEventData
    local function loadCallback(e)
        local topMostNode = tes3ui.findMenu("Options").sceneNode
        while topMostNode.parent do
            topMostNode = topMostNode.parent
        end
        local cursor = topMostNode:getObjectByName("cursor")
        local texturingProperty = cursor.texturingProperty
        local map = texturingProperty.baseMap
        local texture = niSourceTexture.createFromPath("Textures\\cursor_drop.dds")
        map.texture = texture
        cursor:updateProperties()
    end

    event.register(tes3.event.load, loadCallback)
end