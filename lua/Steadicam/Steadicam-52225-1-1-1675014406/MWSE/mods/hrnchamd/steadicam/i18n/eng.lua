--[[
	Mod: Steadicam
	Author: Hrnchamd
	Version: 1.1
]]--

return {
	["DefaultHelp"] = "Hover over a control for a help tip.",

	["ModEnableToggle"] = "Steadicam enable",
	["ModEnableToggleHelp"] = "Switches all camera control features on or off.",
	
	["CategoryPresets"] = "Presets",
	["PresetDefault"] = "Default",
	["PresetDefaultHelp"] = "Reset camera settings to default.",
	["PresetClose"] = "Close",
	["PresetCloseHelp"] = "Set camera to follow the mouse more closely than the default preset.",
	["PresetSmooth"] = "Smooth",
	["PresetSmoothHelp"] = "Set camera to follow the mouse more smoothly than the default preset.",
	["PresetLoose"] = "Loose",
	["PresetLooseHelp"] = "Set camera to swoop around like a drunk migratory bird.",
	
	["CategoryCameraAngle"] = "Camera angle",
	["1PSmoothness"] = "First person smoothness",
	["1PSmoothnessHelp"] = "The smoothness of the first person view when looking around.",
	["1PFreelookSmoothness"] = "First person free-look smoothness",
	["1PFreelookSmoothnessHelp"] = "The smoothness of the first person free-look view when looking around.",
	["3PSmoothness"] = "Third person smoothness",
	["3PSmoothnessHelp"] = "The smoothness of the third person view when looking around.",

	["CategoryCameraTracking"] = "Camera tracking",
	["3PMotionSmoothness"] = "Third person motion smoothness",
	["3PMotionSmoothnessHelp"] = "The smoothness of the position of the third person camera as it follows the player. Higher smoothness will make the camera lag behind when the player is moving quickly.",

	["CategoryBody"] = "Body",
	["BodyInertiaToggle"] = "Body inertia toggle",
	["BodyInertiaToggleHelp"] = "In first person view, controls if the player's body and arms have added inertia. They will take a short time to react to camera changes.",
	["BodyInertiaSmoothness"] = "Body inertia smoothness",
	["BodyInertiaSmoothnessHelp"] = "The reaction time of the body and arms to changes in look direction.",

	["CategoryControls"] = "Controls",
	["KeybindToggleFreeLook"] = "Toggle free look key",
	["KeybindToggleFreeLookHelp"] = "Press to toggle free look mode. The mouse will control the camera without changing movement direction. Works in both first and third person.",
	["MouseHSensitivity"] = "Horizontal mouse sensitivity",
	["MouseHSensitivityHelp"] = "A finer control of the game's mouse sensitivity.",
	["MouseVSensitivity"] = "Vertical mouse sensitivity",
	["MouseVSensitivityHelp"] = "A finer control of the game's mouse sensitivity.",
}