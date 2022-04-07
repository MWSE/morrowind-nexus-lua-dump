local config = mwse.loadConfig("MWSE-SkillCap")
local skillCap = config.SkillCap

local function saveConfig()
	local values = {}
	for k, _ in pairs(config) do
		values[k] = config[k]
	end
	mwse.saveConfig("MWSE-SkillCap", values)
end

local function capAllSkills()
	--tes3.messageBox("Cap all skills")
	tempTable = {}
	tempTableDiff = {}
	
	for i, v in ipairs(tes3.mobilePlayer.skills) do
		table.insert(tempTable, v.base + 0)
		tempTableDiff[i] = (v.current - v.base)
	end
	
	for i, v in ipairs(tes3.mobilePlayer.skills) do
		tempTableLength = #(tempTable)
		if (v.base > skillCap) then
			tes3.setStatistic( {reference = tes3.player, skill = (i-1), value = skillCap} )
			tes3.modStatistic( {reference = tes3.player, skill = (i-1), current = tempTableDiff[i]} )
		end
	end
end

local function capRaisedSkill(e)
	capAllSkills()
end

local config = {
	name = "MWSE Skill Capper",
	template = "Template",
	pages = {
		{
			label = "SideBar Page",
			class = "SideBarPage",
			components = {
				{
					label = "Skill Cap Limit: %s",
					class = "Slider",
					description = "Any skills above this number will be capped. They will still level up.",
					min = 1,
					max = 255,
					step = 1,
					jump = 10,
					variable = {
						id = "SkillCap",
						class = "TableVariable",
						table = config,
					},
				},
			},
			sidebarComponents = {
				{
					label = "Notice:",
					class = "Info",
					text = "This will not take effect until you save and reload the game.",
				},
			},
		},
	},
	onClose = saveConfig,
}

local function registerModConfig()
	mwse.mcm.registerMCM(config)
end

event.register("loaded", capAllSkills)
event.register("skillRaised", capRaisedSkill)

event.register("modConfigReady", registerModConfig)