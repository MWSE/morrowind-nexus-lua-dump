local seph = require("seph")

local highlighter = seph.Module()

highlighter.uuid = tes3ui.registerID("seph.hudCustomizer:highlight")
highlighter.highlight = nil

function highlighter:setHighlight(element)
    if element then
        if self.highlight and self.highlight.parent ~= element then
            self.highlight:destroy()
        elseif not self.highlight then
            local highlightConfig = self.mod.config.current.highlight
            local wasVisible = element.visible
            self.highlight = element:createRect{id = self.uuid}
            self.highlight:register("destroy",
                function()
                    self.highlight = nil
                    element.visible = wasVisible
                    event.unregister("enterFrame", self.onEnterFrame)
                    self.logger:debug(string.format("Removed highlight from '%s'", element.name or "Unnamed"))
                end
            )
            element.visible = true
            self.highlight.visible = highlightConfig.visible
            self.highlight.color = {highlightConfig.color.r / 100, highlightConfig.color.g / 100, highlightConfig.color.b / 100}
            self.highlight.alpha = highlightConfig.alpha / 100
            self.highlight.absolutePosAlignX = 0.5
            self.highlight.absolutePosAlignY = 0.5
            event.register("enterFrame", self.onEnterFrame, {priority = -2^16})
            self.logger:debug(string.format("Set highlight to '%s'", element.name or "Unnamed"))
        end
        self:updateHighlight()
    end
end

function highlighter:removeHighlight()
    if self.highlight then
        self.highlight:destroy()
    end
end

function highlighter:updateHighlight()
    if self.highlight then
        local element = self.highlight.parent
        self.highlight.width = element.maxWidth or element.width
        self.highlight.height = element.maxHeight or element.height
        self.highlight.alpha = math.abs(seph.math.sineWave(self.mod.config.current.highlight.alpha / 100, 2.0))
        element.visible = true
    else
        event.unregister("enterFrame", self.onEnterFrame)
    end
end

function highlighter.onEnterFrame()
    highlighter:updateHighlight()
end

return highlighter