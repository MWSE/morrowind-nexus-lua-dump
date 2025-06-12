local fmt = string.format
local defns = require "herbert100.more quickloot.defns"
local ERR_CODES = defns.can_take_err_codes
local common = require("herbert100.more quickloot.common")

-- living container, ensures that `Services` will die as soon as we start sneaking or the target becomes nil
local cfg = require "herbert100.more quickloot.config"
local log = mwse.Logger.new()

---@class herbert.MQL.Container.Training : herbert.MQL.Container
---@field items herbert.MQL.Item.Training[]
---@field timer mwseTimer Routinely checks to see if this container should be closed.
local Training_Container = { cls_name = "Training" }

local meta = {__index = Training_Container}
---make a new one
---@param ref tes3reference
---@return herbert.MQL.Container.Training
function Training_Container.new(ref)
	---@type herbert.MQL.Container.Training
	local obj = setmetatable({
		handle = tes3.makeSafeObjectHandle(ref),
		items = {},
		disabled = false,
	}, meta)

	obj.timer = common.services.make_timer_for_service(obj)

	obj:make_items()
	
	return obj
end


common.services.register_service{
    cls = Training_Container, 
	display_name = "Training",
    filter_contexts = {tes3.dialogueFilterContext.serviceTraining},
	is_valid_for_service = function (ref)
		return 
			cfg.training.enable
			and ref.object.aiConfig.offersTraining 
			and tes3.checkMerchantOffersService{
				service = tes3.merchantService.training,
				context = tes3.dialogueFilterContext.serviceTraining,
				reference = ref,
			}
	end
}



function Training_Container:make_items()
	self.items = {}

    -- special thanks to Hrnchamd for telling me how to determine which skills NPCs offer training in
    local ref = self.handle:getObject()
    if not ref then return end
    local mob = ref.mobile
    if not mob then return end
    local mob_skills = mob.skills ---@type tes3statisticSkill[]
    -- get the three highest skills. start each value off at an impossibly low value, just so we can compare them
    

	---@type tes3.skill[]
    local skill_ids = table.values(tes3.skill, function(id1, id2)
        local v1 =  mob_skills[id1 + 1].base
        local v2 =  mob_skills[id2 + 1].base
        -- sort by highest skills
        if v1 ~= v2 then return v1 > v2 end
        -- break ties via lowest id
        return id1 < id2
    end)
	log('calculated highest skills for "%s": {\n\t%s\n}', function ()
		local highest_skill_names = {}
		for i, id in ipairs(skill_ids) do
			highest_skill_names[i] = tes3.getSkillName(id)
		end
		return ref.object.name, highest_skill_names
	end)
    
    -- add the 3 best skills
    for i=1, 3 do
        local skill_id = skill_ids[i]
        self.items[i] = {
            from = ref,
			count = 1,
            skill = tes3.getSkill(skill_id), 
            max_lvl = mob_skills[1 + skill_id].base, 
            merchant_mob = mob,
			value = tes3.calculatePrice{merchant = mob, skill = skill_id, training = true}
        }
    end
end

function Training_Container:get_action_names(_item, modifier_pressed)
	if modifier_pressed then
		local ref = assert(self.handle:getObject())
		local next_service = common.services.get_next_service(Training_Container, ref)
		return { false, "Train", next_service and next_service.display_name or false}
	else
		return { "-", "(Hold Modifier)", "Talk"}
	end
end

--- get the number of items that should be taken, based on current config settings.
--- should only be called if `item.count > 1`
---@param _item herbert.MQL.Item.Training the item to take
---@param bulk boolean are we doing a batch take?
---@param modifier_pressed boolean is the modifier key pressed?
---@return integer num_to_take
function Training_Container:get_num_to_take(_item, bulk, modifier_pressed)
    -- only take items if holding the modifier key and pressing the "take all" key.
	return bulk and modifier_pressed and 1 or 0
end


function Training_Container:get_name()
    return fmt("%s (training)", self.handle:getObject().object.name)
end

function Training_Container:get_status_bar_text()
    return fmt("YOUR GOLD: %s", tes3.getPlayerGold())
end



--- internal mechanism for takign a certain number of copies of an item
--- This method should check if an item status is okay.
---@protected
---@param item herbert.MQL.Item.Training the item to take
---@param _num_to_take integer mode we're taking the item in
---@param _bulk boolean are we taking a bunch of things?
---@return integer num_taken
---@return string? reason
function Training_Container:take_item(item, _num_to_take, _bulk)
    local ref = self.handle:getObject()
    if not ref then return 0 end

    -- special thanks to Hrnchamd for telling me how to remove gold from the player's inventory
    tes3.payMerchant{merchant = ref.mobile, cost = item.value}
    tes3.playSound{reference = tes3.player, sound = "Item Gold Down"}

    local skill_id = item.skill.id
    -- timer.delayOneFrame(function()
    tes3.mobilePlayer:progressSkillToNextLevel(skill_id)
    item.value = tes3.calculatePrice{training=true, skill=skill_id, merchant=ref.mobile}

    return 1
end

--- This is responsible for controlling all behavior that happens when a button is pressed
---@param selected_item herbert.MQL.Item.Training? Item to do the action on
---@param action herbert.MQL.Action
---@return boolean successful
function Training_Container:do_action(selected_item, action)
	if selected_item == nil then
		return false
	end
	if action.ty == 1 then -- take
		return false
	elseif action.ty == 2 then -- take all
		if action.modifier_held then
			local res, err_code = self:can_take_item(selected_item)
			if res ~= 1 then -- display error code

				if err_code == ERR_CODES.NOT_ENOUGH_GOLD then
					tes3.messageBox("You don't have enough gold to train this skill.")
				elseif err_code == ERR_CODES.SKILL_TOO_HIGH then
					local mob = assert(self.handle:getObject().mobile)
					local pronoun = mob.object.female and "she" or "he"
					tes3.messageBox("%s has already taught you all %s knows.", mob.object.name, pronoun)
				elseif err_code == ERR_CODES.ATTR_TOO_LOW then
					local attr_name = tes3.getAttributeName(selected_item.skill.attribute)
					tes3.messageBox("Your %s is too low.", attr_name)
				else
				   log:error("invalid error code was given! got %s", err_code)
				end
				return false
			end

			local num_to_take = self:get_num_to_take(selected_item, true, true)
			local num_taken = self:take_item(selected_item, num_to_take, true)
			event.trigger(
				defns.EVENT_IDS.container_items_changed, 
				{container=self, severity=2}, -- payload
				{filter = self.cls_name}
			)
			event.trigger(
				defns.EVENT_IDS.container_status_text_updated, 
				{container=self}, -- payload
				{filter = self.cls_name}
			)
			return num_taken > 0

		else
			return false
		end
	elseif action.ty == 3 then -- open
	
		if action.modifier_held then	
			local ref = assert(self.handle:getObject())
			common.services.switch_to_next_service(Training_Container, ref)
			return true
		else
			return false
		end

	elseif action.ty == 4 then
		return false
	else
		-- make LuaLS happy.
		log:error("invalid action given! got %s", action.ty)
		return false
	end
end

--- Checks if a tooltip can be made for this item.
---@param _item herbert.MQL.Item.Training
---@return boolean
function Training_Container:can_make_item_tooltip(_item)
	return not self.disabled and cfg.UI.show_tooltips
end


---@param item herbert.MQL.Item.Training
function Training_Container:make_item_tooltip(item)
    tes3ui.createTooltipMenu{skill = item.skill}
end

---Checks if the item at the given index can be taken
---@param item herbert.MQL.Item.Training
---@return -1|0|1 val Whether we can take the item
---@return herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out.
function Training_Container:can_take_item(item)
	
    -- self.value = tes3.calculatePrice{training=true, skill=skill.id, merchant=self:get_merchant_mob()}

    if tes3.getPlayerGold() < item.value then
		return 0, ERR_CODES.NOT_ENOUGH_GOLD
	end
    local skill_base = tes3.mobilePlayer.skills[1 + item.skill.id].base

    if skill_base > item.max_lvl then
        return 0, ERR_CODES.SKILL_TOO_HIGH
    end

    local attr_cur = tes3.mobilePlayer.attributes[1 + item.skill.attribute].current
	if attr_cur <= skill_base then
        return 0, ERR_CODES.ATTR_TOO_LOW
    end

	return 1
end



---@param item herbert.MQL.Item.Training
function Training_Container:format_item_name(item)
    return fmt("%s (%i)", 
        item.skill.name, 
        tes3.mobilePlayer:getSkillStatistic(item.skill.id).base
    )
end

---@param item herbert.MQL.Item.Training
function Training_Container:get_item_icon_path(item) 
    return tes3.getSkill(item.skill.id).iconPath 
end

function Training_Container:get_item_bg_color(item) 
end


---@param item herbert.MQL.Item.Training
function Training_Container:format_item_weight(item, _num) 
    return cfg.training.max_lvl_is_weight and tostring(item.max_lvl) or '-'
end

function Training_Container:format_item_value(item, _num) 
    return item.value
end

--- Should this container be re-enabled for a given reference?
---@param ref tes3reference The reference to potentially enable the container for.
---@return -1|0|1 result If -1, don't enable. if 0, enable but hide contents. if 1, enable and show contents
---@return string? contents hidden reason. The reason why the contents should be hidden. This should only be erturned if the first return result is `0`.
function Training_Container:can_enable(ref)
	if ref ~= self.handle:getObject() then
		return -1
	end
	return 1
end


--- Enable the container for a particular reference.
---@param ref tes3reference
function Training_Container:enable(ref)
	self.disabled = false
end

--- Disables the container
function Training_Container:disable()
	self.disabled = true
end


function Training_Container:destruct()
	self.timer:cancel()
end

function Training_Container:get_title()
	return self.handle:getObject().object.name
end
function Training_Container:get_subtitles()
	local ref = self.handle:getObject()
	return {"Disposition: " .. ref.object.disposition}
end



common.assert_interface_is_implemented(Training_Container)


return Training_Container