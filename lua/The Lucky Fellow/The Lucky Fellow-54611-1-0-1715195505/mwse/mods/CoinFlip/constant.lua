return {coinId = "aa_coin_the_coin",



--NOTE: If you change these values, it will only apply to MWSE, you must change the spell in the CS for it to take effect in OpenMW.
luckySpellName = "Lucky Coin",
unluckySpellName = "Unlucky Coin",
luckModifier = 50,
hoursToApply = 24,
--See above

luckySpellId = "zhac_spell_lucky",
unLuckySpellId = "zhac_spell_unlucky",
chanceIncrement = 1,--Chance reduced by this amount each flip
startingChance = 80,--The chance of a successful effect when first flipping the coin. Reduced by 1 for each subsequent flip.
pickUpDelay = 1--After the coin is flipped, and lands, the game will wait this long before moving it into the player's inventory.

}