--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk : Camping Module                                         │
╰──────────────────────────────────────────────────────────────────────╯
]]

-- SunsDusk\tents\tent_sticks.nif
-- SunsDusk\tents\tent_sticks_rope.nif
-- SunsDusk\tents\tent_sticks_tarp.nif
-- SunsDusk\tents\tent_sticks_rope_canvas.nif
-- SunsDusk\tents\tent_complete.nif
-- f\Furn_Ex_Ashl_Guarskin.NIF
 
-- misc items: 
-- sd_campingitem_rope
-- sd_campingitem_sticks
-- sd_campingitem_tarp
-- sd_campingitem_tent_perm
-- sd_campingitem_tanningrack

-- activators:
-- sd_campingobject_tent_sturdy
-- sd_campingobject_bedroll
-- sd_campingobject_bedrolltent
-- sd_campingobject_tanningrack

-- tanning rack needs to be much smaller size when placed down 
-- and needs to be changed to activator sd_campingobject_tanningrack

-- to sticks: add rope, add tarp
-- to rope: add sticks 
-- to tarp: add sticks

-- tooltip is greyed out when item is added, message box is played if keybind is pressed again

-- "You are missing a tarp" ; "You are missing rope" ; "You are missing sticks"
-- "You are missing rope and sticks" ; "You are missing a tarp and sticks" ; "You are missing rope and a tarp"
-- "There is already a tarp." ; "There is already rope." "There are already sticks".

-- ════════════════════════════════════════════════════════════════════════════════
-- World Interaction Registration - Tent Building
-- ════════════════════════════════════════════════════════════════════════════════

G_worldInteractions.tent_building = {
	canInteract = function(object, objectType)
		local stage = G_tentStages[object.recordId]
		return stage and stage >= 0
	end,
	getActions = function(object, objectType)
		local recordId = object.recordId
		local stage = G_tentStages[recordId] or 0
		local upgrades = G_tentUpgrades[recordId]
		local actions = {}
		local stageTag = stage > 0 and (" [" .. stage .. "/4]") or ""
		
		-- Upgrade actions from branching table
		if upgrades then
			for i, upgrade in ipairs(upgrades) do
				local hasComponent = not upgrade.component or typesActorInventorySelf:find(upgrade.component)
				table.insert(actions, {
					label = upgrade.label .. stageTag,
					preferred = i == 1 and "ToggleWeapon" or nil,
					disabled = not hasComponent,
					handler = function(obj)
						if hasComponent then
							core.sendGlobalEvent("SunsDusk_upgradeTent", {self, obj, i})
						else
							local name = G_tentComponentNames[upgrade.component] or "a tent component"
							messageBox(2, "You are missing " .. name .. ".")
						end
					end
				})
			end
		end
		
		-- Attack/destroy action for placed tent stages (not misc items)
		if stage >= 1 then
			table.insert(actions, {
				label = "Destroy Tent",
				preferred = "Attack",
				onHit = function(obj, objType, groupname, key, swingData, hitPos)
					local s = G_tentStages[obj.recordId] or 1
					local info = G_tentDowngrades[obj.recordId]
					local breakChance = info.breakChance - typesPlayerStatsSelf.endurance.modifier/400 * getFatigueTerm(self)
					local returnItem = info and math.random() >= breakChance
					if not returnItem then 
						local itemName = types.Miscellaneous.records[info.returns]
						if itemName then
							itemName = itemName.name
						else
							itemName = "Something"
						end
						messageBox(1, itemName.." broke")
					--	ambient.playSound("spell failure alteration")
					end
					if s <= 1 then
						core.sendGlobalEvent("SunsDusk_destroyTent", {self, obj, returnItem})
					else
						core.sendGlobalEvent("SunsDusk_damageTent", {self, obj, returnItem})
					end	
					core.sendGlobalEvent("SpawnVfx", {
						model = "meshes/e/magic_hit_conjure.nif",
						position = (hitPos or obj.position) - v3(0, 0, 20),
						options = {scale = 0.3}
					})
					ambient.playSoundFile("sound/sunsdusk/woodcutfx-001.ogg", {volume = 0.5})
				end
			})
		end
		
		return actions
	end
}

-- ════════════════════════════════════════════════════════════════════════════════
-- Camping - Tent/Bedroll Destroy
-- ════════════════════════════════════════════════════════════════════════════════

G_worldInteractions.campDestroy = {
	canInteract = function(object, objectType)
		if objectType ~= "Activator" then return false end
		local recordId = object.recordId
		return recordId == "sd_campingobject_tent" or recordId == "sd_campingobject_bedroll"
	end,
	getActions = function(object, objectType)
		local isTent = object.recordId == "sd_campingobject_tent"
		return {{
			label = "Destroy " .. (isTent and "Tent" or "Bedroll"),
			preferred = "Attack",
			onHit = function(obj, objType, groupname, key, swingData)
				core.sendGlobalEvent("SunsDusk_destroyCamp", obj)
				core.sendGlobalEvent("SpawnVfx", {
					model = "meshes/e/magic_hit_conjure.nif",
					position = G_raycastResult.hitPos - v3(0, 0, 20),
					options = {scale = 0.4}
				})
				ambient.playSoundFile("sound/sunsdusk/woodcutfx-001.ogg", {volume = 1})
			end
		}}
	end
}