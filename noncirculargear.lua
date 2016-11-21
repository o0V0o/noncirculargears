local class = require'lobject'
local Quaternion = require'drawlib.quaternion'
local Vector = require'drawlib.vector'
local vec3 = Vector.vec3


local Gear = class()

function Gear:__init(speed, profile, center)
	self.speed = speed --a function of time
	self.profile = profile
	self.center = center
	self.up = vec3(0,0,1)
end
function Gear:transform(t)
	local theta = self.speed:integrate(t)
	return Quaternion.axisAngle( self.up, theta ):matrix():translate(self.center)
end

local GearSet = class()

local function calcPitch(t, speed1, speed2, distance)
	local theta = speed1:integrate(t)
	local ratio = math.abs(speed1:get(t)/speed2:get(t))
	local pitch = ratio*distance
	return vec3(math.cos(theta)*pitch, math.sin(theta)*pitch, 0)
end
function GearSet:__init(speed1, speed2, distance, steps)
	steps = steps or 100
	print(speed1, speed2, distance, steps)
	speed2=speed2*-1
	--now we calculate the pitch curve of the two gears
	local stepsize = 2*math.pi/steps
	local t = 0
	local pitchCurve1 = {}
	local pitchCurve2 = {}
	for i=1,steps do
		t = t + stepsize
		table.insert(pitchCurve1, calcPitch( t, speed1, speed2, distance))
		table.insert(pitchCurve2, calcPitch( t, speed2, speed1, distance))
	end
	self.pitchCurve1 = pitchCurve1
	self.pitchCurve2 = pitchCurve2
	self.gears = {Gear(speed1, pitchCurve1, vec3(0,0,0)), Gear(speed2, pitchCurve2, vec3(distance, 0, 0))}
end

return GearSet
