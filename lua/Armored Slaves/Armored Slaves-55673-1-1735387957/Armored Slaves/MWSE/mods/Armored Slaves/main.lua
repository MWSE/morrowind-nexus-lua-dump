local L = {Foots = {[15] = true, [16] = true}, BeastRace = {}}

local function spellResist(e) local eid = e.effect.id
	if (eid == 128 or eid == 129) then local r = e.target.object.race
		if r and L.BeastRace[r] then	r.isBeast = false		timer.delayOneFrame(function() r.isBeast = true end) end
	end
end		event.register("spellResist", spellResist)


local function equip(e)	 local o = e.item
	if o.objectType == tes3.objectType.armor then
		if o.slot == 5 or o.isClosedHelmet then		local r = e.reference.object.race
			if r and L.BeastRace[r] then r.isBeast = false			--tes3.messageBox("%s   beast equip!", e.item.id)
				timer.delayOneFrame(function() r.isBeast = true end, timer.real)
			end
		end
	end
end 	event.register("equip", equip)


local function bodyPartAssigned(e)
	if L.Foots[e.index] and e.object then	local rob = e.reference.object		local tab = L.BeastRace[rob.race]
		if tab then
			e.bodyPart = tab[rob.female and "ff" or "mf"]			--rob.race[rob.female and "femaleBody" or "maleBody"].foot
			--tes3.messageBox("Replace   ind = %s", e.index)
		end
	end
end		event.register("bodyPartAssigned", bodyPartAssigned)

local function loaded(e)	if not e.newGame then	local p = tes3.player
	if L.BeastRace[p.object.race] then p:updateEquipment() end
end end 	event.register("loaded", loaded)


local function initialized(e)
	for _, race in pairs(tes3.dataHandler.nonDynamicData.races) do if race.isBeast then
		L.BeastRace[race] = {id = race.id, mf = race.maleBody.foot, ff = race.femaleBody.foot}
		--tes3.messageBox("beast race = %s", race.id)
	end end
end 	event.register("initialized", initialized)