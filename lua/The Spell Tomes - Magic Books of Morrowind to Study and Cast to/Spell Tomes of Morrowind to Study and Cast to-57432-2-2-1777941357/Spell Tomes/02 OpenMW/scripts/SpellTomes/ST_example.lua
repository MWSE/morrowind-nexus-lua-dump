do return end
--[[

Example registration file for the SpellTomes API.

There are two ways to register a tome:

1. DROP-IN VFS FILE (this pattern).
   Place a .lua file under scripts/SpellTomes/registrations/ that returns
   either a single def table or a list of def tables. SpellTomes will
   auto-load it on both the player and global sides at startup.

2. LIVE INTERFACE CALL.
   From your mod's own player script, require I.SpellTomes and call
   I.SpellTomes.registerTome{ ... }. This mirrors to the global script
   automatically so cell/NPC distribution picks up your tome too.

Either way, the def fields are the same.

Required:
  tomeId   = "myMod_book_fireball"  -- Book record id
  spellId  = "myMod_spell_fireball" -- Spell record id to teach

Optional (defaults shown):Z
  learnTrigger          = "read"    -- "read" | "activate"
                                       "read" fires when the book UI opens
                                       "activate" fires on world pickup/click
                                       (before the reading UI)
  learnedMessage        = nil       -- Defaults to "You have learned the spell X."
  learnedSound          = "skillraise"  -- Ambient sound id
  learnedSoundFile      = nil       -- Path to .wav, overrides learnedSound
  distributeToClasses   = true      -- Can be carried by spellcaster NPCs
  distributeToMerchants = "both"    -- "both" | "enchanter" | "bookseller" | "none"
  allowRestockWhenKnown = true      -- If false, skip distribution entirely
                                       (world/merchants/NPCs) when the player
                                       already knows the spell
  rare                  = false     -- Treated as a rare tome (RARE_SPAWN_CHANCE)
  replaceable           = true      -- Can replace generic books in the world
  weight                = 1         -- Relative draw weight when picking from a pool.
                                       2 = twice as likely as default, 0.5 = half.
                                       Applied AFTER the rare-spawn gate, so rare
                                       tomes can also be weighted relative to each
                                       other once they make it into the pool. 0
                                       means the tome is registered but never drawn.
  onLearned             = nil       -- fn(player, spellId) callback after learning

-- Single-tome example
return {
	tomeId = "myMod_book_fireball",
	spellId = "myMod_spell_fireball",
	learnedMessage = "The pages burn themselves into your memory.",
	rare = true,
	distributeToMerchants = "enchanter",
	onLearned = function(player, spellId)
		-- Optional: custom side effect, e.g. trigger an achievement
	end,
}

Multi-tome example (comment out the return above and uncomment this):

return {
	tomeId = "myMod_book_fireball",
	spellId = "myMod_spell_fireball",
	addSpellToVendors = true,
	addTomeToVendors = true,
	spellVendorRequireTrainer = true,
	spellVendorSkill = "destruction",
	spellVendorMinLevel = 50,
}
]]