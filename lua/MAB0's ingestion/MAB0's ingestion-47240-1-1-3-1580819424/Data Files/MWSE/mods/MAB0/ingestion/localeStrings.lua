local this = {
}

this[ "eng" ] = {
  mcm = {
    ingestionButtonLabel = "Enable or disable the ingestion mod.\nIt prevents the player to consume more that one potion or ingredient at a time whenever either on them is active on the player."
  },
  messageBox = {
    justIngestedFormatString = "I've just ingested %s. I want first to figure out its effect before ingesting other things.",
    justIngestedAnIngredientArg = "an ingredient",
    justIngestedAPotionArg = "a potion",
    underInfluenceFormatString = "I'm still under the influence of %s. I prefer its effects fade out instead of risking an intoxication.",
    underInfluenceGenericString = "I'm still under the influence of an alchemical effect. I prefer its effects fade out instead of risking an intoxication."
  }
}

this[ "fra" ] = {
  mcm = {
    ingestionButtonLabel = "Active ou desactive le mod ingestion.\nCe mod empeche le joueur d'etre beneficiaire de plus d'un effet alchimique a la fois, qu'il provienne d'une potion ou d'un ingredient."
  },
  messageBox = {
    justIngestedFormatString = "Je viens juste d'avaler %s. Je veux d'abord identifier ses effets avant de consommer autre chose.",
    justIngestedAnIngredientArg = "un ingredient",
    justIngestedAPotionArg = "une potion",
    underInfluenceFormatString = "Je suis toujours sous l'influence d'%s. Je prefere que ses effets disparaissent plutot que de risquer une intoxication.",
    underInfluenceGenericString = "Je suis toujours sous l'influence d'un effet alchimique. Je prefere que ses effets disparaissent plutot que de risquer une intoxication."
  }
}

return this