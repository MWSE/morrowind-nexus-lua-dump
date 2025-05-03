--------------------------------------
-- Helmet Fixes
local offset = tes3vector3.new(2.8, 1.2, 0)
local rotation = tes3vector3.new(0, 0, 12)
local scale = 0.1
--------------------------------------

local positionStart
local rotationStart
local scaleStart

local nagaRaceId = "godzilla"

local m = tes3matrix33.new()
m:fromEulerXYZ(
	math.rad(rotation.x),
	math.rad(rotation.y),
	math.rad(rotation.z)
)

---@param eulerAngles tes3vector3
---@return tes3matrix33
local function getRotationMatrix(eulerAngles)
	local rot = tes3matrix33.new()
	rot:fromEulerXYZ(
		math.rad(eulerAngles.x),
		math.rad(eulerAngles.y),
		math.rad(eulerAngles.z)
	)
	return rot
end

---@param ref tes3reference
---@return boolean
local function isNaga(ref)
	return (
		ref.object.race and
		ref.object.race.id:lower() == nagaRaceId or false
	)
end


local function moveHelmNode(e)
	local ref = e.timer.data.ref
	if not ref then return end
	local manager = ref.bodyPartManager
	local helmBodyPart = manager:getActiveBodyPart(tes3.activeBodyPartLayer.armor, tes3.activeBodyPart.hair)
	if not helmBodyPart then return end

	local node = helmBodyPart.node
	if not positionStart then
		positionStart = node.translation:copy()
	end
	if not rotationStart then
		rotationStart = node.rotation:copy()
	end
	if not scaleStart then
		scaleStart = node.scale
	end

	node.translation = positionStart:copy() + offset
	local rot = getRotationMatrix(rotation)
	node.rotation = rot * rotationStart
	node.scale = scaleStart + scale
	node.parent:update()
end

---@param ref tes3reference
local function moveHelm(ref)
	local helm = tes3.getEquippedItem({
			actor = ref,
			objectType = tes3.objectType.armor,
			slot = tes3.armorSlot.helmet
		})
	if helm then
		timer.start({
			type = timer.real,
			duration = 0.0000001,
			iterations = 1,
			data = {
				ref = ref
			},
			callback = moveHelmNode
		})
	end
end

local function moveIf(e)
	if isNaga(e.reference) then
		moveHelm(e.reference)
	end
end

event.register(tes3.event.equipped, moveIf)
event.register(tes3.event.unequipped, moveIf)
event.register(tes3.event.mobileActivated, moveIf)
event.register(tes3.event.loaded, function()
	timer.frame.delayOneFrame(function()
		moveHelm(tes3.player)
	end)
end)

---------------------------
-- PCRace Fix
---------------------------
local raceCheckScriptID = "RaceCheck"

local function updatePCRace()
	local pcRaceID = tes3.player.object.race.id:lower()
	local PCRace = tes3.findGlobal("PCRace")

	if pcRaceID == "argonian" or pcRaceID == "godzilla" then
		PCRace.value = 1
	elseif pcRaceID == "breton" then
		PCRace.value = 2
	elseif pcRaceID == "dark elf" then
		PCRace.value = 3
	elseif pcRaceID == "high elf" then
		PCRace.value = 4
	elseif pcRaceID == "imperial" then
		PCRace.value = 5
	elseif pcRaceID == "khajiit" then
		PCRace.value = 6
	elseif pcRaceID == "nord" then
		PCRace.value = 7
	elseif pcRaceID == "orc" then
		PCRace.value = 8
	elseif pcRaceID == "redguard" then
		PCRace.value = 9
	elseif pcRaceID == "wood elf" then
		PCRace.value = 10
	end

	mwscript.stopScript({ script = raceCheckScriptID })
end


event.register(tes3.event.initialized, function()
	mwse.overrideScript(raceCheckScriptID, updatePCRace)
end)
------------------------