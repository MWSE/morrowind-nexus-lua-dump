--[[Tramatic Experience
	mod makes trama hurt player on collision

	authors = {
	["Greatness7"] = {collision script},
	["RedFurryDemon"] = {scripting}}
	name of the mod was shamelessly stolen from R-Zero

	in case of bugs, please ping RFD on discord
]]--

local abs = math.abs

local timerRunning = false

--you can decrease it if you have a good PC; increase if there's an FPS hit
local timerInterval = 0.25
local tramaTimer
local tramaCount
local tramaDamage = 2
local debugMode = false

local tramaList = {
	["tramaroot_01"] = true,
	["tramaroot_02"] = true,
	["tramaroot_03"] = true,
	["tramaroot_04"] = true,
	["tramaroot_05"] = true,
	["tramaroot_06"] = true,
	["contain_trama_shrub_01"] = true,
	["contain_trama_shrub_02"] = true,
	["contain_trama_shrub_03"] = true,
	["contain_trama_shrub_04"] = true,
	["contain_trama_shrub_05"] = true,
	["contain_trama_shrub_06"] = true,
}

local function obb(ref)
    local box = ref.object.boundingBox
    local center = (box.min + box.max) * 0.5
    local t = ref.sceneNode.worldTransform
    return {
        pos = (t.rotation * t.scale * center) + t.translation,
        axis = t.rotation:transpose(),
        extents = box.max - center,
    }
end

local function gsp(pos, plane, obb1, obb2)
    local a1, a2 = obb1.axis, obb2.axis
    local e1, e2 = obb1.extents, obb2.extents
    return abs(pos:dot(plane)) > (abs((a1.x * e1.x):dot(plane)) +
                                  abs((a1.y * e1.y):dot(plane)) +
                                  abs((a1.z * e1.z):dot(plane)) +
                                  abs((a2.x * e2.x):dot(plane)) +
                                  abs((a2.y * e2.y):dot(plane)) +
                                  abs((a2.z * e2.z):dot(plane)))
end

local function intersects(obb1, obb2)
    local pos = (obb2.pos - obb1.pos)
    local a1, a2 = obb1.axis, obb2.axis
    return not (gsp(pos, a1.x, obb1, obb2) or
                gsp(pos, a1.y, obb1, obb2) or
                gsp(pos, a1.z, obb1, obb2) or
                gsp(pos, a2.x, obb1, obb2) or
                gsp(pos, a2.y, obb1, obb2) or
                gsp(pos, a2.z, obb1, obb2) or
                gsp(pos, a1.x:cross(a2.x), obb1, obb2) or
                gsp(pos, a1.x:cross(a2.y), obb1, obb2) or
                gsp(pos, a1.x:cross(a2.z), obb1, obb2) or
                gsp(pos, a1.y:cross(a2.x), obb1, obb2) or
                gsp(pos, a1.y:cross(a2.y), obb1, obb2) or
                gsp(pos, a1.y:cross(a2.z), obb1, obb2) or
                gsp(pos, a1.z:cross(a2.x), obb1, obb2) or
                gsp(pos, a1.z:cross(a2.y), obb1, obb2) or
                gsp(pos, a1.z:cross(a2.z), obb1, obb2))
end


local function test()
    local playerOBB = obb(tes3.player)
    for ref in tes3.player.cell:iterateReferences() do
		if (tramaList[ref.object.id]) then
			if ref.sceneNode and ref.object.boundingBox and not ref.disabled then
				if ref.position:distance(tes3.player.position) < 1024 then
					local targetOBB = obb(ref)
					if intersects(playerOBB, targetOBB) then
						tes3.mobilePlayer:applyHealthDamage(tramaDamage)
						if (debugMode == true) then
							tes3.messageBox("Collision: %s", ref)
							mwse.log("Collision: %s", ref)
						end
					end
				end
			end
		end
    end
end

local function checkPlayerCell(e)
if (debugMode == true) then
	tes3.messageBox("Checking for trama")
end
	tramaCount = 0
	for i, cells in ipairs(tes3.getActiveCells()) do
		for ref in cells:iterateReferences() do
			local name = ref.id:lower()
			if (tramaList[name]) then
				tramaCount = tramaCount + 1
				if (debugMode == true) then
					tes3.messageBox("Found %.0f trama", tramaCount)
				end
			end
		end
	end
	if (tramaCount > 0) then
		if (debugMode == true) then
			tes3.messageBox("Trama-infested cell")
		end
		if (timerRunning == false) then
			tramaTimer = timer.start{iterations=-1, duration=0.5, callback=test}
			timerRunning = true
		end
	else
		if (debugMode == true) then
			tes3.messageBox("Trama-free cell")
		end
		if (timerRunning == true) then
			tramaTimer:cancel()
			timerRunning = false
		end
	end
end

local function initialized()
	event.register("cellChanged", checkPlayerCell)
	mwse.log("[Tramatic Experience] initialized")
	if (debugMode == true) then
		tes3.messageBox("[Tramatic Experience] initialized")
	end
end

event.register("initialized", initialized)
