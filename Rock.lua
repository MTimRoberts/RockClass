--[[ 
Made by 0MRob

This is a class for simplifying creation of rock effects that are more commonly being used in games now.

Example Usage:
	(this will make an rock fling from 1,1,1 with the size of 3,3,3 and will last 1 second)
	EX#1: 
		local Rock = Rock.new(CFrame(1,1,1), Vector3.new(3,3,3), 1)
		Rock:UpdateFromGround({workspace.Map})
		Rock:Fling(workspace, 50)

	(this will do the same above but create an rock explosion effect)
	EX#1: 
		for i =1, 10 do
			local Rock = Rock.new(CFrame(1,1,1), Vector3.new(3,3,3), 1)
			Rock:UpdateFromGround({workspace.Map})
			Rock:Fling(workspace, 50)
		end

API:

Constructor:
	Rock.new(CFrame cf, Vector3 size, Float life, Instance custompart)
			> Creates a rock at a certain cframe, size, and sets how long the rock will live
			> custompart can be any part you want to use instead of the default part
			
Methods:
	Rock:UpdateFromGround(Integer distance_down, Instance Array Whitelist desc_tab)
		> Sets the Rock properties to match what is below it, (material, color, transparency, reflectancy)
		> Uses raycast to get the properties below
		> Correctly implement whitelist array, this function is called :FindPartOnRayWithWhitelist()
	
	Rock:AddTween(Tween Instance tween, Integer tween_delay)
		> Adds a tween to the part to be played at a specific time once Rock:Play() is called
		> You can add multiple Tweens to be played
	
	Rock:Fling(Integer vel, Integer rvel )
		> Flings the rock upwards randomly, at the certain velocity specified
		> Default parameters are Rock:Fling(50, 0, workspace)
		> This function is an exit point and calls Rock:Play()
		> rvel is how random the velocity is
		
	Rock:Play()
		> Plays all tweens added and once done, destroys itself
		> This function is an exit point
		
Properties:
	Rock.Part
		> Returns the instance to be used, you can set its properties and add children to the part, read/edit
	Rock.Life
		> How long the rock will last once played until its deleted, read/edit
	Rock.Tweens
		> An array of arrays that contain a tween object and delay for that object to be played, read/edit
		
Note:
	feel free to edit anything below.
]]


local Rock = {}
Rock.__index = Rock

--// Services
local Debris = game:GetService('Debris')

--// Objects
local RockBase = script.Part
local PARTS_IN_CACHE = 200
local PartCache = require(script.Parent.PartCache:WaitForChild("PartCache"))
local RockCache = PartCache.new(RockBase, PARTS_IN_CACHE)
RockCache:SetCacheParent(workspace.CurrentCamera)
--// Variable Localization
local WS = workspace
local CFrame_new, Vector3_new, Ray_new, Instance_new = CFrame.new, Vector3.new, Ray.new, Instance.new
local setmeta, pairss, er, del, war = setmetatable, pairs, error, delay, warn
local math_rad, math_random, CFrame_Angles = math.rad, math.random, CFrame.Angles
local table_insert, table_remove = table.insert, table.remove
math.randomseed(os.time())
--// Constructor
function Rock.new(cf, size, life, custompart)
	cf = cf or CFrame_new(0,5,0)
	custompart = custompart or RockBase
	if typeof(cf) == 'Vector3' then cf = CFrame_new(cf) end
	local NewRock = {}
	setmeta(NewRock, Rock)
	local rock = RockCache:GetPart()
	rock.Size = size or Vector3_new(1,1,1)
	rock.CFrame = cf
	rock.CanCollide = false
	rock.Anchored = true
	rock.Locked = true
	rock.CastShadow = false
	NewRock.EnableTrail = false
	NewRock.EnableParticle = false
	NewRock.Part = rock
	NewRock.Life = life
	NewRock.Tweens = {}
	NewRock.OnTouch = (function() end)
	return NewRock
end

--// Updates the properties of the part of the rock
-- Example: rock:UpdatePartProps({{'Transparency', 1},{CanCollide, true}})
function Rock:UpdatePartProps(table_of_props)
	for i,v in pairss(table_of_props) do
		self.Part[v[1]] = v[2]
	end
end

--// Updates the color and material of rock from bneath the cframe of the part
function Rock:UpdateFromGround(desc_tab, distance_down)
	desc_tab = desc_tab or {WS}
	distance_down = distance_down or -100
	local ray = Ray_new(self.Part.Position + Vector3_new(0,5,0), Vector3_new(0, distance_down, 0))
	local p, pos, _, material = WS:FindPartOnRayWithWhitelist(ray, desc_tab)
	if p then
		self.Part.Material = material
		self.Part.Color = p.Color
		self.Part.Transparency = p.Transparency
		self.Part.Reflectance = p.Reflectance
		local lookvec = self.Part.CFrame.LookVector
		self.Part.Position = pos + Vector3.new(0,0, 0)
		return p
	end
end

function Rock:RandomRotate()
	self.Part.CFrame = self.Part.CFrame * CFrame_Angles(math_rad(math_random(-180, 180)),math_rad(math_random(-180, 180)),math_rad(math_random(-180, 180)))
end

--// Adds a tween effect to the rock on play
function Rock:AddTween(tween, tween_delay)
	tween_delay = tween_delay or 0
	table_insert(self.Tweens, {tween = tween, tween_delay=tween_delay})
end

--// Plays the rock but flings it with a certain velocity at a random direction (mostly upwards)
function Rock:Fling(vel, rvel)
	vel = vel or 50
	rvel = rvel or 0
	local Part = self.Part
	Part.Anchored = false
	Part.CFrame = Part.CFrame * CFrame_Angles(0, math_rad(math_random(-100,100)), 0) *  CFrame_Angles(math_rad(math_random(0, 80)), 0, 0)
	Part.Velocity = Part.CFrame.LookVector * (vel + math_random(-rvel, rvel)) + Vector3_new(0, vel + math_random(-rvel, rvel), 0)
	local a = Instance_new('BodyAngularVelocity')
	a.AngularVelocity = Vector3_new(math_random(-10,10),math_random(-10,10),math_random(-10,10))
	a.Parent = Part
	--Debris:AddItem(a, .1)
	self:Play()
end

function Rock:Destroy()
	self.Part.ParticleEmitter.Enabled = false
	self.Part.Trail.Enabled = false
	self.Part.Anchored = true
	RockCache:ReturnPart(self.Part)
	self = nil
end
--//  removes rock, if it has a tween, plays that too
function Rock:Play()
	local part = self.Part
	part.Parent = workspace.Junk
	part.Trail.Enabled = self.EnableTrail
	part.ParticleEmitter.Enabled = self.EnableParticle
	if self.Life ~= nil then 
		del(self.Life, function()
			self:Destroy()
		end)
	else
		del(.1, function()
			local con = nil
			local touch = false
			con = part.Touched:Connect(function(p)
				if p.Parent == workspace.Junk then return end
				if touch then con:Disconnect() return end
				touch = true
				self.OnTouch()
				self:Destroy()
			end)
		end)
	end
	if #self.Tweens ~= 0 then 
		for i,v in pairss(self.Tweens) do
			if v.tween_delay >= (self.Life or math.huge) then
				war('[Rock]: TweenDelay was set greater than part life...  Tween will not play')
			else
				del(v.tween_delay, function()
					v.tween:Play()
				end)
			end
		end
	end

end

function Rock:GetPart()
	return self.Part
end

return Rock