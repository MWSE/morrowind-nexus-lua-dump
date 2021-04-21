--[[ 	Public functions for mods to add and manipulate custom skills	]]--

local common = include("OtherSkills.common")
local this = {}

this.version = 1.4

mwse.log("[Skills Module] Initialised version %s", this.version)
--[[
	@id : id of the skill to update
	@skillVals : table of values to update. Whatever fields are included will be changed to the values in the table
	
	E.g to change the name and description of a skill:
		updateSkill ( "MySkill_ID", { name = "My Skill", description = "This is a new skill description" } )
]]--
local validUpdateFields = {
    name = true,
    lvlCap = true,
    icon = true,
    description = true,
    specialization = true,
    active = true,	
}
function this.updateSkill(id, skillVals)
	if common.otherSkills[id] then
        for key, val  in pairs(skillVals) do
            if validUpdateFields[key] then
                common.otherSkills[id][key] = val
            end
        end
        common.updateSkillList()
	else
		mwse.log("[Skills Module: ERROR] Skill %s does not exist", id)
	end
end

--[[
	@id : id of the skill to increment
	@skillVals : table containing a value and/or progress field. Whichever is included will be incremented by that amount
	-  Increasing value will only level up the skill. 
	-  Increasing progress will add experience to the skill, subject to 25% class specialization bonus, and count towards Player level progress.
	-  If no skillVals is provided, incrementSkills(id) will simply increment progress by 10
	-  Will only increment if skill.active is set to "active"
	
	E.g. to add experience when exercising a skill: 
		incrementSkill ( "MySkill_ID", { progress = 10 } )
	To increase skill by 5 levels:
		incrementSkill ( "MySkill_ID", { value = 5 } )
]]--
function this.incrementSkill(id, skillVals)

	if not skillVals then
		--default to 10 experience per "action"
		skillVals = {progress = 10}
	end



	if not common.otherSkills[id] then
		mwse.log("[Skills Module: ERROR] Skill %s does not exist", id)
		return
	elseif common.otherSkills[id].active ~= "active" then
		--Skill is not active, don't increment
		return
    else
        --25% faster for specialization skill
        local playerSpecialization = tes3.player.object.class.specialization
        if 
            skillVals.progress 
            and 
            playerSpecialization == 
            common.otherSkills[id].specialization 
        then
            skillVals.progress = skillVals.progress * 1.25
        end

        --if field was included, add it to current field value
        if skillVals.value  then
            mwse.log("Incrementing by %s", skillVals.value)
            common.otherSkills[id].value = common.otherSkills[id].value + skillVals.value
            mwse.log("New value = %s", common.otherSkills[id].value)
        end
        if skillVals.progress then
            common.otherSkills[id].progress = common.otherSkills[id].progress  + skillVals.progress
        end
		--Handle skill raises
		while common.otherSkills[id].progress >= 100 do
			if common.otherSkills[id].value < common.otherSkills[id].lvlCap then
				common.otherSkills[id].progress = 0
				common.otherSkills[id].value = common.otherSkills[id].value + 1
				mwscript.playSound{reference= tes3.player, sound="skillraise"}
				local message = string.format( tes3.findGMST(tes3.gmst.sNotifyMessage39).value, common.otherSkills[id].name, common.otherSkills[id].value ) 
                tes3.messageBox( message )--"Your %s skill increased to %d."

				--Handle governing attribute
				if common.otherSkills[id].attribute then	
					local adjustedAttribute = common.otherSkills[id].attribute + 1
					tes3.mobilePlayer.levelupsPerAttribute[ adjustedAttribute ] = tes3.mobilePlayer.levelupsPerAttribute[ adjustedAttribute ] + 1
				end
			else
				--Level cap reached
				common.otherSkills[id].value = common.otherSkills[id].lvlCap
				common.otherSkills[id].progress = 0
			end
		end
	end
	common.updateSkillList() 
end

--Clones and adds functions to skill
local function createSkillObject(skill)
	--Clone table and add functions to return to player
    local skillObject = {}
    local meta = {}
    setmetatable(skillObject, meta)
    function meta.__index(_, key)
        return skill[key]
    end

	function skillObject:levelUpSkill (value)
		this.incrementSkill(self.id, {value = value})
	end
    function skillObject:progressSkill(value)
		this.incrementSkill( self.id, {progress = value} ) 
	end
	
	function skillObject:updateSkill(skillVals)
		this.updateSkill(self.id, skillVals)
    end		

    
	return skillObject
end


function this.getSkill(id)
	return createSkillObject(common.otherSkills[id] or {})
end


--[[
	Create or activate a skill. 
	If the skill doesn't exist, it is created with values from @skill paramater
	If the skill already exists, simply activate it (unless the skill.active flag is specifically set to false)
]]--
function this.registerSkill(id, skill)

	if not id then 
		mwse.log("[Skills Module: ERROR] registerSkill needs at least an id")
		return
	end
	if not common.otherSkills then
		mwse.log("[Skills Module: ERROR] Skills table not loaded - trigger register using event 'OtherSkills:Ready'")
		return
	end	
	
	--exists: set active flag
	if common.otherSkills[id] then
		common.otherSkills[id].active = skill.active or "active"
	--doesnt' exiist: set values
	else
		skill = skill or {}
		skill.id				= id
		skill.name 				= skill.name 				or id
		skill.value 			= skill.value and math.floor(skill.value) 	or 5
		skill.base				= skill.value
		skill.current			= skill.value
		skill.progress 			= skill.progress 			or 0
		skill.lvlCap			= skill.lvlCap				or 100
		skill.icon 				= skill.icon 				or "Icons/OtherSkills/default.dds"
		skill.description 		= skill.description 		or ""
		skill.specialization 	= skill.specialization 		or tes3.specialization.invalid
		skill.active		 	= skill.active 				or "active"			
		--Store just the data on player ref
		common.otherSkills[id] 	= skill
	end
	common.updateSkillList()
	mwse.log("[Skills Module INFO] Registered skill %s with active flag set to: %s", skill.name, common.otherSkills[id].active )
	return common.otherSkills[id]

end


return this