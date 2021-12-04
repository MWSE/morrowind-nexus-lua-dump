local paid = false
local canUse = nil
local bedfee = 15
local servicefaction
local alone = false

--[[----------------------------------------------------------------------------------------------------------------------------------------------]]
local function anyoneThere()
	--if (tes3.getCurrentAIPackageId(actor) ~= tes3.aiPackage.follow) then end
    for actor in tes3.getPlayerCell():iterateReferences(tes3.objectType.npc) do
        if actor.object and actor.object.faction == servicefaction and not actor.disabled and not actor.isDead then
           alone = false
		   return
        end
    end
    alone = true
end
--[[----------------------------------------------------------------------------------------------------------------------------------------------]]
local function resetPaid()
    if paid then
        paid = false
    end
    if canUse then
        canUse = nil
    end
end
event.register("cellChanged", resetPaid)
--[[----------------------------------------------------------------------------------------------------------------------------------------------]]
local function checkFee(playerrank, label2)
    if alone then
        label2.color = {0, 1, 0}
        return "Free to use"
    end

    if paid then
        label2.color = {0, 1, 0}
        return "Service is paid"
    end

    if playerrank < 5 then
        canUse = "pay"
        bedfee = 10 - playerrank
        label2.color = {1, 1, 0}
        return string.format("Fee: %d gold", bedfee)
    else
        canUse = "free"
        bedfee = 0
        label2.color = {0, 1, 0}
        return "Free to use"
    end
end

local function denyBed(e)
    if
        e.target.cell.isInterior and e.target.object.script and e.target.object.script.id == "Bed_Standard" and servicefaction and canUse == "no" and not alone
     then
        e.block = true
    --e.element:findChild("MenuRestWait_cancel_button"):triggerEvent("mouseClick") --726
    end
end
event.register("activate", denyBed)

--[[----------------------------------------------------------------------------------------------------------------------------------------------]]
--[[local function enfo(e)
	if servicefaction and (e.block.id == -723 or e.block.id == -724) then
	local stat = tes3ui.createTooltipMenu()
    block = stat:createBlock()
    block.minWidth = 1
    block.maxWidth = 1368
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 1
    block.flowDirection = "top_to_bottom"
    local label = block:createLabel {}
	label.text = checkfee(servicefaction.playerRank, label)
    label.wrapText = true
    label.borderBottom = 4
    label.justifyText = "center"
	end
	end
	event.register("uiPreEvent", enfo)]]
--[[----------------------------------------------------------------------------------------------------------------------------------------------]]
local function freeandpay(e)
    if e.element.name == "MenuRestWait" then
        if canUse == "pay" and paid == false then
            e.element:findChild(-723):register(
                "mouseClick",
                function()
                    paid = true
                    tes3.removeItem {
                        reference = tes3.player,
                        item = "gold_001",
                        count = bedfee,
                        playSound = false
                    }
                    if bedfee > 0 then
                        tes3.playSound {sound = "Item Gold Up"}
                        tes3.messageBox(bedfee .. " gold has been removed from your inventory")
                    end
                    e.element:findChild(-723):unregister("mouseClick")
                    e.element:findChild(-723):triggerEvent("mouseClick")
                end
            )
            e.element:findChild(-724):register(
                "mouseClick",
                function()
                    paid = true
                    tes3.removeItem {
                        reference = tes3.player,
                        item = "gold_001",
                        count = bedfee,
                        playSound = false
                    }
                    if bedfee > 0 then
                        tes3.playSound {sound = "Item Gold Up"}
                        tes3.messageBox(bedfee .. " gold has been removed from your inventory")
                    end
                    e.element:findChild(-724):unregister("mouseClick")
                    e.element:findChild(-724):triggerEvent("mouseClick")
                end
            )
        elseif canUse == "free" then
            e.element:findChild(-723):unregister("mouseClick")
            e.element:findChild(-724):unregister("mouseClick")
        end
    end
end
event.register("uiActivated", freeandpay)
--[[----------------------------------------------------------------------------------------------------------------------------------------------]]
return function(tooltip, joinstatus, expelstatus, faction, serviceBed)
	if not serviceBed then
		canUse = true
		return
	end
	alone = false
	anyoneThere()
    servicefaction = faction
    canUse = nil
	if alone then return end
    local block = tooltip:createBlock {}
    block.minWidth = 1
    block.maxWidth = 512
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 6
    block.flowDirection = "top_to_bottom"
    local label = block:createLabel {}

    local label2 = block:createLabel {}

    --tooltip.block = true
    if (joinstatus and expelstatus ~= "expelled") then
        label.text =
            string.format(
            "You rank is %s in the %s.\n--------------",
            servicefaction:getRankName(servicefaction.playerRank),
            servicefaction
        )
        label.wrapText = true
        label.borderBottom = 2
        label.justifyText = "center"
        label2.text = string.format("%s", checkFee(servicefaction.playerRank, label2))
        label2.wrapText = true
        label2.justifyText = "center"
    elseif joinstatus and expelstatus == "expelled" then
        canUse = "no"
        label.text = string.format("You are expelled from the %s.\n--------------", servicefaction)
        label.wrapText = true
        label.borderBottom = 2
        label.justifyText = "center"
        label2.text = string.format("Expelled members cannot use the bed")
        label2.wrapText = true
        label2.justifyText = "center"
        label2.color = {1, 0, 0}
    elseif joinstatus ~= "joined" then
        canUse = "no"
        label.text = string.format("Only %s members can use this service\n--------------", servicefaction)
        label.wrapText = true
        label.borderBottom = 2
        label.justifyText = "center"
        label2.text = string.format("Non-members cannot use the bed")
        label2.wrapText = true
        label2.justifyText = "center"
        label2.color = {1, 0, 0}
    end
end

--[[----------------------------------------------------------------------------------------------------------------------------------------------]]
