local this = {
  id = "MAB0_manipulated",
  name = "MetaBarj0's manipulated",
  config = {
    calmHumanoidEnabled = true,
    commandHumanoidEnabled = true,
    demoralizeHumanoidEnabled = true,
    frenzyHumanoidEnabled = true,
    rallyHumanoidEnabled = true,
    charmEnabled = true
  },
}

local function loadConfig()
  this.config = mwse.loadConfig( this.id ) or this.config
end

local function registerMcm()
  local localeStrings = require( "MAB0.manipulated.localeStrings" )
  local locale = require( "MAB0.locale" ).new( localeStrings )

  local template = mwse.mcm.createTemplate( this.name )

  template:saveOnClose( this.id, this.config )

  local page = template:createPage()

  page:createOnOffButton( {
    label = locale.getLocalizedString( "mcm.calmHumanoidEnabled" ),
    variable = mwse.mcm.createTableVariable( {
      id = "calmHumanoidEnabled",
      table = this.config
    } )
  } )

  page:createOnOffButton( {
    label = locale.getLocalizedString( "mcm.commandHumanoidEnabled" ),
    variable = mwse.mcm.createTableVariable( {
      id = "commandHumanoidEnabled",
      table = this.config
    } )
  } )

  page:createOnOffButton( {
    label = locale.getLocalizedString( "mcm.demoralizeHumanoidEnabled" ),
    variable = mwse.mcm.createTableVariable( {
      id = "demoralizeHumanoidEnabled",
      table = this.config
    } )
  } )

  page:createOnOffButton( {
    label = locale.getLocalizedString( "mcm.frenzyHumanoidEnabled" ),
    variable = mwse.mcm.createTableVariable( {
      id = "frenzyHumanoidEnabled",
      table = this.config
    } )
  } )

  page:createOnOffButton( {
    label = locale.getLocalizedString( "mcm.rallyHumanoidEnabled" ),
    variable = mwse.mcm.createTableVariable( {
      id = "rallyHumanoidEnabled",
      table = this.config
    } )
  } )

  page:createOnOffButton( {
    label = locale.getLocalizedString( "mcm.charmEnabled" ),
    variable = mwse.mcm.createTableVariable( {
      id = "charmEnabled",
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