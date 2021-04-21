local this = {
}

this[ "eng" ] = {
  mcm = {
    spellUnstackedDescription = "Enables or disables the unstack spell effect feature for magic effect whose the source is spell. If enabled, any current active magic effect on the actor is replaced by a newer identical effect present on the affecting spell rather than being stacked.",
    enchantUnstackedDescription = "Enables or disables the unstack spell effect feature for magic effect whose the source is enchantment. The behavior of this module depends of the enchantment type affecting the actor. For all enchantment types but constant effect, the behavior is the same as the spell module, newer identical effect replaces currently active effect rather than being stacked. If the enchantment type is constant effect, any previously equipped item whose magic effect is identical to the new applied constant effect enchantment will be automatically unequipped and placed into the inventory if applicable."
  }
}

this[ "fra" ] = {
  mcm = {
    spellUnstackedDescription = "Active ou desactive le cumul des effets magiques dont la source est un sort. Si cette fonctionnalite est active, un effect magique actuellement actif se voit remplace par un effet magique identique plus recent provenant du sort applique au lieu de se cumuler.",
    enchantUnstackedDescription = "Active ou desactive le cumul des effects magiques dont la source est un enchantement. Le comportement de ce module depend du type d'enchatement concerne. Pour tout type d'enchamtement excepte d'effet constant, le comportement de ce module est identique au module de sort, tout effet plus recent remplace un ancien effet actif plutot que de se cumuler. S'il s'agit d'un enchantement d'effet constant, l'objet actuellement equipe portant l'enchantement est automatiquement retire du personnage puis est place dans l'inventaire si c'est possible."
  }
}

return this