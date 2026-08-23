export type PropertyTypes=
	UDim2|
	UDim|
	Vector2|
	Vector3|
	CFrame|
	number
export type Properties = "Size"|"Position"|"Transparency"|"CFrame"|CustomProperty

export type CustomProperty = string

return {
	Size = "Size", Position = "Position", Transparency = "Transparency", CFrame = "CFrame"
}
