-- Pretty Gold --
-- OpenMW 50 --

local ui      = require('openmw.ui')
local util    = require('openmw.util')
local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local storage = require('openmw.storage')

-- Settings
local cfg          = storage.playerSection("SettingsPrettyLoot")
local cfgScale     = storage.playerSection("ScalingPrettyLoot")
local cfgBehavior  = storage.playerSection("BehaviorPrettyLoot")

-- State
local currentGold, targetGold, goldTimer, goldDelay, lastGoldCount = 0, 0, 0, 0, 0
local goldHUD = nil   
local lastShowBgState = nil 
local isPulsing, pulseTimer = false, 0
local GOLD_ROLL_DELAY, FADE_TIME, PULSE_DURATION = 0.8, 1.2, 0.5 

local function updateGoldUI(textAlpha, iconAlpha, pulseScale)
    local fontSize = cfgScale:get("goldFontSize") or 28
    local posX, posY = cfgScale:get("goldPosX") or 0.52, cfgScale:get("goldPosY") or 0.60
    local iconStyle = cfgScale:get("goldIconStyle")
    local iconPath = (iconStyle == "Starwind") and "icons/gold.dds" or "icons/m/Tx_Gold_001.dds"
    
    local showBg = cfg:get("showGoldBackground")
    if showBg == nil then showBg = true end

    if goldHUD and lastShowBgState ~= showBg then
        goldHUD:destroy()
        goldHUD = nil
    end

    if not goldHUD then
        local hudContent = ui.content {}
        
        if showBg then
            hudContent:add({
                type = ui.TYPE.Image,
                name = "bg",
                props = {
                    resource = ui.texture { path = "textures/pretty_loot/popup_gold.dds" },
                    relativeSize = util.vector2(1, 1),
                    color = util.color.rgba(1, 1, 1, 0.5)
                }
            })
        end

        hudContent:add({
            type = ui.TYPE.Flex,
            name = "mainFlex",
            props = { horizontal = true, align = ui.ALIGNMENT.Center, relativeSize = util.vector2(1, 1) },
            content = ui.content {
                { 
                    type = ui.TYPE.Image, 
                    name = "icon",
                    props = { resource = ui.texture { path = iconPath }, size = util.vector2(36, 36) }
                },
                {
                    type = ui.TYPE.Flex,
                    name = "numStack",
                    props = { horizontal = false, align = ui.ALIGNMENT.Start, position = util.vector2(8, 0) },
                    content = ui.content {
                        { type = ui.TYPE.Text, name = "total", props = { text = "", textSize = fontSize, textColor = util.color.rgb(1, 0.85, 0.45), textShadow = true } },
                        { type = ui.TYPE.Text, name = "change", props = { text = "", textSize = math.floor(fontSize * 0.9), textColor = util.color.rgb(1, 1, 1), textShadow = true } }
                    }
                }
            }
        })

        goldHUD = ui.create {
            layer = 'HUD',
            props = {
                relativePosition = util.vector2(posX, posY), 
                anchor = util.vector2(0.5, 0.5),
                size = util.vector2(250, 100), 
            },
            content = hudContent
        }
        lastShowBgState = showBg
    end
    
    local layout = goldHUD.layout.content
    
    if showBg and layout.bg then
        layout.bg.props.color = util.color.rgba(1, 1, 1, iconAlpha * 0.5)
    end

    local flexRoot = layout.mainFlex.content
    local stack    = flexRoot.numStack.content
    
    flexRoot.icon.props.alpha = iconAlpha
    flexRoot.icon.props.resource = ui.texture { path = iconPath }

    stack.total.props.textSize = math.floor(fontSize * pulseScale)
    stack.total.props.text = tostring(math.floor(currentGold + 0.5))
    stack.total.props.alpha = textAlpha
    
    local changeVal = math.floor((targetGold - currentGold) + 0.5)
    stack.change.props.text = (changeVal == 0) and "" or ((changeVal > 0 and "+" or "") .. tostring(changeVal))
    stack.change.props.alpha = textAlpha

    goldHUD.layout.props.relativePosition = util.vector2(posX, posY)
    goldHUD:update()
end


return {
    engineHandlers = {
        onInit = function()
            local inv = types.Actor.inventory(self)
            lastGoldCount = inv:countOf("gold_001")
            currentGold, targetGold = lastGoldCount, lastGoldCount
            print("Gold Script Loaded: Initial count is " .. lastGoldCount)
        end,
        onLoad = function()
            local inv = types.Actor.inventory(self)
            local actualGold = inv:countOf("gold_001")
            lastGoldCount, currentGold, targetGold = actualGold, actualGold, actualGold
        end,
        onFrame = function(dt)
            if cfg:get("showGold") == false then 
                if goldHUD then 
                    goldHUD:destroy() 
                    goldHUD = nil 
                end
                goldTimer, goldDelay, isPulsing = 0, 0, false
                return 
            end

            -- 2. PERFORMANCE CHECK
            local inv = types.Actor.inventory(self)
            local count = inv:countOf("gold_001")
            local GOLD_STAY_TIME = cfgBehavior:get("goldStayTime") or 2.5
            local GOLD_ROLL_SPEED = cfgBehavior:get("goldRollSpeed") or 12.0

            -- 3. DETECT CHANGES
            if count ~= lastGoldCount then
                targetGold = count
                goldTimer = GOLD_STAY_TIME
                goldDelay = GOLD_ROLL_DELAY
                lastGoldCount = count
                isPulsing = false
            end

            -- 4. ANIMATION & RENDERING
            if goldTimer > 0 then
                if goldDelay > 0 then 
                    goldDelay = goldDelay - dt
                else
                    local diff = targetGold - currentGold
                    if math.abs(diff) > 0.01 then
                        local step = diff * dt * GOLD_ROLL_SPEED
                        if math.abs(step) < 1 then step = (diff > 0) and 1 or -1 end
                        currentGold = (math.abs(step) >= math.abs(diff)) and targetGold or (currentGold + step)
                        goldTimer = GOLD_STAY_TIME 
                    else
                        currentGold = targetGold
                        if not isPulsing then isPulsing, pulseTimer = true, PULSE_DURATION end
                    end
                end

                local pScale = 1.0
                if isPulsing and pulseTimer > 0 then
                    pulseTimer = pulseTimer - dt
                    pScale = 1.0 + (math.sin((PULSE_DURATION - pulseTimer) / PULSE_DURATION * math.pi) * 0.3)
                end

                goldTimer = goldTimer - dt
                local tAlpha, iAlpha = 1.0, 1.0
                if goldTimer < FADE_TIME then
                    local progress = goldTimer / FADE_TIME
                    tAlpha = math.max(0, (progress - 0.5) * 2)
                    iAlpha = math.min(1, progress * 2)
                end

                updateGoldUI(tAlpha, iAlpha, pScale)

                if goldTimer <= 0 then 
                    if goldHUD then goldHUD:destroy() end
                    goldHUD, isPulsing = nil, false
                end
            elseif goldHUD then
                goldHUD:destroy()
                goldHUD = nil
            end
        end 
    } 
}