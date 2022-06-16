local config = json.loadfile("config/kne_SecurityChanceInfo_config")
if not config then
    config = {
        showInfo = false,
        keyPress = false
    }
end
pickChance = 0
needKey = false
isLocked = false
isTrapped = false
local function ShowTheChance()
    if config.showInfo then
        if isequippingLockpick and isLocked then
            if not needKey then
                tes3.messageBox("Unlock chance: %.3f %s", pickChance, "%")
            else
                tes3.messageBox("Lockpicking not possible")
            end
        elseif isequippingProbe and isTrapped then
            tes3.messageBox("Disarm chance: %.2f %s", disarmChance, "%")
        end
    end
end
local function myOnKeyCallback(e)
    if config.keyPress then
        if (e.isAltDown and isequippingLockpick and isLocked) then
            if not needKey then
                tes3.messageBox("Unlock chance: %.3f %s", pickChance, "%")
            else
                tes3.messageBox("Lockpicking not possible")
            end
        elseif (e.isAltDown and isequippingProbe and isTrapped) then
            tes3.messageBox("Disarm chance: %.2f %s", disarmChance, "%")
        end
    end
end
event.register("keyDown", myOnKeyCallback)
local function DoyouKnowHowToPickALock(Tar)
    pickChance = 0
    needKey = false
    isLocked = false
    isTrapped = false
    if Tar.current == nil or Tar.current.lockNode == nil then
        return
    end
    if
        (Tar.current.object.objectType == tes3.objectType.container or
            Tar.current.object.objectType == tes3.objectType.door)
     then
        --TERUSKAN USAHA
        isequippingLockpick = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.lockpick})
        isequippingProbe = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.probe})
    else
        return
    end
    if Tar.current.lockNode.locked == false then
        isLocked = false
    else
        isLocked = true
    end
    if tes3.getTrap {reference = Tar.current} == nil then
        isTrapped = false
    else
        isTrapped = true
    end
    if tes3.getLockLevel {reference = Tar.current} > 0 then
        needKey = false
    else
        needKey = true
    end
    local fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value
    local fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value
    local fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult).value
    local fTrapCostMult = tes3.findGMST(tes3.gmst.fTrapCostMult).value
    local pcNormFat = (tes3.mobilePlayer.fatigue.current / tes3.mobilePlayer.fatigue.base)
    local fatigueTerm = fFatigueBase - fFatigueMult * (1 - pcNormFat)
    if isequippingLockpick and isLocked then
        if (tes3.getLockLevel {reference = Tar.current} ~= nil) then
            pickChance =
                math.max(
                0,
                ((0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
                    tes3.mobilePlayer.security.current) *
                    tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.lockpick}).object.quality *
                    (fFatigueBase - fFatigueMult * (1 - pcNormFat)) +
                    tes3.findGMST(tes3.gmst.fPickLockMult).value * tes3.getLockLevel {reference = Tar.current}
            )
            ShowTheChance()
        end
    elseif isequippingProbe and isTrapped then
        local trapPoints = tes3.getTrap {reference = Tar.current}.magickaCost
        local probQual = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.probe}).object.quality
        local y =
            (0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) +
            tes3.mobilePlayer.security.current
        y = y + (tes3.findGMST(tes3.gmst.fTrapCostMult).value * tes3.getTrap {reference = Tar.current}.magickaCost)
        disarmChance = math.max(0, y * probQual * fatigueTerm)
        ShowTheChance()
    end
end
event.register("activationTargetChanged", DoyouKnowHowToPickALock)
local modConfig = {}
function modConfig.onCreate(container)
    local pane = container:createThinBorder {}
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"
    local header = pane:createLabel {}
    header.color = tes3ui.getPalette("header_color")
    header.borderBottom = 25
    header.text = "Security Success Info\nversion 1.0"
    local txtBlock = pane:createBlock()
    txtBlock.widthProportional = 1.0
    txtBlock.autoHeight = true
    txtBlock.borderBottom = 25
    local txt = txtBlock:createLabel {}
    txt.wrapText = true
    txt.text = "Exposes the chance to unlock/disarm an object while equipping the appropriate tool."
    local whenHover = pane:createBlock()
    whenHover.flowDirection = "left_to_right"
    whenHover.widthProportional = 1.0
    whenHover.autoHeight = true
    local hoverLabel = whenHover:createLabel({text = "Expose when targeting a locked/trapped object:"})
    local hoverButton =
        whenHover:createButton(
        {text = config.showInfo and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value}
    )
    hoverButton.absolutePosAlignX = 1.0
    hoverButton.paddingTop = 2
    hoverButton.borderRight = 6
    hoverButton:register(
        "mouseClick",
        function(e)
            config.showInfo = not config.showInfo
            hoverButton.text =
                config.showInfo and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
        end
    )
    local whenKeyPressed = pane:createBlock()
    whenKeyPressed.flowDirection = "left_to_right"
    whenKeyPressed.widthProportional = 1.0
    whenKeyPressed.autoHeight = true
    local KeyPressedLabel = whenKeyPressed:createLabel({text = "Expose when pressing Alt:"})
    local KeyPressedButton =
        whenKeyPressed:createButton(
        {text = config.keyPress and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value}
    )
    KeyPressedButton.absolutePosAlignX = 1.0
    KeyPressedButton.paddingTop = 2
    KeyPressedButton.borderRight = 6
    KeyPressedButton:register(
        "mouseClick",
        function(e)
            config.keyPress = not config.keyPress
            KeyPressedButton.text =
                config.keyPress and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
        end
    )
    pane:updateLayout()
end
function modConfig.onClose(container)
    json.savefile("config/kne_SecurityChanceInfo_config", config, {indent = true})
end
local function registerModConfig()
    mwse.registerModConfig("Security Success Info", modConfig)
end
event.register("modConfigReady", registerModConfig)
