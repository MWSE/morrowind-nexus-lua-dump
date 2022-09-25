local function onKeyDown(e)
    local target = tes3.getPlayerTarget()
    ---@diagnostic disable-next-line: param-type-mismatch
    if e.isAltDown and target and tes3.getCurrentAIPackageId(target.mobile) ==
        tes3.aiPackage.follow then
        ---@diagnostic disable-next-line: param-type-mismatch
        local targetActor = target.mobile.aiPlanner:getActivePackage()
                                .targetActor
        tes3.setAITravel({
            reference = target,
            destination = tes3.mobilePlayer.position +
                (tes3.mobilePlayer.position - target.mobile.position) * 0.25
        })
        timer.start {
            duration = 4,
            type = timer.simulate,
            callback = function()
                tes3.setAIFollow({reference = target, target = targetActor})
            end
        }
    end
end
event.register("keyDown", onKeyDown)
