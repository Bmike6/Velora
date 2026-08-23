--!strict
--!native
local module = {}


export type EaseStyles =
	"Linear"
| "Quad"
| "Cubic"
| "Quart"
| "Quint"
| "Circular"
| "Exponential"
| "Sine"
| "Back"
| "Bounce"
| "Elastic"

local Easing = {
	Linear = {
		In = function(Value: number): number
			return Value
		end,
		
		Out = function(Value: number): number
			return Value
		end,
		
		InOut = function(Value: number): number
			return Value
		end,
	},
	
	Quad = {
		In = function(Value: number): number
			return Value * Value
		end,
		
		Out = function(Value: number): number
			local Base = 1 - Value
			return 1 - Base * Base
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				return 2 * Value * Value
			end
			
			local Base = -2 * Value + 2
			return 1 - Base * Base * 0.5
		end,
	},
	
	Cubic = {
		In = function(Value: number): number
			return Value * Value * Value
		end,
		
		Out = function(Value: number): number
			local Base = 1 - Value
			return 1 - Base * Base * Base
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				return 4 * Value * Value * Value
			end
			
			local Base = -2 * Value + 2
			return 1 - Base * Base * Base * 0.5
		end,
	},
	
	Quart = {
		In = function(Value: number): number
			return Value * Value * Value * Value
		end,
		
		Out = function(Value: number): number
			local Base = 1 - Value
			return 1 - Base * Base * Base * Base
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				return 8 * Value * Value * Value * Value
			end
			
			local Base = -2 * Value + 2
			return 1 - Base * Base * Base * Base * 0.5
		end,
	},
	
	Quint = {
		In = function(Value: number): number
			return Value * Value * Value * Value * Value
		end,
		
		Out = function(Value: number): number
			local Base = 1 - Value
			return 1 - Base * Base * Base * Base * Base
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				return 16 * Value * Value * Value * Value * Value
			end
			
			local Base = -2 * Value + 2
			return 1 - Base * Base * Base * Base * Base * 0.5
		end,
	},
	
	Circular = {
		In = function(Value: number): number
			return 1 - (1 - Value * Value) ^ 0.5
		end,
		
		Out = function(Value: number): number
			local Base = Value - 1
			return (1 - Base * Base) ^ 0.5
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				return (1 - (1 - 4 * Value * Value) ^ 0.5) * 0.5
			end
			
			local Base = -2 * Value + 2
			return (1 + (1 - Base * Base) ^ 0.5) * 0.5
		end,
	},
	
	Exponential = {
		In = function(Value: number): number
			return 2 ^ (10 * Value - 10)
		end,
		Out = function(Value: number): number
			return 1 - 2 ^ (-10 * Value)
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				return 2 ^ (20 * Value - 11)
			end
			
			return 1 - 2 ^ (-20 * Value + 9)
		end,
	},
	
	Sine = {
		In = function(Value: number): number
			return 1 - math.cos(Value * 1.5707963267948966)
		end,
		
		Out = function(Value: number): number
			return math.sin(Value * 1.5707963267948966)
		end,
		
		InOut = function(Value: number): number
			return (math.cos(3.141592653589793 * Value) - 1) * -0.5
		end,
	},
	
	Back = {
		In = function(Value: number): number
			return 2.70158 * Value * Value * Value - 1.70158 * Value * Value
		end,
		
		Out = function(Value: number): number
			local Base = Value - 1
			return 1 + 2.70158 * Base * Base * Base + 1.70158 * Base * Base
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				local Base = 2 * Value
				return Base * Base * (3.5949095 * Base - 2.5949095) * 0.5
			end
			
			local Base = 2 * Value - 2
			return Base * Base * (3.5949095 * Base + 2.5949095) + 2 * 0.5
		end,
	},
	
	Bounce = {
		In = function(Value: number): number
			local Compliment = 1 - Value
			
			if Compliment < 0.36363636363636365 then
				return 1 - 7.5625 * Compliment * Compliment
			end
			
			if Compliment < 0.7272727272727273 then
				local Base = Compliment - 0.5454545454545454
				return 1 - 7.5625 * Base * Base + 0.75
			end
			
			if Compliment < 0.9090909090909091 then
				local Base = Compliment - 0.9090909090909091
				return 1 - 7.5625 * Base * Base + 0.9375
			end
			
			local Base = Compliment - 0.9545454545454546
			return 1 - 7.5625 * Base * Base + 0.984375
		end,
		
		Out = function(Value: number): number
			if Value < 0.36363636363636365 then
				return 7.5625 * Value * Value
			end
			
			if Value < 0.7272727272727273 then
				local Base = Value - 0.5454545454545454
				return 7.5625 * Base * Base + 0.75
			end
			
			if Value < 0.9090909090909091 then
				local Base = Value - 0.9090909090909091
				return 7.5625 * Base * Base + 0.9375
			end
			
			local Base = Value - 0.9545454545454546
			return 7.5625 * Base * Base + 0.984375
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				local Compliment = 1 - 2 * Value
				
				if Compliment < 0.36363636363636365 then
					return (1 - 7.5625 * Compliment * Compliment) * 0.5
				end
				
				if Compliment < 0.7272727272727273 then
					local Base = Compliment - 0.5454545454545454
					return (1 - 7.5625 * Base * Base + 0.75) * 0.5
				end
				
				if Compliment < 0.9090909090909091 then
					local Base = Compliment - 0.9090909090909091
					return (1 - 7.5625 * Base * Base + 0.9375) * 0.5
				end
				
				local Base = Compliment - 0.9545454545454546
				return (1 - 7.5625 * Base * Base + 0.984375) * 0.5
			end
			
			local Compliment = 2 * Value - 1
			
			if Compliment < 0.36363636363636365 then
				return (1 + 7.5625 * Compliment * Compliment) * 0.5
			end
			
			if Compliment < 0.7272727272727273 then
				local Base = Compliment - 0.5454545454545454
				return (1 + 7.5625 * Base * Base + 0.75) * 0.5
			end
			
			if Compliment < 0.9090909090909091 then
				local Base = Compliment - 0.9090909090909091
				return (1 + 7.5625 * Base * Base + 0.9375) * 0.5
			end
			
			local Base = Compliment - 0.9545454545454546
			return (1 + 7.5625 * Base * Base + 0.984375) * 0.5
		end,
	},
	
	Elastic = {
		In = function(Value: number): number
			return -2 ^ (10 * Value - 10) * math.sin((Value * 10 - 10.75) * 2.0943951023931953)
		end,
		
		Out = function(Value: number): number
			return 2 ^ (-10 * Value) * math.sin((Value * 10 - 0.75) * 2.0943951023931953) + 1
		end,
		
		InOut = function(Value: number): number
			if Value < 0.5 then
				return -2 ^ (20 * Value - 10) * math.sin((20 * Value - 11.125) * 1.3962634015954636) * 0.5
			end
			
			return 2 ^ -20 * Value + 10 * math.sin(20 * Value - 11.125 * 1.3962634015954636) * 0.5 + 1
		end,
	},
}

return Easing
