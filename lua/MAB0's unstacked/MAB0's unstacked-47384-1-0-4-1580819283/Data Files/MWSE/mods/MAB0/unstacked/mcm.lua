local this = {
  id = "MAB0_unstacked",
  name = "MetaBarj0's unstacked",
  config = {
    spellUnstackedEnabled = true,
    enchantUnstackedEnabled = true
  },
}

local function loadConfig()
  this.config = mwse.loadConfig( this.id ) or this.config
end

local function registerMcm()
  local localeStrings = require( "MAB0.unstacked.localeStrings" )
  local locale = require( "MAB0.locale" ).new( localeStrings )

  local template = mwse.mcm.createTemplate( this.name )

  template:saveOnClose( this.id, this.config )

  local page = template:createPage()

  page:createOnOffButton( {
    label = locale.getLocalizedString( "mcm.spellUnstackedDescription" ),
    variable = mwse.mcm.createTableVariable( {
      id = "spellUnstackedEnabled",
      table = this.config
    } )
  } )

  page:createOnOffButton( {
    label = locale.getLocalizedString( "mcm.enchantUnstackedDescription" ),
    variable = mwse.mcm.createTableVariable( {
      id = "enchantUnstackedEnabled",
      table = this.config
    } )
  } )

  mwse.mcm.register( template )
end

local function getConfig()
  return this.config
end

return {
  new = function()
    loadConfig()
    registerMcm()

    return {
      getConfig = getConfig
    }
  end
}