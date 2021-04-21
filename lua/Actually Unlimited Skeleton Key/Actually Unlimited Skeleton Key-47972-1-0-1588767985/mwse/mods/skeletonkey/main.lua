
local function initialized(e)

		print("Unlimited Skeleton Key registered")
			end


local function onLockPick(e)

local skeletonKey = tes3.getObject("skeleton_key")

local currentTool = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.lockpick })

	if e.tool == skeletonKey then
		currentTool.itemData.condition = 100
			end
				end

local function onUiObjectTooltip(e)

local skeletonKey = tes3.getObject("skeleton_key")

	if e.object ~= skeletonKey then
		return
			end

    local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
				    e.tooltip:updateLayout()
						end
end

event.register("initialized", initialized)
event.register("lockPick", onLockPick)
event.register("uiObjectTooltip", onUiObjectTooltip)
