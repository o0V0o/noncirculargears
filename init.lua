package.path = package.path..";?/init.lua;?.lua;/drawlib/?.lua;drawlib/?.lua"
print("path:", package.path)
js.global.console:log("path:", package.path)

require("httploader")
require'strict'({"js", "calcPitch"})



local GearSet = require'noncirculargear'
local Functions = require'functions'

local anim = false
local step = false

--local gearset = GearSet(Functions.Constant(1), Functions.Constant(1)+2, 6)
local offset = 1.5
local gearset = GearSet(Functions.Constant(1), Functions.normalize(Functions.Sine()+offset, math.pi*2, 2*math.pi), 6, 25, 30, anim)
--local gearset = GearSet(Functions.Constant(1), Functions.Constant(1), 6, 4)

if anim then
	require'cutanim'(gearset, true)
else 
	print("printing...")
	print(gearset.gears[1]:export(), gearset.gears[2]:export())
	require'display'(gearset.gears[1], gearset.gears[2])
end
