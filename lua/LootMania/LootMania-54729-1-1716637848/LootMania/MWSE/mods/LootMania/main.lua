local cf = mwse.loadConfig("LootMania", {expmult = 1, chmult = 1})
local L = {}	local G = {}
local p, mp

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("LootMania")	tpl:saveOnClose("LootMania", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createDecimalSlider{label = "Security experience multiplier for finding loot", min = 0, max = 10, variable = var{id = "expmult", table = cf}}
p0:createDecimalSlider{label = "Chance to find additional loot multiplier", min = 0, max = 2, variable = var{id = "chmult", table = cf}}
end		event.register("modConfigReady", registerModConfig)

L.PickLL = function(list)
	local l = list.list		local new = l[math.random(#l)].object
	if new.value then return new else return L.PickLL(new) end
end

local function leveledItemPicked(e) local list = e.list		local r = e.spawner		local rob = r.object
	if not tes3ui.menuMode() and rob.objectType == tes3.objectType.container and not rob.organic then
		if not r.modified or G.CurConT then	local ob = e.pick
			if not G.CurConT then G.CurConT = timer.delayOneFrame(function() r.modified = true	G.CurConT = nil		--tes3.messageBox("timer expired")
			end, timer.real) end
			
			if ob then mp:exerciseSkill(18, ob.value/1000 * cf.expmult) end
			local chance = (mp.luck.base * 0.5 + mp:getSkillValue(18) * 0.5) * cf.chmult		local New
			if chance > math.random(100) then
				New = L.PickLL(list)		tes3.addItem{reference = r, item = New}		mp:exerciseSkill(18, New.value/1000 * cf.expmult)
			end
			
			--tes3.messageBox("%s    %s (%s)      modr = %s   New = %s (%d)", list, ob, ob and ob.value, r.modified, New, chance)
		end
	end
end		event.register("leveledItemPicked", leveledItemPicked)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer
end		event.register("loaded", loaded)