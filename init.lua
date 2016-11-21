require'drawlib.strict'({"js"})

package.path = package.path..";/drawlib/?lua;drawlib/?.lua"
--require("httploader")



local GearSet = require'noncirculargear'
local Functions = require'functions'


gear = GearSet(Functions.Constant(1), Functions.Sine(), 6)
