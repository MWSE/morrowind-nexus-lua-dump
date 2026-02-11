local hudCustomizerInterop = include("Seph.hudCustomizer.interop")

event.register("uiActivated", function(e)
    if not e.newlyCreated or e.element.name ~= "MenuMulti" then return end
    if hudCustomizerInterop then
        hudCustomizerInterop:registerElement(
            "DirtOMeter:FillbarBlock",
            "Dirt'O'Meter",
            { visible = true, positionX = 0.0, positionY = 0.90, width = 80, height = 14 },
            { position = true, size = true, visibility = true }
        )
    end
end)

event.register("seph.hudCustomizer:sizeUpdated", function(e)
    if e.element.name ~= "DirtOMeter:FillbarBlock" then return end
    local fill = e.element:findChild(tes3ui.registerID("DirtOMeter:Fillbar"))
    if fill then fill.width = e.width; fill.height = e.height end
end)

event.register("seph.hudCustomizer:positionUpdated", function(e)
    if e.element.name ~= "DirtOMeter:FillbarBlock" then return end
end)

event.register("seph.hudCustomizer:visibilityUpdated", function(e)
    if e.element.name ~= "DirtOMeter:FillbarBlock" then return end
    e.element.visible = e.visible
end)
