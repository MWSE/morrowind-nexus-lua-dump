return{
	metadata = {
		name = "QuickStack",
		modId = "QuickStack",
		version = "1.0",
		author = "petward",
		
	},
	content = {
		message = {
			prefix = "[QuickStack] ",
			transferedItemsSuccess = "Transferred items!",
			transferedNothing = "Nothing to transfer.",
			nearbyQuickStackStart = "Running nearby quick stack...",
			noContainers = "No containers found.",
			cannotTransferPrefix = "Cannot transfer to ",
			cannotTransferLocked = "because it is locked.",
			cannotTransferOrganic = "because it is organic.",
			cannotTransferRespawning = "because it is respawning.",
			cannotTransferOwned = "because it is owned by an NPC.",
			cannotTransferCapacity = "because the container is at capacity.",
			transferedNearbySuccessPrefix = "Transferred items to these containers: "
		},
		transferResult = {
			headerTitle = "Transfer Result"
		}
	},
	config = {
		title = "QuickStack",
		description = "Set a key binding to quickly transfer all items from inventory to container if there is at least one of that item in the container.",
		categoryKeybinds = "Keybinds",
		keybinds = {
			key = "Settings/QuickStack/Keybinds",
			placeholder = "No key set",
			stackLabel = "Quick Stack",
			stackDescription = "When pressed in container inventory--\nQuickStack to that single container. \n\nWhen pressed outside container--\nQuickStack to all containers in an area around the player (area created by Horizontal and Vertical Distance below.) \n\n(Default: V)"
		},
		categoryOptions = "Options",
		options = {
			key = "Settings/QuickStack/Options",
			itemRestrictionGold = {
				key = "isGoldTransferred",
				label = "Allow gold to be stacked?",
				description = 'If enabled, gold will be including when stacking items to containers. \n\n(Default: No)',
			},
			enableCompanionStacking = {
				key = "enableNearbyCompanionStacking",
				label = "Is nearby companion QuickStacking enabled?",
				description = 'If enabled, pressing the Stack key outside a container will also QuickStack to companions that are following you. Companion stacking takes priority over containers. \n\n(Default: Yes)',
			},
			distanceHorizontal = {
				key = "distanceHorizontal",
				label = "Horizontal Distance",
				description = 'The horizontal radius around the player in which containers will receive items from quickstacking. \n\n(Min: 100 / Max: 1000 / Default: 250)',
			},
			distanceVertical = {
				key = "distanceVertical",
				label = "Vertical Distance",
				description = 'The vertical range above and below the player in which containers will receive items from quickstacking. \n\n(Min: 10 / Max: 500 / Default: 100)',
			},
			transferAnimation = {
				key = "isTransferAnimationEnabled",
				label = "Is transfer animation enabled?",
				description = 'If enabled, an animation will be applied to a container upon successful transfer of items. \n\n(Default: Yes)',
			},
			transferAnimationDuration = {
				key = "transferAnimationDuration",
				label = "Transfer Animation Duration",
				description = 'The number of seconds the transfer animation will play. \n\n(Default: 10)',
			},
			successNotificationEnabled = {
				key = "isSuccessNotificationEnabled",
				label = "Turn on success notifications?",
				description = 'If enabled, will send a notification about a successful quickstack and which containers received items. The type of success notification can be changed below. \n\n(Default: Yes)',
			},
			successNotificationType = {
				key = "isSuccessNotificationVerboseOrSimple",
				label = "Success Notifications Type",
				description = 'Verbose -- \nOpens a Transfer Result menu upon successful quickstacks that details what containers all items went to and a breakdown of the items and their counts for each container. Interact with this menu by opening your inventory. \n\nSimple -- \nCreates a simple notification at the bottom of the screen notifying that the quickstack was a success and what containers received items.  \n\n(Default: Verbose)',
				items = {
					verbose = "Verbose",
					simple = "Simple"
				}
			},
			successVerboseNotificationAutoCloseDuration = {
				key = "successVerboseNotificationAutoCloseDuration",
				label = "Verbose Success Auto-Close Duration",
				description = 'The number of seconds until the verbose success notification will close automatically. \n\n(Default: 10)',
			},
			failureNotificationEnabled = {
				key = "isFailureNotificationEnabled",
				label = "Turn on failed notifications?",
				description = 'If enabled, will send a notification about a failed quickstack and the cause. \n\n(Default: No)',
			},

		}
	}
}