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
function Gear:export()
	local str = {}
	for k,v in pairs(self.profile) do
		table.insert(str, tostring(v))
		table.insert(str, ",\n")
	end
	print(table.concat(str))
	return table.concat(str)
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

local function expand(pitch, distance)
	local newpitch = {}
	for i,point in pairs(pitch) do
		newpitch[i] = point:copy():normalize():scale(distance):add(point)
	end
	return newpitch
end
local function rotateAround(shape, point, angle)
	angle = angle * 180/math.pi
	shape = shape:translate( csg.Vector3D(point*-1) )
	shape = shape:rotateZ(angle)
	shape = shape:translate( csg.Vector3D(point) )
	return shape
end
local function cutMatingGear(pitch, speed1,  gear, speed2, distance, addendum, stepsize, step)
	local mate = cag.Polygon(expand(pitch, addendum))
	local gearything = cag.Polygon(pitch)

	step = false
	local center = vec3(-distance, 0, 0)
	gear = gear:translate( csg.Vector3D(center) )
	for t=0,2*math.pi,stepsize do
		local angle1 = speed1:integrate(t)
		local angle2 = speed2:integrate(t)
		mate = mate:rotateZ((angle1)*180/math.pi)
		gear = rotateAround(gear, center, (angle2))
		mate = mate:subtract(gear)
		if step then coroutine.yield(mate, gear, gearything) end
		gear = rotateAround(gear, center, (-angle2))
		mate = mate:rotateZ((-angle1)*180/math.pi)
	end
	return mate, gear, gearything
end
local function cutTeeth(pitch, tooth, nteeth, addendum, step)

	local gear = cag.Polygon(expand(pitch, addendum))
	local gearything = cag.Polygon(pitch)
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


	--for t=0,2*math.pi,0.1 do
	--for t=0, 360, 10 do
	local lastPoint = pitch[#pitch]
	print("!",lastPoint)
	local transformedRack = rack:translate( csg.Vector3D(lastPoint) )
	--coroutine.yield(gear, transformedRack)
	local zero = vec3(-1,0,0)
	local lastSegment = zero
	for i=1,2 do
		for _,point in ipairs(pitch) do
			local segment = (point - lastPoint):normalize()
			local angle = math.acos(lastSegment:dot(segment))
			if point == pitch[1] and i==1 then angle = -angle end --hack. only works for SPECEFIC GEARS

			transformedRack = rotateAround(transformedRack, lastPoint, -angle)
			gear = gear:subtract(transformedRack)
			if step then coroutine.yield(gear, transformedRack, gearything) end
			lastPoint = point
			lastSegment = segment
		end
	end

	return gear, rack, gearything
end

local function involuteTooth(addendum, dedendum, pressureAngle)
	return cag.Polygon( {vec3(-0.5, addendum, 0), vec3(0, -dedendum, 0), vec3(0, -2*(dedendum+addendum), 0), vec3(-1, -2*(addendum+dedendum), 0), vec3(-1, -dedendum, 0)})
end

function GearSet:__init(speed2, speed1, distance, nteeth, steps, animate)
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
		local pts = cag.toPolyline(polygon)
		for i,pt in pairs(pts) do
			pts[i] = vec3(pt[1], pt[2], 0)
		end
		return pts
	end
	local co = coroutine.create(cutTeeth)
	local ok, gear = coroutine.resume(co, pitchCurve1, tooth, nteeth, addendum, false)
	if not ok then print( gear ) end

	local gear1, gear2 = gear
	--used to do cutting animations.
	function self:step()
		local ok, gear, rack, extra
		if coroutine.status(co) ~= 'dead' then 
			ok, gear, rack, extra = coroutine.resume(co)
			if not gear2 then gear1=gear else gear2=gear end
		else
			co = coroutine.create(cutMatingGear)
			ok, gear, rack, extra = coroutine.resume(co, pitchCurve2, speed2, gear1, speed1, distance, addendum, .1, animate)
			gear2 = gear
		end
		if not ok or not gear or not rack then
			print(ok, gear, rack)
		else
			return blah(gear), blah(rack), blah(extra or rack)
		end
	end


	self.pitchCurve1 = pitchCurve1
	self.pitchCurve2 = pitchCurve2
	if not animate then
		local co = coroutine.create(cutMatingGear)
		local ok, gear, rack, extra = coroutine.resume(co, pitchCurve2, speed2, gear1, speed1, distance, addendum, .1, animate)
		print(ok, gear, rack)
		gear2 = gear
		self.gears = {Gear(speed1, blah(gear1), vec3(0,0,0)), Gear(speed2, blah(gear2), vec3(distance, 0, 0))}
	end
end

return GearSet
