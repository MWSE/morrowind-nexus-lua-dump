local content = require('openmw.content')

content.magicEffects.records.spellsword_effect = {
  template = content.magicEffects.records['spellabsorption'],
  name = "Imbue",
  school = "mysticism",
  description = "Imbues current weapon with magic. Does nothing by itself",
  hasMagnitude = true,
  hasArea = false,
  hasDuration = false,
  allowsEnchanting = false,
  allowsSpellmaking = true,
  harmful = false,
  onSelf = true,
  onTarget = false,
  onTouch = false,
}

content.spells.records.spellsword_fire = {
  name = 'Imbue Fire',
  type = content.spells.TYPE.Spell,
  isAutocalc = false,
  cost = 9,
  effects = {
    {
      id = 'spellsword_effect',
      range = content.RANGE.Self,
      magnitudeMin = 10,
      magnitudeMax = 10,
    },
    {
      id = "firedamage",
      range = content.RANGE.Touch,
      magnitudeMin = 10,
      magnitudeMax = 20,
    },
  }
}

content.spells.records.spellsword_frost = {
  name = 'Imbue Frost',
  type = content.spells.TYPE.Spell,
  isAutocalc = false,
  cost = 9,
  effects = {
    {
      id = 'spellsword_effect',
      range = content.RANGE.Self,
      magnitudeMin = 10,
      magnitudeMax = 10,
    },
    {
      id = "frostdamage",
      range = content.RANGE.Touch,
      magnitudeMin = 10,
      magnitudeMax = 20,
    },
  }
}

content.spells.records.spellsword_shock = {
  name = 'Imbue Shock',
  type = content.spells.TYPE.Spell,
  isAutocalc = false,
  cost = 9,
  effects = {
    {
      id = 'spellsword_effect',
      range = content.RANGE.Self,
      magnitudeMin = 10,
      magnitudeMax = 10,
    },
    {
      id = "shockdamage",
      range = content.RANGE.Touch,
      magnitudeMin = 10,
      magnitudeMax = 20,
    },
  }
}