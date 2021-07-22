--local gameHUDID = nil
--local gameHUD = nil
local barMenuID = nil
local barMenu = nil

local lastTarget = nil

local function opponentFatigueReset()
	lastTarget = nil 
	--barMenu.visible = false
	barMenu:destroy()
	barMenu = nil
end

local function createFatigueBar(_current, _max)
	-- Create the bar itself
    barMenuID = tes3ui.registerID("OpponentFatigueIndicator.bar")
	
	-- ROOT vanilla HUD element
	-- Could also do:
	--	local gameHUDID = tes3ui.registerID("MenuMulti")
	--  local gameHUD = tes3ui.findMenu(gameHUDID)
	local menuMulti = tes3ui.findMenu(-526)
	local enemyHealthBar = menuMulti:findChild(-573)
	
	-- Make sure the enemy fatigue bar appears below the health bar
	enemyHealthBar.parent.flowDirection = "top_to_bottom"
	barMenu = enemyHealthBar.parent:createFillBar{id = barMenuID, current = _current, max = _max}
	
	-- Vanilla bar sizes
	barMenu.width = 65
	barMenu.height = 12
	
	-- Not sure this does anything useful
	barMenu.alpha = menuMulti.alpha
	
	-- Set the bar's color to orange
	barMenu.widget.fillColor = {1.0, 0.47, 0.0}
	
	barMenu.widget.showText = false
end

local function updateFatigueBar()
    -- Can't update or destroy the fatigue bar if it's been destroyed
	if((barMenu == nil) or (lastTarget == nil)) 
	then
		return
	end
	
	--[[
	if(lastTarget.mobile.health.widget.alpha ~= 1.0) 
	then
		barMenu.alpha = lastTarget.mobile.health.widget.alpha
	end
	
    if(lastTarget.mobile.health.widget.fillAlpha ~= 1.0) 
	then
		barMenu.fillAlpha = lastTarget.mobile.health.widget.fillAlpha
	end
	--]]


	-- Need to cancel the bar if the enemy is dead
	--mwse.log("Updating fatigue bar values")		
	barMenu.widget.max = lastTarget.mobile.fatigue.base
	barMenu.widget.current = lastTarget.mobile.fatigue.current
end

local function onSimulate(e)	
	-- Check if that target is alive
	if (lastTarget ~= nil) 
	then
		if(lastTarget.mobile.health.current <= 0.0)
		then
			--mwse.log("Target has died")
			lastTarget = nil
			opponentFatigueReset()
			return
		end
	end

    -- We have a valid enemy for the player
    if (lastTarget ~= nil) 
	then
		-- The fatigue bar does not already exist
		if(barMenu == nil) 
		then
		    --mwse.log("Creating fatigue bar")
			createFatigueBar(lastTarget.mobile.fatigue.current, lastTarget.mobile.fatigue.base)
		end
		
		updateFatigueBar()
	else 
		if(barMenu ~= nil) 
		then
			opponentFatigueReset()
		end
    end
end

local function updateLastTarget(e) 
    -- Someone other than the player is attacking
    if (e.reference ~= tes3.player) 
	then
        return
    end

    -- The player has hit an ememy
    if (e.targetReference ~= nil) 
	then
		--mwse.log("Updating target")
		lastTarget = e.targetReference
	end
end

-- Initialize 
--event.register("load", opponentFatigueReset)

-- On any attack, we must update who the current target is
event.register("attack", updateLastTarget);

-- Every frame, we must update the bar's state
event.register("simulate", onSimulate)