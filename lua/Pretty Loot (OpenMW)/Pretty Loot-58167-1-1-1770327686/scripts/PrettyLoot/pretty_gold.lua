-- Pretty Gold --
-- OpenMW 50 --

local ui      = require('openmw.ui')
local util    = require('openmw.util')
local self    = require('openmw.self')
local types   = require('openmw.types')
local core    = require('openmw.core')
local storage = require('openmw.storage')

--------------------------------------------------
-- Pull from shared settings
--------------------------------------------------
local cfg          = storage.playerSection("SettingsPrettyLoot")
local cfgScale     = storage.playerSection("ScalingPrettyLoot")
local cfgBehavior  = storage.playerSection("BehaviorPrettyLoot")

--------------------------------------------------
-- State
--------------------------------------------------
local currentGold   = 0      
local targetGold    = 0       
local goldTimer     = 0        
local goldDelay     = 0        
local lastGoldCount = 0
local goldHUD       = nil   
local isPulsing     = false
local pulseTimer    = 0

--------------------------------------------------
-- Constants
--------------------------------------------------
local GOLD_ROLL_DELAY = 0.8
local FADE_TIME       = 0.8
local PULSE_DURATION  = 0.4

local function updateGoldUI(alpha, pulseScale)
    local combinedScale = pulseScale
	local fontSize = cfgScale:get("goldFontSize") or 24
    local posX = cfgScale:get("goldPosX") or 0.52
    local posY = cfgScale:get("goldPosY") or 0.60

    if not goldHUD then
        goldHUD = ui.create {
            layer = 'HUD',
            props = {
                relativePosition = util.vector2(posX, posY), 
                anchor = util.vector2(0.5, 0.5),
                size = util.vector2(260, 80),
            },
            content = ui.content {
                { type = ui.TYPE.Image, props = { resource = ui.texture { path = "textures/pretty_loot/gold_bg.dds" }, relativeSize = util.vector2(1, 1) }},
                { type = ui.TYPE.Image, props = { resource = ui.texture { path = "icons/m/Tx_Gold_001.dds" }, size = util.vector2(38, 38), relativePosition = util.vector2(0.105, 0.425), anchor = util.vector2(0.5, 0.5), color = util.color.rgb(1, 0.85, 0.6), }},
                { type = ui.TYPE.Text, name = "total", props = { text = "", textSize = fontSize, textColor = util.color.rgb(1, 0.8, 0.4), textShadow = true, relativePosition = util.vector2(0.4, 0.3), anchor = util.vector2(0.5, 0.5) }},
                { type = ui.TYPE.Text, name = "change", props = { text = "", textSize = math.floor(fontSize * 0.9), textColor = util.color.rgb(1, 0.85, 0.55), textShadow = true, relativePosition = util.vector2(0.4, 0.58), anchor = util.vector2(0.5, 0.5) }}
            }
        }
    end
    
    local content = goldHUD.layout.content
    content.total.props.textSize = math.floor(fontSize * pulseScale)
    content.total.props.text = tostring(math.floor(currentGold + 0.5))
    
    local change = math.floor((targetGold - currentGold) + 0.5)
    content.change.props.text = (change == 0) and "" or ((change > 0 and "+" or "") .. tostring(change))
    
    local useColors = cfgBehavior:get("useColors")
    if useColors ~= false then
        content.change.props.textColor = (targetGold >= currentGold and util.color.rgb(0.45, 0.85, 0.15) or util.color.rgb(1, 0.2, 0.2))
    else
        content.change.props.textColor = util.color.rgb(1, 1, 1)
    end
    
    goldHUD.layout.props.relativePosition = util.vector2(posX, posY)
    goldHUD.layout.props.alpha = alpha
    goldHUD:update()
end

return {
    engineHandlers = {
        onInit = function()
            local inv = types.Actor.inventory(self)
            lastGoldCount = inv:countOf("gold_001")
            currentGold, targetGold = lastGoldCount, lastGoldCount
        end,
		
        onLoad = function(data)
            local inv = types.Actor.inventory(self)
            local actualGold = inv:countOf("gold_001")
            lastGoldCount, currentGold, targetGold = actualGold, actualGold, actualGold
        end,

        onFrame = function(dt)
    if cfg:get("enabled") == false or cfgBehavior:get("showGold") == false then 
        if goldHUD then goldHUD:destroy(); goldHUD = nil end
        return 
    end

            local inv = types.Actor.inventory(self)
            local count = inv:countOf("gold_001")
            
            local GOLD_STAY_TIME  = cfgBehavior:get("goldStayTime") or 2.5
            local GOLD_ROLL_SPEED = cfgBehavior:get("goldRollSpeed") or 12.0

            if count ~= lastGoldCount then
                targetGold = count
                goldTimer = GOLD_STAY_TIME
                goldDelay = GOLD_ROLL_DELAY
                lastGoldCount = count
                isPulsing = false
            end

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
                        if not isPulsing then
                            isPulsing = true
                            pulseTimer = PULSE_DURATION
                        end
                    end
                end

                local pScale = 1.0
                if isPulsing and pulseTimer > 0 then
                    pulseTimer = pulseTimer - dt
                    local progress = (PULSE_DURATION - pulseTimer) / PULSE_DURATION
                    pScale = 1.0 + (math.sin(progress * math.pi) * 0.3)
                end

                goldTimer = goldTimer - dt
                local alpha = (goldTimer < FADE_TIME) and (goldTimer / FADE_TIME) or 1.0
                updateGoldUI(alpha, pScale)

                if goldTimer <= 0 then 
                    if goldHUD then goldHUD:destroy() end
                    goldHUD = nil 
                    isPulsing = false
                end
            end
        end
    }
}
