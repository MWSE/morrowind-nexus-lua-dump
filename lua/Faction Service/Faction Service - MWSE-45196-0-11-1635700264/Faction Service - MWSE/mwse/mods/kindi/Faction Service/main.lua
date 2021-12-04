local bed = require("kindi.faction service.bed")
local services = require("kindi.faction service.services")


local config
local joinstatus = nil
local expelstatus = nil
local servicefaction = nil





local factions = {
    "Fighters Guild",
    "Mages Guild",
    "Temple",
    "Imperial Legion",
    "Morag Tong",
    "Imperial Cult",
    "Thieves Guild"
}


local function pcfactionstatus(servicefaction)
    if servicefaction.playerJoined == true then
        joinstatus = "joined"
    else
        joinstatus = nil
    end

    if servicefaction.playerExpelled == true then
        expelstatus = "expelled"
    else
        expelstatus = nil
    end
end

local function getcellfaction()
    if tes3.getPlayerCell() ~= nil then
        local c = tes3.getPlayerCell().name

        if string.find(c, "Guild of Fighters") or string.find(c, "Fighter's Guild") then
            servicefaction = tes3.getFaction("Fighters Guild")
        elseif string.find(c, "Guild of Mages") or string.find(c, "Mage's Guild") then
            servicefaction = tes3.getFaction("Mages Guild")
        elseif string.find(c, "Legion") or string.find(c, "Fort") then
            servicefaction = tes3.getFaction("Imperial Legion")
        elseif string.find(c, "Temple") then
            servicefaction = tes3.getFaction("Temple")
        elseif string.find(c, "Morag Tong") or c == "Vivec, Arena Hidden Area" then
            servicefaction = tes3.getFaction("Morag Tong")
        elseif string.find(c, "Chapel") then
            servicefaction = tes3.getFaction("Imperial Cult")
        else
            servicefaction = nil
        end

        if servicefaction then
            pcfactionstatus(servicefaction)
        end
    end
end

local function getactorfaction(speakerfactionid)
    servicefaction = nil
    for k, v in ipairs(factions) do
        if v == speakerfactionid then
            servicefaction = tes3.getFaction(speakerfactionid)
            break
        end
    end

    if servicefaction then
        pcfactionstatus(servicefaction)
    end
end

local function bedservice(e)
	if tes3.onMainMenu() or not config.modActive then
		return
	end
    getcellfaction()
    if servicefaction then
        if e.reference.object.script and e.reference.object.script.id == "Bed_Standard" then
            local tooltip = e.tooltip
            bed(tooltip, joinstatus, expelstatus, servicefaction, config.bed)
        else
            return
        end
    end
end
event.register("uiObjectTooltip", bedservice)

local function service(e)
	if tes3.onMainMenu() or not config.modActive then
		return
	end
    if tes3ui.getMenuOnTop().name ~= "MenuDialog" then
        return
    end

    if tes3ui.getServiceActor().object.baseObject.faction then
        local speakerfactionid = tes3ui.getServiceActor().object.baseObject.faction.id
        getactorfaction(speakerfactionid)
    else
        return
    end

	local loadstr = (e.block.name):sub((e.block.name):find("%a+$")):gsub("%a", string.upper, 1)

	if servicefaction and e.block.name:match("service_") then
		services(e.block, joinstatus, expelstatus, servicefaction, loadstr)
		--loadstring(loadstr..'(...)')(e.block, joinstatus, expelstatus, servicefaction, loadstr)
	end

end
event.register("uiPreEvent", service)




event.register("modConfigReady", function() config = require("kindi.faction service.config") require("kindi.faction service.mcm") end)







