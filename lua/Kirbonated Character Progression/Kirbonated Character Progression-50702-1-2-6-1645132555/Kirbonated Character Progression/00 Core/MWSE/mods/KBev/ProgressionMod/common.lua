local public = {}

public.modName = "Kirbonated Character Progression"
public.version = "1.2.2-Test"

public.info = function (message)
    local prepend = '[KB Progression Overhaul: INFO] '
    mwse.log(prepend .. message)
end

public.err = function(message)
	local prepend = '[KB Progression Overhaul: ERROR] '
	mwse.log(prepend .. message)
end

public.xpMsg = function(params)
	tes3.messageBox(params.message .. "\n" .. (params.xp or "nil") .. " xp")
	tes3.playSound({sound = "skillraise", loop = false, reference = tes3.player})
end

public.bossMonsters = {
	["dagoth araynys"] = true,
	["dagoth endus"] = true,
	["dagoth gilvoth"] = true,
	["dagoth odros"] = true,
	["dagoth Tureynul"] = true,
	["dagoth uthol"] = true,
	["dagoth vemyn"] = true,
	["dagoth_ur_1"] = true,
	["dagoth_ur_2"] = true,
	["vivec_god"] = true,
	["almalexia_warrior"] = true,
	["almalexia"] = true,
	["Imperfect"] = true,
	["BM_hircine_huntaspect"] = true,
	["BM_hircine_spdaspect"] = true,
	["BM_hircine_straspect"] = true,
	["BM_udyrfrykte"] = true,
}

public.questType = {}
public.guildQuestIDHeaders = { 
	"FG_",
	"MG_", 
	"TG_", 
	"TT_", 
	"MT_", 
	"IC%d+_", 
	"IC_", 
	"IL_", 
	"HH_", 
	"HR_", 
	"HT_", 
	"CO_", 
	"VA_",
}

public.loadedModules = {}

public.perkList = {}

return public