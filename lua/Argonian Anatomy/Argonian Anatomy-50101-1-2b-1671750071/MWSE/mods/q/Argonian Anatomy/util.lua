local config = require("q.Argonian Anatomy.config")

local this = {}

---@param reference tes3reference
---@return boolean argonian
function this.isArgonian(reference)
	return config[reference.object.race.id:lower()] or false
end

---@param reference tes3reference
---@return boolean loaded
function this.loadSkeleton(reference)
	if this.isArgonian(reference) then

		tes3.loadAnimation{
			reference = reference,
			file = "zilla\\base_animkna.nif"
		}
		return true
	end

	return false
end

---@param reference tes3reference
---@return boolean removed
function this.removeSkeleton(reference)
	if this.isArgonian(reference) then

		tes3.loadAnimation{
			reference = reference,
			-- This is a workaround because tes3.loadAnimations
			-- doesn't account for werewolf transformations.
			file = "Wolf\\Skin.nif"
		}

		return true
	end

	return false
end

return this