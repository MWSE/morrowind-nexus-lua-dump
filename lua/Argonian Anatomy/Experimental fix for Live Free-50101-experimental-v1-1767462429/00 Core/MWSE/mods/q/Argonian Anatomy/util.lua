local config = require("q.Argonian Anatomy.config")

local log = mwse.Logger.new()
local this = {}

---@param reference tes3reference
local function hasCustomSkeletonLoaded(reference)
	if reference.tempData.argonianAnatomy
		and reference.tempData.argonianAnatomy.skeletonLoaded then
		return true
	end
	return false
end

---@param reference tes3reference
local function setCustomSkeletonLoaded(reference)
	local data = table.getset(reference.tempData, "argonianAnatomy", {})
	data.skeletonLoaded = true
end

---@param reference tes3reference
function this.isArgonian(reference)
	return config[reference.object.race.id:lower()] or false
end

---@param reference tes3reference
---@return boolean loaded
function this.loadSkeleton(reference)
	if not this.isArgonian(reference) then
		return false
	end
	if hasCustomSkeletonLoaded(reference) then
		log:trace("%s already has custom skeleton loaded, skipping.", reference.id)
		return false
	end

	local posBefore
	posBefore = reference.position:copy()
	tes3.loadAnimation({
		reference = reference,
		file = "zilla\\base_animkna.nif"
	})
	reference.position = posBefore
	log:debug("Loading custom skeleton for:\n\tId: %s,\n\tPosition before: %s,\n\tPosition after:  %s", reference.id,
		posBefore, reference.position)
	setCustomSkeletonLoaded(reference)
	return true
end

---@param reference tes3reference
---@return boolean removed
function this.removeSkeleton(reference)
	if not this.isArgonian(reference) then
		return false
	end

	-- We need to remove this skeleton if the player transformed into a werewolf
	tes3.loadAnimation({ reference = reference })

	return true
end

return this
