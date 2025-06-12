local ui = require('openmw.ui')
local v2 = require('openmw.util').vector2

local constants = require('scripts.OblivionRemasterLikeLeveling.constants')

local templates = {}

templates.borderedButton = {
  type = ui.TYPE.Container,
  content = ui.content({
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{ path ='textures/menu_button_frame_left.dds' },
        tileH = false,
        tileV = true,
        position = v2(0, constants.BORDER_WIDTH),
        relativePosition = v2(0, 0),
        size = v2(constants.BORDER_WIDTH, 0),
        relativeSize = v2(0, 1),
      }
    },
    {
      type = ui.TYPE.Image,
      props = {

        resource = ui.texture{ path ='textures/menu_button_frame_right.dds' },
        tileH = false,
        tileV = true,
        position = v2(constants.BORDER_WIDTH, constants.BORDER_WIDTH),
        relativePosition = v2(1, 0),
        size = v2(constants.BORDER_WIDTH, 0),
        relativeSize = v2(0, 1),
      }
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{ path ='textures/menu_button_frame_top.dds' },
        tileH = true,
        tileV = false,
        position = v2(constants.BORDER_WIDTH,0),
        relativePosition = v2(0, 0),
        size = v2(0,constants.BORDER_WIDTH),
        relativeSize = v2(1, 0),
      }
    } ,
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{ path ='textures/menu_button_frame_bottom.dds' },
        tileH = true,
        tileV = false,
        position = v2(constants.BORDER_WIDTH, constants.BORDER_WIDTH),
        relativePosition = v2(0, 1),
        size = v2(0,constants.BORDER_WIDTH),
        relativeSize = v2(1, 0),
      }
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{ path ='textures/menu_button_frame_top_left_corner.dds' },
        position = v2(0,0),
        relativePosition = v2(0, 0),
        size = v2(constants.BORDER_WIDTH, constants.BORDER_WIDTH)
      }
    },

    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{ path ='textures/menu_button_frame_top_right_corner.dds' },
        position =v2(constants.BORDER_WIDTH, 0),
        relativePosition = v2(1,0),
        size = v2(constants.BORDER_WIDTH, constants.BORDER_WIDTH)
      }
    },

    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{ path ='textures/menu_button_frame_bottom_left_corner.dds' },
        position = v2(0, constants.BORDER_WIDTH),
        relativePosition = v2(0, 1),
        size = v2(constants.BORDER_WIDTH, constants.BORDER_WIDTH)
      }
    },
    {
      type = ui.TYPE.Image,
      props = {
        resource = ui.texture{ path ='textures/menu_button_frame_bottom_right_corner.dds' },
        position = v2(constants.BORDER_WIDTH, constants.BORDER_WIDTH),
        relativePosition = v2(1, 1),
        size = v2(constants.BORDER_WIDTH, constants.BORDER_WIDTH)
      }
    },
    {
      external = { slot = true },
      props = {
        position = v2(constants.BORDER_WIDTH, constants.BORDER_WIDTH),
        relativeSize = v2(1, 1)
      }
    }
  })
}

return templates