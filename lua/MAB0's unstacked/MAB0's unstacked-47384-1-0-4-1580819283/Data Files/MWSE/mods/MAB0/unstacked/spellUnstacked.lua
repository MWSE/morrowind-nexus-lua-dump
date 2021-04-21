local function isFromPureSpell( spellHitData )
  local sourceType = spellHitData.sourceInstance.sourceType

  if( sourceType ~= tes3.magicSourceType.spell ) then return false end

  local spell = spellHitData.sourceInstance.source

  return spell.castType == tes3.spellType.spell
end

return {
  mustHandleSpellHitData = function( spellHitData )
    return isFromPureSpell( spellHitData )
  end,

  getExtraPropertyTableForEffectCollection = function ( _ )
    return nil
  end,

  getMustIgnoreSpellTickCallback = function( _, serialNumber )
    return function ( spellTickData )
      return ( not isFromPureSpell( spellTickData ) ) or ( spellTickData.sourceInstance.serialNumber == serialNumber )
    end
  end
}