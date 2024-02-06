local config = require "herbert100.animated containers.config" ---@type herbert.AC.config
local collision_cfg = config.collision

local common = require("herbert100.animated containers.common")
local defns = require("herbert100.animated containers.defns")

local Class = require("herbert100").Class
local class_utils = require("herbert100.Class.utils")

local UP = tes3vector3.new(0,0,1)
local DOWN = tes3vector3.new(0,0,-1)

local log = require("herbert100.logger")(defns) .. "Container"





local _state = defns.persistent_data_keys.container_state
local _blocked = defns.persistent_data_keys.blocked_by_immovable

---@class herbert.CA.Container.optional_new_params
---@field anim_info_override herbert.AC.Animation_Info? override animation info
---@field check_collisions boolean? default is true. you should enable this if you're trying to open containers. will be overridden by user config settings.

--[[## Container
This class holds a reference to a container, as well as various other information.
It's responsible for keeping track of the open/close state of the container, as well as any logic about whether the container
should be opened/closed.

You can create new `Container` objects using the `Container.new` function, via the syntax
	Container.new(ref, anim_info, check_activate_blacklist)

Only `ref` is required. These arguments have the following meaning
1. `ref: tes3reference`: The reference to the `tes3container` to manage.
2. `anim_info: herbert.AC.Animation_Info|nil`: this lets you override the animation info used by a specified container. use with care.
3. `check_activate_blacklist: boolean|nil`: If true, the `activate_blacklist` will be checked when creating the object.

**NOTE:** After calling `new`, you should **ALWAYS** check that a container was returned.
If the container was unsupported (i.e. no animation data or it was blacklisted) then `new` won't return an object.
]]
---@class herbert.AC.Container : herbert.Class
---@field ref tes3reference
---@field anim_info herbert.AC.Animation_Info
---@field state herbert.AC.defns.container_state
---@field collision_detected boolean whether a collision was detected
---@field safe_handle mwseSafeObjectHandle
---@field bb_min tes3vector3? 	min bounding box vector to use. takes rotation and position into account. could be `nil`
---@field bb_max tes3vector3?	min bounding box vector to use. takes rotation and position into account. could be `nil`
---@field bb_up tes3vector3 direction this container thinks is up
---@field bb_right tes3vector3 direction this container thinks is right
---@field bb_forward tes3vector3 direction this container thinks is forward
---@field bb_verts tes3vector3[] vertices of this containers bounding box, after scaling, rotating, and resizing
---@field check_collisions boolean? should this object check for collisions?
---@field new fun(ref:tes3reference, options: herbert.CA.Container.optional_new_params?): herbert.AC.Container
local Container = Class.new{name="Container",
	fields={
		{"ref"},
		{"state", tostring=class_utils.generators.table_find(defns.container_state)},
		{"check_collisions", default=true},
		{"collision_detected", default=false},
		{"safe_handle", tostring=false, factory = function(self) return tes3.makeSafeObjectHandle(self.ref) end},
		{"anim_info",},
		{"bb_min"},
		{"bb_max"}
	},


	---@param ref tes3reference
    ---@param options herbert.CA.Container.optional_new_params?
	new_obj_func = function(ref, options)
		-- check the blacklist
		if config.blacklist[ref.baseObject.id:lower()] then return end

		local anim_info = options and options.anim_info_override or common.get_animation(ref)

		if anim_info then
			return { ref = ref, anim_info = anim_info }
		end
	end,

	---@param self herbert.AC.Container
    ---@param options herbert.CA.Container.optional_new_params?
	init = function(self, _, options)
		
		if collision_cfg.check then
			if options and options.check_collisions ~= nil then
				self.check_collisions = options.check_collisions
			else
				self.check_collisions = self.anim_info.check_collisions
			end
		else
			self.check_collisions = false
		end

		local data = self.ref.data

		if data[_state] then
			self.state = data[_state]
		else
			self:set_state(defns.container_state.closed)
		end

		self:check_for_collisions()
	end,
}




---@param state herbert.AC.defns.container_state
function Container:set_state(state)
	self.state = state
	self.ref.data[_state] = state
	self.ref.modified = true
end









-- close the container
function Container:close()
	local c_ref, anim_info = self.ref, self.anim_info

	self:set_state(defns.container_state.closing)
	tes3.playAnimation {reference = c_ref, group = anim_info.close_group, startFlag = 1}

	if config.play_sound and anim_info.close_sound then
		tes3.playSound {soundPath = anim_info.close_sound, reference = c_ref}
	end

	timer.start{duration=anim_info.close_time, callback = function ()
		if not self.safe_handle:valid() then return end
		self:set_state(defns.container_state.closed)
	end}
end

-- happens after the `open` timer finishes running. it's the logic that happens once the object is opened
---@param show_contents_menu boolean? should we open the inventory menu after the animation finishes?
function Container:opened(show_contents_menu) 
	local c_ref = self.ref
    self:set_state(defns.container_state.open)

    -- if it's a plant, then mark it as harvested
    if self.anim_info.sound_id == "kollop" then
        local switch_node = self.ref.sceneNode:getObjectByName("HerbalismSwitch")
        if switch_node then switch_node.switchIndex = 1 end
    end
	
	if not show_contents_menu then return end

	tes3.showContentsMenu{reference=c_ref}
	
	if config.auto_close then
		-- this will close the container soon after we exit the menu
		timer.start{duration = 0.5, callback=function()
			if self.safe_handle:valid() and self.state == defns.container_state.open then
				self:close()
			end
		end}
	end
end



-- plays the open animation for this container.
-- **NOTE:** this method **does not** check if the container _should_ be opening. to do that, use `can_open` (or the `interop` file)
---@param show_contents_menu boolean? should the inventory menu be opened once the animation finishes? Default: `false`
function Container:open(show_contents_menu) 
    local anim_info = self.anim_info
	if not anim_info then return end

	self:set_state(defns.container_state.opening)
	tes3.playAnimation {reference = self.ref, group = anim_info.open_group, startFlag = 1}

    -- if it's a plant, mark it as empty
    if anim_info.sound_id == "kollop" then
        local switch_node = self.ref.sceneNode:getObjectByName("HerbalismSwitch")
        if switch_node then switch_node.switchIndex = 2 end
    end

    -- play opening sounds if appropriate
	if config.play_sound and anim_info.open_sound then
		tes3.playSound{soundPath = anim_info.open_sound, reference = self.ref}
	end
    -- either open it now, or open it in a little
    local wait_time = self.anim_info.open_time * config.open_wait_percent
	if wait_time == 0 then
		self:opened(show_contents_menu)
	else
		timer.start{duration = wait_time, callback = function ()
			if self.safe_handle:valid() then
				self:opened(show_contents_menu)
			end
		end}
	end
end


-- checks if the container can be opened. this will also move items inside the container, depending on config settings
---@return boolean
function Container:can_open()
	log("checking if container can be opened: %s", self)
	if not self.state then 
		log("container is not supported, so returning false.")
		return false 
	end
	-- container must be closed if its possible to open it
	if self.state >= 3 then
		log("container is opening or open, so it cannot be opened.")
		return false
	end
	-- nothing else to check if we dont need to worry about collisions
	if not self.anim_info.check_collisions then return true end

	local data = self.ref.data
	if self.collision_detected then return false end

	-- do graphic herbalism compatibility if appropriate
	if common.gh_installed then
		if data.GH == 0 then return true end
		if data.GH == nil and self.anim_info.sound_id == "kollop" then return true end
	end

	log("container can be opened!")
	return true
end

-- this method isn't actually needed, but its included for consistency with the `can_open` method.
function Container:can_close(check_auto_close)
	if check_auto_close and not config.auto_close then return false end
	return self.state and self.state >= 3 -- can only be closed if it's open or it's opening
end


-- this one isnt really used, but no harm in keeping it, i guess

-- opens the container if its closed (and it can be opened)
-- closes the container if it's open
---@param show_contents_menu boolean? should the container be activated after trying to open it?
---@param check_auto_close boolean? should be true if this is considered an "automatic" close. (i.e. quickloot menu destroyed)
--- if `check_auto_close == true`, then the container will only be closed if the users config settings are set accordingly.
---@return boolean opened whether the container was opened
function Container:toggle(show_contents_menu, check_auto_close)
	log("toggling container status")
	if self:can_open() then
		self:open(show_contents_menu)
		return true
	elseif self:can_close(check_auto_close) then
		self:close()
		return true
	end
	return false
end


-- =============================================================================
-- COLLISION CHECKING 
-- =============================================================================

-- everything past this point has to do with collision checking :)

-- get bounding box vertices
-- i'm using this instead of `tes3boundingBox:vertices()` because `min` and `max` will often be scaled/rotated/translated
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




-- for internal use only. this will initialize the bounding box of this container, if it exists.
-- the bounding box will be shifted and modified as needed
function Container:_initialize_bounding_box()
	if not self.check_collisions then return end

	local bb, pos  = self.ref.object.boundingBox, self.ref.position

	if not bb then return false end
	local o = self.ref.orientation
	local A = tes3matrix33.new()
	A:fromEulerXYZ(o.x, o.y, o.z)



	self.bb_up = A:getUpVector()
	self.bb_right = A:getRightVector()
	self.bb_forward = A:getForwardVector()

	local bb_min = A * bb.min * self.ref.scale
	local bb_max = A * bb.max * self.ref.scale


	bb_min.x = collision_cfg.bb_xy_scale * bb_min.x + pos.x
	bb_min.y = collision_cfg.bb_xy_scale * bb_min.y + pos.y

	bb_max.x = collision_cfg.bb_xy_scale * bb_max.x + pos.x
	bb_max.y = collision_cfg.bb_xy_scale * bb_max.y + pos.y

	local new_bb_max_z = collision_cfg.bb_z_top_scale * bb_max.z

	bb_min.z = math.lerp(bb_min.z, new_bb_max_z, collision_cfg.bb_z_ignore_bottom_percent) + pos.z
	
	bb_max.z = new_bb_max_z + pos.z

	self.bb_max = bb_max
	self.bb_min = bb_min

	self.bb_verts = get_bb_verts(bb_min, bb_max)

end

local function logmsg_too_far(self, ref)
	return [[item %s isn't colliding because it's too far from %s
	ref position: 		%s
	container position: %s
	]], ref, self, ref.position, self.ref.position
end

local function logmsg_bad_angle(self, ref)
	return [[item %s isn't colliding because it's at a bad angle with %s
	ref position: 		%s
	container position: %s
	angle with UP: 		%s
	max angle allowed:  %s
	]], ref, self, 
	ref.position, 
	self.ref.position,
	math.abs(UP:angle(self.ref.position - ref.position)) * 180/math.pi,
	collision_cfg.max_degree
end

local function logmsg_ref_not_inside(self, ref)
	local ref_bb = ref.object.boundingBox
	return [[item %s isn't colliding because its bounding box isn't colliding with %s
	ref position: 		%s
	ref bb max: 		%s
	ref bb min: 		%s
	container bb min:   %s
	container bb max:   %s
	]], ref, self,
	ref.position, 
	ref_bb.max,
	ref_bb.min,
	self.bb_max,
	self.bb_min
end


-- find a good point of `ref` to shoot a ray down from. this will nudge the center of `ref` 
-- slightly in the direction of the center of `self.ref`. the reason being that we may find ourselves in a situation where
-- the center of `ref` isn't above `self.ref`, but one of the sides of `ref` is above `self.ref`. e.g: stacked crates.
---@param ref tes3reference
---@return tes3vector3
function Container:find_a_good_point(ref)
	-- dont do any fancy math on small objects
	if ref.sceneNode.worldBoundRadius
	and ref.sceneNode.worldBoundRadius < collision_cfg.bb_min_radius 
	or collision_cfg.bb_min_radius == 0
	then return ref.position end

	local min, max, ref_pos, center = 
		ref.object.boundingBox.min,
		ref.object.boundingBox.max,
		ref.position,
		self.ref.position

	local z_pos = ref.position.z


	local x_positions = {
		ref_pos.x,
		0.5 * max.x + ref_pos.x,
		0.5 * min.x + ref_pos.x,
	}

	local y_positions = {
		ref_pos.y,
		0.5 * max.y + ref_pos.y,
		0.5 * min.y + ref_pos.y,
	}
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


-- check if there's something in this cell that collides with this container
-- update `self.collision_detected` if we found a collision
function Container:check_for_collisions()
	if not self.check_collisions then return end

	if self.ref.data[_blocked] ~= nil then
		self.collision_detected = self.ref.data[_blocked]
		return
	end


	if not self.bb_min then 
		self:_initialize_bounding_box() 
	end

	local c_ref = self.ref

	local deg = collision_cfg.max_degree > 0 and collision_cfg.max_degree * math.pi/180
		or false
	
	
	local max_xy_dist = collision_cfg.max_xy_dist^2
	local max_z_dist = collision_cfg.max_z_dist

	local pos = c_ref.position
	local blacklist = collision_cfg.blacklist

	local rtd = collision_cfg.initial_raytest_max_dist

	if rtd > 0 then
		local ref_z_dist = self.ref.object.boundingBox.max.z -- approximates how far `ref.pos` is from the top of the container

		local hit_results = tes3.rayTest{ direction = UP, position = self.ref.sceneNode.worldBoundOrigin,
			findAll = true, ignore = {self.ref}, root = tes3.game.worldObjectRoot, 
			maxDistance = rtd + ref_z_dist,
		}
	
		log("doing initial raytest collision hit")
		for _, res in ipairs(hit_results or {}) do
			if not blacklist[res.reference.baseObject.id:lower()]
			and res.reference.position.z - (pos.z + ref_z_dist) <= max_z_dist
			then
				log("found raytest hit with %s", res.reference)
				self.collision_detected = true
				if not common.is_pickupable(res.reference) then
					self.ref.data[_blocked] = true
					self.ref.modified = true
				end
	
				return
			end
		end
	end
	

	log("updating items. container has position %s", pos)

	local abs = math.abs

	for ref in c_ref.cell:iterateReferences(common.obj_types_to_check) do
		
		if ref == c_ref or ref.deleted then
			log:trace("item %s failed because it was deleted or the same as the container", ref)
			goto next_ref
		end
		
		local ref_pos = ref.position

		if (pos.x - ref_pos.x)^2 + (pos.y - ref_pos.y)^2 > max_xy_dist or abs(pos.z - ref_pos.z) > max_z_dist then
			log:trace(logmsg_too_far, self, ref)
			goto next_ref
		end

		if deg and abs(UP:angle(ref_pos - pos)) > deg then
			log:trace(logmsg_bad_angle, self, ref)
			goto next_ref
		end

		-- also weeds out stuff that's too big
		if collision_cfg.bb_check and not self:is_ref_inside(ref) then
			log:trace(logmsg_ref_not_inside, self, ref)
			goto next_ref

		end

		if blacklist[ref.baseObject.id:lower()] then
			log:trace("ref %s isnt colliding because it's blacklisted", ref)
			goto next_ref
		end

		local results = tes3.rayTest{
			direction = DOWN, 
			position = self:find_a_good_point(ref),
			maxDistance = max_z_dist,
			root = tes3.game.worldPickRoot,
			ignore = {ref},
			findAll = true
		}

		local ref_min_z = math.abs(0.5 * ref.scale * ref.object.boundingBox.min.z)
		for _, res in ipairs(results or {}) do
			if res.reference == c_ref 
			and res.distance - ref_min_z < collision_cfg.obj_raytest_max_dist 
			then
				log("ray hit on %s. is blocking %s", ref, self)
				self.collision_detected = true
				if not common.is_pickupable(ref) then
					self.ref.data[_blocked] = true
					self.ref.modified = true
				end
				return
			end
		end
		log("%s had no ray hits on %s", ref, self)

		::next_ref::
	end
	log("no objects intersect %s", self)
	self.collision_detected = false
	self.ref.data[_blocked] = false
	self.ref.modified = true

end

-- see if the projection of `A` and `B` along `axis` are separated
-- originally found here: https://gamedev.stackexchange.com/questions/44500/how-many-and-which-axes-to-use-for-3d-obb-collision-with-sat
---@param A tes3vector3[]
---@param B tes3vector3[]
---@param axis tes3vector3
local function test_boxes(A,B, axis)
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
	return math.max(A_max, B_max) - math.min(A_min, B_min) > A_max - A_min + B_max - B_min
end

-- do a SAT test to see if `ref_to_find` is inside this container
---@param ref_to_find tes3reference
function Container:is_ref_inside(ref_to_find)
	local bb2 = ref_to_find.object.boundingBox
	if not bb2 then return false end

	if collision_cfg.bb_other_max_diagonal > 0 
	and tes3vector3.length(bb2.max - bb2.min) > collision_cfg.bb_other_max_diagonal 
	then
		return false
	end


	local R2 = tes3matrix33.new()
	
	local o = ref_to_find.orientation
	R2:fromEulerXYZ(o.x, o.y, o.z)

	local bb2min = R2 * bb2.min * ref_to_find.scale + ref_to_find.position
	local bb2max = R2 * bb2.max * ref_to_find.scale + ref_to_find.position

	local up = R2:getUpVector()
	local forward = R2:getForwardVector()
	local right = R2:getRightVector()

	local bb1verts = self.bb_verts
	local bb2verts = get_bb_verts(bb2min, bb2max)

	return not (
		test_boxes(bb1verts, bb2verts, self.bb_up)
		or	test_boxes(bb1verts, bb2verts, self.bb_forward)
		or	test_boxes(bb1verts, bb2verts, self.bb_right)
		or	test_boxes(bb1verts, bb2verts, up)
		or	test_boxes(bb1verts, bb2verts, forward)
		or	test_boxes(bb1verts, bb2verts, right)
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_up:cross(up)))
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_up:cross(forward)))
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_up:cross(right)))
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_forward:cross(up)))
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_forward:cross(forward)))
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_forward:cross(right)))
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_right:cross(up)))
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_right:cross(forward)))
		or	test_boxes(bb1verts, bb2verts, tes3vector3.normalized(self.bb_right:cross(right)))
	)
end

return Container