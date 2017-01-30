
local class = require'lobject'
local F = {}

F.Function = class()
function F.Function.__add(f,g)
	if type(f)=='number' then f=F.Constant(f) end
	if type(g)=='number' then g=F.Constant(g) end
	return F.Addition(f,g)
end
function F.Function.__mul(f,g)
	if type(f)=='number' then f=F.Constant(f) end
	if type(g)=='number' then g=F.Constant(g) end
	return F.Multiplication(f,g)
end

function F.normalize(f, period, value)
	local integration = f:integrate(period)
	return f*(value/integration)
end

F.Multiplication = class(F.Function)
function F.Multiplication:__init(f,g)
	self.f=f
	self.g=g
end
function F.Multiplication:integrate(t)
	if self.f.c then
		return self.g:integrate(t)*self.f.c
	end
	if self.g.c then
		return self.f:integrate(t)*self.g.c
	end
	error('cant integrate the multiplication of functions. (yet)')
end
function F.Multiplication:get(t)
	return self.f:get(t) * self.g:get(t)
end

F.Addition = class(F.Function)
function F.Addition:__init(f,g)
	self.f = f
	self.g = g
end
function F.Addition:integrate(t)
	return self.f:integrate(t) + self.g:integrate(t)
end
function F.Addition:get(t)
	return self.f:get(t) + self.g:get(t)
end

F.Sine = class(F.Function)
function F.Sine:integrate(t)
	return 1-math.cos(t)
end
function F.Sine:get(t)
	return math.sin(t)
end

F.SineSquared = class(F.Function)
function F.SineSquared:integrate(x)
	return (1/4)*(2*x-math.sin(2*x))
end
function F.SineSquared:get(t)
	return math.sin(t)*math.sin(t)
end

F.Periodic = class(F.Function)
function F.Periodic:__init(func, period)
	self.func = func
	self.period = period
end
function F.Periodic:integrate(t)
	return self.func:integrate( t%self.period ) + (self.func:integrate(self.period)*math.floor(t/self.period))
end
function F.Periodic:get(x)
	return self.func:get(x%self.period)
end

F.Constant = class(F.Function)
function F.Constant:__init(c)
	self.c = c
end
function F.Constant:integrate(t)
	return self.c*t
end
function F.Constant:get(x)
	return self.c
end

F.Linear = class(F.Function)
function F.Linear:__init(slope, intercept)
	self.slope = slope
	self.intercept = intercept
end
function F.Linear:integrate(t)
	return 0.5*self.slope*t*t  + self.intercept*t
end
function F.Linear:get(x)
	return self.slope*x + self.intercept
end

F.LinearSpline = class(F.Function)
function F.LinearSpline:__init(points)
	self.points = points
end
function F.LinearSpline:get(x)
	local lastPoint
	for i,point in ipairs(self.points) do
		if lastPoint and lastPoint.x <= x and x <= point.x then
			local t = (x-lastPoint.x)/(point.x-lastPoint.x)
			return lastPoint.y*(1-t) + point.y*(t)
		end
		lastPoint = point
	end
	return 0
end
function F.LinearSpline:integrate(t)
	local lastPoint
	local sum = 0
	for i,point in ipairs(self.points) do
		if lastPoint then
			local dx = (point.x-lastPoint.x)
			local dy = (point.y-lastPoint.y)
			if t>= point.x then
				--sum = sum + 0.5*dx*dy + lastPoint.y*dx
				sum = sum + 0.5*(lastPoint.y + point.y)*dx
			elseif t>lastPoint.x then
				local x = t-lastPoint.x
				local slope, intercept = dy/dx, lastPoint.y
				sum = sum + 0.5*slope*x*x  + intercept*x
			end
		end
		lastPoint = point
	end
	if t>lastPoint.x then
		sum = sum + lastPoint.y*(t-lastPoint.x)
	end
	return sum
end

return F
