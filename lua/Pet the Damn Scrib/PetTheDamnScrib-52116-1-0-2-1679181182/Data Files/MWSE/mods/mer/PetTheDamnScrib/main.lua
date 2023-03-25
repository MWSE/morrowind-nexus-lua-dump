---@param e activateEventData
event.register("activate", function(e)
    if e.target.baseObject.id:lower() ~= "scrib" then return end
    if not e.target.mobile then return end
    if e.target.mobile.inCombat then return end
    if e.target.isDead then return end
    tes3.playAnimation{reference = e.target, group = tes3.animationGroup.idle3, loopCount = 0, startFlag = tes3.animationStartFlag.immediate}
    tes3.messageBox("You pet the scrib.")
end)