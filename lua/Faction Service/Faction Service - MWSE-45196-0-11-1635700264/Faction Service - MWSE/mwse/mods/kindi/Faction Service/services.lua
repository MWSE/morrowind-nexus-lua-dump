local config = require("kindi.faction service.config")
local diffrank = 0
local palette = {}
local servicefaction
local service


local function checkeligible(e, speakerrank)
    if (speakerrank - servicefaction.playerRank) <= diffrank then
        e:unregister("mouseClick")
        palette = {0, 1, 0}
        return "You are eligible for "..service.." service"
    else
        e:register(
            "mouseClick",
            function()
                --tes3.messageBox("You are ineligible") --service refusal dialogue
            end
        )
        palette = {1, 0, 0}
        return string.format(
            "Rank %s[%s] or above is required for "..service,
            servicefaction:getRankName(speakerrank - diffrank),
            speakerrank - diffrank
        )
    end
end

local function determinerank(speakerrank)
--[[
0 - service given if player rank is atleast same or higher than speaker
1 - service given if player rank is atleast 1 lower than speaker
2 - service given if player rank is atleast 2 lower than speaker
-1 - service given if player rank is atleast 1 higher than speaker
]]
    if (speakerrank - servicefaction.playerRank) <= diffrank then
        return string.format(
            "Your rank is %s[%s].\n%s's rank is %s[%s].\n--------------",
            servicefaction:getRankName(servicefaction.playerRank),
            servicefaction.playerRank,
            tes3ui.getServiceActor().object.name,
            servicefaction:getRankName(speakerrank),
            speakerrank
        )
    else
        return string.format(
            "Your rank is %s[%s].\n%s's rank is %s[%s].\n--------------",
            servicefaction:getRankName(servicefaction.playerRank),
            servicefaction.playerRank,
            tes3ui.getServiceActor().object.name,
            servicefaction:getRankName(speakerrank),
            speakerrank
        )
    end
end

return function (e, joinstatus, expelstatus, faction, str)
	diffrank = tonumber(config.rankDiff)
	service = str
	if not config[service:lower()] then return end
	servicefaction = faction
    local speakerrank = tes3ui.getServiceActor().object.baseObject.factionRank

    local stat = tes3ui.createTooltipMenu()
    block = stat:createBlock()
    block.minWidth = 1
    block.maxWidth = 1368
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 1
    block.flowDirection = "top_to_bottom"
    local label = block:createLabel {}
    label.wrapText = true
    label.borderBottom = 4
    label.justifyText = "center"
    local stattext = block:createLabel {}
    stattext.wrapText = true
    stattext.justifyText = "center"


    if joinstatus and expelstatus ~= "expelled" then
        label.text = determinerank(speakerrank)
        stattext.text = checkeligible(e, speakerrank)
        stattext.color = palette
    elseif joinstatus and expelstatus == "expelled" then
        label.text = string.format("You are expelled from the %s.\n--------------", servicefaction)
        stattext.text = service.." service is unavailable for expelled members"
        stattext.color = {1, 0, 0}
    elseif joinstatus ~= "joined" then
		checkeligible(e, 9999)
        label.text = string.format("You are not a member of the %s.\n--------------", servicefaction)
        stattext.text = service.." service is unavailable for non-members"
        stattext.color = {1, 0, 0}

    end

end




--[[local function onClick()
tes3ui.findMenu(-314).visible = false
event.unregister("enterFrame", onClick)
end



local function ac(e)
if e.element.name == "MenuBarter" then
local button = e.element:findChild("MenuBarter_Cancelbutton")
button:triggerEvent("mouseClick")
event.register("enterFrame", onClick)
end
end
event.register("uiActivated", ac)]]
