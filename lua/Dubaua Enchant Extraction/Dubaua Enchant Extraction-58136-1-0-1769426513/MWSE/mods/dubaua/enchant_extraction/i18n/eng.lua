return {
  ["mod.name"] = "Dubaua Enchant Extraction",

  ["ui.rename.title"] = "Rename item",
  ["ui.rename.ok"] = "Transfer enchantment",
  ["ui.rename.cancel"] = "Cancel",
  ["ui.select.title"] = "Select item to receive enchantment",

  ["msg.noTarget"] = "No valid target",
  ["msg.invalidTarget"] = "Invalid target",
  ["msg.noEnchantment"] = "Target has no enchantment",
  ["msg.specialItem"] = "This item is special and its enchantment cannot be separated",
  ["msg.failedCreate"] = "Failed to create item",
  ["msg.success"] = "Enchantment transferred",

  ["mcm.settings.label"] = "Settings",
  ["mcm.info"] = "It can be frustrating to find an item with a great enchantment, only to realize it doesn't fit your skills, playstyle, or equipment type.\n\n" ..
      "This mod adds a spell that lets you extract an enchantment from one item and transfer it to another. Cast the spell on an enchanted weapon, armor, or clothing, then pick a suitable unenchanted item from your inventory to receive the enchantment. You can also provide a new name for the item, and this step can be disabled in the settings. Transferring enchantments from or to quest items or other special items is not allowed, so you don't accidentally ruin important gear.\n\n" ..
      "Also, to avoid breaking the economy, the original item disappears. In effect, this spell merges two items into one.\n\n" ..
      "You can obtain the spell by asking enchanters for the latest rumors and completing a small quest, or add it via the console command player->addspell dubaua_enchant_extraction.\n\n" ..
      "Happy enchanting!\n\n" .. "For questions, contact dubaua@gmail.com",
  ["mcm.enabled.label"] = "Enabled",
  ["mcm.enabled.desc"] = "Enable or disable the mod.",
  ["mcm.renamePrompt.label"] = "Rename Prompt",
  ["mcm.renamePrompt.desc"] = "Ask for a new name after selecting the item.",
  ["mcm.verboseHits.label"] = "Verbose Hits",
  ["mcm.verboseHits.desc"] = "Show hint messages during enchantment extraction.",
}
