--!strict

local Velora = require(script.Parent.Velora)

-- Create an object to animate.
local part = Instance.new("Part", workspace)
part.Anchored = true

-- Create a Velora animation.
local velora = Velora.new({
	goal = {
		Size = Vector3.new(5, 5, 5),
		Transparency = 1,
	},

	objects = {
		part,
	},

	easingStyle = "Cubic",
	duration = 2,
	yield = false,
	continuous = false,

	callbacks = {
		onCompletedVelora = {
			function()
				-- Runs when the animation completes.
			end,
		},

		durationReached = {
			{
				duration = 0.5,
				previousCalled = false,
				callback = function()
					-- Runs when the animation reaches 0.5 seconds.
				end,
			},
		},
	},
})

task.wait(1)

-- Start the animation.
velora:play()

-- Pause and resume it.
task.wait(0.6)
velora:pause()
velora:play()

-- Add another object while Velora is running.
local newPart = Instance.new("Part", workspace)
newPart.Anchored = true
newPart.Position = Vector3.new(5, 5, 5)

velora:addObjectList({
	newPart,
})

task.wait(1)

velora:pause()
task.wait(3)
velora:play()
