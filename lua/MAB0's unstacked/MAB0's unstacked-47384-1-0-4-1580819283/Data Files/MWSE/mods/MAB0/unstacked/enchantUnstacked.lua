local function isFromEnchant( spellHitData )
  return spellHitData.sourceInstance.sourceType == tes3.magicSourceType.enchantment
end

return {
  mustHandleSpellHitData = function( spellHitData )
    return isFromEnchant( spellHitData )
  end,

  getExtraPropertyTableForEffectCollection = function ( spellHitData )
    return { castType = spellHitData.source.castType }
  end,

  getMustIgnoreSpellTickCallback = function( collectedEffectInfo, serialNumber )
    return function ( spellTickData )
      return ( not isFromEnchant( spellTickData ) ) or ( spellTickData.sourceInstance.serialNumber == serialNumber ) or ( spellTickData.source.castType ~= collectedEffectInfo.castType )
    end
  end
}