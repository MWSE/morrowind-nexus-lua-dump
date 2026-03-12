function getSkillLevel()
	if S_USE_MINING_SKILL and G_skillRegistered then
		local skillStat = I.SkillFramework.getSkillStat(MINING_SKILL_ID)
		return skillStat and skillStat.modified or 5
	else
		return types.NPC.stats.skills.armorer(self).modified
	end
end

function grantSkillExp(amount)
	if S_USE_MINING_SKILL and G_skillRegistered then
		I.SkillFramework.skillUsed(MINING_SKILL_ID, { skillGain = amount * 3 * S_EXP_MULT/100, useType = 1, scale = nil })
	else
		I.SkillProgression.skillUsed('armorer', { skillGain = amount * S_EXP_MULT/100, useType = I.SkillProgression.SKILL_USE_TYPES.Armorer_Repair, scale = nil })
	end
	core.sendGlobalEvent("SimplyMining_receivePlayerSkill", {self, getSkillLevel()})
end

function isTheft(object)
	if object.owner.recordId then
		return true
	elseif object.owner.factionId and types.NPC.getFactionRank(self, object.owner.factionId) == 0 then
		return true
	elseif object.owner.factionId and types.NPC.getFactionRank(self, object.owner.factionId) < object.owner.factionRank then
		return true
	end
	return false
end

function calcChance(item)
	if not db_difficulties[item] then
		return 1
	end
	local armorerSkill = getSkillLevel()
	if S_USE_MINING_SKILL and G_skillRegistered then
		armorerSkill = armorerSkill + 5
	end
	local difficulty = db_difficulties[item]
	if item == "ingred_diamond_01" then -- 40
		local addExp = math.min(1,armorerSkill/difficulty)^1.5-0.2
		local addLinear = armorerSkill/difficulty/5
		local res = 0.5+ addLinear + addExp
		if res > 1 then
			res = res ^ 0.7
		end
		res = res/1.2
		res = (res * (1-S_YIELD_EQUALIZER/100) + 1.5 * (S_YIELD_EQUALIZER/100)) * S_YIELD_MULT/100
		return res
	else
		local addExp = math.min(1,armorerSkill/difficulty)^2.5		
		local addLinear = armorerSkill/difficulty/3.33
		local res = 0.03+ addLinear + addExp
		if res > 1 then
			res = res ^ 0.55
		end
		res = (res * (1-S_YIELD_EQUALIZER/100) + 1.5 * (S_YIELD_EQUALIZER/100)) * S_YIELD_MULT/100
		return res
	end
end

function randomNode(shiftDifficulty)
	shiftDifficulty = shiftDifficulty or 0
	local scaleFactor = (S_ORE_LEVEL_SCALING or 25) / 100
	local skillLevel = getSkillLevel()

    local adjustedWeights = {}
    local totalWeight = 0
    for i, entry in ipairs(db_weights) do
        -- Red Mountain
        local w = entry.weight + shiftDifficulty

        if scaleFactor > 0 then
            local diff = db_difficulties[entry.item] or 30
            local distance = math.abs(diff - skillLevel)
            local closeness = math.exp(-(distance * distance) / 450) -- sigma ~15
            w = w * (1 - scaleFactor + (1 + closeness * 8) * scaleFactor)
        end

        w = math.max(0.5, w)
        adjustedWeights[i] = w
        totalWeight = totalWeight + w
    end
    
    local random = math.random() * totalWeight
    local currentWeight = 0
    
    for i, entry in ipairs(db_weights) do
        currentWeight = currentWeight + adjustedWeights[i]
        if random <= currentWeight then
            local nodes = db_nodes[entry.item]
            if nodes and #nodes > 0 then
				local rnd = math.random(1, #nodes)
                return nodes[rnd]
            else
				print("ERROR: ",nodes,entry.item)
                return "sm_coal_vein"
            end
        end
    end
    
	print("ERROR: fallback sm_coal_vein")
    return "sm_coal_vein"
end



function view(t, depth)
	depth = depth or 0
	local depthStr = ""


	if depth == 0 then 
		print("{")
		depth = depth + 1
	end
	
	for i=1, depth do
		depthStr = depthStr.."   "
	end
	
	-- collect and sort keys, "id" always first
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end
	table.sort(keys, function(a, b)
		local priority = { id = 1, type = 2 }
		return (priority[a] or math.huge) < (priority[b] or math.huge)
			or (priority[a] == priority[b] and tostring(a) < tostring(b))
	end)

	for _, a in ipairs(keys) do
		local b = t[a]
		local key = type(a) == "string" and (a:match("^[%a_][%w_]*$") and a or '["'..a..'"]') or "["..tostring(a).."]"
		if type(b) == "string" then
			print(depthStr..key..' = "'..b..'",')
		elseif type(b) == "table" then
			if not next(b) then
				print(depthStr..key.." = {},")
			else
				print(depthStr..key.." = {")
				view(b, depth+1)
				print(depthStr.."},")
			end
		else
			print(depthStr..key.." = "..tostring(b)..",")
		end
	end

	if depth == 1 then 
		depth = 0
		print("},") 
	end
end