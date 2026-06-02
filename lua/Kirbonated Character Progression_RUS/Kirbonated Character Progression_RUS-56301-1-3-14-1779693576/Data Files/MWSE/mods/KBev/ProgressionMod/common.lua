local public = {}

public.modName = "Классическая система развития"
public.version = 20230117

local doDBG = false

public.info = function (message)
    local prepend = '[KB Progression Overhaul: INFO] '
    mwse.log(prepend .. message)
	if doDBG then
		tes3ui.logToConsole(prepend .. message, false)
	end
end

public.dbg = function (message)
	if not doDBG then return end
    local prepend = '[KB Progression Overhaul: DEBUG] '
    mwse.log(prepend .. message)
	tes3ui.logToConsole(prepend .. message, false)
end

public.err = function(message)
	local prepend = '[KB Progression Overhaul: ERROR] '
	mwse.log(prepend .. message)
	if doDBG then
		tes3ui.logToConsole(prepend .. message, false)
	end
end

public.xpMsg = function(params)
	tes3.messageBox((params.message or "Опыта получено") .. "\n" .. (params.xp or "nil") .. " опыта")
	tes3.playSound({sound = "skillraise", loop = false, reference = tes3.player})
end

public.playerData = {
	version = public.version,
	xp = 0,
	levelPoints = {atr = 0, prk = 0, mjr = 0, mnr = 0, msc = 0},
	incPoints = {atr = 0, prk = 0, mjr = 0, mnr = 0, msc = 0}, --controls flat bonuses to level points
	pntMult = {atr = 1, prk = 1, mjr = 1, mnr = 1, msc = 1}, --controls multipliers to level points
	wrldCellsVisited = {}, --stores worldspace cells for the exploration XP tracker
	questsCompleted = {}, --stores questIDs after they've been completed
	perkData = {},
}

public.defaultPlayerData = { --this is a hacky bandaid solution to me being an idiot and referencing playerData incorrectly throughout development
	version = public.version,
	xp = 0,
	levelPoints = {atr = 0, prk = 0, mjr = 0, mnr = 0, msc = 0},
	incPoints = {atr = 0, prk = 0, mjr = 0, mnr = 0, msc = 0}, --controls flat bonuses to level points
	pntMult = {atr = 1, prk = 1, mjr = 1, mnr = 1, msc = 1}, --controls multipliers to level points
	wrldCellsVisited = {}, --stores worldspace cells for the exploration XP tracker
	questsCompleted = {}, --stores questIDs after they've been completed
	perkData = {},
}

public.perks = {}

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
	--Skyrim Home of the Nords Guild Quests
	"Sky_qRe_KWFG",
	"Sky_qRe_KWTG",
	"Sky_qRe_KWMG",
	"Sky_qRe_DSTG",
	"Sky_qRe_DSMG",
	--Project Cyrodiil Guild Quests
	"PC_m1_TG",
	"PC_m1_MG",
	"PC_m1_K1",
	"PC_m1_IP",
	"PC_m1_FG",
	"PC_m1_AFP",
	--Wyrmhaven Guild Quests
	"WYRM_",
}

return public