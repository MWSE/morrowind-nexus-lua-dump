return {
    Conditions = {
        ICondition = require("sb_htn.Conditions.ICondition"),
        FuncCondition = require("sb_htn.Conditions.FuncCondition")
    },

    Contexts = {
        IContext = require("sb_htn.Contexts.IContext"),
        BaseContext = require("sb_htn.Contexts.BaseContext"),
    },

    Effects = {
        IEffect = require("sb_htn.Effects.IEffect"),
        EEffectType = require("sb_htn.Effects.EEffectType"),
        ActionEffect = require("sb_htn.Effects.ActionEffect"),
    },

    Factory = {
        IFactory = require("sb_htn.Factory.IFactory"),
        DefaultFactory = require("sb_htn.Factory.DefaultFactory"),
    },

    Operators = {
        IOperator = require("sb_htn.Operators.IOperator"),
        FuncOperator = require("sb_htn.Operators.FuncOperator"),
    },

    Planners = {
        Planner = require("sb_htn.Planners.Planner"),
    },

    Tasks = {
        ITask = require("sb_htn.Tasks.ITask"),
        ETaskStatus = require("sb_htn.Tasks.ETaskStatus"),

        CompoundTasks = {
            ICompoundTask = require("sb_htn.Tasks.CompoundTasks.ICompoundTask"),
            IDecomposeAll = require("sb_htn.Tasks.CompoundTasks.IDecomposeAll"),
            EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus"),
            CompoundTask = require("sb_htn.Tasks.CompoundTasks.CompoundTask"),
            PausePlanTask = require("sb_htn.Tasks.CompoundTasks.PausePlanTask"),
            Selector = require("sb_htn.Tasks.CompoundTasks.Selector"),
            Sequence = require("sb_htn.Tasks.CompoundTasks.Sequence"),
            TaskRoot = require("sb_htn.Tasks.CompoundTasks.TaskRoot"),
        },

        OtherTasks = {
            Slot = require("sb_htn.Tasks.OtherTasks.Slot"),
        },

        PrimitiveTasks = {
            IPrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask"),
            PrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.PrimitiveTask")
        }
    },

    IDomain = require("sb_htn.IDomain"),
    BaseDomainBuilder = require("sb_htn.BaseDomainBuilder"),
    Domain = require("sb_htn.Domain"),
    DomainBuilder = require("sb_htn.DomainBuilder")
}
