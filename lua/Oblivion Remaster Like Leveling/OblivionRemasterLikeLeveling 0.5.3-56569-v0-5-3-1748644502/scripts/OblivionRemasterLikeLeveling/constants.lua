local ui = require('openmw.ui')
local I = require("openmw.interfaces")
local util = require("openmw.util")
local v2 = require('openmw.util').vector2

local constants = { }
constants.MAX_ATTRIBUTE_VALUE = 100
constants.MAX_SKILL_VALUE = 100
constants.ATRIBUTE_INCREASE_LIMIT = 5

constants.HOVER_COLOR = util.color.rgb(242 / 255, 205 / 255, 136 / 255)
constants.IDLE_COLOR = I.MWUI.templates.textNormal.props.textColor
constants.PRESSED_COLOR = util.color.rgb(101 / 255, 82 / 255, 48 / 255)

constants.INCREMENT_BUTTON_TEXTURE_PROPERTIES = {
  path="icons/menu_number_inc.dds",
  offset = v2(0, 0),
  size = v2(10, 18),
}
constants.DECREMENT_BUTTON_TEXTURE_PROPERTIES = {
  path="icons/menu_number_dec.dds",
  offset = v2(0, 0),
  size = v2(10, 18),
}
constants.GOLD_COIN_TEXTURE_PROPERTIES = {path="icons/gold.dds"}

constants.STRENGTH_TEXTURE_PROPERTIES = {path = 'icons/k/attribute_strength.dds'}
constants.INTELLIGENCE_TEXTURE_PROPERTIES = {path = 'icons/k/attribute_int.dds'}
constants.WILLPOWER_TEXTURE_PROPERTIES = {path = 'icons/k/attribute_wilpower.dds'}
constants.AGILITY_TEXTURE_PROPERTIES = {path = 'icons/k/attribute_agility.dds'}
constants.SPEED_TEXTURE_PROPERTIES = {path = 'icons/k/attribute_speed.dds'}
constants.ENDURANCE_TEXTURE_PROPERTIES =  {path = 'icons/k/attribute_endurance.dds'}
constants.PERSONNALITY_TEXTURE_PROPERTIES = {path = 'icons/k/attribute_personality.dds'}
constants.LUCK_TEXTURE_PROPERTIES = {path = 'icons/k/attribute_luck.dds'}

constants.BORDER_WIDTH = 4

constants.CLICK_SOUND = "Menu Click"

constants.WINDOWS_LAYER = "Windows"
constants.POP_UP_LAYER = "Popup"

constants.LEVEL_UP_DIALOG = "LevelUpDialog"
constants.LEVEL_UP_MUSIC = "Music/Special/MW_Triumph.mp3"
constants.LEVEL_UP_MODE = "LevelUp"

constants.STRENGTH = "strength"
constants.INTELLIGENCE = "intelligence"
constants.WILLPOWER = "willpower"
constants.AGILITY = "agility"
constants.SPEED = "speed"
constants.ENDURANCE = "endurance"
constants.PERSONALITY = "personality"
constants.LUCK = "luck"

constants.ATRIBUTES = {
  {id=constants.STRENGTH, tooltip='sStrDesc', tooltipSize=v2(419,48), icon=ui.texture(constants.STRENGTH_TEXTURE_PROPERTIES)},
  {id=constants.INTELLIGENCE, tooltip='sIntDesc', tooltipSize=v2(348, 16), icon=ui.texture(constants.INTELLIGENCE_TEXTURE_PROPERTIES)},
  {id=constants.WILLPOWER, tooltip='sWilDesc', tooltipSize=v2(408, 32), icon=ui.texture(constants.WILLPOWER_TEXTURE_PROPERTIES)},
  {id=constants.AGILITY, tooltip='sAgiDesc', tooltipSize=v2(411,32), icon=ui.texture(constants.AGILITY_TEXTURE_PROPERTIES)},
  {id=constants.SPEED, tooltip='sSpdDesc', tooltipSize=v2(259,16), icon=ui.texture(constants.SPEED_TEXTURE_PROPERTIES)},
  {id=constants.ENDURANCE, tooltip='sEndDesc', tooltipSize=v2(410,32), icon=ui.texture(constants.ENDURANCE_TEXTURE_PROPERTIES)},
  {id=constants.PERSONALITY, tooltip='sPerDesc', tooltipSize=v2(429,32), icon=ui.texture(constants.PERSONNALITY_TEXTURE_PROPERTIES)},
  {id=constants.LUCK, tooltip='sLucDesc', tooltipSize=v2(314,16), icon=ui.texture(constants.LUCK_TEXTURE_PROPERTIES)}
}

constants.LEVEL_UP_MESSAGE_HEIGHT = {}
constants.LEVEL_UP_MESSAGE_HEIGHT[2]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[3]=70
constants.LEVEL_UP_MESSAGE_HEIGHT[4]=130
constants.LEVEL_UP_MESSAGE_HEIGHT[5]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[6]=110
constants.LEVEL_UP_MESSAGE_HEIGHT[7]=70
constants.LEVEL_UP_MESSAGE_HEIGHT[8]=70
constants.LEVEL_UP_MESSAGE_HEIGHT[9]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[10]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[11]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[12]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[13]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[14]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[15]=130
constants.LEVEL_UP_MESSAGE_HEIGHT[16]=110
constants.LEVEL_UP_MESSAGE_HEIGHT[17]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[18]=110
constants.LEVEL_UP_MESSAGE_HEIGHT[19]=90
constants.LEVEL_UP_MESSAGE_HEIGHT[20]=140

return constants
