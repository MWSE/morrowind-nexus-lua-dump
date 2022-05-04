local common = require("MTArmor.common")

event.register("modConfigReady", function()
    require("MTArmor.mcm")
	common.config  = require("MTArmor.config")
end)

local moragTongArmor = {
    helmet = "smt_hl_cl",
    cuirass = "smt_chest",
    leftPauldron = "smt_pl_l",
    rightPauldron = "smt_pl_r",
    greaves = "smt_greaves",
    boots = "smt_boots",
    leftBracer = "smt_wr_l",
    rightBracer = "smt_wr_r",
    leftGauntlet = "smt_wr_l",
    rightGauntlet = "smt_wr_r"
}

local helmetSwitch = {
    smt_hl_op = "smt_hl_cl",
    smt_hl_cl = "smt_hl_op"
}

local function switchItems(current, new, itemData)
    tes3.removeItem{item = current, itemData = itemData, reference = tes3.player}
    tes3.addItem{item = new, itemData = itemData, reference = tes3.player}
    tes3.mobilePlayer:equip({item = new, itemData = itemData})
end

local function addArmor(reference)
    for part, item in pairs(moragTongArmor) do
        if not string.endswith(part, "Gauntlet") then
            tes3.addItem{reference = reference, item = item}
        end
    end
	tes3.addItem{reference = reference, item = "smt_skirt"}
end

local function replaceArmor(reference)
    local greaves = false
    for armorPart, slot in pairs(tes3.armorSlot) do
        local stack = tes3.getEquippedItem{actor = reference, objectType = tes3.objectType.armor, slot = slot}
        if stack then
            if slot == 'greaves' then
                greaves = true
            end
            tes3.removeItem{reference = reference, item = stack.object}
            tes3.addItem{reference = reference, item = moragTongArmor[armorPart]}
        end
    end
    if not greaves then
        tes3.addItem{reference = reference, item = "smt_skirt"}
    end
end

local function onMobileActivated(e)
	if e.reference.baseObject.faction ~= tes3.getFaction("Morag Tong") then
		return
    end

    local armorAdded = e.reference.data["moragTongArmorAdded"]

    if armorAdded  then
        return
    end

    if common.config.addFullSetTo[e.reference.baseObject.id:lower()] then
        addArmor(e.reference)
        e.reference.data["moragTongArmorAdded"] = true
    elseif common.config.replaceArmor and not common.config.dontReplaceArmorOf[e.reference.baseObject.id:lower()] then
        replaceArmor(e.reference)
        e.reference.data["moragTongArmorAdded"] = true
    end
end

local function onEquip(e)

    local current = e.item.id
    local new = helmetSwitch[current]

	if not new then
		return
    end

    if e.reference ~= tes3.player then
        return
    end

    local itemData = e.itemData
    
    if tes3.player.object.race.isBeast then
        if current == "smt_hl_cl" then
            timer.frame.delayOneFrame(function()
                switchItems(current, new, itemData)
            end)
            return false
        end
    elseif current == "smt_hl_op" then
        timer.frame.delayOneFrame(function()
            switchItems(current, new)
        end)
        return false
    end
end



local function onInitialized(e)
	if common.config.modEnabled then
		mwse.log(string.format("[%s]: enabled", common.dictionary.modName))
		event.register("equip", onEquip)
		event.register("mobileActivated", onMobileActivated)
		--event.register("activate", onActivate)
	else
		mwse.log(string.format("[%s]: disabled", common.dictionary.modName))
	end
end

event.register("initialized", onInitialized)