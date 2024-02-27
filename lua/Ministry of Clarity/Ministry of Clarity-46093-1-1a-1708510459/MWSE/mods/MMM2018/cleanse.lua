local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		print("[Ministry of Clarity: DEBUG] " .. string)
	end
end



--Buttons
local cleanse = "Cleanse using Amulet of Clarity"
local pickup = "Pick up Ash Statue"
local cancel = "Do nothing"
local menuButtons = { cleanse, pickup, cancel }

local ignoreActivateEvent
local targetRef

local function pickUp()
    local target = targetRef
    -- delay to prevent activation while menu mode
    timer.delayOneFrame(
        function ()
            -- bypass the event
			debugMessage(( "Picking up " .. targetRef.object.name ))	
            tes3.player:activate(target)
        end
    )
end

local function doCleanse()
	debugMessage("exploding spell")
	mwscript.explodeSpell({ reference=targetRef, spell = "sx1_ash_cleanse" })
	timer.start({
		duration = 0.1,
		callback = function()
			debugMessage("disabling statue")
			mwscript.disable({ reference=targetRef })
			debugMessage("adding cleansed statue")
			mwscript.addItem({ reference=tes3.player, item="sx1_statue_cleansed", count=1 })

			tes3.messageBox("Cleansed statue has been added to your inventory.")
		end,
		type = timer.simulate
	})
end

local function onMenuSelect(e)
	
	local result = menuButtons[e.button + 1]
	debugMessage("result = " .. result .. ", cleanse = " .. cleanse)
	if 		result 	== cleanse then
		debugMessage("calling cleanse")
		doCleanse()
		
	elseif 	result 	== pickup then
		ignoreActivateEvent = 1
		pickUp()
		
	elseif 	result 	== cancel then
		return
	end
end

local function onActivate(e)

	if e.target.object == tes3.getObject("misc_6th_ash_statue_01") then	
		targetRef = e.target
		
		if ignoreActivateEvent == 1 then
			ignoreActivateEvent = 2
			debugMessage( ("Ignoring activate event. Ref: " .. targetRef.object.name ) )
			return
		elseif ignoreActivateEvent == 2 then
			ignoreActivateEvent = nil
			debugMessage( ("Ignoring activate event. Ref: " .. targetRef.object.name ) )
			return
		end

		
		debugMessage( (" Not ignoring activate event Ref: " .. targetRef.object.name ) )
		
		--check player inventory for Amulet of Clarity
		local hasAmulet = false
		for stack in tes3.iterate(tes3.player.object.inventory.iterator) do
			local item = stack.object
			if item.id == "sx1_amulet_of_clarity" then
				hasAmulet = true
				break
			end
		end
		if hasAmulet then 
			debugMessage("has amulet: sending message")
			tes3.messageBox({
				message = "The Ash Statue gives off a sinister aura",
				buttons = menuButtons,
				callback = onMenuSelect,
			})
			return false
		else
			debugMessage("no amulet")
			return
		end
	end
end

event.register("activate", onActivate)