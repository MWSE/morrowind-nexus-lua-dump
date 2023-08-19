local input = require("openmw.input")
local keys = input.KEY
local ctrl = input.CONTROLLER_BUTTON
return   {
    finishTextEdit = {
        key = keys.Enter,
        ctrl = ctrl.A,
        label = "Set Name",
        context = { "rename" }
    },
    selectMarkDest = {
        key = keys.Enter,
        ctrl = ctrl.A,
        label = "Teleport",
        context = { "normal" },
        inputAction = input.ACTION.Use
    },
    selectMarkOverwrite = {
        key = keys.Enter,
        ctrl = ctrl.A,
        label = "Save Marked Location over Selected Mark",
        context = { "overwrite" },
        inputAction = input.ACTION.Use
    },
    navUp = {
        key = keys.UpArrow,
        ctrl = ctrl.DPadUp,
        inputAction = input.ACTION.ZoomOut,
        inputAction2 = input.ACTION.MoveForward
    },
    navDown = {
        key = keys.DownArrow,
        ctrl = ctrl.DPadDown,
        inputAction = input.ACTION.ZoomIn,
        inputAction2 = input.ACTION.MoveBackward
    },
    enterEditMode = {
        key = keys.R,
        ctrl = ctrl.Y,
        label = "Rename Marked Location",
        context = { "normal" }
    },
    deleteItem = {
        key = keys.D,
        ctrl = ctrl.X,
        label = "Delete Marked Location",
        context = { "normal" }
    },
    cancelMenu = {
        key = keys.Backspace,
        ctrl = ctrl.Back,
        label = "Cancel Recall",
        context = { "normal" }
    },
    cancelMenuOverwrite = {
        key = keys.Backspace,
        ctrl = ctrl.Back,
        label = "Cancel Mark",
        context = { "overwrite" }
    },
    controllerMode = false
}