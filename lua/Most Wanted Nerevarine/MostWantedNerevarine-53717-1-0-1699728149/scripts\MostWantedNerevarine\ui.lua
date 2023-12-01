local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local settings = storage.playerSection('SettingsMostWantedNerevarine')

local BountyLevel = {
   none = 0,
   criminal = 1,
   arrest = 2,
   attack = 3,
}

local sealIcon = ui.texture({ path = 'bookart/moragtong.dds' })
local goldIcon = ui.texture({ path = 'icons/gold.dds' })
local inactiveShading = util.color.rgb(0.3, 0.3, 0.3)

local l10n = core.l10n('MostWantedNerevarine')

local padding = {
   props = { size = util.vector2(1, 1) * 10 },
}

local function renderSeals(level, horizontal)
   local wrapper = {
      type = ui.TYPE.Flex,
      props = {
         horizontal = horizontal,
         arrange = ui.ALIGNMENT.Center,
      },
      content = ui.content({
         padding,
      }),
   }
   local sealSize = settings:get('iconSize')
   local sealPaddingSize = math.ceil(sealSize * 0.25)
   local sealPadding = {
      props = { size = util.vector2(1, 1) * sealPaddingSize },
   }
   for i = BountyLevel.criminal, BountyLevel.attack do
      local seal = {
         type = ui.TYPE.Image,
         props = {
            size = util.vector2(1, 1) * sealSize,
            resource = sealIcon,
         },
      }
      if i > level then
         seal.props.color = inactiveShading
      end
      wrapper.content:add(seal)
      wrapper.content:add(sealPadding)
   end
   return wrapper
end

local function levelHintKey(level)
   for key, i in pairs(BountyLevel) do
      if i == level then
         return 'hint_' .. key
      end
   end
   error('Invalid bounty level: ' .. tostring(level))
end

local function renderHorizontalDetails(bounty, level)
   local bountyIcon = {
      type = ui.TYPE.Image,
      props = {
         resource = goldIcon,
         size = util.vector2(1, 1) * 16,
      },
   }

   local bountyText = {
      template = I.MWUI.templates.textNormal,
      props = {
         text = tostring(bounty),
      },
   }

   local levelHint = {
      template = I.MWUI.templates.textNormal,
      props = {
         relativeSize = util.vector2(1, 0),
         size = util.vector2(16, 16),
         text = l10n(levelHintKey(level)),
      },
      external = {
         stretch = 1,
      },
   }

   return {
      type = ui.TYPE.Flex,
      props = {
         horizontal = true,
         arrange = ui.ALIGNMENT.Center,
      },
      content = ui.content({
         padding,
         bountyIcon,
         padding,
         bountyText,
         padding,
         levelHint,
         padding,
      }),
   }
end

local function renderVerticalDetails(bounty, level)
   local bountyIcon = {
      type = ui.TYPE.Image,
      props = {
         resource = goldIcon,
         size = util.vector2(1, 1) * 16,
      },
   }

   local bountyText = {
      template = I.MWUI.templates.textNormal,
      props = {
         text = tostring(bounty),
      },
   }

   local bountyRow = {
      type = ui.TYPE.Flex,
      props = {
         horizontal = true,
         arrange = ui.ALIGNMENT.Center,
      },
      content = ui.content({
         bountyIcon, padding, bountyText,
      }),
   }

   local levelHint = {
      template = I.MWUI.templates.textParagraph,
      props = {
         text = l10n(levelHintKey(level)),
      },
      external = {
         stretch = 1,
      },
   }

   return {
      type = ui.TYPE.Flex,
      props = {
         horizontal = false,
      },
      content = ui.content({
         bountyRow,
         padding,
         levelHint,
         padding,
      }),
   }
end

local function renderRootWrapper(layer, content)
   local screenPosition = settings:get('screenPosition')
   local paddingOffset = (util.vector2(1, 1) - screenPosition * 2):emul(util.vector2(13, 13))
   local border = {
      layer = layer,
      template = I.MWUI.templates.boxTransparent,
      props = {
         anchor = screenPosition,
         relativePosition = screenPosition,
         position = paddingOffset,
      },
      content = content,
   }
   return border
end

local function renderHud(level)
   local horizontal = not settings:get('verticalHud')
   return renderRootWrapper('HUD', ui.content({ renderSeals(level, horizontal) }))
end

local function renderWindow(bounty, level)
   local horizontal = not settings:get('verticalHud')
   local renderDetails = horizontal and renderHorizontalDetails or renderVerticalDetails
   local column = {
      type = ui.TYPE.Flex,
      props = {
         horizontal = not horizontal,
         arrange = ui.ALIGNMENT.Center,
      },
      content = ui.content({
         padding,
         renderSeals(level, horizontal),
         padding,
         renderDetails(bounty, level),
         padding,
      }),
   }
   return renderRootWrapper('Windows', ui.content({ column }))
end

local hudElement = nil
local windowElement = nil

return {
   BountyLevel = BountyLevel,
   updateHud = function(active, level)
      if hudElement and not active then
         hudElement:destroy()
         hudElement = nil
      elseif active and not hudElement then
         hudElement = ui.create(renderHud(level))
      elseif active and hudElement then
         hudElement.layout = renderHud(level)
         hudElement:update()
      end
   end,
   updateWindow = function(active, bounty, level)
      if windowElement and not active then
         windowElement:destroy()
         windowElement = nil
      elseif active and not windowElement then
         windowElement = ui.create(renderWindow(bounty, level))
      elseif active and windowElement then
         windowElement.layout = renderWindow(bounty, level)
         windowElement:update()
      end
   end,
}
