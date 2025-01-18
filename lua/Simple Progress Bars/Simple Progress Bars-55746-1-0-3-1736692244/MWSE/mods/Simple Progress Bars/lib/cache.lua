local MDIR = "Simple Progress Bars"

local mod = require(MDIR .. ".lib.mod")
local log = require(MDIR .. ".lib.log")
local mcm = require(MDIR .. ".mcm")
local i18n = require(MDIR .. ".lib.i18n")

local this = {tick = 0}
local armor = {}
local cache = {}
local timer = {}
local configError

local function getExtrapolation (id, data)
	local oldestTick = table.maxn(timer[id].log)

	local tickSpanOld = timer[id].log[oldestTick-1].tick - timer[id].log[oldestTick].tick
	local tickSpanCur = timer[id].log[1].tick - timer[id].log[2].tick
	if (not tes3ui.menuMode()) and (tickSpanOld > tickSpanCur*3 or tickSpanOld == 0) then
		table.remove(timer[id].log, oldestTick)
		oldestTick = oldestTick - 1
		log.debug("[".. this.tick .."] " .. id .. " Purge stale log data")
	end

	local time = timer[id].log[1].tick - timer[id].log[oldestTick].tick
	local delta = timer[id].log[1].val - timer[id].log[oldestTick].val

	if mod.config.logTicks then
		log.trace("[".. this.tick .."] " .. id .. " " .. data.progress .. " " .. delta)
	end

	if (delta == 0 or time == 0) then return end

	if (not data.reverse) then
		return math.round((data.required - data.progress) / delta * time)
	else
		return math.round((data.progress) / (- delta) * time)
	end
end

local function getTimer (id, data)
	timer[id] = timer[id] or {log = {}}
	timer[id].text = ""

	if (mod.config.showTime) then
		local progress = data.progress
		local required = data.required

		if (timer[id].log[1] and timer[id].log[1].tick < (this.tick - 60)) or
		   (not data.reverse and timer[id].cur and progress < timer[id].cur) or
		   (data.reverse and timer[id].cur and progress > timer[id].cur) then
			timer[id].log = {}
		end
	
		if (timer[id].cur and progress ~= timer[id].cur) then
			table.insert(timer[id].log, 1, {
				tick = this.tick,
				val = progress
			})
			table.remove(timer[id].log, 30)
		end

		timer[id].cur = progress

		if (timer[id].log[2] and timer[id].log[1].tick >= (this.tick - 30)) then
			local dumbAssess = getExtrapolation(id, data)
			if (not dumbAssess) then return end
			if (dumbAssess < 60) then
				timer[id].text = dumbAssess .. i18n("tooltip.timer.s")
			elseif (dumbAssess < 90) then
				timer[id].text = math.round(dumbAssess/60, 1) .. i18n("tooltip.timer.m")
			elseif (dumbAssess / 60 < 60) then
				timer[id].text = math.round(dumbAssess/60) .. i18n("tooltip.timer.m")
			else
				timer[id].text = math.round(dumbAssess/3600, 1) .. i18n("tooltip.timer.h")
			end
		end
	end
end

local function getLvlUpsPerAttribute ()
	local lvlups = tes3.mobilePlayer.levelupsPerAttribute
	local details = string.format("%2d", tes3.mobilePlayer.levelUpProgress)
		.. i18n("tooltip.lvl.of") .. 10
		.. i18n("tooltip.lvl.to") .. "\n\n"

	for id,val in pairs(lvlups) do
		local sid = mod.attributes[id]
		if not sid then
			log:error("Can't find attribute value " .. id)
		else
			local name = tes3.findGMST(tes3.gmst[sid]).value
			local mod = 0
			if (val < 1) then mod = 1
			elseif (val < 5) then mod = 2
			elseif (val < 8) then mod = 3
			elseif (val < 10) then mod = 4
			elseif (val >= 10) then mod = 5 end
			details = details .. string.format("%2d", val) .. " (x" .. mod .. ") " .. name .. "\n"
		end
	end

	return details
end


local function calcSkillProgress (skillID)
	local types = {0.75, 1, 1.25, 1.25}
	local classFavors = {1, 0.8}
	local baseGain = tes3.mobilePlayer.skillProgress[skillID]
	local skillLevel = tes3.mobilePlayer.skills[skillID].base
	local specializationMod = types[tes3.mobilePlayer.skills[skillID].type + 1]
	local favoredClassMod = classFavors[tes3.mobilePlayer.skills[skillID].type + 1]
	return baseGain / ( (skillLevel + 1) * specializationMod * favoredClassMod )
end

local function calcMaxRange(val, range)
	table.sort(range, function(x, y) return x > y end)
	local max = range[1]
	for _,i in pairs(range) do
		if (val <= i) then max = i end
	end
	return max
end

local function calcArmorStats ()
	local cur, max, equipped, potential, worst = 0, 0, 0, 0, 100
	armor.worst = {}
	armor.worstDetails = i18n("tooltip.ar.stats")

	for _,i in pairs(tes3.mobilePlayer.object.equipment) do
		if (i.object.objectType == 1330467393) then
			local ar = i.object:calculateArmorRating(tes3.mobilePlayer)
			local cond = i.itemData.condition
			local condMax = i.object.maxCondition
			local contribution = i.object.armorScalar
			local unarmoredSkill = tes3.mobilePlayer.unarmored.current
			equipped = equipped + 1
			curNorm = cond / condMax * 100
			cur = cur + ar * cond / condMax * contribution
			max = max + ar * contribution
			potential = potential + unarmoredSkill * unarmoredSkill * 0.0065 * contribution
			if curNorm < worst then
				if (mod.config.logTicks) then
					log.trace("[".. this.tick .."] " .. i.object.name .. " " .. curNorm .. "/" .. worst)
				end
				worst = curNorm
				armor.worst = i
			end
			armor.worstDetails = armor.worstDetails ..
				"\n" .. string.format("%3d", math.round(curNorm)) ..
				"% " .. i.object.name ..
				" " .. cond .. "/" .. condMax ..
				" (" .. math.round(ar * cond / condMax * contribution, 1) .. ")"
		end
	end

	armor.equipped = equipped
	armor.calculated = true

	armor.actualCur = tes3.mobilePlayer.armorRating
	armor.actualMax = armor.actualCur - cur + max
	armor.uaContribution = armor.actualCur - cur
	armor.uaPotential = armor.uaContribution + potential

	armor.tooltipDetails = i18n("tooltip.ar.stats") .. "\n" ..
		i18n("tooltip.ar.current") .. string.format("%.1f", armor.actualCur) .. "\n" ..
		i18n("tooltip.ar.max") ..	string.format("%.1f", armor.actualMax) .. "\n" ..
		i18n("tooltip.ar.ua") .. string.format("%.1f", armor.uaContribution) .. "\n" ..
		i18n("tooltip.ar.uamax") .. string.format("%.1f", armor.uaPotential) .. "\n"
end

local calcStats = {
	level = function (stat)
		return {
			cur = tes3.mobilePlayer.levelUpProgress,
			max = 10,
			icon = "icons\\" .. stat.icon,
			title = "tooltip.lvl.title",
			text = getLvlUpsPerAttribute(),
			note = "tooltip.lvl.note"
		}
	end,
	encumbrance = function (stat)
		return {
			cur = tes3.mobilePlayer.encumbrance.current,
			max = tes3.mobilePlayer.encumbrance.base,
			icon = "icons\\" .. stat.icon,
			reverseColors = true,
			title = "tooltip.weight.title",
			text = "tooltip.weight.note"
		}
	end,
	bounty = function (stat)
		local bounty = tes3.mobilePlayer.bounty
		return {
			cur = bounty,
			max = calcMaxRange(bounty, stat.range),
			icon = "icons\\" .. stat.icon,
			reverseColors = true,
			title = "tooltip.bounty.title",
			text = "tooltip.bounty.note"
		}
	end,
	rep = function (stat)
		local rep = tes3.mobilePlayer.object.reputation
		return {
			cur = rep,
			max = calcMaxRange(rep, stat.range),
			icon = "icons\\" .. stat.icon,
			title = "tooltip.rep.title",
			text = "tooltip.rep.note"
		}
	end,
	armor = function (stat)
		local cache = armor.calculated or calcArmorStats()
		if (armor.equipped >= 1) then
			return {
				cur = armor.actualCur,
				max = armor.actualMax,
				icon = "icons\\" .. stat.icon,
				title = "tooltip.ar.title",
				text = armor.tooltipDetails,
				note = i18n("tooltip.ar.note")
			}
		end
	end,
	armorToUnarmored = function (stat)
		local cache = armor.calculated or calcArmorStats()
		if (armor.equipped >= 1) then
			return {
				cur = armor.actualCur,
				max = armor.uaPotential,
				icon = "icons\\" .. stat.icon,
				title = "tooltip.arua.title",
				text = armor.tooltipDetails,
				note = i18n("tooltip.ar.note")
			}
		end
	end,
	armorWorst = function (stat)
		local cache = armor.calculated or calcArmorStats()
		if (armor.worst.object) then
			local cond = armor.worst.itemData.condition
			local condMax = armor.worst.object.maxCondition
			getTimer("armorWorst", {
				progress = cond,
				required = condMax,
				reverse = true
			})
			return {
				cur = cond,
				max = condMax,
				icon = "icons\\" .. armor.worst.object.icon,
				timer = timer.armorWorst.text,
				title = i18n("tooltip.arworst.title"),
				text = armor.worstDetails,
				note = "\n" .. i18n("tooltip.arw.note")
			}
		end
	end,
	test = function (stat)
		if (mod.config.showTime) then
			timer.test = timer.test or {}
			timer.test.text = this.tick .. "t"
		end
		return {
			cur = mod.config.testValue or 50,
			max = 100,
			icon = "icons\\s\\b_tx_s_frost_dmg.dds",
			reverseColors = mod.config.testRevert,
			timer = timer.test.text,
			title = i18n("tooltip.test.title")
		}
	end
}


local checkValue = {
	skill = function (id, skill)
		local idnum = skill.id
		local progress = tes3.mobilePlayer.skillProgress[idnum + 1]
		local required = tes3.mobilePlayer:getSkillProgressRequirement(idnum)
		local current = 100 * progress / required

		cache[id] = cache[id] or {}
		getTimer(id, {
			progress = progress,
			required = required
		})
	
		if (current ~= cache[id].cur) or (timer[id].text ~= cache[id].timer) then
			cache[id] = {
				name = skill.name,
				cur = current,
				max = 100,
				icon = skill.iconPath,
				timer = timer[id].text,
				skill = skill
			}
			this.updated = true
		end
		
		cache[id].shown = true
	end,

	slot = function (id, slot)
		local equipped
		local idnum = slot.id
		for _,i in pairs(tes3.mobilePlayer.object.equipment) do
			if (i.object.objectType == 1330467393) and
			   (i.object.slot == idnum) then
				equipped = i
				break
			end
		end
		if (equipped) then
			local item = equipped.object
			local durability = item.maxCondition
			local condition = equipped.itemData.condition

			cache[id] = cache[id] or {}
			getTimer(id, {
				progress = condition,
				required = durability,
				reverse = true
			})

			if (condition ~= cache[id].cur) or
			   (durability ~= cache[id].max) or
			   (timer[id].text ~= cache[id].timer) then
				cache[id] = {
					name = slot.name,
					cur = condition,
					max = durability,
					icon = "icons\\" .. item.icon,
					timer = timer[id].text,
					itemData = equipped.itemData,
					item = item,
				}
				this.updated = true
			end

			cache[id].shown = true
		end
	end,

	stat = function (id, stat)
		cache[id] = cache[id] or {}
		local result = calcStats[id](stat)
		if (not result) then return end
		if (result.cur ~= cache[id].cur) or
		   (result.max ~= cache[id].max) or
		   (result.reverseColors ~= cache[id].reverseColors) or
		   (timer[id] and timer[id].text ~= cache[id].timer) then
			cache[id] = result
			cache[id].name = stat.name
			this.updated = true
		end
		
		cache[id].shown = true
	end
}


local function resetCacheState()
	this.updated = false
	for id,i in pairs(cache) do
		i.shown = false
	end
end

local function updateCache ()
	resetCacheState()
	armor.calculated = false

	if mod.config.logTicks then
		log:debug("[".. this.tick .."] Cache update initialize")
	end
	
	if not mcm.values then mcm.getDisplayedList() end

	for n,_ in pairs(mod.config.values) do
		local val = mcm.values[n]
		if (val) then
			checkValue[val.type](val.id, val.item)
		else
			if not configError then
				configError = true
				log:error("Error indexing value " .. n)
				log:error("The mod configuration appears to be broken")
				log:error("Consider deleting your config file!")
			elseif mod.config.logTicks then
				log:error("[".. this.tick .."] Can't index value " .. n)
			end
		end
	end

	if (mod.config.testBarShow) then
		checkValue["stat"]("test", {name = i18n("tooltip.test.title")})
	end

	return this.updated
end


this.update = updateCache
this.data = cache
this.timer = timer

return this
