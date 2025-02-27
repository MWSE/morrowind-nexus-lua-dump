local function whoIsThat()
    if tes3.menuMode() or tes3.onMainMenu() then return end
    local hitResult = tes3.rayTest({ position = tes3.getCameraPosition(), direction = tes3.getCameraVector(), root = tes3.game.worldPickRoot })
    local hitReference = hitResult and hitResult.reference
    if hitReference == nil then return end
    mwse.log("TARGET TYPE: "..hitReference.objectType)
    if not hitReference.object.level then
        return
    end
    local levelDiff = tes3.mobilePlayer.object.level - hitReference.object.level
    local message
    if levelDiff >= 3 then
        message = "You easily outclass "..hitReference.object.name.."."
    end
    if levelDiff < 3 then
        message = "You should have the edge over "..hitReference.object.name..", given your experiences."
    end
    if levelDiff == 0 then
        message = "You and "..hitReference.object.name.." are roughly equal in power. You might be able to take them on."
    end
    if levelDiff < 0 then
        message = hitReference.object.name.." appears to have the upper hand on you."
    end
    if levelDiff <= -3 then 
        message = hitReference.object.name.." looks to be a powerful foe. You might want to steer clear."
    end
    tes3.messageBox(message)
end

event.register(tes3.event.keyDown, whoIsThat, { filter = tes3.keyboardCode.h})