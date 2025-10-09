local public = {}

public.modName = "MWSE Perk System"
public.version = "1.0"

local doDBG = true

public.info = function (message)
    local prepend = '[MWSE Perk System: INFO] '
    mwse.log(prepend .. message)
	if doDBG then
		tes3ui.logToConsole(prepend .. message, false)
	end
end

public.dbg = function (message)
	if not doDBG then return end
    local prepend = '[MWSE Perk System: DEBUG] '
    mwse.log(prepend .. message)
	tes3ui.logToConsole(prepend .. message, false)
end

public.err = function(message)
	local prepend = '[MWSE Perk System: ERROR] '
	mwse.log(prepend .. message)
	if doDBG then
		tes3ui.logToConsole(prepend .. message, false)
	end
end

public.playerData = {
	perks = {},
	activatedPerks = {},
}
public.defaultplayerData = {
	perks = {},
	activatedPerks = {},
}

public.perkList = {}

return public