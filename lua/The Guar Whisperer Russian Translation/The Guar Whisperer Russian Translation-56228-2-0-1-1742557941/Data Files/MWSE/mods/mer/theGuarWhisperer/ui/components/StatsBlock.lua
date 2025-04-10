local Syntax = require("mer.theGuarWhisperer.components.Syntax")
local StatBar = require("mer.theGuarWhisperer.ui.components.StatBar")
local AttributeBar = require("mer.theGuarWhisperer.ui.components.AttributeBar")

---Create a UI block that displays stats for a given guar
---@class GuarWhisperer.UI.StatsBlock
local StatsBlock = {}

StatsBlock.ids = {
    infoBlock = "TheGuarWhisperer_infoBlock"
}


---Create a block with stats for a guar.
---@param e { parent: tes3uiElement, guar: GuarWhisperer.GuarCompanion, inMenu: boolean }
function StatsBlock.new(e)
    --Right side info
    local infoBlock = e.parent:createBlock { id = StatsBlock.ids.infoBlock }
    infoBlock.autoHeight = true
    infoBlock.autoWidth = true
    infoBlock.minWidth = 200
    infoBlock.flowDirection = "top_to_bottom"
    infoBlock.paddingAllSides = 8

    local statData = {
        {
            label = "Здоровье",
            description = "Кормите гуара, чтобы восстановить его здоровье.",
            current = e.guar.mobile.health.current,
            max = e.guar.mobile.health.base,
            color = { 1, 0, 0 }
        },
        {
            label = "Счастье",
            description =
            "Счастье гуара определяется всеми остальными факторами. Хорошо кормите гуара, гладьте его и время от времени играйте в мяч. Счастье определяет, как быстро ваш гуар начнет вам доверять.",
            current = e.guar.needs:getHappiness(),
            max = 100,
            color = { 0.1, 0.9, 0.1 }
        },

        {
            label = "Доверие",
            description =
            "Укрепляйте доверие, поддерживая счастье гуара. Чем больше ваш гуар доверяет вам, тем больше команд вы можете ему давать.",
            current = e.guar.needs:getTrust(),
            max = 100,
            color = { 0.2, 0.1, 0.8 }
        },
        {
            label = "Голод",
            description =
            "Гуары любят листья растений. Следите за тем, чтобы ваш гуар получал хороший корм, и тогда он будет счастлив и здоров. Гуары могут есть с вашей руки, или вы можете приказать им есть прямо с растений.",
            current = e.guar.needs:getHunger(),
            max = 100,
            color = { 0.1, 0.5, 0.5 }
        }
    }

    for _, stat in ipairs(statData) do
        stat.inMenu = e.inMenu
        StatBar.new(infoBlock, stat)
    end

    if e.inMenu then
        infoBlock:createDivider()
        local attributesBlock = infoBlock:createBlock()
        attributesBlock.flowDirection = "top_to_bottom"
        attributesBlock.autoHeight = true
        attributesBlock.widthProportional = 1.0
        for attrName, attribute in pairs(tes3.attribute) do
            AttributeBar.new(attributesBlock, {
                label = attrName,
                current = e.guar.mobile.attributes[attribute + 1].current
            })
        end
    end
end

return StatsBlock
