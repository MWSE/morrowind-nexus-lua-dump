local Actor = require('openmw.types').Actor
local async = require('openmw.async')
local core = require('openmw.core')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local constants = require('scripts.omw.mwui.constants')

local ZUtility  = require('scripts.ZModUtils.Utility')
local ZUI       = require('scripts.ZModUtils.UI')

local vector2 = util.vector2

local CONSTANTS = {
    
    SkillTextSize = 14,
    SkillGroupInternalPadding = 2,
    SkillGroupPadding = 4,
    SkillProgressBarSize = vector2(216, 4),

    SkillGroupSize = vector2(220, 20),

    SkillProgressBarColor = util.color.rgb(0.90, 0.20, 0.15),
    SkillProgressBarTexturePath = 'textures/menu_bar_gray.dds',

    -- When skill gain occurs, text will switch to highlight and then fade towards normal over some time.
    SkillTextColorNormal = constants.normalColor,
    SkillTextColorHighlight = util.color.rgb(0.85, 0.85, 0.85),
}

local sWindowAlpha = 1.0
local sBackgroundAlpha = 1.0
local sWindowBorder = true
local sSkillFlashTime = 2.0

local progressBarTexture = ui.texture({
    path = CONSTANTS.SkillProgressBarTexturePath,
    size = vector2(1, 16),
    offset = vector2(0, 0),
})

local function lerp(c0, c1, a)
    return util.color.rgb(
        c0.r + (c1.r - c0.r) * a,
        c0.g + (c1.g - c0.g) * a,
        c0.b + (c1.b - c0.b) * a
    )
end

local function createTrackedSkillElement()

    local textLayout = {
        type = ui.TYPE.Text,
        props = {
            text = "SkillName 1.00 (0.00)",
            textSize = CONSTANTS.SkillTextSize,
            textColor = constants.normalColor,
            textShadowColor = util.color.rgb(0, 0, 0),
        }
    }


    local pbarImage = {
        type = ui.TYPE.Image,
        props = {
            tileH = true,
            tileV = true,
            size = CONSTANTS.SkillProgressBarSize,
            color = CONSTANTS.SkillProgressBarColor,
            resource = progressBarTexture,
        }
    }

    local pbarBorder = {
        template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        props = {

        },
        content = ui.content({
            {
                type = ui.TYPE.Widget,
                props = {
                    size = CONSTANTS.SkillProgressBarSize,
                },
                content = ui.content({
                    pbarImage
                })
            }
        })
    }

    local vGroup = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            size = CONSTANTS.SkillGroupSize,
            --align = ui.ALIGNMENT.Center,
            --arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({
            textLayout,
            {
                type = ui.TYPE.Widget,
                props = {
                    size = vector2(0, CONSTANTS.SkillGroupInternalPadding)
                },
            },
            pbarBorder,
        })
    }

    local root = {
        --template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Container,
        props = {

        },
        userData = {
            progressBar = pbarImage,
            text = textLayout,
        },
        content = ui.content({vGroup})
    }

    return ui.create(root)
end

local function createTrackerWindow()

    local list = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            anchor = vector2(0.5, 0.5),
            relativePosition = vector2(0.5, 0.5),
            inheritAlpha = false,
            alpha = sWindowAlpha,
            --arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({})
    }

    local windowLayout = {
        --template = I.MWUI.templates.boxSolid,
        type = ui.TYPE.Widget,
        layer = 'ZST_WINDOW',
        props = {
            --anchor = vector2(0.0, 0.0),
            position = vector2(0, 0),
            alpha = sWindowAlpha,
            inheritAlpha = false,
            --size = vector2(0, 0),
            --relativePosition = vector2(0.0, 0.5)
        },
        userData = {
            skills = {},
            listLayout = list,
        },
        content = ui.content({ list }),
    }

    local layout = {
        template = sWindowBorder and I.MWUI.templates.boxSolid or nil,
        type = ui.TYPE.Container,
        layer = 'ZST_WINDOW',
        props = {
            alpha = sBackgroundAlpha,
            inheritAlpha = false,
        },
        userData = {
            drag = false,
            dragStart = vector2(0, 0),
            dragOffset = vector2(0, 0),
        },
        content = ui.content{
            windowLayout,
        }
    }

    local element = ui.create(layout)
    windowLayout.userData.element = element

    layout.events = {
        mousePress = async:callback(function(evt, layout)
            layout.userData.drag = true
            layout.userData.dragOffset = evt.offset
            layout.userData.dragStart = evt.position
        end),
        mouseRelease = async:callback(function(evt, layout)
            layout.userData.drag = false
        end),
        mouseMove = async:callback(function(evt, layout)
            if layout.userData.drag then
                local newX = evt.position.x - layout.userData.dragOffset.x
                local newY = evt.position.y - layout.userData.dragOffset.y

                local sz = ui.layers[ui.layers.indexOf('HUD')].size

                local inner = layout.content[1]

                newX = math.max(0.0, math.min(sz.x - inner.props.size.x, newX))
                newY = math.max(0.0, math.min(sz.y - inner.props.size.y, newY))

                layout.props.position = vector2(newX, newY)
                I.ZST.setWindowPosition(layout.props.position)
                inner.userData.element:update()
            end
        end)
    }

    element:update()
    return element
end

local function getSkillData(window, idx)
    assert(window and window.layout.content and #window.layout.content > 0)
    local inner = window.layout.content[1]
    assert(inner and inner.userData)

    local skills = inner.userData.skills
    assert(skills)

    return skills[idx]
end

-- Update the values for a specific skill, does not require a window update.
 local function updateTrackedSkill(window, idx, value)
    local sd = getSkillData(window, idx)
    assert(sd, 'unable to find skill data in window')

    if value > sd.value then
        sd.interp = sSkillFlashTime
    end
    sd.value = value

    local element = sd.element
    assert(element, 'skill UiElement not set')

    local text = element.layout.userData.text
    local pbar = element.layout.userData.progressBar
    assert(text and pbar)

    local delta = sd.value - sd.startValue

    local progress = sd.value - math.floor(sd.value)

    text.props.text = string.format("%s %.2f (%.2f)", sd.name, sd.value, delta)
    pbar.props.size = vector2(progress * CONSTANTS.SkillProgressBarSize.x, CONSTANTS.SkillProgressBarSize.y)

    element:update()
end

local function refreshSkillList(window)
    assert(window and window.layout.content)
    local inner = window.layout.content[1]
    assert(inner and inner.userData)

    local list = inner.userData.listLayout
    assert(list)

    local skills = inner.userData.skills
    assert(skills)

    -- Clear list and insert again
    list.content = ui.content({})
    local height = 0
    for i=1, #skills do
        
        if skills[i] and skills[i].name ~= 'None' then
            assert(skills[i].element ~= nil)

            -- Add Padding between elements
            if #list.content > 0 then
               list.content:add({
                    type = ui.TYPE.Widget,
                    props = {
                        size = vector2(0, CONSTANTS.SkillGroupPadding)
                    }
                })
                height = height + CONSTANTS.SkillGroupPadding
            end
            list.content:add(skills[i].element)
            height = height + CONSTANTS.SkillGroupSize.y + CONSTANTS.SkillGroupPadding
        end
    end

    height = height + CONSTANTS.SkillGroupPadding

    inner.props.size = vector2(CONSTANTS.SkillGroupSize.x + CONSTANTS.SkillGroupPadding, height)
end

local lib = {
    -- Set the skill tracked at a specific index
    setTrackedSkill = function(window, idx, skillName, startValue)
        assert(window and window.layout.content and #window.layout.content > 0)
        local inner = window.layout.content[1]

        local skills = inner.userData.skills
        assert(skills)

        -- for i=1, #skills do
        --     local s = skills[i]
        --     assert(s.name ~= skillName, 'skill already added')
        -- end
        if not skills[idx] and skillName ~= 'None' then
            local element = createTrackedSkillElement()

            skills[idx] = {
                name = skillName,
                startValue = startValue,
                value = 0.0,
                element = element,
                interp = 0.0,
            }

            refreshSkillList(window)
        elseif skills[idx] then
            skills[idx].name = skillName
            skills[idx].startValue = startValue
            skills[idx].interp = 0.0

            if skillName == 'None' then
                assert(skills[idx].element)
                skills[idx].element:destroy()
                skills[idx] = nil
                refreshSkillList(window)
            end
        end

        if skills[idx] then
            updateTrackedSkill(window, idx, startValue)
        end
        window:update()
    end,

    -- Update the values for a specific skill, does not require a window update.
    updateTrackedSkill = updateTrackedSkill,

    update = function(window, dt)
        assert(window and window.layout.content and #window.layout.content > 0)
        local inner = window.layout.content[1]
        assert(inner and inner.userData)
        local skills = inner.userData.skills
        assert(skills)

        for i=1, #skills do
            local s = skills[i]
            if s and s.name ~= 'None' then
                s.interp = math.max(0.0, s.interp - dt)
                local a = sSkillFlashTime > 0 and (s.interp / sSkillFlashTime) or 0.0

                s.element.layout.userData.text.props.textColor = lerp(CONSTANTS.SkillTextColorNormal, CONSTANTS.SkillTextColorHighlight, a)

                s.element:update()
            end
        end
    end,

    create = createTrackerWindow,

    setPosition = function(window, position)
        assert(window and window.layout)
        window.layout.props.position = position
        window:update()
    end,

    setWindowAlpha = function(val)
        sWindowAlpha = val and val or sWindowAlpha
    end,

    setBackgroundAlpha = function(val)
        sBackgroundAlpha = val and val or sBackgroundAlpha
    end,

    setWindowBorder = function(val)
        if type(val) == 'boolean' then
            sWindowBorder = val
        end
    end,

    setSkillFlashTime = function(val)
        sSkillFlashTime = val and val or sSkillFlashTime
    end,
}

return lib
