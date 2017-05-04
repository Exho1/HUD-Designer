if CLIENT then
	-- Contains commands and functions
	
	HD = HD or {}
	local client = LocalPlayer()
	
	-- Open panel commands
	net.Receive("HD_OpenDesigner", function( len, ply )
		HD.OpenDesigner()
	end)
	concommand.Add("hd_open", function(ply)
		HD.OpenDesigner()
	end)
	concommand.Add("hd_reset", function(ply) -- Sometimes the table doesn't behave, so we start over
		if HD.Frame then
			HD.Frame:SetVisible(false)
		end
		HD = {} 
		include("autorun/cl_util.lua")
		include("autorun/cl_assorted.lua")
		include("autorun/cl_base.lua")
	end)
	
	--// Create objects
	function HD.AddShape(id, x, y, width, height, color, special, layer) 
		-- Fallbacks
		color = color or HD.DefaultCol
		layer = layer or HD.CurLayer
		HD.DrawnObjects[layer] = HD.DrawnObjects[HD.CurLayer] or {}
		HD.DrawnObjects[layer][HD.CurType] = HD.DrawnObjects[HD.CurLayer][HD.CurType] or {}
		
		-- Snap to grid
		x,y = math.SnapTo(x, HD.GridSize), math.SnapTo(y, HD.GridSize)
		width, height = math.SnapTo(width, HD.GridSize), math.SnapTo(height, HD.GridSize)
		
		if HD.CurType == "draw.RoundedBox" then
			HD.DrawnObjects[layer][HD.CurType][id] = {x=x, y=y, width=width, height=height, color=color, corner=special.corner}
		elseif HD.CurType == "surface.DrawTexturedRect" then
			HD.DrawnObjects[layer][HD.CurType][id] = {x=x, y=y, width=width, height=height, color=color, texture=special.texture}
		else
		
		end

		-- Boundaries somehow need to be altered in order for them to be accurate... Look into this
		HD.SetBoundaries(id, x, y, width, height, layer)
		
		-- Advance shape count
		HD.ShapeID = HD.ShapeID + 1
		HD.ShapeCount = HD.ShapeCount + 1
	end

	function HD.AddText(id, x, y, text, font, color, layer)
		-- Fallbacks
		layer = layer or HD.CurLayer
		color = color or Color(0,0,0)
		HD.DrawnObjects[layer] = HD.DrawnObjects[layer] or{}
		HD.DrawnObjects[layer]["draw.DrawText"] = HD.DrawnObjects[layer]["draw.DrawText"] or {}
		
		if color == HD.DefaultCol then color = Color(0,0,0) end -- Text should not be blue by default :/
		
		x,y = math.SnapTo(x, HD.GridSize), math.SnapTo(y, HD.GridSize)
		
		-- Tell the designer to draw this shape
		HD.DrawnObjects[layer]["draw.DrawText"][id] = {x=x, y=y, text=text, font=font, color=color}
		
		-- Create boundaries
		local width, height = HD.GetTextSize(text, font)
		HD.SetBoundaries(id, x, y, width, height, layer)
		
		-- Advance shape count
		HD.ShapeID = HD.ShapeID + 1
		HD.ShapeCount = HD.ShapeCount + 1
	end
	
	--// Edit objects
	function HD.EditShape(id, tab, mode) 
		if id == nil then return end
		mode = string.lower(mode)
		
		local ShapeLay = HD.GetShapeLayer(id) or HD.CurLayer
		local Type = HD.GetShapeType(id) or HD.CurType
		
		-- Make sure the tables exist
		HD.DrawnObjects[ShapeLay] = HD.DrawnObjects[ShapeLay] or {}
		HD.DrawnObjects[ShapeLay][Type] = HD.DrawnObjects[ShapeLay][Type] or {}
		
		local D = HD.DrawnObjects[ShapeLay][Type][id] -- Grab the data table
		if D == nil then return end
		
		-- Localize some variables
		local x, y width, height, text, font, color, layer, newlayer, corner, format, texture, texturestring = nil
		local origin, angles = nil
		
		-- Declare the basics with fallbacks
		x, y = tab.x or D.x, tab.y or D.y
		layer, newlayer = tab.layer or ShapeLay, tab.newlayer or ShapeLay
		color = tab.color or D.color
		
		-- Declare specifics
		if Type == "draw.DrawText" then
			text, font = tab.text or D.text, tab.font or D.font
			width, height = HD.GetTextSize(text, font)
			format = tab.format or D.format
		else
			width, height = tab.width or D.width, tab.height or D.height
		end
		
		if Type == "draw.RoundedBox" then
			corner =  tab.corner or D.corner
		elseif Type == "surface.DrawTexturedRect" then
			texture = tab.texture or D.texture, tab.texturestring or D.texturestring 
		end
		
		if mode == "size" then -- Size shape
			if Type == "draw.DrawText" then return end
			
			width, height = math.SnapTo(width, HD.GridSize), math.SnapTo(height, HD.GridSize)
			width, height = math.Clamp(width, HD.GridSize, ScrW()), math.Clamp(height, HD.GridSize, ScrH())
				
			HD.DrawnObjects[layer][Type][id].width = width
			HD.DrawnObjects[layer][Type][id].height = height
			
			HD.SetBoundaries(id, x, y, width, height, layer)
		elseif mode == "move" then -- Move shape
			local cfarx, cfary = HD.Canvas:GetSize()
			
			x, y = math.Clamp(x, 0, cfarx-width), math.Clamp(y, 0, cfary-height)
			
			HD.DrawnObjects[layer][Type][id].x = x
			HD.DrawnObjects[layer][Type][id].y = y

			HD.SetBoundaries(id, x, y, width, height, layer)
		elseif mode == "layer" then -- Edit shape layers
			local CurLayer = layer
			local NewLayer = newlayer
			
			-- Fallbacks
			HD.DrawnObjects[NewLayer] = HD.DrawnObjects[NewLayer] or {}
			HD.DrawnObjects[NewLayer][Type] = HD.DrawnObjects[NewLayer][Type] or {}
			
			-- Destroy the current drawn shape
			local i = 1
			for i = 1, HD.Layers do
				-- Remove any copies of this shape in any layer
				for Type, objects in pairs(HD.DrawnObjects[i]) do
					if objects[id] then
						objects[id] = nil
					end
				end	
			end
			HD.DrawnObjects[CurLayer][Type][id] = nil
			
			--Modify existing data to use the new layer
			if Type == "draw.RoundedBox" then
				HD.DrawnObjects[NewLayer][Type][id] = {x=x, y=y, width=width, height=height, color=color, corner=corner}
			elseif Type == "draw.DrawText" then
				HD.DrawnObjects[NewLayer][Type][id] = {x=x, y=y, text=text, font=font, color=color, format=format}
			elseif Type == "surface.DrawTexturedRect" then
				HD.DrawnObjects[NewLayer][Type][id] = {x=x, y=y, width=width, height=height, color=color, texture=texture, texturestring=texturestring}
			else
				print("Attempt to layer unknown object")
				return
			end
			
			HD.SetBoundaries(id, x, y, width, height, NewLayer)
			return
		elseif mode == "corner" then -- Edit shape corner
			if Type == "draw.DrawText" then return end
			
			HD.DrawnObjects[ShapeLay][Type][id].corner = corner
			HD.SetBoundaries(id, x, y, width, height, layer)
		end
	end
	
	function HD.CloseOpenInfoPanels() -- Close the open info panels
		if HD.GridOpen then
			HD.GridEditor:SetVisible(false) HD.GridOpen = false HD.GridEditor = nil
		end
		if HD.ColMixerOpen then
			HD.ColMixer:SetVisible(false) HD.ColMixerOpen = false HD.ColMixer = nil
		end
		if HD.LayerOpen then
			HD.LayerSel:SetVisible(false) HD.LayerOpen = false HD.LayerView = false HD.LayerSel = nil
		end
		if HD.ExportOpen then
			HD.Exporter:SetVisible(false) HD.ExportOpen = false HD.Exporter = nil
		end
		if HD.LoadOpen then
			HD.LoadSel:SetVisible(false) HD.LoadOpen = false HD.LoadSel = nil
		end
		if HD.CreateOpen then
			HD.CreatePanel:SetVisible(false) HD.CreateOpen = false HD.CreatePanel = nil
		end
		HD.SetTool()
	end
	
	
	
	--// GetX Functions
	function HD.GetMousePos() -- Altered mouse position because of the canvas's position
		local offsetX = 1
		local offsetY = 38
		local mx = HD.Canvas:ScreenToLocal( gui.MouseX() ) -- offsetX
		local my = HD.Canvas:ScreenToLocal( gui.MouseY() ) -- offsetY

		return mx, my
	end
	
	function HD.GetTool()
		return HD.CurTool, HD.SelectedButton
	end
	
	function HD.GetTextSize(text, font) -- Helper function
		surface.SetFont(font)
		local width, height = surface.GetTextSize(text)
		return width, height
	end
	
	function HD.GetShapeData(id) -- Get a table of the shape's data
		if id == nil then return end
		
		local Type = HD.GetShapeType(id)
		local layer = HD.GetShapeLayer(id)
		local Table = {}
		
		for k, v in pairs(HD.DrawnObjects[layer][Type][id]) do
			Table[k] = v
		end

		return Table
	end
	
	function HD.GetShapeLayer(id) -- Retrieve the shape's layer
		if id == nil then return end
		
		local i = 1
		for i = 1, HD.Layers do
			local Type = HD.GetShapeType(id) or HD.CurType
			if HD.DrawnObjects[i][Type] ~= nil then 
				if HD.DrawnObjects[i][Type][id] then
					return i
				end
			end
		end
	end
	
	function HD.GetShapeType(id) -- Get the shape's Type
		local i = 1
		for i = 1, HD.Layers do
			for k, v in pairs (HD.Types) do
				if HD.DrawnObjects[i][v] ~= nil then
					if HD.DrawnObjects[i][v][id] then
						return v 
					end
				end
			end
		end
	end
	
	
	
	--// SetX Functions
	function HD.SetTool( num, name ) -- Toolbar highlighting and stuff
		HD.CurTool = num -- HUD.Tools number
		HD.SelectedButton = name -- String name
	end
	
	function HD.SetType( name )
		for k, v in pairs(HD.Types) do
			if string.lower(v) == string.lower(name) then
				HD.CurType = HD.Types[k]
				return true
			end
		end
	end
	
	function HD.SetBoundaries(id, x, y, width, height, layer)
		layer = layer or HD.CurLayer

		HD.Boundaries[id] = {x=x, y=y, farx=x+width, fary=y+height, layer=layer}
	end
	
	
	--// Other functions
	function HD.InfoPanelOpen() -- If one of the special info panels is open
		if HD.GridOpen or HD.ColMixerOpen or HD.LayerOpen or HD.ExportOpen or HD.CreateOpen or HD.LoadOpen then
			return true
		end
		return false
	end
	
	function HD.CancelAlter() -- Cancels any moving or shape altering taking place
		HD.CurMovingData = {}
		HD.Moving = false
		HD.CurSizeID = nil
		HD.Sizing = false
	end
	
	function HD.IsInCanvas(x, y) -- Check if the mouse cursor is in the canvas
		x,y = tonumber(x), tonumber(y)
		local cfarx, cfary = HD.Canvas:GetSize()
		local cx, cy = 0, HD.GridSize
		if HD.InfoPanelOpen() then return false end
		
		if x > cx and x < cfarx then
			if y > cy and y < cfary then
				return true
			end
		end
		return false
	end
	
	function HD.IsInSize(id, x, y) -- Mouse cursor inside the sizing box
		x,y = tonumber(x), tonumber(y)
		
		if HD.GetShapeType(id) == "draw.DrawText" then return end
		
		local gs = 20
		
		local b = HD.Boundaries[id]
		if b then
			local farx, fary = b.farx, b.fary
			local minx, miny = farx-gs, fary-gs
			
			if HD.InfoPanelOpen() then return false end
			
			if x > minx and x < farx then
				if y > miny and y < fary then
					return true
				end
			end
		end
		return false
	end
	
	function HD.IsInShape(x, y) -- Mouse cursor inside a shape
		x,y = tonumber(x), tonumber(y) 
		local difx, dify, id 
		
		for shapeID, tab in pairs(HD.Boundaries) do
			if x > tab.x and x < tab.farx then
				if y > tab.y and y < tab.fary then
					if tab.layer == HD.CurLayer then
						-- Difference from Shape Pos to the Mouse Pos to smooth moving
						difx, dify = x - tab.x, y - tab.y
						id = shapeID
						return true, id, difx, dify
					end	
				end
			end
		end
		return false
	end

	-- Math functions from Luabee's poly editor, modified for my purposes
	function math.SnapTo(num, point)
		if HD.GridEnabled ~= true then return num end
		
		num = math.Round(num)
		local possible = {min=0, max=0}
		for i=1, point do
			if math.IsDivisible(num+i, point) then
				possible.max = num+i
			end
			if math.IsDivisible(num-i, point) then
				possible.min = num-i
			end
		end
		
		if possible.max - num <= num - possible.min then
			return possible.max
		else
			return possible.min
		end
	end

	function math.IsDivisible(divisor, dividend)
		return divisor%dividend == 0
	end
	
	function HD.Load( txt )
		HD.CancelAlter()
		local json = file.Read( "hud_designer/"..txt, "DATA" )
		local tab = util.JSONToTable( json ) 
		
		HD.ProjectName = tab.ProjectName or HD.ProjectName
		HD.ProjectText:SetText(HD.ProjectName)
		
		local i = 1
		local size = table.Count(tab)
		if size > 1 then size = size - 1 end -- Tables are weird
		
		for i = 1, size do
			HD.DrawnObjects[i] = HD.DrawnObjects[i] or {} -- Layer fallback
			for Type, objects in pairs(tab[i]) do
				HD.DrawnObjects[i][Type] = HD.DrawnObjects[i][Type] or {} -- Type fallback
				for id, data in pairs(objects) do
					HD.DrawnObjects[i][Type][HD.ShapeID] = {}
					
					-- Merge the table
					table.Merge( HD.DrawnObjects[i][Type][HD.ShapeID], data )
					
					-- Fix up broken colors
					local col = HD.DrawnObjects[i][Type][HD.ShapeID].color or HD.DefaultCol
					HD.DrawnObjects[i][Type][HD.ShapeID].color = Color(col.r, col.g, col.b, col.a)
					
					-- Fix up textures
					if Type == "surface.DrawTexturedRect" then
						local Fake = HD.FAKE_TEXTURE -- Checkerboard texture fallback
						local tex = HD.DrawnObjects[i][Type][HD.ShapeID].texturestring or Fake
						local num = surface.GetTextureID(tex)
						
						HD.DrawnObjects[i][Type][HD.ShapeID].texture = num
						HD.DrawnObjects[i][Type][HD.ShapeID].texturestring = tex
					end
						
					-- Create the boundaries
					local width, height = nil
					if Type == "draw.DrawText" then
						width, height = HD.GetTextSize(data.text, data.font)
					else
						width, height = data.width, data.height
					end
					HD.SetBoundaries(HD.ShapeID, data.x, data.y, width, height, i)
					
					-- Acknowledge the shape exists
					HD.ShapeID = HD.ShapeID + 1
					HD.ShapeCount = HD.ShapeCount + 1
				end
			end
		end
		print("Loaded HUD from "..txt)
	end
	
	function HD.Save( name ) -- Save shape data into JSON format
		if HD.ShapeCount < 2 then print("Not enough shapes ("..HD.ShapeCount..") to save!") return end
		print("Saving current project..")
		
		local tojson = table.Copy(HD.DrawnObjects)
		local i = 1
		for i = 1, HD.Layers do
			for Type, objects in pairs(tojson[i]) do
				for id, data in pairs(objects) do
					-- Json isn't a big fan of the color tables, so we will make sure it recognizes them
					local col = data.color or HD.DefaultCol
					data.color = {r=col.r, g=col.g, b=col.b, a=col.a}
					
				end
			end
		end
		tojson.ProjectName = tojson.ProjectName or HD.ProjectName
		
		local json = util.TableToJSON( tojson )
		
		if json ~= "[]" then
			local Banned, proj, session = nil
			-- Create a file name
			Banned = {"/", "\\", "?", "|", "<", ">", '"', ":" }
			proj = name or HD.ProjectName
			for k, v in pairs(Banned) do -- Remove bad characters
				proj = string.gsub(proj, v, "-")
			end
			proj = string.gsub(proj, " ", "")
			session = os.date("%H%M%S")
			session = string.gsub(session, ":", "")
			session = string.lower("save_"..proj.."_"..session)
			
			-- Write to the directory
			file.CreateDir( "hud_designer" )
			file.Write( "hud_designer/"..session..".txt", json)
		end
		
		timer.Simple(0.5, function()
			HD.SetTool(HD.Tools.Select, "Select")
		end)
	end
	
	function HD.Autosave() -- Autosave shape data
		print("Autosaving current project..")
		local json = util.TableToJSON( HD.DrawnObjects )
		
		if json ~= "[]" then
			local Banned = {"/", "\\", "?", "|", "<", ">", '"', ":" }
			local proj = HD.ProjectName
			for k, v in pairs(Banned) do -- Remove bad characters
				proj = string.gsub(proj, v, "-")
			end
			proj = string.gsub(proj, " ", "")
			local session = os.date("%H%M%S")
			session = string.gsub(session, ":", "")
			session = string.lower("autosave_"..proj.."_"..session)
			
			-- Write to the directory
			file.CreateDir( "hud_designer/autosaves/" )
			file.Write( "hud_designer/autosaves/"..session..".txt", json)
		end
	end
	
	function HD.CreateExportCode() -- Create the exporting code to be used by both Console and a .txt file
	
		HD.CancelAlter()
		local ExportData = {}
		local i = 1
		for i = 1, HD.Layers do
			ExportData[i] = {}
			for Type, objects in pairs(HD.DrawnObjects[i]) do
				if Type == "draw.RoundedBox" then -- Filter by Type
					local c = 1
					for c = 1, HD.ShapeCount do -- Loop through by ID
						local tab = HD.DrawnObjects[i][Type][c] -- Object data
						if tab ~= nil then
							-- Valid entry, lets declare variables
							local x,y,width,height,col,corner = tab.x,tab.y,tab.width,tab.height,tab.color,tab.corner
							
							-- Auto sizing for all of the vgui elements
							local modx, mody, modw, modh = nil
							if HD.ScaleSize then
								modw,modh = math.Round(ScrW()/width, 2), math.Round(ScrH()/height, 2)
								-- Extra precautions to prevent game crashes from bad math
								if modw == math.huge then width = 0 else width = "ScrW()/"..modw.."" end
								if modh == math.huge then height = 0 else height = "ScrH()/"..modh.."" end
							end
							y = y + HD.Y_BUFFER -- Fix for the Canvas not being exactly screen size
							if HD.ScalePos then
								modx, mody = math.Round(ScrW()/x, 2), math.Round(ScrH()/y, 2)
								if modx == math.huge then x = 0 else x = "ScrW()/"..modx end
								if mody == math.huge then y = 0 elseif mody == 1.24 then y = "ScrH()-("..height..")" 
								else y = "ScrH()/"..mody end
							else -- Going to slightly scale the position anyways
								if x > ScrW()/2 then
									modx = ScrW() - x
									x = "ScrW()-"..modx
								end
								if y > ScrH()/2 then
									mody = ScrH() - y
									y = "ScrH()-"..mody
								end
							end
							
							-- Assemble the color
							col = "Color("..col.r..", "..col.g..", "..col.b..", "..col.a..")"
							-- Add a new table entry
							ExportData[i][c] = string.format("draw.RoundedBox(%i, %s, %s, %s, %s, "..col..")", corner, x, y, width, height)
						end
					end
				elseif Type == "draw.DrawText" then
					local c = 1
					for c = 1, HD.ShapeCount do -- Loop through by ID
						local tab = HD.DrawnObjects[i][Type][c] -- Object data
						if tab ~= nil then
							local x,y,width,height,col,corner = tab.x,tab.y,tab.width,tab.height,tab.color,tab.corner
							local x,y,text,font,col,format = tab.x,tab.y,tab.text,tab.font,tab.color,tab.format
							
							y = y + HD.Y_BUFFER
							local modx, mody = nil
							if HD.ScalePos then
								modx, mody = math.Round(ScrW()/x, 2), math.Round(ScrH()/y, 2)
								if modx == math.huge then x = 0 else x = "ScrW()/"..modx end
								if mody == math.huge then y = 0 elseif mody == 1.24 then y = "ScrH()-("..height..")" 
								else y = "ScrH()/"..mody end
							end

							if format ~= nil then -- Set up string formatting
								local tab, param = nil
								for k, v in pairs(HD.FormatTypes) do
									if v.code == format then
										tab = k -- Grab the FormatType key
									end
								end
								tab = HD.FormatTypes[tab] -- Plug it back into the table
								
								param = tab.code
								
								text = param
							else
								text = '"'..text..'"'
							end
							
							-- Assemble the color
							col = "Color("..col.r..", "..col.g..", "..col.b..", "..col.a..")"
							-- Add a new table entry
							ExportData[i][c] = string.format('draw.DrawText(%s, "%s", %s, %s, '..col..')', text, font, x, y, col)
						end
					end
				elseif Type == "surface.DrawTexturedRect" then
					local c = 1
					for c = 1, HD.ShapeCount do
						local tab = HD.DrawnObjects[i][Type][c] 
						if tab ~= nil then
							local x,y,width,height,col,texture,texturestring = tab.x,tab.y,tab.width,tab.height,tab.color,tab.texture,tab.texturestring
							
							texturestring = texturestring or "INVALID_TEXTURE"
							
							-- Auto sizing for all of the vgui elements
							local modx, mody, modw, modh = nil
							if HD.ScaleSize then
								modw,modh = math.Round(ScrW()/width, 2), math.Round(ScrH()/height, 2)
								-- Extra precautions to prevent game crashes from bad math
								if modw == math.huge then width = 0 else width = "ScrW()/"..modw.."" end
								if modh == math.huge then height = 0 else height = "ScrH()/"..modh.."" end
							end
							y = y + HD.Y_BUFFER -- Fix for the Canvas not being exactly screen size
							if HD.ScalePos then
								modx, mody = math.Round(ScrW()/x, 2), math.Round(ScrH()/y, 2)
								if modx == math.huge then x = 0 else x = "ScrW()/"..modx end
								if mody == math.huge then y = 0 elseif mody == 1.24 then y = "ScrH()-("..height..")" 
								else y = "ScrH()/"..mody end
							else -- Going to slightly scale the position anyways
								if x > ScrW()/2 then
									modx = ScrW() - x
									x = "ScrW()-"..modx
								end
								if y > ScrH()/2 then
									mody = ScrH() - y
									y = "ScrH()-"..mody
								end
							end
							
							-- Assemble the color
							col = "Color("..col.r..", "..col.g..", "..col.b..", "..col.a..")"
							
							-- Put together the surface stuff, its a hacky fix
							local draw = string.format("surface.DrawTexturedRect(%s, %s, %s, %s, "..col..")", x, y, width, height)
							ExportData[i][c] = [[
-- Move this OUT of the HUDPaint hook in order to make sure your HUD is efficient
--local Texture]]..c..[[ = Material("]]..texturestring..[[") 
surface.SetMaterial(Texture]]..c..[[)
surface.SetDrawColor(]]..col..[[)
]]..draw
						end
					end
				else
					-- New Type
				end
			end
		end
		return ExportData or {}
	end
	
	
	function HD.FontCreator()
			local AntiClick = vgui.Create("DFrame")
		AntiClick:SetSize(ScrW(),ScrH())
		AntiClick:SetPos(0,0)
		AntiClick:SetTitle("")
		AntiClick:SetDraggable(false)
		AntiClick.btnMaxim:SetVisible( false )
		AntiClick.btnMinim:SetVisible( false )
		AntiClick.btnClose:SetVisible( false )
		AntiClick.Paint = function()
			draw.RoundedBox(0, 0, 0, AntiClick:GetWide(), AntiClick:GetTall(), Color(0,0,0,0))
		end
		
			local Frame = vgui.Create("DFrame", AntiClick)
		Frame:SetSize(500, 400)
		Frame:SetPos(ScrW()/2-Frame:GetWide()/2,ScrH()/2-Frame:GetTall()/2)
		Frame:SetTitle("")
		Frame:MakePopup()
		Frame:SetDraggable(true)
		Frame.btnMaxim:SetVisible( false )
		Frame.btnMinim:SetVisible( false )
		Frame.btnClose:SetVisible( true )
		Frame.Paint = function()
			draw.RoundedBox(0, 0, 0, Frame:GetWide(), Frame:GetTall(), Color(39, 174, 96))
		end
		
		local Exit = vgui.Create( "DButton", Frame )
		Exit:SetText( "Exit" )
		Exit:SetTextColor( Color(255,255,255,255) )
		Exit:SetFont("HD_Title")
		Exit:SetSize( 80, 30 ) 
		Exit:SetPos( Frame:GetWide()-Exit:GetWide()-10, 10 ) 
		Exit.Paint = function()
			draw.RoundedBox( 0, 0, 0, Exit:GetWide(), Exit:GetTall(), Color(200, 79, 79,255) )
		end
		Exit.DoClick = function()
			AntiClick:Close()
			Frame:Close()
		end
	
	end
	
	--// Tutorial opener
	function HD.OpenTutorial()
			local Frame = vgui.Create("DFrame")
		Frame:SetSize(ScrW()-80,ScrH()-80)
		Frame:SetPos(40,40)
		Frame:SetTitle("")
		Frame:MakePopup()
		Frame:SetDraggable(false)
		Frame.btnMaxim:SetVisible( false )
		Frame.btnMinim:SetVisible( false )
		Frame.btnClose:SetVisible( false )
		Frame.Paint = function()
			draw.RoundedBox(0, 0, 0, Frame:GetWide(), Frame:GetTall(), Color(39, 174, 96))
		end
		
		local text = "Exho's HUD Designer"
		local w, h = HD.GetTextSize(text, "HD_Title")
		
			local Title = vgui.Create("DLabel", Frame)
		Title:SetPos( Frame:GetWide()/2-w/2, 15) 
		Title:SetColor(Color(255,255,255)) 
		Title:SetFont("HD_Title")
		Title:SetText(text)
		Title:SizeToContents() 
		

			local Choose = vgui.Create("DLabel", Frame) 
		Choose:SetSize(Frame:GetWide()/2, 0)
		Choose:SetColor(Color(255,255,255)) 
		Choose:SetFont("HD_Title")
		Choose:SetText("Please choose a tutorial type to view") 
		Choose:SizeToContents() 
		local w,h =HD.GetTextSize(Choose:GetText(), "HD_Title")
		Choose:SetPos(ScrW()/2-w/1.5, ScrH()/2-120) 
		
		local Choice1, Choice2 = nil
		
			Choice1 = vgui.Create( "DButton", Frame )
		Choice1:SetText( "Text" )
		Choice1:SetTextColor( Color(255,255,255,255) )
		Choice1:SetFont("HD_Title")
		Choice1:SetSize( 140, 60 ) 
		Choice1:SetPos( Frame:GetWide()/2-Choice1:GetWide()-10, Frame:GetTall()/2-Choice1:GetTall()/2 ) 
		Choice1.Paint = function()
			draw.RoundedBox( 0, 0, 0, Choice1:GetWide(), Choice1:GetTall(), Color(200, 79, 79,255) )
		end
		Choice1.DoClick = function()
			Choice1:SetVisible(false)
			Choice2:SetVisible(false)
			Title:SetVisible(false)
			Choose:SetVisible(false)
			surface.PlaySound("buttons/button9.wav")
			
			local text = "Exho's HUD Designer Tutorial"
			local w, h = HD.GetTextSize(text, "HD_Title")
			
				local Title = vgui.Create("DLabel", Frame)
			Title:SetPos( Frame:GetWide()/2-w/2, 15) 
			Title:SetColor(Color(255,255,255)) 
			Title:SetFont("HD_Title")
			Title:SetText(text)
			Title:SizeToContents() 
			
				local Video = vgui.Create( "HTML", Frame) 
			Video:SetSize( Frame:GetWide()-100, Frame:GetTall() - 100 )
			Video:SetPos(50, 50)
			Video:OpenURL("http://www.exho.comeze.com/huddesigner/tutorial.html")
			
			local Exit = vgui.Create( "DButton", Frame )
			Exit:SetText( "Exit" )
			Exit:SetTextColor( Color(255,255,255,255) )
			Exit:SetFont("HD_Title")
			Exit:SetSize( 80, 30 ) 
			Exit:SetPos( Frame:GetWide()/2+10, Frame:GetTall()-Exit:GetTall()-10 ) 
			Exit.Paint = function()
				draw.RoundedBox( 0, 0, 0, Exit:GetWide(), Exit:GetTall(), Color(200, 79, 79,255) )
			end
			Exit.DoClick = function()
				Frame:Close()
				LocalPlayer():ConCommand( "hd_tutorial 0" )
				timer.Simple(0.3, function()
					HD.OpenDesigner(true)
				end)
			end
			
				local Back = vgui.Create( "DButton", Frame )
			Back:SetText( "Back" )
			Back:SetTextColor( Color(255,255,255,255) )
			Back:SetFont("HD_Title")
			Back:SetSize( 80, 30 ) 
			Back:SetPos( Frame:GetWide()/2-Back:GetWide()-10, Frame:GetTall()-Back:GetTall()-10 ) 
			Back.Paint = function()
				draw.RoundedBox( 0, 0, 0, Back:GetWide(), Back:GetTall(), Color(66, 244, 123,255) )
			end
			Back.DoClick = function()
				Frame:Close()
				HD.OpenTutorial()
			end
		end
		
			Choice2 = vgui.Create( "DButton", Frame )
		Choice2:SetText( "Video" )
		Choice2:SetTextColor( Color(255,255,255,255) )
		Choice2:SetFont("HD_Title")
		Choice2:SetSize( 140, 60 ) 
		Choice2:SetPos( Frame:GetWide()/2+10, Frame:GetTall()/2-Choice2:GetTall()/2 ) 
		Choice2.Paint = function()
			draw.RoundedBox( 0, 0, 0, Choice2:GetWide(), Choice2:GetTall(), Color(200, 79, 79,255) )
		end
		Choice2.DoClick = function()
			Choice1:SetVisible(false)
			Choice2:SetVisible(false)
			Title:SetVisible(false)
			surface.PlaySound("buttons/button9.wav")
			
				local Video = vgui.Create( "HTML", Frame) 
			Video:SetSize( Frame:GetWide()-100, Frame:GetTall() - 100 )
			Video:SetPos(50, 50)
			Video:OpenURL("www.youtube.com/embed/iakAzLzjfb8")
			
				local Exit = vgui.Create( "DButton", Frame )
			Exit:SetText( "Exit" )
			Exit:SetTextColor( Color(255,255,255,255) )
			Exit:SetFont("HD_Title")
			Exit:SetSize( 80, 30 ) 
			Exit:SetPos( Frame:GetWide()/2+10, Frame:GetTall()-Exit:GetTall()-10 ) 
			Exit.Paint = function()
				draw.RoundedBox( 0, 0, 0, Exit:GetWide(), Exit:GetTall(), Color(200, 79, 79,255) )
			end
			Exit.DoClick = function()
				Frame:Close()
				LocalPlayer():ConCommand( "hd_tutorial 0" )
				timer.Simple(0.3, function()
					HD.OpenDesigner(true)
				end)
			end
			
				local Back = vgui.Create( "DButton", Frame )
			Back:SetText( "Back" )
			Back:SetTextColor( Color(255,255,255,255) )
			Back:SetFont("HD_Title")
			Back:SetSize( 80, 30 ) 
			Back:SetPos( Frame:GetWide()/2-Back:GetWide()-10, Frame:GetTall()-Back:GetTall()-10 ) 
			Back.Paint = function()
				draw.RoundedBox( 0, 0, 0, Back:GetWide(), Back:GetTall(), Color(66, 244, 123,255) )
			end
			Back.DoClick = function()
				Frame:Close()
				HD.OpenTutorial()
			end
			
		end
	end
	
	function HD.Splash()
		-- Invisible panel so clients cannot click the Editor
			local AntiClick = vgui.Create("DFrame")
		AntiClick:SetSize(ScrW(),ScrH())
		AntiClick:SetPos(0,0)
		AntiClick:SetTitle("")
		AntiClick:MakePopup()
		AntiClick:SetDraggable(false)
		AntiClick.btnMaxim:SetVisible( false )
		AntiClick.btnMinim:SetVisible( false )
		AntiClick.btnClose:SetVisible( false )
		AntiClick.Paint = function()
			draw.RoundedBox(0, 0, 0, AntiClick:GetWide(), AntiClick:GetTall(), Color(0,0,0,0))
		end
		
			HD.SplashFrame = vgui.Create("DFrame", AntiClick)
		HD.SplashFrame:SetSize(400,300)
		HD.SplashFrame:SetPos(ScrW()/2 - HD.SplashFrame:GetWide()/2, ScrH()/2 - HD.SplashFrame:GetTall()/2)
		HD.SplashFrame:SetTitle("")
		HD.SplashFrame:SetDraggable(false)
		HD.SplashFrame.btnMaxim:SetVisible( false )
		HD.SplashFrame.btnMinim:SetVisible( false )
		HD.SplashFrame.btnClose:SetVisible( false )
		HD.SplashFrame.Paint = function()
			draw.RoundedBox(0, 0, 0, HD.SplashFrame:GetWide(), HD.SplashFrame:GetTall(), Color(39, 174, 96))
		end
		
		local Saves = file.Find( "hud_designer/save_*.txt", "DATA" ) -- Grab all the saves
			
			local SplashLoader = vgui.Create("DScrollPanel", HD.SplashFrame)
		SplashLoader:SetSize(350, 240)
		SplashLoader:SetPos(30, 40)
		SplashLoader.Paint = function()
			draw.RoundedBox(0, 0, 0, SplashLoader:GetWide(), SplashLoader:GetTall(), Color(39, 174, 96))
		end
		
		local x, y = SplashLoader:GetPos()
		local width, height = HD.GetTextSize("Click on a save to load", "HD_Smaller")
		
			local Label1 = vgui.Create("DLabel", HD.SplashFrame)
		Label1:SetPos(x+ width - 30, 10) 
		Label1:SetColor(Color(255,255,255)) 
		Label1:SetFont("HD_Title")
		Label1:SetText("Choose a save to load")
		Label1:SizeToContents() 
		
		local SavePanels = {}
		local i = 1
		local YBuffer = 70
		local BarBuffer = 0
		if #Saves > 1 then BarBuffer = 15 end
		
			local NewProject = vgui.Create("DButton", SplashLoader)
		NewProject:SetPos(10, 0)
		NewProject:SetSize(SplashLoader:GetWide()-20-BarBuffer, 50)
		NewProject:SetTextColor(Color(255,255,255))
		NewProject:SetText("New Project")
		NewProject:SetFont("HD_Button")
		NewProject.Paint = function()
			local col = Color(90,90,90, 250)
			draw.RoundedBox(0, 0, 0, NewProject:GetWide(), NewProject:GetTall(), col)
		end
		NewProject.DoClick = function()
			HD.SplashFrame:Close()
			HD.SplashFrame = nil
			AntiClick:Close()
		end
		
		for i = 1, #Saves do	
			local txt = file.Read( "hud_designer/"..Saves[i], "DATA" )
			local tab = util.JSONToTable( txt ) 
			
			local name = tab.ProjectName or Saves[i]
			name = string.gsub(name, "save_", "")
			name = string.gsub(name, ".txt", "")
			name = string.gsub(name, "_", " ")
			
			local Count 
				SavePanels[i] = vgui.Create("DButton", SplashLoader)
			SavePanels[i]:SetPos(10, YBuffer)
			SavePanels[i]:SetSize(SplashLoader:GetWide()-20-BarBuffer, 50)
			SavePanels[i]:SetTextColor(Color(255,255,255))
			SavePanels[i]:SetText(name)
			SavePanels[i]:SetFont("HD_Button")
			SavePanels[i].Paint = function()
				local col = Color(90,90,90, 250)
				draw.RoundedBox(0, 0, 0, SavePanels[i]:GetWide(), SavePanels[i]:GetTall(), col)
			end
			SavePanels[i].DoClick = function()
				HD.Load( Saves[i] )
				
				HD.SplashFrame:Close()
				HD.SplashFrame = nil
				AntiClick:Close()
			end
			
			YBuffer = YBuffer + SavePanels[i]:GetTall() + 20
		end
	end
end
	
	
	

