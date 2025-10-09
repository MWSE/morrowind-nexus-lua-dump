local core = require('openmw.core')
local self = require('openmw.self')
local input = require('openmw.input')
local types = require('openmw.types')

-- 标记是否正在加速
local isSprinting = false
local speedBonus = 0  -- 当前加成的速度值
local sprintMultiplier = 3.0  -- 加速倍率（这里是3倍）

local function spdMod(modSign, modVal)
    -- 修改速度属性修正值
    local attr = types.Actor.stats.attributes.speed(self)
    attr.modifier = attr.modifier + modSign * modVal
end

local function onFrame()
    -- 检测左Alt键状态
    local altPressed = input.isAltPressed()
    local attr = types.Actor.stats.attributes.speed(self)

    if altPressed and not isSprinting then
        -- 开始加速
        isSprinting = true
        speedBonus = attr.base * (sprintMultiplier - 1)  -- 加成值 = 原始速度 × (倍率 - 1)
        spdMod(1, speedBonus)
    elseif not altPressed and isSprinting then
        -- 结束加速
        spdMod(-1, speedBonus)
        isSprinting = false
        speedBonus = 0
    end
end

return {
    engineHandlers = {
        onFrame = onFrame,
    }
}
