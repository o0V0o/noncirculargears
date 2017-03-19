package.path = package.path..";?/init.lua;?.lua;/drawlib/?.lua;drawlib/?.lua;/strange/?.lua;/noncirculargears/drawlib/?.lua;"
print("path:", package.path)
js.global.console:log("path:", package.path)

require("httploader")
require'strict'
local event = require'eventhandler'
--require'strict'({"js", "calcPitch"})



local GearSet = require'noncirculargear'
local Functions = require'functions'

js.global.document:getElementById("loading").style.display = 'none'

local anim = false
local step = true

--local gearset = GearSet(Functions.Constant(1), Functions.Constant(1)+2, 6)
local offset = 1.5

-- sin wave gear
--local gearset = GearSet(Functions.Constant(1), Functions.normalize(Functions.Sine()+offset, math.pi*2, 2*math.pi), 6, 25, 30, anim, true)

--circular gear.
--local gearset = GearSet(Functions.Constant(1), Functions.Constant(1), 6, 4)

-- better sine wave gear
--[[
local gearset = GearSet(
	Functions.normalize(Functions.Sine()+offset, math.pi*2, 2*math.pi),
	Functions.normalize(Functions.Constant(1), math.pi*2, 2*math.pi),
6, 25, 30, anim, false)
--]]


local slow, fast = 0.45, 1.6
-- triangle wave gear
local gearset = GearSet(  Functions.Constant(1), Functions.normalize(Functions.Periodic(Functions.LinearSpline( { {x=0, y=slow}, {x=math.pi, y=fast}, {x=math.pi*2, y=slow}}), math.pi*2), math.pi*2, math.pi*2), 6, 20, 30, anim, true)

if anim then
	require'cutanim'(gearset, true)
else 
	print("printing...")
	print(gearset.gears[1]:export(), gearset.gears[2]:export())
	event("d1", "click", function()
		js.global:jsSave( gearset.gears[1]:export(), "gear1.py", "text")
	end)
	event("d2", "click", function()
		js.global:jsSave( gearset.gears[2]:export(), "gear2.py", "text")
	end)
	require'display'(gearset.gears[1], gearset.gears[2])
end
