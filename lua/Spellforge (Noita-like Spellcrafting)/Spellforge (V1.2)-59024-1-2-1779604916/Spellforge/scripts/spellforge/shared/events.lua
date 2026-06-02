local events = {}

events.CHECK_BACKEND = "Spellforge_CheckBackend"
events.BACKEND_READY = "Spellforge_BackendReady"
events.BACKEND_UNAVAILABLE = "Spellforge_BackendUnavailable"

events.COMPILE_RECIPE = "Spellforge_CompileRecipe"
events.COMPILE_RESULT = "Spellforge_CompileResult"
events.VALIDATE_RECIPE = "Spellforge_ValidateRecipe"
events.VALIDATE_RESULT = "Spellforge_ValidateResult"
events.PREVIEW_RECIPE = "Spellforge_PreviewRecipe"
events.PREVIEW_RESULT = "Spellforge_PreviewResult"
events.QUERY_UI_CATALOG = "Spellforge_QueryUiCatalog"
events.UI_CATALOG_RESULT = "Spellforge_UiCatalogResult"
events.QUERY_AVAILABLE_EFFECTS = "Spellforge_QueryAvailableEffects"
events.AVAILABLE_EFFECTS_RESULT = "Spellforge_AvailableEffectsResult"

events.DELETE_COMPILED = "Spellforge_DeleteCompiled"

events.REHYDRATE_COMPILED_REQUEST = "Spellforge_RehydrateCompiledRequest"
events.REHYDRATE_COMPILED_RESULT = "Spellforge_RehydrateCompiledResult"

events.CAST_REQUEST = "Spellforge_CastRequest"
events.BEGIN_CAST_OBSERVE = "Spellforge_BeginCastObserve"
events.CAST_OBSERVE_RESULT = "Spellforge_CastObserveResult"
events.CAST_HIT_OBSERVED = "Spellforge_CastHitObserved"
events.CAST_DIAG_SIGNAL = "Spellforge_CastDiagSignal"
events.INTERCEPT_DISPATCH_SUPPRESSED = "Spellforge_InterceptDispatchSuppressed"
events.RUNTIME_STATS_REQUEST = "Spellforge_RuntimeStatsRequest"
events.RUNTIME_STATS_RESULT = "Spellforge_RuntimeStatsResult"

events.QUERY_SPELL_METADATA = "Spellforge_QuerySpellMetadata"
events.QUERY_SPELL_METADATA_RESULT = "Spellforge_QuerySpellMetadataResult"

events.INTERCEPT_CAST = "Spellforge_InterceptCast"
events.INTERCEPT_DISPATCH_RESULT = "Spellforge_InterceptDispatchResult"
events.CHAIN_LOS_REQUEST = "Spellforge_ChainLosRequest"
events.CHAIN_LOS_RESULT = "Spellforge_ChainLosResult"
events.DIAG_OSSC_STYLE_CAST = "SPELLFORGE_DIAG_CAST_OSSC_STYLE"
events.DIAG_OSSC_STYLE_DIRECT_LAUNCH = "Spellforge_DiagOsscStyleDirectLaunch"

return events
