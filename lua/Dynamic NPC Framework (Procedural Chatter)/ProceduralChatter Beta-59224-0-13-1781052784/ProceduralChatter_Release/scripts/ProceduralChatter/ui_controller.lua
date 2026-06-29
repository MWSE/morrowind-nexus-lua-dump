local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local originalPrint = print
_G.print = function(...)
    if ScheduleConfig.DEBUG_MODE then
        originalPrint(...)
    end
end

local ui = require('openmw.ui')
local self = require('openmw.self')
local types = require('openmw.types')
local camera = require('openmw.camera')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local anim = require('openmw.animation')

-- Require settings moved to player.lua to avoid double registration

local settingsGroup = storage.playerSection("01_Settings_Chatter_General")

local activeSubtitles = {}
local uiScale = 1.0 -- Default, might need adjusting based on resolution/settings

local function splitByPunctuation(text)
    local chunks = {}
    for sentence in text:gmatch("[^%.%!%?]+[%.%!%?]*") do
        -- Trim whitespace
        sentence = sentence:match("^%s*(.-)%s*$")
        if #sentence > 0 then
            table.insert(chunks, sentence)
        end
    end
    if #chunks == 0 then table.insert(chunks, text) end
    return chunks
end

local function wrapText(text, maxLength)
    if not maxLength or maxLength <= 0 then return text end
    
    local lines = {}
    local line = ""
    for word in text:gmatch("%S+") do
        local space = (#line > 0) and 1 or 0
        if #line + space + #word > maxLength then
            if #line > 0 then
                table.insert(lines, line)
                line = word
            else
                table.insert(lines, word)
                line = ""
            end
        else
            if #line > 0 then line = line .. " " .. word else line = word end
        end
    end
    if #line > 0 then table.insert(lines, line) end
    
    -- Fallback for empty
    if #lines == 0 then table.insert(lines, text) end
    
    return lines
end

local function showSubtitle(data)
    local actor = data.actor
    if not actor then return end

    local mode = settingsGroup:get("04_SubtitleMode")
    if not data.companionDialogue and (mode == "None" or mode == "Regular") then return end
    
    if activeSubtitles[actor.id] and activeSubtitles[actor.id].widget then 
        activeSubtitles[actor.id].widget:destroy() 
    end
    
    local maxLen = settingsGroup:get("06_MaxLineLength") or 60
    
    -- 1. Split into Sentences
    local rawChunks = splitByPunctuation(data.text)
    local processedChunks = {}
    local totalLen = 0
    
    for _, raw in ipairs(rawChunks) do
        -- wrapText now returns a TABLE of lines
        local lines = wrapText(raw, maxLen)
        -- Flatten text for weight calculation
        local fullText = table.concat(lines, " ")
        local weight = #fullText 
        totalLen = totalLen + weight
        table.insert(processedChunks, { lines = lines, weight = weight })
    end
    
    local totalDuration = data.duration or 3.0
    for _, chunk in ipairs(processedChunks) do
        chunk.duration = (chunk.weight / totalLen) * totalDuration
    end

    -- Initial Frame Content Construction
    local currentLines = processedChunks[1].lines
    local textSize = settingsGroup:get("03_SubtitleTextSize") or 18
    local contentList = {}
    
    for _, lineStr in ipairs(currentLines) do
        table.insert(contentList, {
            type = ui.TYPE.Text,
            props = {
                text = lineStr,
                textSize = textSize,
                textColor = util.color.rgb(1, 1, 1),
                textAlign = ui.ALIGNMENT.Center,
                textShadow = true,
                textShadowColor = util.color.rgb(0, 0, 0),
                margins = util.vector2(0, 0), -- Tight spacing between lines
            }
        })
    end

    local widget = ui.create({
        type = ui.TYPE.Flex,
        layer = 'HUD',
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 1.0),
            horizontal = false, 
            vertical = true,
            autosize = true,
            arrange = ui.ALIGNMENT.Center,
            visible = false
        },
        content = ui.content(contentList)
    })

    activeSubtitles[actor.id] = {
        widget = widget,
        actor = actor,
        startTime = core.getSimulationTime(),
        chunks = processedChunks,
        currentChunkIndex = 1,
        chunkStartTime = core.getSimulationTime(), 
        endTime = core.getSimulationTime() + totalDuration,
        lastLines = currentLines,
        lastSize = textSize,
        lastAlpha = 1.0
    }
end

local function onFrame(dt)
    local mode = settingsGroup:get("04_SubtitleMode")
    if mode == "None" or mode == "Regular" then 
        for id, sub in pairs(activeSubtitles) do
            if sub.widget then sub.widget:destroy() end
            activeSubtitles[id] = nil
        end
        return 
    end

    local now = core.getSimulationTime()
    local viewportToWorld = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    local camPos = camera.getPosition()
    local currentTextSize = settingsGroup:get("03_SubtitleTextSize") or 18

    for id, sub in pairs(activeSubtitles) do
        if now > sub.endTime then
            if sub.widget then sub.widget:destroy() end
            activeSubtitles[id] = nil
        else
            -- 1. Update Content
            local chunk = sub.chunks[sub.currentChunkIndex]
            local chunkElapsed = now - sub.chunkStartTime
            
            if chunkElapsed > chunk.duration and sub.currentChunkIndex < #sub.chunks then
                sub.currentChunkIndex = sub.currentChunkIndex + 1
                sub.chunkStartTime = now 
                chunk = sub.chunks[sub.currentChunkIndex]
            end
            
            -- Re-build content if lines changed (Page flip or new wrap results if dynamic?)
            -- Note: We only check if the *pointer* to lines array changed or content differs
            local linesChanged = false
            if #sub.lastLines ~= #chunk.lines then 
                linesChanged = true 
            else
                for i, l in ipairs(chunk.lines) do
                    if l ~= sub.lastLines[i] then linesChanged = true; break end
                end
            end
            
            if linesChanged or sub.lastSize ~= currentTextSize then
                 -- We need to replace the content list totally because number of lines might change
                 -- OpenMW ui widgets allow updating content? Yes, layout.content is mutable?
                 -- Usually better to just update properties of existing if count same, but count changes.
                 -- Simplest: Destroy and recreate? Or just update content list.
                 -- Updating `layout.content` directly with a new list works in OpenMW.
                 
                 local newContent = {}
                 for _, lineStr in ipairs(chunk.lines) do
                    table.insert(newContent, {
                        type = ui.TYPE.Text,
                        props = {
                            text = lineStr,
                            textSize = currentTextSize,
                            textColor = util.color.rgba(1, 1, 1, sub.lastAlpha), -- preserve alpha
                            textAlign = ui.ALIGNMENT.Center,
                            textShadow = true,
                            textShadowColor = util.color.rgba(0, 0, 0, sub.lastAlpha),
                            margins = util.vector2(0, 0),
                        }
                    })
                 end
                 sub.widget.layout.content = ui.content(newContent)
                 
                 sub.lastLines = chunk.lines
                 sub.lastSize = currentTextSize
            end

    -- 2. Update Position
             local isSitting = false
             if sub.actor and sub.actor:isValid() then
             local ok, sitting = pcall(function()
                 return anim.isPlaying(sub.actor, 'pcdbssit5') or anim.isPlaying(sub.actor, 'dbssit5') or anim.isPlaying(sub.actor, 'dbssit6') or anim.isPlaying(sub.actor, 'sdpvasitting6') or anim.isPlaying(sub.actor, 'sitidle1') or anim.isPlaying(sub.actor, 'IdleSit')
             end)
             isSitting = ok and sitting or false
             end
             
             local zOffset = isSitting and 115 or 150
             local headOffset = util.vector3(0, 0, zOffset) 
             local worldPos = sub.actor.position + headOffset
             local screenPos = camera.worldToViewportVector(worldPos)
             local distVector = worldPos - camPos
             local dist = distVector:length()
             local inFront = distVector:dot(viewportToWorld) > 0
             
             local maxDist = settingsGroup:get("10_SubtitleFadeEnd") or 1000
             local fadeStartDist = settingsGroup:get("09_SubtitleFadeStart") or 300
             
             if inFront and dist < maxDist and screenPos.z < maxDist then 
                 local screenSize = ui.screenSize()
                 local relX = screenPos.x / screenSize.x
                 local relY = screenPos.y / screenSize.y
                 
                 sub.widget.layout.props.relativePosition = util.vector2(relX, relY)
                 
                 local alpha = 1.0
                 if dist > fadeStartDist then
                     local factor = 1.0 - ((dist - fadeStartDist) / (maxDist - fadeStartDist))
                     factor = math.max(0, math.min(1, factor))
                     alpha = factor
                 end
                 
                 if math.abs(sub.lastAlpha - alpha) > 0.01 then
                     -- Propagate alpha to all children
                     for _, child in ipairs(sub.widget.layout.content) do
                         child.props.textColor = util.color.rgba(1, 1, 1, alpha)
                         child.props.textShadowColor = util.color.rgba(0, 0, 0, alpha)
                     end
                     sub.lastAlpha = alpha
                 end
                 
                 sub.widget.layout.props.visible = true
             else
                 sub.widget.layout.props.visible = false
             end
             
             sub.widget:update()
        end
    end
end

local function clearAllSubtitles(_data)
    for id, sub in pairs(activeSubtitles) do
        if sub.widget then
            pcall(function() sub.widget:destroy() end)
        end
        activeSubtitles[id] = nil
    end
end

return {
    engineHandlers = {
        onFrame = onFrame
    },
    eventHandlers = {
        ProceduralChatter_ShowSubtitle = showSubtitle,
        ProceduralChatter_ClearSubtitle = clearAllSubtitles,
    }
}
