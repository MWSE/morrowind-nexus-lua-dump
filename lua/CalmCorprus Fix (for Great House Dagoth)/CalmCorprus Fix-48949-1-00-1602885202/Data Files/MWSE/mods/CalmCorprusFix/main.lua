local configPath = "CalmCorprusFix"
local defaultConfig = {
	IsBlocked = {
		["ascended_sleeper"]= true,
		["ash_ghoul"]= true,
		["ash_ghoul_fgr"]= true,
		["ash_ghoul_ganel"]= true,
		["ash_ghoul_mulyn"]= true,
		["ash_slave"]= true,
		["ash_zombie"]= true,
		["skeleton_vemynal"]= true,
		["ash_zombie_fgaz"]= true,
		["corprus_lame"]= true,
		["corprus_lame_fyr01"]= true,
		["corprus_lame_fyr02"]= true,
		["corprus_lame_fyr03"]= true,
		["corprus_lame_fyr04"]= true,
		["corprus_lame_morvayn"]= true,
		["corprus_stalker"]= true,
		["corprus_stalker_berwen"]= true,
		["corprus_stalker_danar"]= true,
		["corprus_stalker_fgcs"]= true,
		["corprus_stalker_fyr01"]= true,
		["corprus_stalker_fyr02"]= true,
		["corprus_stalker_fyr03"]= true,
		["corprus_stalker_morvayn"]= true,
		["dagoth aladus"]= true,
		["dagoth araynys"]= true,
		["dagoth baler"]= true,
		["dagoth daynil"]= true,
		["dagoth delnus"]= true,
		["dagoth drals"]= true,
		["dagoth draven"]= true,
		["dagoth elam"]= true,
		["dagoth endus"]= true,
		["dagoth fals"]= true,
		["dagoth fandril"]= true,
		["dagoth felmis"]= true,
		["dagoth fervas"]= true,
		["dagoth fovon"]= true,
		["dagoth galmis"]= true,
		["dagoth garel"]= true,
		["dagoth gares"]= true,
		["dagoth gilvoth"]= true,
		["dagoth girer"]= true,
		["dagoth goral"]= true,
		["dagoth ienas"]= true,
		["dagoth irvyn"]= true,
		["dagoth malan"]= true,
		["dagoth mendras"]= true,
		["dagoth molos"]= true,
		["dagoth mulis"]= true,
		["dagoth muthes"]= true,
		["dagoth nilor"]= true,
		["dagoth odros"]= true,
		["dagoth ralas"]= true,
		["dagoth rather"]= true,
		["dagoth reler"]= true,
		["dagoth soler"]= true,
		["dagoth tanis"]= true,
		["dagoth tureynul"]= true,
		["dagoth ulen"]= true,
		["dagoth uthol"]= true,
		["dagoth uvil"]= true,
		["dagoth vaner"]= true,
		["dagoth velos"]= true,
		["dagoth vemyn"]= true,
		["dagoth_hlevul"]= true,
		["dagoth_ur_1"]= true,
		["dagoth_ur_2"]= true,
		["dreamer"]= true,
		["dreamer guard"]= true,
		["dreamer priest"]= true,
		["dreamer prophet"]= true,
		["dreamer worker"]= true,
		["dreamer_02"]= true,
		["dreamer_04"]= true,
		["dreamer_05"]= true,
		["dreamer_06"]= true,
		["dreamer_dead"]= true,
		["dreamer_f_01"]= true,
		["dreamer_f_key"]= true,
		["dreamer_ranged"]= true,
		["dreamer_talker"]= true,
		["dreamer_talker01"]= true,
		["dreamer_talker02"]= true,
		["dreamer_talker03"]= true,
		["dreamer_talker04"]= true,
		["dreamer_talker05"]= true,
		["dreamer_talker06"]= true,
		["dreamer_talker07"]= true,
		["dreamer_talker08"]= true,
		["dreamer_talker09"]= true,
		["dreamer_talker10"]= true,
		["dreamer_talker11"]= true,
		["dreamer_talker12"]= true
	}
}
local config = mwse.loadConfig(configPath, defaultConfig)

local function Mobile(e)
	if (tes3.getJournalIndex({ id = "HD_Recruited" }) == nil) or (tes3.getJournalIndex({ id = "HD_Recruited" }) < 10) then
		return
	end

	if (config.IsBlocked[e.reference.baseObject.id:lower()] ~= nil) then
		e.mobile.fight = 0
		e.mobile.alarm = 0
	end
end

event.register("mobileActivated", Mobile)

----MCM
local function registerModConfig()

	local template = mwse.mcm.createTemplate({ name = "CalmCorprus Fix" })
	template:saveOnClose(configPath, config)

	template:createExclusionsPage{
		label = "Whitelist",
		leftListLabel = "Affected",
		rightListLabel = "Unaffected",
		description = "Select the NPCs and creatures who will not attack you if you fully succumb to Corprus through GHD.",
		showAllBlocked = false,
		variable = mwse.mcm:createTableVariable{
			id = "IsBlocked",
			table = config,
		},

		filters = {
			{
				label = "NPCs",
				type = "Object",
				objectType = tes3.objectType.npc
			},
			{
				label = "Creatures",
				type = "Object",
				objectType = tes3.objectType.creature
			}
		}
	}

	mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)