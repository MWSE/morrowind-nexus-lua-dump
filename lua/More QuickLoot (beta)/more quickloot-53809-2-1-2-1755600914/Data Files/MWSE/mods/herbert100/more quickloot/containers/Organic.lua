-- =============================================================================
-- ORGANIC LOOTING
-- =============================================================================
local defns = require("herbert100.more quickloot.defns")
local log = mwse.Logger.new()
local common = require("herbert100.more quickloot.common")
local cfg = require("herbert100.more quickloot.config")
local organic_cfg = cfg.organic
local organic_blacklist = cfg.blacklist.organic

local register_event = common.register_event

local EVENT_IDS = defns.EVENT_IDS

local Physical_Container = require(
	"herbert100.more quickloot.containers.abstract.Physical")
local gh_installed = cfg.compat.gh_current == defns.misc.gh.installed
local UI_cfg = cfg.UI

---@alias herbert.MQL.GH.switch
---|0 default
---|1 picked
---|2 spoiled

-- only define the function if graphic herbalism is installed

-- the body of this function was copy-pasted from Graphic Herbalism without change, with permission from Greatness7.
-- it will be used to update how plants look after they're looted, assuming Graphic Herbalism is installed, and the relevant settings
-- are selected
-- Update and serialize the reference's HerbalismSwitch.
---@param ref tes3reference the reference of the plant to update
---@param index herbert.MQL.GH.switch the switch parameter
local function updateHerbalismSwitch(ref, index)
	-- valid indices are: 0=default, 1=picked, 2=spoiled

	local sceneNode = ref.sceneNode
	if not sceneNode then
		return
	end

	local switchNode = sceneNode:getObjectByName("HerbalismSwitch")
	if not switchNode then
		return
	end

	-- bounds check in case mesh does not implement a spoiled state
	index = math.min(index, #switchNode.children - 1)
	switchNode.switchIndex = index

	-- only serialize if non-zero state (e.g. if picked or spoiled)
	ref.data.GH = (index > 0) and index or nil
	log("updated herbalism switch on %s to %s", ref, ref.data.GH)
end


---@class herbert.MQL.Container.Organic : herbert.MQL.Container.Physical
---@field items herbert.MQL.Item.Physical[]  the base chance you have of stealing an item
---@field base_chance number the base chance you have of taking something
---@field penalty_mult number the multiplier applied to the total_value of the plant
local Organic = { cls_name = "Organic" }

local meta = { __index = Organic, __tostring = Physical_Container.__tostring }

---make a new one
---@param ref tes3reference
---@return herbert.MQL.Container.Organic
function Organic.new(ref)
	---@type herbert.MQL.Container.Organic
	local obj = setmetatable({
		handle = tes3.makeSafeObjectHandle(ref),
		items = {},
		history = {},
		relevant_handles = {},
		disabled = false,
	}, meta)

	log("checking ownership access for %s", ref.object)
	if tes3.hasOwnershipAccess { target = ref } then
		log("\thave access!\n\n")
	else
		obj.owner = tes3.getOwner { reference = ref }
		log("\tno access! set obj.owner = %s\n\n", obj.owner)
	end

	obj:make_items()

	return obj
end

function Organic:make_items()
	self.history = {}
	self.items = {}
	self.relevant_handles = {}
	if self.disabled then
		return
	end

	local this_ref = self.handle:getObject()
	common.add_items_to_list(self, this_ref)
	local max_distance = organic_cfg.sn_dist
	-- add nearby items
	if organic_cfg.sn_cf ~= defns.sn_cf.no_other_containers and max_distance >= 5 then
		log:trace("searching nearby containers")
		local pos = this_ref.position
		local name = this_ref.object.name
		local owner = self.owner

		local base_id = this_ref.baseObject.id:lower()

		-- numbers control how many ingredients a plant has. so not relevant here.
		local first_num_pos = base_id:find("_?%d")

		if first_num_pos then
			base_id = base_id:sub(1, first_num_pos - 1)
		end

		local base_id_len = base_id:len()

		local compare_name = organic_cfg.sn_cf == defns.sn_cf.same_base_obj
		for container_ref in tes3.player.cell:iterateReferences(tes3.objectType
			.container) do
			-- distance check
			if max_distance then
				local container_pos = container_ref.position
				if pos:distanceXY(container_pos) > max_distance or
					pos:heightDifference(container_ref.position) > max_distance then
					goto next_container
				end
			end
			if compare_name and container_ref.baseObject.id:lower():sub(1, base_id_len) ~=
				base_id then
				goto next_container
			end

			-- do the owned by check and scripted container check
			if owner and owner ~= tes3.getOwner { reference = container_ref } -- owned item check
				or container_ref:testActionFlag(tes3.actionFlag.useEnabled) == false -- skip scripted
				or container_ref == this_ref                             -- dont add the same container twice
				or not common.is_organic(container_ref, container_ref.baseObject.id:lower()) then
				goto next_container
			end

			log:trace("%s passed all checks", container_ref.object.name)

			common.add_items_to_list(self, container_ref)
			::next_container::
		end
	end

	log("finished adding items", self)

	do -- sort the items
		do -- sort the items
			local sort_items = UI_cfg.sort_items
			if sort_items == defns.sort_items.dont then
				return
			end

			if sort_items == defns.sort_items.weight then
				table.sort(self.items, common.item_sorters.weight_comp)
				return
			end

			if cfg.compat.bg and tes3.mobilePlayer.mercantile.current <
				common.bg_cfg.knowsPrice then
				return
			end

			if sort_items == defns.sort_items.value_weight_ratio then
				table.sort(self.items, common.item_sorters.value_weight_ratio)
			else
				table.sort(self.items, common.item_sorters.value_comp)
			end
		end
	end
	event.trigger(EVENT_IDS.container_items_changed, { container = self, severity = 2 }, -- payload
		{ filter = self.cls_name })
end

---@param item herbert.MQL.Item.Physical
---@param successes integer
---@param failures integer
function Organic:award_xp(item, successes, failures)
	local xp_cfg = organic_cfg.xp
	-- if we allow xp rewards, and if (there's either no max level OR we are below the max level)
	if not xp_cfg.award or 5 < xp_cfg.max_lvl and xp_cfg.max_lvl <
		tes3.mobilePlayer.alchemy.base then
		return
	end

	local value = item.value * successes
	if xp_cfg.on_failure then
		value = value + 0.25 * failures
	end

	local xp = math.lerp(0.2, 0.5, math.clamp(value / 100, 0, 1))
	tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, xp)
end

local mi_cfg = organic_cfg.mi
local mi_defns = defns.mi

--- get the number of items that should be taken, based on current config settings.
--- should only be called if `item.count > 1`
---@param item herbert.MQL.Item.Physical
---@param bulk boolean are we doing a batch take?
---@param modifier_pressed boolean is the modifier key pressed?
---@
---@return integer num_to_take
---@return herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out. any reason we could only take 0?
function Organic:get_num_to_take(item, bulk, modifier_pressed)
	if item.count <= 1 or item.object.weight <= 0 then
		return item.count
	end

	local mode = mi_cfg[common.get_mi_index(bulk, modifier_pressed)]

	if mode == mi_defns.one or
		(mode == mi_defns.ratio and common.value_weight_ratio(item) < mi_cfg.min_ratio) then
		return 1
	end

	local weight = item.object.weight
	local num_to_take = 1
	local max_wgt = mi_cfg.max_total_weight
	if max_wgt / weight >= 2 then
		log("\t\tcalculating weight constraint", item)
		num_to_take = math.floor(max_wgt / weight)

		-- need biggest integer `num` so that max_wgt > num * weight
		--              ~>   max_wgt / weight > num
		log("\t\t\tnum_to_take= %s", num_to_take)
	end

	local min_chance = mi_cfg.min_chance
	if min_chance < 1 then
		local chance = self:get_item_chance(item)
		if chance > 0 and min_chance > 0 then
			log("\t\tcalculating chance constraint", item)
			-- need smallest `num` so that `chance ^ num > min_chance`
			--              ~>                      `num > log(min_chance, chance)`
			local y = math.floor(math.log(min_chance) / math.log(chance))
			if y >= num_to_take then
				num_to_take = y
			end
		end
	end

	return math.clamp(num_to_take, 1, item.count)
end

--- takes the currently activated item. also checks if the item can be looted, and if we're currently in a menu.
---@param item herbert.MQL.Item.Physical the item to take
---@param num_to_take integer mode we're taking the item in
---@param bulk boolean are we taking a bunch of things?
---@return integer num_taken
---@return string? reason
function Organic:take_item(item, num_to_take, bulk)
	local box_ref = item.box_handle:getObject()
	if not box_ref then
		return 0, "This item didn't exist!"
	end

	local chance = self:get_item_chance(item)

	local lucky = false

	local successes = 0
	if chance >= 1 then
		successes = num_to_take
		-- luck override
	elseif tes3.mobilePlayer.luck.current >= 260 or math.random(100) <= 0.5 *
		(tes3.mobilePlayer.luck.current - 30) then
		successes = num_to_take
		lucky = true
	else
		-- roll for each item, so that we can fail to take some, and succeed at taking others
		for _ = 1, num_to_take do
			if math.random() <= chance then
				successes = successes + 1
			end
		end
	end

	local failures = num_to_take - successes

	if failures > 0 then
		failures = common.remove_item(box_ref, item, failures, bulk)
		log('\tfailed to take %s "%s". deleting them', failures, item.object.name)
		item.count = item.count - failures
	end

	if successes > 0 then
		successes = common.transfer_item(box_ref, tes3.player, item, successes, bulk)
		item.count = item.count - successes
		table.insert(self.history, { item = item, num_removed = successes })
	end

	if not bulk then
		if lucky and cfg.UI.show_lucky_msg then
			tes3.messageBox "You got lucky."
		end
		if cfg.UI.show_msgbox and successes > 0 then
			local verb = common.is_equip_modifier_held() and "ate" or "harvested"
			local item_name = common.get_item_name(item)
			if failures > 0 then
				-- e.g. "you ate 3 out of 5 Muck"
				tes3.messageBox("You %s %s out of %s %s.", verb, successes, failures + successes, item_name)
			else
				tes3.messageBox("You %s %s %s.", verb, successes, item_name)
			end
		elseif cfg.UI.show_failure_msg and failures > 0 then
			local verb = common.is_equip_modifier_held() and "eat" or "harvest"
			local item_name = common.get_item_name(item)

			tes3.messageBox("You failed to %s %s %s.", verb, failures, item_name)
		end
	end

	if item.count <= 0 then
		log('\t\tupdating plant')
		if organic_cfg.change_plants == 1 then
			local gh_flag = successes > 0 and 1 or 2
			updateHerbalismSwitch(box_ref, gh_flag)
		elseif organic_cfg.change_plants == 2 and
			not organic_blacklist[box_ref.baseObject.id:lower()] then
			box_ref:disable()
		end
	end

	local total_altered = successes + failures

	if total_altered > 0 and self.owner then
		tes3.triggerCrime {
			type = tes3.crimeType.theft,
			victim = self.owner,
			value = item.value * total_altered,
		}
			tes3.setItemIsStolen { item = item.object, from = self.owner }

	end

	self:award_xp(item, successes, failures)

	return successes
end

---@param e herbert.MQL.events.pick_container
register_event(defns.EVENT_IDS.pick_container, function(e)
	if not organic_cfg.enable then
		return
	end
	if not e.is_organic or e.claim or e.container_cls ~= nil or e.scripted then
		return
	end

	e.container_cls = Organic
end
)

--- Make sure at least one plant shows up in the alchemy container.
---@param e leveledItemPickedEventData
register_event(tes3.event.leveledItemPicked, function(e)
	local spawner = e.spawner
	if e.pick or not spawner or
		not common.is_organic(spawner, spawner.baseObject.id:lower()) or
		e.list.chanceForNothing >= 100 then
		return
	end

	local player_level = tes3.player.object.level
	-- if at least one item can be picked, then we should pick it
	for _, item in ipairs(e.list.list) do
		if item.levelRequired <= player_level then
			log('making sure a leveled item is picked for "%s"', spawner.id)
			log('before calling pickfrom, e.pick = %s', e.pick)
			e.pick = e.list:pickFrom()
			log('after calling pickfrom, e.pick = %s', e.pick)
			break
		end
	end
end
)

-- =============================================================================
-- ITEM METHODS
-- =============================================================================

--- Calculate the chance of successfully taking this item. this is called before the UI is created.
---@param item herbert.MQL.Item.Physical
---@return number take_chance The chance of successfully taking one copy of this item. This is a number between 0 and 1.
function Organic:get_item_chance(item)
	local pm = tes3.mobilePlayer
	local base_chance = 0.01 *
		(1.00 * math.max(0, pm.intelligence.current) + 0.50 *
			math.max(0, pm.alchemy.current) + 0.25 *
			math.max(0, pm.agility.current))

	local sec_lvl = math.max(pm.security.current, 0)

	local alch_penalty_multiplier = 0.1 + 0.9 * 2 ^
		(-0.0004 * sec_lvl ^ 2 - 0.003 * sec_lvl)

	local penalty = 0.15 * item.object.weight + 0.1 *
		math.log(math.max(item.value, 1)) ^ 1.5

	local chance = organic_cfg.chance_mult *
		(base_chance - alch_penalty_multiplier * penalty)

	log("calculating take chance for %s:\n\tchance: %s\n\tpenalty: %s", item,
		chance, alch_penalty_multiplier * penalty)

	return math.clamp(chance, organic_cfg.min_chance, organic_cfg.max_chance)
end

-- -----------------------------------------------------------------------------
-- ITEM_UI_METHODS
-- -----------------------------------------------------------------------------
function Organic:format_item_name(index, num)
	local name = Physical_Container.format_item_name(self, index, num)

	if organic_cfg.show_chances == defns.ui_show_chances.always or
		tes3.mobilePlayer:getSkillValue(tes3.skill.alchemy) >
		organic_cfg.show_chances_lvl then
		return string.format("%s - %s%%", name,
			math.round(100 * self:get_item_chance(index) ^ num))
	end
	return name
end

--- Gets the action labels, depending on the context
---@param item herbert.MQL.Item.Physical? The item to generate action names for.
---@param modifier_pressed boolean Is the modifier key pressed?
---@return string[]
function Organic:get_action_names(item, modifier_pressed, equip_modifier_held)
	local take_verb, take_all_verb

	if equip_modifier_held then
		take_verb = "Eat"

		if cfg.reg.equip_modifier_take_all_enabled then
			take_all_verb = "Eat"
		else
			take_all_verb = self.owner and "Steal" or "Harvest"
		end
	else
		take_verb = self.owner and "Steal" or "Harvest"
		take_all_verb = take_verb
	end
	local count = 0
	if item and self:can_take_item(item) == 1 then
		count = self:get_num_to_take(item, false, modifier_pressed)
	end

	return {
		(count > 0) and string.format("%s %s", take_verb, count) or take_verb,
		take_all_verb .. " All",
		"Open",
	}
end

-- manual inheritence
Organic.do_action = Physical_Container.do_action
Organic.can_enable = Physical_Container.can_enable
Organic.enable = Physical_Container.enable
Organic.disable = Physical_Container.disable
Organic.destruct = Physical_Container.destruct

Organic.can_take_item = Physical_Container.can_take_item

Organic.format_item_value = Physical_Container.format_item_value
Organic.format_item_weight = Physical_Container.format_item_weight

Organic.can_make_item_tooltip = Physical_Container.can_make_item_tooltip
Organic.make_item_tooltip = Physical_Container.make_item_tooltip

Organic.get_item_bg_color = Physical_Container.get_item_bg_color
Organic.get_item_icon_path = Physical_Container.get_item_icon_path
Organic.get_subtitles = Physical_Container.get_subtitles
Organic.get_title = Physical_Container.get_title
Organic.get_status_bar_text = Physical_Container.get_status_bar_text

common.assert_interface_is_implemented(Organic)

return Organic
