local world = require('openmw.world')
local core = require('openmw.core')
local util = require('openmw.util')

print("[pxm_airship][global] LOADED")

local flyingShipVisual = nil

-- Offsets from the flying ship visual origin to the standalone animated parts.
-- These are in ship-local space:
-- forward = +front / -rear
-- side    = +right / -left
-- z       = up/down
local rotorForwardOffset = 34.5
local rotorSideOffset = 0
local rotorZOffset = -317

local rudderForwardOffset = 90
local rudderSideOffset = 0
local rudderZOffset = -258.40

local visualBackOffset = 350
local visualZOffset = 450
local visualYawOffset = math.rad(180)
local cabinReturnCell = nil
local cabinReturnPosition = nil
local cabinReturnRotation = nil

local function removeFlyingShipVisual()
    if flyingShipVisual and flyingShipVisual:isValid() then
        flyingShipVisual:remove()
    end

    flyingShipVisual = nil
end

local function createObjectSafe(lowerId, originalId)
    local ok, obj = pcall(world.createObject, lowerId, 1)

    if ok and obj then
        return obj
    end

    ok, obj = pcall(world.createObject, originalId, 1)

    if ok and obj then
        return obj
    end

    print("[pxm_airship][global] ERROR: failed to create object " .. tostring(originalId))
    return nil
end

local function offsetFromShipOrigin(x, y, z, yaw, forwardOffset, sideOffset, zOffset)
	return
		x + math.sin(yaw) * forwardOffset + math.cos(yaw) * sideOffset,
		y + math.cos(yaw) * forwardOffset - math.sin(yaw) * sideOffset,
		z + zOffset
end

local function placeAirshipPartVisuals(data)
	local player = world.players[1]
	if not player then
		return
	end

	local g = world.mwscript.getGlobalVariables(player)
	if not g then
		return
	end

	data = data or {}

	local x = tonumber(data.x) or player.position.x
	local y = tonumber(data.y) or player.position.y
	local z = tonumber(data.z) or player.position.z
	local yawRad = tonumber(data.yaw) or 0
	local yawDeg = math.deg(yawRad)
	local rudderAngleDeg = math.deg(tonumber(data.rudderAngle) or 0)

	local rotorX, rotorY, rotorZ = offsetFromShipOrigin(
		x,
		y,
		z,
		yawRad,
		rotorForwardOffset,
		rotorSideOffset,
		rotorZOffset
	)

	local rudderX, rudderY, rudderZ = offsetFromShipOrigin(
		x,
		y,
		z,
		yawRad,
		rudderForwardOffset,
		rudderSideOffset,
		rudderZOffset
	)

	g.pxm_airship_rotor_x = rotorX
	g.pxm_airship_rotor_y = rotorY
	g.pxm_airship_rotor_z = rotorZ
	g.pxm_airship_rotor_yaw = yawDeg
	g.pxm_airship_rotor_state = 1

	g.pxm_airship_rudder_x = rudderX
	g.pxm_airship_rudder_y = rudderY
	g.pxm_airship_rudder_z = rudderZ
	g.pxm_airship_rudder_yaw = yawDeg + rudderAngleDeg
	g.pxm_airship_rudder_state = 1
end

local function placeFlyingShipVisual(data)
    local player = world.players[1]

    if not player then
        print("[pxm_airship][global] ERROR: no player for flying visual")
        return
    end

    if not flyingShipVisual or not flyingShipVisual:isValid() then
        flyingShipVisual = createObjectSafe(
            "pxm_airship_flying_visual",
            "pxm_airship_flying_visual"
        )
    end

    if not flyingShipVisual then
        return
    end

    local pos = util.vector3(
        tonumber(data.x) or player.position.x,
        tonumber(data.y) or player.position.y,
        tonumber(data.z) or player.position.z
    )

    local yaw = tonumber(data.yaw) or 0
    local rot = util.transform.rotateZ(yaw)

	local ok, err = pcall(function()
		flyingShipVisual:teleport(player.cell, pos, rot)
	end)

	if not ok then
		--print("[pxm_airship][global] visual teleport skipped: " .. tostring(err))
	end
end

local function setDoorGlobals(g, data, player)
    data = data or {}

    local x = tonumber(data.x) or player.position.x
    local y = tonumber(data.y) or player.position.y
    local z = tonumber(data.z) or player.position.z
    local yaw = tonumber(data.yaw) or 0

    -- Start with the door at the same origin as the ship.
    -- The original door and ship refs are only a few units apart.
    local doorForwardOffset = 0
    local doorSideOffset = 0
    local doorZOffset = 0

    x = x + math.sin(yaw) * doorForwardOffset + math.cos(yaw) * doorSideOffset
    y = y + math.cos(yaw) * doorForwardOffset - math.sin(yaw) * doorSideOffset
    z = z + doorZOffset

    g.pxm_airship_door_x = x
    g.pxm_airship_door_y = y
    g.pxm_airship_door_z = z
    g.pxm_airship_door_yaw = math.deg(yaw)
end

return {
    eventHandlers = {
        pxm_airship_move = function(data)
            --[[print(string.format(
                "[pxm_airship][global] EVENT pxm_airship_move dx=%.3f dy=%.3f dz=%.3f",
                tonumber(data.dx) or -999,
                tonumber(data.dy) or -999,
                tonumber(data.dz) or -999
            ))]]

            local player = world.players[1]
            if not player then
                print("[pxm_airship][global] ERROR: world.players[1] is nil")
                return
            end

            local g = world.mwscript.getGlobalVariables(player)
            if not g then
                print("[pxm_airship][global] ERROR: getGlobalVariables returned nil")
                return
            end

            --[[print(string.format(
                "[pxm_airship][global] BEFORE request=%s dx=%s dy=%s dz=%s",
                tostring(g.pxm_airship_move_request),
                tostring(g.pxm_airship_move_dx),
                tostring(g.pxm_airship_move_dy),
                tostring(g.pxm_airship_move_dz)
            ))]]

            g.pxm_airship_move_dx = data.dx or 0
            g.pxm_airship_move_dy = data.dy or 0
            g.pxm_airship_move_dz = data.dz or 0
            g.pxm_airship_move_request = 1

            --[[print(string.format(
                "[pxm_airship][global] AFTER request=%s dx=%s dy=%s dz=%s",
                tostring(g.pxm_airship_move_request),
                tostring(g.pxm_airship_move_dx),
                tostring(g.pxm_airship_move_dy),
                tostring(g.pxm_airship_move_dz)
            ))]]
        end,
		pxm_airship_set_levitation = function(data)
			local player = world.players[1]
			local g = world.mwscript.getGlobalVariables(player)

			g.pxm_airship_levitate_state = data.state or 0

			--print("[pxm_airship][global] levitation state=" .. tostring(g.pxm_airship_levitate_state))
		end,	

		pxm_airship_set_hide = function(data)
			local player = world.players[1]
			if not player then
				return
			end

			local g = world.mwscript.getGlobalVariables(player)
			if not g then
				return
			end

			g.pxm_airship_hide_state = data.state or 0

			--print("[pxm_airship][global] hide state=" .. tostring(g.pxm_airship_hide_state))
		end,

		pxm_airship_set_flying_state = function(data)
			local player = world.players[1]
			if not player then
				return
			end

			local g = world.mwscript.getGlobalVariables(player)
			if not g then
				return
			end

			g.pxm_airship_is_flying = tonumber(data.state) or 0

			--print("[pxm_airship][global] flying state=" .. tostring(g.pxm_airship_is_flying))
		end,		
	
		pxm_check_flight_toggle = function()

			local player = world.players[1]
			if not player then
				return
			end

			local g = world.mwscript.getGlobalVariables(player)
			if not g then
				return
			end

			if g.PP_SimulEnable == 1 then

				g.PP_SimulEnable = 0
				g.pxm_airship_landed_state = 1

				--print("[pxm_airship][global] PP_SimulEnable detected")

				local startData = {}

				if tonumber(g.pxm_airship_visual_state) == 1
					and tonumber(g.pxm_airship_visual_x)
					and tonumber(g.pxm_airship_visual_y)
					and tonumber(g.pxm_airship_visual_z) then

					local visualYaw = math.rad(tonumber(g.pxm_airship_visual_yaw) or 0)

					startData.hasVisual = 1
					startData.visualX = tonumber(g.pxm_airship_visual_x)
					startData.visualY = tonumber(g.pxm_airship_visual_y)
					startData.visualZ = tonumber(g.pxm_airship_visual_z)
					startData.shipYaw = visualYaw - visualYawOffset

					--print("[pxm_airship][global] sending stored visual as takeoff source of truth")
				end

				player:sendEvent("pxm_toggle_flight", startData)
			end

			if g.pxm_airship_cabin_enter_request == 1 then
				g.pxm_airship_cabin_enter_request = 0

				cabinReturnCell = player.cell
				cabinReturnPosition = player.position
				cabinReturnRotation = player.rotation

				g.pxm_airship_cabin_return_valid = 1
				g.pxm_airship_cabin_return_exterior = player.cell and player.cell.isExterior and 1 or 0
				g.pxm_airship_cabin_return_x = player.position.x
				g.pxm_airship_cabin_return_y = player.position.y
				g.pxm_airship_cabin_return_z = player.position.z
				g.pxm_airship_cabin_return_yaw = player.rotation:getYaw()

				--print("[pxm_airship][global] cabin enter requested")

				local ok, err = pcall(function()
					player:teleport(
						"Serican Rain",
						util.vector3(3615.029, 4153.711, 15080.000),
						util.transform.rotateZ(math.rad(270))
					)
				end)

				if not ok then
					print("[pxm_airship][global] cabin enter teleport failed: " .. tostring(err))
				end
			end

			if g.pxm_airship_cabin_exit_request == 1 then
				g.pxm_airship_cabin_exit_request = 0

				--print("[pxm_airship][global] cabin exit requested")

				if cabinReturnCell and cabinReturnPosition then
					local ok, err = pcall(function()
						player:teleport(
							cabinReturnCell,
							cabinReturnPosition,
							cabinReturnRotation or util.transform.rotateZ(0)
						)
					end)

					if not ok then
						print("[pxm_airship][global] cabin exit teleport failed: " .. tostring(err))
					end

					return
				end

				if g.pxm_airship_cabin_return_valid == 1
					and g.pxm_airship_cabin_return_exterior == 1 then

					local ok, err = pcall(function()
						player:teleport(
							"",
							util.vector3(
								tonumber(g.pxm_airship_cabin_return_x) or 0,
								tonumber(g.pxm_airship_cabin_return_y) or 0,
								tonumber(g.pxm_airship_cabin_return_z) or 0
							),
							util.transform.rotateZ(tonumber(g.pxm_airship_cabin_return_yaw) or 0)
						)
					end)

					if not ok then
						print("[pxm_airship][global] cabin exit persistent teleport failed: " .. tostring(err))
					end

					return
				end

				print("[pxm_airship][global] cabin exit failed: no saved return position")
			end
		end,
		
		pxm_airship_visual_start = function(data)
			local player = world.players[1]
			if not player then
				print("[pxm_airship][global] ERROR: no player for visual start")
				return
			end

			local g = world.mwscript.getGlobalVariables(player)
			if not g then
				print("[pxm_airship][global] ERROR: no globals for visual start")
				return
			end

			data = data or {}

			g.pxm_airship_visual_x = tonumber(data.x) or player.position.x
			g.pxm_airship_visual_y = tonumber(data.y) or player.position.y
			g.pxm_airship_visual_z = tonumber(data.z) or player.position.z

			-- Lua yaw is radians; MWScript SetAngle wants degrees.
			g.pxm_airship_visual_yaw = math.deg(tonumber(data.yaw) or 0)

			g.pxm_airship_visual_state = 1
			setDoorGlobals(g, data, player)
			g.pxm_airship_door_state = 1

			placeAirshipPartVisuals(data)

			--print("[pxm_airship][global] flying visual bridge started")
		end,

		pxm_airship_visual_update = function(data)
			local player = world.players[1]
			if not player then
				return
			end

			local g = world.mwscript.getGlobalVariables(player)
			if not g then
				return
			end

			data = data or {}

			g.pxm_airship_visual_x = tonumber(data.x) or player.position.x
			g.pxm_airship_visual_y = tonumber(data.y) or player.position.y
			g.pxm_airship_visual_z = tonumber(data.z) or player.position.z
			g.pxm_airship_visual_yaw = math.deg(tonumber(data.yaw) or 0)

			g.pxm_airship_rotor_spin = tonumber(data.rotorSpin) or 0

			g.pxm_airship_visual_state = 1
			setDoorGlobals(g, data, player)
			g.pxm_airship_door_state = 1

			placeAirshipPartVisuals(data)
			g.pxm_airship_rotor_spin = tonumber(data.rotorSpin) or 0
		end,

		pxm_airship_visual_stop = function()
			local player = world.players[1]
			if not player then
				return
			end

			local g = world.mwscript.getGlobalVariables(player)
			if not g then
				return
			end

			g.pxm_airship_rotor_spin = 0

			g.pxm_airship_visual_state = 2
			g.pxm_airship_door_state = 2

			--print("[pxm_airship][global] flying visual bridge stopped")
		end,
		pxm_airship_visual_land = function(data)
			local player = world.players[1]
			if not player then
				return
			end

			local g = world.mwscript.getGlobalVariables(player)
			if not g then
				return
			end

			data = data or {}

			if data.x and data.y and data.z then
				g.pxm_airship_visual_x = tonumber(data.x) or g.pxm_airship_visual_x
				g.pxm_airship_visual_y = tonumber(data.y) or g.pxm_airship_visual_y
				g.pxm_airship_visual_z = tonumber(data.z) or g.pxm_airship_visual_z
				g.pxm_airship_visual_yaw = math.deg(tonumber(data.yaw) or 0)

				setDoorGlobals(g, data, player)
				placeAirshipPartVisuals(data)

				g.pxm_airship_rotor_spin = 0
				-- Keep bridge active so MWScript applies the final landed position.
				g.pxm_airship_visual_state = 1
				g.pxm_airship_door_state = 1
			else
				-- Fallback: leave current position as-is.
				g.pxm_airship_visual_state = 0
				g.pxm_airship_door_state = 0
			end

			--print("[pxm_airship][global] flying visual landed")
		end,		
    },
}