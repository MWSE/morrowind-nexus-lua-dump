local M = require("herbert100.math.core")

local splines = require("herbert100.math.Polynomial_Spline")
M.Polynomial_Spline = splines.Polynomial_Spline
M.Evenly_Spaced_Spline = splines.Evenly_Spaced_Spline

M.Polynomial = require("herbert100.math.Polynomial")
M.Rational = require("herbert100.math.Rational")

return M

