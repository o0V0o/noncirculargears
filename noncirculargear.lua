local class = require'lobject'
local Quaternion = require'drawlib/quaternion'
local Vector = require'drawlib/vector'
local vec3 = Vector.vec3

local csg = require'csg'
local cag = require'cag'


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

function calcPitch(t, speed1, speed2, distance)
	local s1, s2 = speed1:get(t), speed2:get(t)
	local ratio = math.abs(s2/s1)
	local pitch = (ratio*distance)/(1+ratio)
	return pitch
end
local function plot(t, pitch, speed1, offset)
	local theta = speed1:integrate(t) + (offset or 0)
	theta = theta * -1
	return vec3(math.cos(theta)*pitch, math.sin(theta)*pitch, 0)
end

local function toShape(curve, center)
	local points = {}
	local center = center or vec3(0,0,0)
	local up = vec3(0,0,1)

	local polygons, lastPt = {}, nil
	for _,pt in ipairs(curve) do
		if lastPt then
			table.insert(polygons, csg.Polygon({ csg.Vertex( center, up), csg.Vertex(pt, up), csg.Vertex(lastPt, up)} ))
		end
		lastPt = pt
	end

	return csg.Solid(polygons)
end

local function calcPerimeter(pitch)
	local sum = 0
	local lastPoint = pitch[#pitch]
	for _,point in ipairs(pitch) do
			print((point-lastPoint):len())
			sum = sum + (point-lastPoint):len()
		lastPoint = point
	end
	return sum
end

local function cutTeeth(pitch, tooth, nteeth, addendum, dedendum)
	local gear = cag.Polygon(pitch)
	local gearything = gear
	local perimeter = calcPerimeter(pitch)
	local toothSize = perimeter/nteeth

	local toothytooth = tooth
	local tooth = tooth:scale( toothSize )
	local rack = toothytooth:scale( toothSize )

	local v = csg.Vector3D(-1*toothSize,0,0)
	print(perimeter, nteeth, toothSize, v, toothSize*nteeth)
	for i=1,nteeth do
		tooth = tooth:translate(v)
		rack = rack:union(tooth)
	end

	local function rotateAround(shape, point, angle)
		angle = angle * 180/math.pi
		shape = shape:translate( csg.Vector3D(point*-1) )
		shape = shape:rotateZ(angle)
		shape = shape:translate( csg.Vector3D(point) )
		return shape
	end

	--for t=0,2*math.pi,0.1 do
	--for t=0, 360, 10 do
	local lastPoint = pitch[#pitch]
	print("!",lastPoint)
	local transformedRack = rack:translate( csg.Vector3D(lastPoint) )
	coroutine.yield(gear, transformedRack)
	local zero = vec3(-1,0,0)
	local lastSegment = zero
	for i=1,2 do
		for _,point in ipairs(pitch) do
			local segment = (point - lastPoint):normalize()
			local angle = math.acos(lastSegment:dot(segment))
			if point == pitch[1] and i==1 then angle = -angle end --hack. only works for SPECEFIC GEARS

			transformedRack = rotateAround(transformedRack, lastPoint, -angle)
			gear = gear:subtract(transformedRack)
			--coroutine.yield(gear, transformedRack, gearything)
			lastPoint = point
			lastSegment = segment
		end
	end

	return gear, rack, gearything
end

local function involuteTooth(addendum, dedendum, pressureAngle)
	return cag.Polygon( {vec3(0, 0, 0), vec3(-1, 0, 0), vec3(-0.5, addendum+dedendum, 0)} )
end

function GearSet:__init(speed2, speed1, distance, nteeth, steps)
	steps = steps or 100
	print(speed1, speed2, distance, steps)
	speed2=speed2*-1
	--now we calculate the pitch curve of the two gears
	local stepsize = 2*math.pi/steps
	local t = 0
	local pitchCurve1 = {}
	local pitchCurve2 = {}
	for i=1,steps do
		table.insert(pitchCurve1, plot(t, calcPitch( t, speed1, speed2, distance), speed1))
		table.insert(pitchCurve2, plot(t, -calcPitch( t, speed2, speed1, distance), speed2))
		t = t + stepsize
	end

	--local shape = js.global.CSG:cube()

	local gear = cag.Polygon(pitchCurve1)

	local addendum, dedendum = .3, .3
	local tooth = involuteTooth(addendum, dedendum)

	--tooth = tooth:extrude({})
	--js.global.tooth = tooth
	--local viewer =  js.new( js.global.Viewer, tooth, 500, 500, 15)
	--js.global:jsAddViewer(viewer)
	
	local blah = function(polygon)
		local pts = cag.toLines(polygon)
		for i,pt in pairs(pts) do
			pts[i] = vec3(pt[1], pt[2], 0)
		end
		return pts
	end
	local co = coroutine.create(cutTeeth)
	coroutine.resume(co, pitchCurve1, tooth, nteeth, addendum, dedendum)
	local ok, gear = coroutine.resume(co, pitchCurve1, tooth, nteeth, addendum, dedendum)

	function self:step()
		local ok, gear, rack, extra
		if coroutine.status(co) ~= 'dead' then 
			ok, gear, rack, extra = coroutine.resume(co)
		end
		if not ok or not gear or not rack then
			print(ok, gear, rack)
		else
			return blah(gear), blah(rack), blah(extra or rack)
		end
	end

	self.pitchCurve1 = pitchCurve1
	self.pitchCurve2 = pitchCurve2
	self.gears = {Gear(speed1, blah(gear), vec3(0,0,0)), Gear(speed2, pitchCurve2, vec3(distance, 0, 0))}
end

return GearSet
