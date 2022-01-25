local Module = require("seph.hudCustomizer.lib.module")

local highlighter = Module()

highlighter.uuid = tes3ui.registerID("seph.hudCustomizer:highlight")
highlighter.highlight = nil

function highlighter:removeHighlight()
    if self.highlight then
        self.highlight:destroy()
        self.highlight = nil
        self.logger:trace("Removed")
    end
end

function highlighter:setHighlight(element)
    if element then
        local highlightConfig = self.mod.config.current.highlight
        if not self.highlight or self.highlight.parent ~= element.parent then
            self:removeHighlight()
            self.highlight = element.parent:createRect{id = self.uuid}
            self.logger:trace("Created")
        end
        self.highlight.visible = highlightConfig.visible
        self.highlight.color = {highlightConfig.color.r / 100, highlightConfig.color.g / 100, highlightConfig.color.b / 100}
        self.highlight.alpha = highlightConfig.alpha / 100
        self.highlight.absolutePosAlignX = element.absolutePosAlignX
        self.highlight.absolutePosAlignY = element.absolutePosAlignY
        self.highlight.borderAllSides = element.borderAllSides
        self.highlight.width = element.maxWidth or element.width
        self.highlight.height = element.maxHeight or element.height
        self.logger:trace(string.format("Set to '%s'", element.name or "Unnamed"))
    end
end

function highlighter:onMorrowindInitialized(eventData)
	event.register("load",
        function()
            self:removeHighlight()
        end
    )
end

return highlighter