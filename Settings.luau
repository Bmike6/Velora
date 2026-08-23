--!strict

local Settings = {
	easingStyle = "Linear",
	continousPlayback = false,
	yield = false,
	objectListEnabled = false,
	autoInferStartValuesOnPlay = true, -- keep on without manually updating the start list
}




export type SettingKeys = "easingStyle"?|"continousPlayback"?|"Yield"?|"objectListEnabled"?

export type Settings = {[SettingKeys]:any}

return Settings
