local bs = require("BeefStranger.Fist of Azuras Star.common")
local cfg = require("BeefStranger.Fist of Azuras Star.config")


event.register("initialized", function()
    print("[MWSE:Fist of Azura's Star] initialized")
end)

local function logmsg(string, ...)
    local line = debug.getinfo(2, "l").currentline
    local message = string.format("[%s|FistOfAzura] - %s", line, string)
    mwse.log(message, ...)
    tes3.messageBox(message, ...)
end

local function H2H()
    if tes3.mobilePlayer then
        -- mwse.log("H2H triggered")
        local useSpeed = cfg.useSpeed
        local h2hMax = cfg.h2hMax
        local speedMax = cfg.speedMax
        local baseSpeedOnly = cfg.baseSpeedOnly

        local h2hSkill = tes3.mobilePlayer.handToHand.current
        local playerSpeed = tes3.mobilePlayer.speed
        local speedType = (baseSpeedOnly and playerSpeed.base) or playerSpeed.current

        local handToHand = bs.lerp(0.1, h2hMax, 100, h2hSkill, true)
        local speed = ((useSpeed and bs.lerp(0.01, speedMax, 100, speedType, true)) or 0)

        -- debug.log(speedType)
        -- debug.log((baseSpeedOnly and playerSpeed.base) or playerSpeed.current)

        return handToHand + speed
    end
end

local counter = 0 --Debug Counter

---@param e attackStartEventData
local function punchy(e)
    if e.reference == tes3.player then
        if not e.mobile.readiedWeapon then
            e.attackSpeed = H2H()
            ---------------------Debug-----------------------
            -- local ps = e.mobile.speed --Player speed
            -- local handToHand = e.mobile.handToHand
            -- counter = counter + 1
            -- if counter % 5 == 0 then
            --     debug.log(H2H())
            --     debug.log(e.attackSpeed)
            --     debug.log(cfg.h2hMax)
            --     debug.log(handToHand.current)
            --     debug.log(cfg.baseSpeedOnly and ps.base or ps.current)
            --     debug.log(cfg.speedMax)
            --     debug.log(counter)
            -- end
            ---------------------Debug-----------------------
        end
    end
end
event.register(tes3.event.attackStart, punchy)


local function skillTooltip(e)
    if not cfg.showSpeed then return end
    if e.skill == tes3.skill.handToHand then
        local handToHand = e.tooltip:findChild("attribute").parent        -- can use name
        if handToHand then
            local label = handToHand:createLabel { id = "H2H" }
            label.text = ("Attack Speed: %.2f"):format(H2H())
            label.color = { 0.875, 0.788, 0.624 }
        end
    end
end
event.register(tes3.event.uiSkillTooltip, skillTooltip)
