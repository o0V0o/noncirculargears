local CSG = js.global.CSG
local CAG = js.global.CAG
local cag = {}

local function array(...)
	return js.global:jsArray(...)
end

function cag.Vector2D(x,y)
	if type(x)=='table' then
		return js.new( CSG.Vector2D, x.x, x.y)
	else
		return js.new( CSG.Vector2D, x,y)
	end
end
function cag.toPoints(shape)
	local points = {}
	for _,side in ipairs(shape.sides) do
		table.insert(points, {side.vertex0.pos.x, side.vertex0.pos.y})
	end
	return points
end
function cag.toPolyline(shape)
	local sides = shape.sides
	local points = {}

	local function compare(v1, v2)
		return v1.pos.x==v2.pos.x and v1.pos.y == v2.pos.y
	end

	local side = sides[0]
	table.insert(points, {side.vertex0.pos.x, side.vertex0.pos.y})
	for i=0,#sides do
		table.insert(points, {side.vertex1.pos.x, side.vertex1.pos.y})
		for _,testSide in ipairs(sides) do
			if side ~= testSide and compare(side.vertex1, testSide.vertex0) then
				side = testSide
				break
			end
		end
	end
	--table.insert(points, {sides[0].vertex0.pos.x, sides[0].vertex0.pos.y}) --make a complete loop
	return points
end
function cag.toLines(shape)
	local points = {}
	print("npoints",#shape.sides)
	for _,side in ipairs(shape.sides) do
		table.insert(points, {side.vertex0.pos.x, side.vertex0.pos.y})
		table.insert(points, {side.vertex1.pos.x, side.vertex1.pos.y})
	end
	return points
end
function cag.Polygon(vertices)
	local points = {}
	for _,pt in ipairs(vertices) do
		table.insert(points, cag.Vector2D(pt))
	end
	local verts = array(points)
	local poly = CAG:fromPoints( verts )
	return poly
end

return cag
