local messageBox = require("x0.ash.util.messageBox")

local function canPrayAgain(castingObject)
    local lastPrayDay = castingObject.data.lastPrayDay
    local lastPrayHour = castingObject.data.lastPrayHour
    local currentDay = tes3.findGlobal("DaysPassed").value
    local currentHour = tes3.findGlobal("GameHour").value

    if not lastPrayDay or not lastPrayHour then
        return true
    end

    local hoursPassed = (currentDay - lastPrayDay) * 24 + (currentHour - lastPrayHour)

    if hoursPassed >= 24 then
        return true
    else
        return false, 24 - hoursPassed
    end
end

local function updatePrayTime(castingObject)
    castingObject.data.lastPrayDay = tes3.findGlobal("DaysPassed").value
    castingObject.data.lastPrayHour = tes3.findGlobal("GameHour").value
end

local function useExistingPotion()
    local potionId = "x0_ashblood"
    tes3.addItem({ reference = tes3.player, item = potionId, count = 1 })
    mwscript.equip({ reference = tes3.player, item = potionId })
end

local function useBetterPotion()
    local potionId = "x0_ashbloodpure"
    tes3.addItem({ reference = tes3.player, item = potionId, count = 1 })
    mwscript.equip({ reference = tes3.player, item = potionId })
end

local function hasDaedricDagger()
    return tes3.getItemCount({ reference = tes3.player, item = "daedric dagger" }) > 0
end

local function pray(castingObject)
    local canPray, hoursRemaining = canPrayAgain(castingObject)
    if canPray then
		tes3.playSound{
        	reference = tes3.player,
        	soundPath = 'x0\\bloodritual.wav'
		}
		tes3.playSound{
        	reference = tes3.player,
        	soundPath = 'x0\\blooddrip.wav'
		}
		timer.start{
            duration = .3,
            callback = function()
				tes3.playSound{
				reference = tes3.player,
				soundPath = 'x0\\bloodaura.wav'
			}
			tes3.messageBox("As your blood absorbs into the ash statue, Daedric power floods your body")
			end
		}
		timer.start{
            duration = 2.5,
            callback = function()
				tes3.cast{
					reference = castingObject,
					target = tes3.player,
					spell = "x0 daedric ritual"
				}
				useExistingPotion()
				
			end
		}
        
        updatePrayTime(castingObject)
    else
        local hourText = math.ceil(hoursRemaining) == 1 and "hour" or "hours"
        tes3.messageBox("The ash statue's power has been depleted. You must wait " .. math.ceil(hoursRemaining) .. " more " .. hourText .. " before praying again.")
    end
end

local function prayWithDagger(castingObject)
    local canPray, hoursRemaining = canPrayAgain(castingObject)
    if canPray then
		tes3.playSound{
        	reference = tes3.player,
        	soundPath = 'x0\\bloodritual.wav'
		}
		tes3.playSound{
        	reference = tes3.player,
        	soundPath = 'x0\\blooddrip.wav'
		}
		timer.start{
            duration = .3,
            callback = function()
				tes3.playSound{
					reference = tes3.player,
					soundPath = 'x0\\bloodaura.wav'
				}
				tes3.playSound{
					reference = tes3.player,
					soundPath = 'x0\\bloodwelcome.wav'
				}
				tes3.playSound{
					reference = tes3.player,
					soundPath = 'x0\\bloodom.wav'
				}
			
			tes3.messageBox("As you grasp your Daedric Dagger blade, blood absorbs into the ash statue, Daedric power floods your body")
			end
		}
		timer.start{
            duration = 2.5,
            callback = function()
				tes3.cast{
					reference = castingObject,
					target = tes3.player,
					spell = "x0 daedric ritual pure"
				}
				useBetterPotion()
				
			end
		}
        
        updatePrayTime(castingObject)
    else
        local hourText = math.ceil(hoursRemaining) == 1 and "hour" or "hours"
        tes3.messageBox("The ash statue's power has been depleted. You must wait " .. math.ceil(hoursRemaining) .. " more " .. hourText .. " before praying again.")
    end
end

local function determinePrayFunction(castingObject)
    if hasDaedricDagger() then
        prayWithDagger(castingObject)
    else
        pray(castingObject)
    end
end

local function pickUp(castingObject)
    tes3ui.leaveMenuMode()

    tes3.addItem({
        reference = tes3.player,
        item = castingObject.object.id,
        count = 1,
        playSound = true
    })

    castingObject:disable()
end

local function showAshStatueMenu(castingObject)
    local buttons = {
         {
            text = "Pick Up",
            callback = function()
                tes3ui.leaveMenuMode()
				castingObject:disable()
				tes3.addItem({
					reference = tes3.player,
					item = castingObject.object.id,
					count = 1,
					playSound = true
				})
            end
        },
		{
            text = "Make an Offering",
            callback = function()
                determinePrayFunction(castingObject)
            end
        },
	
	}

    messageBox{
        message = "Make a blood sacrifice to the ash statue?",
        buttons = buttons,
        doesCancel = true
    }
end


local function onActivate(e)
    if e.target and e.target.object.id == "misc_6th_ash_hrcs" then
        showAshStatueMenu(e.target)
        return false
    elseif e.target and e.target.object.id == "misc_6th_ash_hrmm" then
        showAshStatueMenu(e.target)
        return false
    elseif e.target and e.target.object.id == "AB_Misc_6thAshStatue07" then
        showAshStatueMenu(e.target)
        return false
    elseif e.target and e.target.object.id == "misc_6th_ash_statue_01" then
        showAshStatueMenu(e.target)
        return false
    elseif e.target and e.target.object.id == "AB_Misc_6thAshStatue02" then
        showAshStatueMenu(e.target)
        return false
    elseif e.target and e.target.object.id == "AB_Misc_6thAshStatue13" then
        showAshStatueMenu(e.target)
        return false
    elseif e.target and e.target.object.id == "AB_Misc_6thAshStatue04" then
        showAshStatueMenu(e.target)
        return false
    end
end

event.register("activate", onActivate)