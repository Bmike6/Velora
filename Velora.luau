--!strict
local Settings = require(script.Prefabs.Settings)
local VelorableProperties = require(script.Types.VelorableProperties)
local EasingStyles = require(script.Prefabs.EasingStyles)

-- Services --
local RunService = game:GetService("RunService")
local HTTP = game:GetService("HttpService")

export type VeloraArgumentList = {
	objects:{Instance}?,
	duration:number?,
	easingStyle:EasingStyles.EaseStyles?,
	goal:{[VelorableProperties.Properties]:VelorableProperties.PropertyTypes}?,
	yield:boolean?,
	continuous:boolean?,
	attributes:{
		[string]:any
	}?,
	callbacks:{
		onCompletedVelora:{(()->())}?,
		valueChangedVelora:{
			<T>(valueListening:string, updatedValue:T)->()
		}?,
		durationReached:{
			{
				duration:number,
				callback:()->(),
				previousCalled:boolean,
			}
		}?,
		perFrame:{
			(delta:number)->()
		}?
	}?
}

export type VeloraObject = {
	-- public fields --
	settings:typeof(table.clone(Settings)),	
	-- private fields --
	_callbacks:{
		_onCompletedVelora:{(()->())},
		_perFrameCallbacks:{
			(delta:number)->()
		},
		_onDurationReachedCallbacks:{
			{
				callback:()->(),
				duration:number,
				previousCalled:boolean,
			}
		},
		valueChangedVelora:{
			<T>(valueListening:string, updatedValue:T)->()
		}
	},
	_veloraState:"Playing"|"Paused"|"Inactive",

	_goal:{[VelorableProperties.Properties]:VelorableProperties.PropertyTypes},
	_start:{[Instance]:{VelorableProperties.PropertyTypes}},
	attributes:{string:any},
	
	_duration:number,
	_currentRunningTime:number,
	_veloraConnection:RBXScriptConnection?,
	_veloraID:string,
	_objectList:{Instance},
	_alpha:number,
	_cyclesRan:number,
	_reverse:boolean,
	_running:boolean,
	_courutine:thread,

	-- public methods --

	play:(self:VeloraObject)->(),
	pause:(self:VeloraObject)->(),
	cancel:(self:VeloraObject)->(),
	reset:(self:VeloraObject)->(),
	destroy:(self:VeloraObject)->(),
	setEaseStyle:(self:VeloraObject, style:EasingStyles.EaseStyles, tune:"In"|"Out"|"InOut")->(),
	extendDuration:(self:VeloraObject, newDuration:number)->(),
	
	clearObjects:(self:VeloraObject)->(),
	removeObjects:(self:VeloraObject, {Instance|string} )->(),

	setGoal:(self:VeloraObject, goal:VelorableProperties.Properties, value:VelorableProperties.PropertyTypes)->(),	
	setStart:(self:VeloraObject, instance:Instance, startProperty:VelorableProperties.Properties, value:VelorableProperties.PropertyTypes)->(),
	setCurrentTime:(self:VeloraObject, number:number)->(),


	addObjectList:(self:VeloraObject, obj:{Instance})->(),
	modifySettings:(self:VeloraObject, set:{[Settings.SettingKeys]:any})->(),
	addCompletionCallback:(self:VeloraObject, callback:()->())->(),
	addFrameCallback:(self:VeloraObject, (delta:number)->())->(),
	addDurationReachedCallback:(self:VeloraObject, {callback:(delta:number)->()})->(),

	-- private methods --
	_setVeloraID:(self:VeloraObject)->(),
	_handleVeloraCompletion:(self:VeloraObject)->(),
	_resetVeloraState:(self:VeloraObject)->(),
	_setStartValues:(self:VeloraObject)->(),
	_easeStyle:(alpha:number)->number,
	_lerp:(a:number, b:number, t:number)->number,
	

}
local VeloraObject = {}

VeloraObject.__index = VeloraObject

VeloraObject.__tostring = function(self:VeloraObject)
	return`Velora Object {self._veloraID}\n \t\t\t\tState: {self._veloraState}\n\t\t\t\tDuration: {self._duration}\n\t\t\t\tRunningTime: {self._currentRunningTime}`
end

function VeloraObject.new(arguments:VeloraArgumentList):VeloraObject
	local self = setmetatable({}, VeloraObject)::VeloraObject
	self._alpha = 0
	self._veloraState = "Inactive"
	self._goal = arguments.goal or {}
	self._objectList = arguments.objects or {}
	self._duration = arguments.duration or 0
	self._courutine = coroutine.running()
	self.settings = table.clone(Settings)
	self.settings.easingStyle = arguments.easingStyle or "Linear" 
	self.settings.yield = arguments.yield or false
	self.settings.continousPlayback = arguments.continuous or false
	self._easeStyle = (EasingStyles::any)[self.settings.easingStyle].Out
	self._reverse = false
	self._running = true
	self._currentRunningTime = 0
	self._cyclesRan = 0
	self.attributes = arguments.attributes or {}
	self._start = {}
	self._callbacks = {
		_onCompletedVelora = arguments.callbacks and arguments.callbacks.onCompletedVelora or {},
		_onDurationReachedCallbacks = arguments.callbacks and arguments.callbacks.durationReached or {},
		valueChangedVelora = arguments.callbacks and arguments.callbacks.valueChangedVelora or {},
		_perFrameCallbacks = arguments.callbacks and arguments.callbacks.perFrame or {},
	}
	self:_setVeloraID()
	self:_setStartValues()
	return self
end


function VeloraObject.play(self:VeloraObject) 
	if self._veloraState == "Paused" then
		self._veloraState = "Playing"
		return
	elseif self._veloraState == "Playing" then
		warn(`Velora Object <{self._veloraID}> already running thread`)
	end
	self._veloraState = "Playing"
	self._cyclesRan = 0
	self._running = true
	
	task.spawn(function()
		while self._running and task.wait() do
			
			if self._veloraState == "Playing" and  self._cyclesRan >= 1 or self._veloraState == "Paused" and  self._cyclesRan >= 1 then continue end
			if self._veloraState == "Inactive" and self.settings and self.settings.continousPlayback then
				self._veloraState = "Playing"
			elseif self._veloraState == "Inactive" then
				self:_setStartValues()
				self._running = false
				return
			end
			if not self or not self._running then return end
			self._cyclesRan += 1
			self._veloraConnection = RunService.Heartbeat:Connect(function(frameUpdate)
				for _, v in self._callbacks._perFrameCallbacks do
					v(frameUpdate)
				end
				if self._veloraState == "Paused" then 
					return
				elseif self._veloraState == "Inactive" and self._veloraConnection then
					self._veloraConnection:Disconnect()
				elseif self._currentRunningTime >= self._duration and self._veloraConnection then
					self._veloraState = "Inactive"
					self:_handleVeloraCompletion()
					self._veloraConnection:Disconnect()
					if self.settings.continousPlayback then
						self._reverse = not self._reverse
					end
					return
				end
				self._currentRunningTime = math.clamp(self._currentRunningTime+frameUpdate,0,self._duration)
				self._alpha = math.clamp(self._currentRunningTime/self._duration, 0, 1)
				for _, v in self._callbacks._onDurationReachedCallbacks do
					if not v.previousCalled and self._currentRunningTime >= v.duration then
						v.previousCalled = true
						v.callback()
					end
				end
				for i=1, #self._objectList do
					for property, value in self._start[self._objectList[i]] do
						if self._reverse then
							if self._objectList[i]:IsA("Model") then
								(self._objectList::any)[i]:PivotTo((self._goal::any)[property]:lerp((value::any),  self._easeStyle(self._alpha)))
							elseif type(value) == "number" then
								(self._objectList::any)[i][property] = 1-self._lerp(value::number, (self._goal::any)[property], self._easeStyle(self._alpha))
							else
								(self._objectList::any)[i][property] = (self._goal::any)[property]:lerp((value::any),  self._easeStyle(self._alpha))
							end
						else
							if self._objectList[i]:IsA("Model") then
								(self._objectList::any)[i]:PivotTo((value::any):lerp((self._goal::any)[property],  self._easeStyle(self._alpha)))
							elseif type(value) == "number" then
								(self._objectList::any)[i][property] = self._lerp(value::number, (self._goal::any)[property], self._easeStyle(self._alpha))
							else
								(self._objectList::any)[i][property] = (value::any):lerp((self._goal::any)[property],  self._easeStyle(self._alpha))
							end
						end
					end
				end	
			end)
		end
	end)
	if self.settings.yield then
		coroutine.yield(self._courutine) 
	end
end

function VeloraObject.pause(self:VeloraObject)
	self._veloraState = "Paused"
end

function VeloraObject.cancel(self:VeloraObject)
	self._veloraState = "Inactive"
	self._running = false
	if self._veloraConnection then
		self._veloraConnection:Disconnect()
	end	
end

function VeloraObject.clearObjects(self:VeloraObject)
	table.clear(self._objectList)
end

function VeloraObject.removeObject(self:VeloraObject, objectList:{Instance|string})
	local retainList = {}
	for _, object in objectList do
		if (type(object) == "string") then
			warn("WARING high computation for string search recommend type instance Lookup instead")
			for i, listObject in self._objectList do
				if listObject.Name == object::string then
					break
				end 
				retainList[i] = listObject
			end
		else
			table.remove(objectList, table.find(objectList, object::Instance))
		end
	end
	self._objectList = retainList
end

function VeloraObject.destroy(self:VeloraObject) -- clean as much as possible to make this object elligable for GC asap.
	self:cancel()
	table.clear(self._callbacks)
	table.clear(self._objectList)
	table.clear(self);
end

function VeloraObject.setGoal(self:VeloraObject, goal:VelorableProperties.Properties, value:VelorableProperties.PropertyTypes)
	self._goal[goal] = value
	for _, v in self._objectList do
		(self._start[v]::any)[goal] = (v::any)[goal] 
	end
end

function VeloraObject.setStart(self:VeloraObject, instance:Instance, startProperty:VelorableProperties.Properties, value:VelorableProperties.PropertyTypes)
	(self._start[instance]::any)[startProperty] = value
end

function VeloraObject.reset(self:VeloraObject)
	self:_resetVeloraState()
	self:_setStartValues()
end

function VeloraObject.addDurationReachedCallback(self:VeloraObject, duration:number, callback:()->())
	self._callbacks._onDurationReachedCallbacks[#self._callbacks._onDurationReachedCallbacks] = {
		duration = duration,
		previousCalled = false,
		callback = callback
	}
end

function VeloraObject.addObjectList(self:VeloraObject, obj:{Instance})
	for _, instance in obj do		
		self._start[instance] = {}
		for property, _ in self._goal do
			(self._start[instance]::any)[property] = (instance::any)[property]
		end
		(self._objectList::any)[#self._objectList+1] = instance
	end
end

function VeloraObject.modifySettings(self:VeloraObject, set:{[Settings.SettingKeys]:any}) 
	for i, v in set do
		(self.settings::any)[i] = v
	end
end

function VeloraObject.addCompletionCallback(self:VeloraObject, callback:()->())
	self._callbacks._onCompletedVelora[#self._callbacks._onCompletedVelora] = callback
end

function VeloraObject.setEaseStyle(self:VeloraObject, style:EasingStyles.EaseStyles, tune:"In"|"Out"|"InOut")
	if not (EasingStyles::any)[style] or not (EasingStyles::any)[style][tune] then
		warn("Invalid Easing Style")
	else
		self._easeStyle = (EasingStyles::any)[style][tune]
	end
end

function VeloraObject.extendDuration(self:VeloraObject, newDuration:number)
	self._duration = newDuration
end

function VeloraObject.setCurrentTime(self:VeloraObject, number:number)
	self._currentRunningTime = number
end

function VeloraObject.addFrameCallback(self:VeloraObject, callback:(delta:number)->())
	self._callbacks._perFrameCallbacks[#self._callbacks._perFrameCallbacks] = callback
end

-- private methods --

function VeloraObject._setVeloraID(self:VeloraObject)
	self._veloraID = HTTP:GenerateGUID(false):sub(1, 6)
end

function VeloraObject._setStartValues(self:VeloraObject)
	for obj=1, #self._objectList do
		self._start[self._objectList[obj]] = {}
		for property, value in self._goal do
	
			if self._objectList[obj]:IsA("Model") then
				(self._start :: any)[self._objectList[obj]][property] = (self._objectList::any)[obj::any].PrimaryPart[property::any]
			else
				(self._start :: any)[self._objectList[obj]][property] = (self._objectList::any)[obj::any][property::any]
			end
		end
	end
end

function VeloraObject._handleVeloraCompletion(self:VeloraObject)
	if self.settings.yield then
		coroutine.resume(self._courutine)
	end
	self:_resetVeloraState()
	for _, v in self._callbacks._onCompletedVelora do
		v()
	end
end

function VeloraObject._resetVeloraState(self:VeloraObject)
	self._alpha = 0
	self._currentRunningTime = 0
	for i, v in self._callbacks._onDurationReachedCallbacks do
		v.previousCalled = false
	end
end

function VeloraObject.addAttributes(self:VeloraObject, attributes:{[string]:any})
	for i, v in attributes do
		(self.attributes::any)[i] = v
	end
end

function VeloraObject.removeAttribute(self:VeloraObject, attributes:{string})
	for i=1, #attributes do
		(self.attributes::any)[attributes[i]] = nil
	end
end



function VeloraObject._lerp(a:number, b:number, t:number):number
	return a + (b - a) * t
end


print("Running Velora VER 1.3.0")
return VeloraObject
