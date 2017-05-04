Designer = Designer or {}

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile( "huddesigner/cl_base.lua" )
	AddCSLuaFile( "huddesigner/cl_interfaces.lua" )
	AddCSLuaFile( "huddesigner/cl_util.lua" )
	AddCSLuaFile( "huddesigner/cl_file.lua" )
	return
end

if CLIENT then
	
	print("Loading HUD designer")
	include("huddesigner/cl_base.lua")
	include("huddesigner/cl_interfaces.lua")
	include("huddesigner/cl_util.lua")
	include("huddesigner/cl_file.lua")
	
	Designer.createDirectories()
	
end