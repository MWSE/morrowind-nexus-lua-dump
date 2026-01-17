local common = require("herbert100.animated containers.common")
local config = require("herbert100.animated containers.config")
local defns = require("herbert100.animated containers.defns")
local log = mwse.Logger.new()

---@class herbert.AC.interop
local interop = {}

---@param ref tes3reference
---@return herbert.AC.defns.container_state?
function interop.get_state(ref)
	if not ref or not ref.data then
		log("%s did not exist or %s.data did not exist!", ref, ref)
		return
	end
	local state = ref.data.CA_cs
	if not state then
		log("container %s had no saved state. returning 1", ref)
		return 1
	end
	if type(state) ~= "number" or state < 0 or state > 4 then
		log("container %s had an invalid state (%s)! returning nothing and clearing it.", function()
			return ref, state
		end)
		ref.data.CA_cs = nil
		return
	end
	log("container %s had a saved state. returning %s", function()
		return ref, table.find(defns.container_state, state)
	end)
	return state
end

---@param ref tes3reference
---@param state herbert.AC.defns.container_state?
function interop.set_state(ref, state)
	ref.data.CA_cs = state
end

---@param ref tes3reference
---@return herbert.AC.Animation_Info?
function interop.get_animation_info(ref)
	return common.get_animation(ref)
end

---@param ref tes3reference
---@param skip_collision_check boolean
---@return boolean
function interop.can_open(ref, skip_collision_check)
	local state = interop.get_state(ref)
	if not state or state == 3 or state == 4 then
		return false
	end
	local anim_info = interop.get_animation_info(ref)
	if not anim_info then
		log("could not find animation information for %s\n\tmesh: %s\n\tmesh_key: %s", function()
			return ref, ref.object.mesh, common._get_mesh_key(ref.object.mesh)
		end)
		return false
	end
	if skip_collision_check or not anim_info.check_collisions then
		return true
	end
	if interop.has_collision(ref) then
		return false
	end
	-- do graphic herbalism compatibility if appropriate
	if common.gh_installed then
		if ref.data.GH == 0 then
			return true
		end
		if ref.data.GH == nil and anim_info.sound_id == "kollop" then
			return true
		end
	end

	log("container can be opened!")

	return true
end

---@param ref_handle mwseSafeObjectHandle
---@param show_contents_menu boolean
local function on_opened(ref_handle, show_contents_menu)
	local ref = ref_handle:getObject()
	if not ref then
		return
	end

	interop.set_state(ref, defns.container_state.open)
	local anim_info = interop.get_animation_info(ref)
	if not anim_info then
		return
	end

	-- if it's a plant, then mark it as harvested
	if anim_info.sound_id == "kollop" then
		local switch_node = ref.sceneNode:getObjectByName("HerbalismSwitch")
		if switch_node then
			switch_node.switchIndex = 1
		end
	end

	if not show_contents_menu then
		return
	end

	tes3.showContentsMenu { reference = ref }

	if config.auto_close ~= defns.auto_close.never then
		-- this will close the container soon after we exit the menu
		timer.start {
			duration = 0.5,
			callback = function()
				log("trying to close %s", ref)

				if config.auto_close == defns.auto_close.if_nonempty and
					(ref.isEmpty or #ref.object.inventory.items == 0) then
					log("couldn't close because container is empty")
					return
				end
				if ref_handle:valid() and interop.get_state(ref) ==
					defns.container_state.open then
					interop.close(ref)
				end
			end
			,
		}
	end
end


---@param ref tes3reference
---@param show_contents_menu boolean
function interop.open(ref, show_contents_menu)
	local anim_info = interop.get_animation_info(ref)
	if not anim_info then
		return
	end
	interop.set_state(ref, defns.container_state.opening)
	tes3.playAnimation { reference = ref, group = anim_info.open_group, startFlag = 1 }

	-- if it's a plant, mark it as empty
	if anim_info.sound_id == "kollop" then
		local switch_node = ref.sceneNode:getObjectByName("HerbalismSwitch")
		if switch_node then
			switch_node.switchIndex = 2
		end
	end

	-- play opening sounds if appropriate
	if config.play_sound and anim_info.open_sound then
		tes3.playSound { soundPath = anim_info.open_sound, reference = ref }
	end
	local handle = tes3.makeSafeObjectHandle(ref)

	-- either open it now, or open it in a little
	local wait_time = anim_info.open_time * config.open_wait_percent
	if wait_time == 0 then
		on_opened(handle, show_contents_menu)
	else
		timer.start {
			duration = wait_time,
			callback = function()
				if handle:valid() then
					on_opened(handle, show_contents_menu)
				end
			end
			,
		}
	end
end

---@param ref tes3reference
function interop.close(ref)
	local anim_info = interop.get_animation_info(ref)
	if not anim_info then
		return
	end

	interop.set_state(ref, defns.container_state.closing)
	tes3.playAnimation { reference = ref, group = anim_info.close_group, startFlag = 1 }

	if config.play_sound and anim_info.close_sound then
		tes3.playSound { soundPath = anim_info.close_sound, reference = ref }
	end

	local ref_handle = tes3.makeSafeObjectHandle(ref)

	timer.start {
		duration = anim_info.close_time,
		callback = function()
			if not ref_handle:valid() then
				return
			end
			interop.set_state(ref, defns.container_state.closed)
		end
		,
	}
end

---@param ref tes3reference
local function check_auto_close_(ref)
	if config.auto_close == defns.auto_close.never then
		return false
	end
	if config.auto_close == defns.auto_close.if_nonempty then
		-- can be closed if it has items, cant be closed if it has no items
		return not ref.isEmpty and #ref.object.inventory.items > 0
	end
	if config.auto_close == defns.auto_close.always then
		return true
	end
end


-- this method isn't actually needed, but its included for consistency with the `can_open` method.
---@param ref tes3reference
function interop.can_close(ref, check_auto_close)
	if check_auto_close and not check_auto_close_(ref) then
		return false
	end
	local state = interop.get_state(ref)
	return state and state >= 3 -- can only be closed if it's open or it's opening
end

-- opens the container if its closed (and it can be opened)
-- closes the container if it's open
---@param ref tes3reference
---@param show_contents_menu boolean? should the container be activated after trying to open it?
---@param check_auto_close boolean? should be true if this is considered an "automatic" close. (i.e. quickloot menu destroyed)
--- if `check_auto_close == true`, then the container will only be closed if the users config settings are set accordingly.
---@return boolean opened whether the container was opened
function interop.toggle(ref, show_contents_menu, check_auto_close)
	log("toggling container status")
	if interop.can_open(ref, false) then
		interop.open(ref, show_contents_menu or false)
		return true
	elseif interop.can_close(ref, check_auto_close) then
		interop.close(ref)
		return true
	end
	return false
end

-- =============================================================================
-- ACTIVATION SKIPPING
-- =============================================================================

interop._should_skip_next_activation = false
--- Prevents this mod from performing any logic the next time any reference gets activated.
function interop.skip_next_activation()
	interop._should_skip_next_activation = true
end

-- =============================================================================
-- REGISTER REPLACEMENT MESH
-- =============================================================================

-- mesh replacements. consider using the `add_custom_mesh_replacement` when interacting with this table
---@type herbert.AC.interop.add_custom_mesh_replacement.params[]
interop.custom_mesh_replacements = {}

-- parameters for the `add_custom_mesh_replacement` function
---@class herbert.AC.interop.add_custom_mesh_replacement.params
---@field old_mesh string the string representing the old mesh
---@field new_mesh string mesh to replace old mesh with
---@field animation_info string|herbert.AC.Animation_Info the animation info to use when replacing the mesh.
--- this paramater can be one of two types:
--- 1. `CA.Animation_Info`: i.e., an instance of the `Animation_Info` class (make sure to use the `.new` function!).
--- 2. the name of an existing `Animation_Info` class (i.e., a key in the `common.animation_info` table.). in this case, the corresponding `Animation_Info` will be used.
---@field priority integer? The priority of this mesh replacement. This allows for a more predictable outcome when two mods try to replace the same mesh.
-- The replacement with the lowest priority number will win.
-- (This is so that the behavior is consistent with how the `priority` keyword is used in MWSE. i.e., higher priority things happen _first_.)

--- Add a custom mesh replacement. You should specify the old mesh, the new mesh, and information about the animation to use.
---@param p herbert.AC.interop.add_custom_mesh_replacement.params Table that holds information about the mesh you want to replace.
--[[ The following parameters are accepted:
* `old_mesh: string` The mesh you want to replace.
* `new_mesh: string` The mesh to replace the old mesh with.
* `animation_info: string|herbert.AC.Animation_Info`: Information about the animations of this mesh. If this is a `string`, then it should be a key in the `common.animation_info` table.
* `priority integer?`: The priority of this mesh replacement. This allows for a more predictable outcome when two mods try to replace the same mesh.
 See the documentation for `Animation_Info` for more details on this parameter. It's not too bad, I promise!
 The replacement with the lowest priority number will win.
 (This is so that the behavior is consistent with how the `priority` keyword is used in MWSE. i.e., higher priority things _happen first_.)
]]
function interop.add_custom_mesh_replacement(p)
	p.priority = p.priority or 0
	table.insert(interop.custom_mesh_replacements, p)
end

-- =============================================================================
-- COLLISION CHECKING
-- =============================================================================

---@class herbert.AC.ReferenceBoundingBoxData
---@field up tes3vector3
---@field right tes3vector3
---@field forward tes3vector3
---@field min tes3vector3
---@field max tes3vector3
---@field verts tes3vector3

-- get bounding box vertices
-- i'm using this instead of `tes3boundingBox:vertices()` because `min` and `max` will often be scaled/rotated/translated
---@return tes3vector3[]
local function get_bb_verts(min, max)
	return {
		tes3vector3.new(min.x, min.y, min.z),
		tes3vector3.new(min.x, min.y, max.z),
		tes3vector3.new(min.x, max.y, max.z),
		tes3vector3.new(min.x, max.y, min.z),

		tes3vector3.new(max.x, min.y, min.z),
		tes3vector3.new(max.x, min.y, max.z),
		tes3vector3.new(max.x, max.y, max.z),
		tes3vector3.new(max.x, max.y, min.z),
	}
end


local collision_cfg = config.collision
local UP = tes3vector3.new(0, 0, 1)
local DOWN = tes3vector3.new(0, 0, -1)

---@param ref tes3reference
---@return herbert.AC.ReferenceBoundingBoxData
local function get_bounding_box_data(ref)
	local bb, pos = ref.object.boundingBox, ref.position
	local ori = ref.orientation
	local A = tes3matrix33.new()
	A:fromEulerXYZ(ori.x, ori.y, ori.z)

	local bb_up = A:getUpVector()
	local bb_right = A:getRightVector()
	local bb_forward = A:getForwardVector()

	local bb_min = A * bb.min * ref.scale
	local bb_max = A * bb.max * ref.scale

	bb_min.x = collision_cfg.bb_xy_scale * bb_min.x + pos.x
	bb_min.y = collision_cfg.bb_xy_scale * bb_min.y + pos.y

	bb_max.x = collision_cfg.bb_xy_scale * bb_max.x + pos.x
	bb_max.y = collision_cfg.bb_xy_scale * bb_max.y + pos.y

	local new_bb_max_z = collision_cfg.bb_z_top_scale * bb_max.z

	bb_min.z = math.lerp(bb_min.z, new_bb_max_z,
		collision_cfg.bb_z_ignore_bottom_percent) + pos.z

	bb_max.z = new_bb_max_z + pos.z

	bb_max = bb_max
	bb_min = bb_min

	---@type herbert.AC.ReferenceBoundingBoxData
	local data = {
		forward = bb_forward,
		max = bb_max,
		min = bb_min,
		right = bb_right,
		up = bb_up,
		verts = get_bb_verts(bb_min, bb_max),
	}
	return data
end


-- find a good point of `ref` to shoot a ray down from. this will nudge the center of `ref`
-- slightly in the direction of the center of `self.ref`. the reason being that we may find ourselves in a situation where
-- the center of `ref` isn't above `self.ref`, but one of the sides of `ref` is above `self.ref`. e.g: stacked crates.
---@param ref tes3reference
---@param other_ref tes3reference
---@return tes3vector3
local function find_a_good_point(ref, other_ref)
	-- dont do any fancy math on small objects
	if other_ref.sceneNode.worldBoundRadius and
		other_ref.sceneNode.worldBoundRadius < collision_cfg.bb_min_radius or
		collision_cfg.bb_min_radius == 0 then
		return other_ref.position
	end

	local min = other_ref.object.boundingBox.min
	local max = other_ref.object.boundingBox.max
	local pos = other_ref.position
	local center = ref.position

	local z_pos = other_ref.position.z

	local x_positions = { pos.x, 0.5 * max.x + pos.x, 0.5 * min.x + pos.x }

	local y_positions = { pos.y, 0.5 * max.y + pos.y, 0.5 * min.y + pos.y }
	local x_pos, y_pos, dist

	local min_dist = math.huge

	for _, x in ipairs(x_positions) do
		dist = math.abs(x - center.x)
		if dist < min_dist then
			x_pos = x
			min_dist = dist
		end
	end

	min_dist = math.huge
	for _, y in ipairs(y_positions) do
		dist = math.abs(y - center.y)
		if dist < min_dist then
			y_pos = y
			min_dist = dist
		end
	end

	return tes3vector3.new(x_pos, y_pos, z_pos)
end


local function logmsg_too_far(c_ref, ref)
	return [[item %s isn't colliding because it's too far from %s
	ref position: 		%s
	container position: %s
	]], ref, c_ref, ref.position, c_ref.position
end


local function logmsg_bad_angle(c_ref, ref)
	return [[item %s isn't colliding because it's at a bad angle with %s
	ref position: 		%s
	container position: %s
	angle with UP: 		%s
	max angle allowed:  %s
	]], ref, c_ref, ref.position, c_ref.position,
		math.abs(UP:angle(c_ref.position - ref.position)) * 180 / math.pi,
		collision_cfg.max_degree
end


---@param c_ref tes3reference
---@param ref tes3reference
---@param c_ref_bb_data herbert.AC.ReferenceBoundingBoxData
local function logmsg_ref_not_inside(c_ref, ref, c_ref_bb_data)
	local ref_bb = ref.object.boundingBox
	return
		[[item %s isn't colliding because its bounding box isn't colliding with %s
	ref position: 		%s
	ref bb max: 		%s
	ref bb min: 		%s
	container bb min:   %s
	container bb max:   %s
	]], ref, c_ref, ref.position, ref_bb.max, ref_bb.min, c_ref_bb_data.min,
		c_ref_bb_data.max
end


-- see if the projection of `A` and `B` along `axis` are separated
-- originally found here: https://gamedev.stackexchange.com/questions/44500/how-many-and-which-axes-to-use-for-3d-obb-collision-with-sat
---@param A tes3vector3[]
---@param B tes3vector3[]
---@param axis tes3vector3
local function test_boxes(A, B, axis)
	local A_min, A_max, B_min, B_max = 100000, -100000, 100000, -100000
	local dist
	for i = 1, 8 do
		dist = A[i]:dot(axis)
		A_min = math.min(dist, A_min)
		A_max = math.max(dist, A_max)

		dist = B[i]:dot(axis)
		B_min = math.min(dist, B_min)
		B_max = math.max(dist, B_max)
	end
	return
		math.max(A_max, B_max) - math.min(A_min, B_min) > A_max - A_min + B_max - B_min
end


-- do a SAT test to see if `ref_to_find` is inside this container
---@param ref_to_find tes3reference
---@param bb_data herbert.AC.ReferenceBoundingBoxData
local function is_ref_inside(c_ref, bb_data, ref_to_find)
	local bb2 = ref_to_find.object.boundingBox
	if not bb2 then
		return false
	end

	if collision_cfg.bb_other_max_diagonal > 0 and
		tes3vector3.length(bb2.max - bb2.min) > collision_cfg.bb_other_max_diagonal then
		return false
	end

	local R2 = tes3matrix33.new()

	local ori = ref_to_find.orientation
	R2:fromEulerXYZ(ori.x, ori.y, ori.z)

	local bb2min = R2 * bb2.min * ref_to_find.scale + ref_to_find.position
	local bb2max = R2 * bb2.max * ref_to_find.scale + ref_to_find.position

	local up = R2:getUpVector()
	local forward = R2:getForwardVector()
	local right = R2:getRightVector()

	local bb1verts = bb_data.verts
	local bb2verts = get_bb_verts(bb2min, bb2max)

	-- the lua formatter makes this look almost incomprehensible
	-- but the basic idea is to return true if all of the test_boxes calls return false
	return not (test_boxes(bb1verts, bb2verts, bb_data.up) or
		test_boxes(bb1verts, bb2verts, bb_data.forward) or
		test_boxes(bb1verts, bb2verts, bb_data.right) or
		test_boxes(bb1verts, bb2verts, up) or
		test_boxes(bb1verts, bb2verts, forward) or
		test_boxes(bb1verts, bb2verts, right) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.up:cross(up))) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.up:cross(forward))) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.up:cross(right))) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.forward:cross(up))) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.forward:cross(forward))) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.forward:cross(right))) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.right:cross(up))) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.right:cross(forward))) or
		test_boxes(bb1verts, bb2verts,
			tes3vector3.normalized(bb_data.right:cross(right))))
end


-- check if there's something in this cell that collides with this container
-- update `self.collision_detected` if we found a collision
---@param c_ref tes3reference
---@return boolean
function interop.has_collision(c_ref)
	if c_ref.data.CA_bl ~= nil then
		log("collision information for %s was already computed! returning %s", c_ref, c_ref.data.CA_bl)
		return c_ref.data.CA_bl
	end

	local bb_data = get_bounding_box_data(c_ref)

	local deg =
		collision_cfg.max_degree > 0 and collision_cfg.max_degree * math.pi / 180 or
		false

	local max_xy_dist = collision_cfg.max_xy_dist ^ 2
	local max_z_dist = collision_cfg.max_z_dist

	local pos = c_ref.position
	local blacklist = collision_cfg.blacklist

	local rtd = collision_cfg.initial_raytest_max_dist

	if rtd > 0 then
		local ref_z_dist = c_ref.object.boundingBox.max
			.z -- approximates how far `ref.pos` is from the top of the container

		local hit_results = tes3.rayTest {
			direction = UP,
			position = c_ref.sceneNode.worldBoundOrigin,
			findAll = true,
			ignore = { c_ref },
			root = tes3.game.worldObjectRoot,
			maxDistance = rtd + ref_z_dist,
		}

		log("doing initial raytest collision hit")
		for _, res in ipairs(hit_results or {}) do
			if not blacklist[res.reference.baseObject.id:lower()] and
				res.reference.position.z - (pos.z + ref_z_dist) <= max_z_dist then
				log("found raytest hit with %s", res.reference)
				if not common.is_pickupable(res.reference) then
					c_ref.data.CA_bl = true
					c_ref.modified = true
				end

				return true
			end
		end
	end

	log("updating items. container has position %s", pos)

	local abs = math.abs

	for ref in c_ref.cell:iterateReferences(common.obj_types_to_check) do
		if ref == c_ref or ref.deleted then
			log:trace(
				"item %s failed because it was deleted or the same as the container", ref)
			goto next_ref
		end

		local ref_pos = ref.position

		if (pos.x - ref_pos.x) ^ 2 + (pos.y - ref_pos.y) ^ 2 > max_xy_dist or
			abs(pos.z - ref_pos.z) > max_z_dist then
			log:trace(logmsg_too_far, c_ref, ref)
			goto next_ref
		end

		if deg and abs(UP:angle(ref_pos - pos)) > deg then
			log:trace(logmsg_bad_angle, c_ref, ref)
			goto next_ref
		end

		-- also weeds out stuff that's too big
		if collision_cfg.bb_check and not is_ref_inside(c_ref, bb_data, ref) then
			log:trace(logmsg_ref_not_inside, c_ref, ref, bb_data)
			goto next_ref
		end

		if blacklist[ref.baseObject.id:lower()] then
			log:trace("ref %s isnt colliding because it's blacklisted", ref)
			goto next_ref
		end

		local results = tes3.rayTest {
			direction = DOWN,
			position = find_a_good_point(c_ref, ref),
			maxDistance = max_z_dist,
			root = tes3.game.worldPickRoot,
			ignore = { ref },
			findAll = true,
		}

		local ref_min_z = math.abs(0.5 * ref.scale * ref.object.boundingBox.min.z)
		for _, res in ipairs(results or {}) do
			if res.reference == c_ref and res.distance - ref_min_z <
				collision_cfg.obj_raytest_max_dist then
				log("ray hit on %s. is blocking %s", ref, c_ref)
				if not common.is_pickupable(ref) then
					c_ref.data.CA_bl = true
					c_ref.modified = true
				end
				return true
			end
		end
		log("%s had no ray hits on %s", ref, c_ref)

		::next_ref::
	end
	log("no objects intersect %s", c_ref)

	c_ref.data.CA_bl = false
	c_ref.modified = true
	return false
end

-- =============================================================================
-- BACKWARDS COMPATIBILITY
-- =============================================================================

-- here you will most likely find all the functions and tables you need in order to interact with this mod.
-- this includes things like opening and closing containers, as well as changing how meshes are replaced.

--- Checks if a container can be opened, and then opens it if appropriate.
-- **NOTE:** this function only checks animated container related things when determining if something can be opened;
-- it does not check for locks, traps, ownership, etc.
-- In other words, this function *assumes* you have a good reason to try to open this container.
-- **NOTE:** For more advanced behavior/logic, you will have to import the `Container` class and use its fields and methods.
---@param ref tes3reference Reference to the `tes3container` you want to open.
---@param show_contents_menu boolean? Should the contents menu be shown after the animation finishes? Default: `false`.
-- **WARNING:** it's possible to open the menus for locked/trapped containers via this parameter. Handle this accordingly.
-- **NOTE:** this setting will only take effect if the player has their config set to open content menus when animations finish.
-- You can't use this function to override that behavior.
---@return boolean opened Whether the open animation for this container was played. (i.e., whether it could be opened)
function interop.try_to_open(ref, show_contents_menu, skip_collision_check)
	log("trying to open %s", ref)
	if interop.can_open(ref, skip_collision_check) then
		interop.open(ref, show_contents_menu or false)
		return true
	end
	return false
end

--- Checks if a container can be closed, and then closes it if appropriate.
-- **NOTE:** For more advanced behavior/logic, you will have to import the `Container` class and use its fields and methods.
---@param ref tes3reference Reference to the `tes3container` to close.
---@param check_auto_close boolean? This parameter lets you specify whether you're trying to close this container as a result of a state change rather than a choice made by the player.
-- The purpose of this parameter is to let your mod play nicely with the "auto close containers" setting in the MCM.
-- If a user has that setting disabled, then this function will won't ever close containers when `check_auto_close = true`.
-- **Example:** in my QuickLoot mod, I set this parameter to `true` when trying to close containers as a result of a QuickLoot menu being destroyed.
---@return boolean closed whether the container was closed
function interop.try_to_close(ref, check_auto_close)
	log("trying to close %s", ref)
	if interop.can_close(ref, check_auto_close) then
		interop.close(ref)
		return true
	end
	return false
end

--- This will try to open a container. If that doesn't work, it will try to close a container.
---@param ref tes3reference reference to the container to open
---@param show_contents_menu boolean? Should the contents menu be shown after the animation finishes?
-- **WARNING:** it's possible to open the menus for locked/trapped containers via this parameter. Handle this accordingly.
-- **NOTE:** this setting will only take effect if the player has their config set to open content menus when animations finish.
-- You can't use this function to override that behavior.
---@param check_auto_close boolean? This parameter lets you specify whether you're trying to close this container as a result of a state change rather than a choice made by the player.
-- The purpose of this parameter is to let your mod play nicely with the "auto close containers" setting in the MCM.
-- If a user has that setting disabled, then this function will won't ever close containers when `check_auto_close = true`.
-- **Example:** in my QuickLoot mod, I set this parameter to `true` when trying to close containers as a result of a QuickLoot menu being destroyed.
---@return boolean changed Whether the container was toggled. This will be `true` if: the container was open and now it's closed, or the contaienr was closed and now it's open.
function interop.try_to_toggle(ref, show_contents_menu, check_auto_close)
	log("toggling container status")

	if interop.can_open(ref, false) then
		interop.open(ref, show_contents_menu or false)
		return true
	elseif interop.can_close(ref, check_auto_close) then
		interop.close(ref)
		return true
	end
	return false
end

--- get the state of the container. maps to values in the `defns.container_state` table.
interop.get_container_state = interop.get_state

return interop
