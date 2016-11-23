
package.path = package.path..";?/init.lua;?.lua;/drawlib/?lua;drawlib/?.lua"
require("httploader")
require'strict'({"js", "calcPitch"})



local GearSet = require'noncirculargear'
local Functions = require'functions'


--local gearset = GearSet(Functions.Constant(1), Functions.Constant(1)+2, 6)
local gearset = GearSet(Functions.Constant(1), Functions.normalize(Functions.Sine()+1.5, math.pi*2, 2*math.pi), 6)

require'display'(gearset.gears[1], gearset.gears[2])
