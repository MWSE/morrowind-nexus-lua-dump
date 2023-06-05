local cf = mwse.loadConfig("Assassin's Crit", {dbrep = 5, hour = 12})

local function registerModConfig()		local tpl = mwse.mcm.createTemplate("Assassin's Crit")	tpl:saveOnClose("Assassin's Crit", cf)	tpl:register()		local page = tpl:createPage()	local var = mwse.mcm.createTableVariable
page:createSlider{label = "Reputation to start Dark Brotherhood attacks (5 default)", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "dbrep", table = cf}}
page:createSlider{label = "Minimum number of hours between attacks (12 default)", min = 0, max = 36, step = 1, jump = 6, variable = var{id = "hour", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local p, D

local function calcRestInterrupt(e) if e.resting and tes3.getJournalIndex{id = "TR_DBHunt"} < 100 then local reput = p.object.factionIndex	if reput >= cf.dbrep then
	local st = tes3.getSimulationTimestamp()
	if st - (D.DBAlast or 0) > cf.hour and math.random(100) < 20 + reput*2 then D.DBAcount = (D.DBAcount or 0) + 1		D.DBAlast = st		local AST, num
		if D.DBAcount > 9 then AST = {"db_assassin3", "db_assassin4"}						num = 3
		elseif D.DBAcount > 6 then AST = {"db_assassin2", "db_assassin3", "db_assassin4"}	num = table.choice{2,2,3}
		elseif D.DBAcount > 3 then AST = {"db_assassin1", "db_assassin2", "db_assassin3"}	num = table.choice{1,2,2}
		else AST = {"db_assassin1b", "db_assassin1b", "db_assassin1", "db_assassin1", "db_assassin2"}		num = table.choice{1,1,1,2} end
		tes3.wakeUp()		tes3.messageBox("You were awakened by a loud noise")
		for i = 1, num do mwscript.placeAtPC{object = table.choice(AST), distance = 128, direction = 1} end
	end
end end end		event.register("calcRestInterrupt", calcRestInterrupt)

local function loaded(e) p = tes3.player	 D = p.data
	mwscript.stopScript{script = "dbAttackScript"}
end		event.register("loaded", loaded)