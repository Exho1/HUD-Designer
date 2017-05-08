Designer = Designer or {}

--| 							|--
--| Designer.createDirectories
--| 							
--| Creates folders that are used by the hud designer
--| 							|--
function Designer.createDirectories()

	file.CreateDir( "hud_designer" ) 
	file.CreateDir( "hud_designer/autosaves" ) 
	file.CreateDir( "hud_designer/saves" ) 
	file.CreateDir( "hud_designer/exported" ) 
	
end

--| 							|--
--| Designer.sanitizeFilename
--| 							
--| Removes forbidden characters from file names
--| 							|--
function Designer.sanitizeFilename( str )
	
	local banned = {"/", "\\", "?", "|", "<", ">", '"', ":" }
	
	for _, char in pairs( banned ) do
		str = string.gsub( str, char, "-" )
	end
	
	return str
	
end

--| 							|--
--| Designer.newProject
--| 							
--| Opens a new project
--| 							|--
function Designer.newProject()
	
	if not Designer.projectSaved then
		Designer.guiSaveBeforeFunc( Designer.clearCanvas )
	else
		Designer.clearCanvas()
	end
	
end

--| 							|--
--| Designer.openProject
--| 							
--| Prompts the player with a list of projects to load. The gui handles saving
--| 							|--
function Designer.openProject()

	Designer.guiOpenProject()
	
end

--| 							|--
--| Designer.saveProject
--| 							
--| Writes the current project to a text file
--| Arguments (optional):
--| 	Is this an autosave?
--| 	Request a name for this save.
--| 	No chat printing.
--|		Function to be called after saving is completed
--| 							|--
function Designer.saveProject( bAutosave, bRequestName, bSilent, funcCallback )
	
	if not Designer.projectName or bRequestName then
		Designer.guiProjectNameMenu()
		return
	end
	
	Designer.saveCanvasToFile( bAutosave, bSilent, funcCallback )
end

--| 							|--
--| Designer.exportProject
--| 							
--| Exports the current project to Lua code in a text file
--| 							|--
function Designer.exportProject()
	
	print("Export project")
	
	local strExportedText = ""
	
	-- Helper function to add a line of code to our exported text
	local function append( str )
		strExportedText = strExportedText .. tostring(str) .. "\r\n"
		print("Appending: ", str )
	end
	
	-- Helper function to concatenate arguments into a comma-seperated string
	local function stringArgs( ... )
		local args = {...}
		local str = ""
		
		for k, v in pairs( args ) do
			if k == 1 then
				str = str .. tostring(v)
			else
				str = str .. ", " .. tostring(v)
			end
		end
		
		return str
	end
	
	-- Helper function to convert a color structure into a Lua statement 
	local function stringColor( col )
		local s = stringArgs( Designer.unpackColor( col ) )
		return "Color( " .. s .. " )"
	end
	
	if Designer.isCanvasEmpty() then
		Designer.print( "Canvas is empty, not exporting", "notify" )
		return
	end
	
	for layerNum, layerContents in pairs( Designer.canvasElements ) do
		for k, data in pairs( layerContents ) do
			-- Add a line for readability
			append("")
			
			-- Scale the coords back to the screen size
			Designer.designerToScreenDim( data.x, data.y, data.w, data.h )
			
			-- Convert our data into Lua
			if data.type == "rect" then
				if isnumber(data.special[1]) then
					-- Its a rounded rectangle
					local strFunc = "draw.RoundedBox"
					
					-- Concatenate the arguments into a string
					local strArgs = stringArgs( data.special[1], x, y, w, h, stringColor( data.color ) )
					
					-- Append to the soon-to-be file
					append( strFunc .. "( " .. strArgs .. " )" )
				elseif data.special[2] then
					-- Its a textured rectangle
					print("attempt to export textured rect")
					
				else
					-- Its a regular rectangle
					local strFunc = "surface.DrawRect"
					
					-- Concatenate arguments
					local strArgs = stringArgs( x, y, w, h )
					
					-- Surface library prefers colors taken as arguments
					local strColor = stringArgs( Designer.unpackColor( data.color ) )
					
					-- Append Lua
					append( "surface.SetDrawColor( " .. strColor .. " )" )
					append( strFunc .. "( " .. strArgs .. " )" )
				end
			elseif data.type == "text" then
				if data.xalign then
					-- Its aligned text
					local strFunc = "draw.DrawText"
					
					local strArgs = stringArgs( data.text, "'" .. data.font .. "'", x, y, data.color, data.xalign )
					
					append( strFunc .. "( " .. strArgs .. " )" )
				else
					-- Its regular text
					local strFunc = "surface.DrawText"
					
					-- Get the color and the position for the surface library
					local strColor = stringArgs( Designer.unpackColor( data.color ) )
					local strPos = stringArgs( x, y )
					
					append( "surface.SetFont( '" .. data.font .. "' )" )
					append( "surface.SetTextColor( " .. strColor .. " )" )
					append( "surface.SetTextPos( " .. strPos .. " )" )
					append( strFunc .. "( '" .. data.text .. "' )" )
				end
			else
				print("Attempt to export unknown type ", data.type )
			end
		end
	end
	
	print(strExportedText)

	local json = util.TableToJSON( Designer.canvasElements )
	local path = "hud_designer/exported/" .. tostring(Designer.projectName) .. ".txt"
	
	file.Write( path, json ) 
	
	Designer.print( "Exported code to garrysmod/data/" .. path, "notify" )
end

--| 							|--
--| Designer.saveCanvasToFile
--| 							
--| Internal: Saves the contents of the canvas to a text file
--| Optional argument to categorize it as an autosave
--| 							|--
function Designer.saveCanvasToFile( bAutosave, bSilent, funcCallback )
	
	-- Write the project name into the canvas table
	--Designer.canvasElements.projectName = Designer.projectName
	
	local json = util.TableToJSON( Designer.canvasElements )
	
	--Designer.canvasElements.projectName = nil
	
	local topDir = "hud_designer/"
	local dir = ""
	local prefix = ""
	
	if bAutosave then
		dir = "autosaves/"
		prefix = "autosave_"	
	else
		dir = "saves/"
		prefix = "save_"
	end
	
	-- ex: save_myhudproject.txt
	local filename = Designer.concat( prefix, Designer.projectName, ".txt" )

	-- ex: hud_designer/saves/^
	local path = Designer.concat( topDir, dir, filename )
	
	file.Write( path, json ) 
	
	Designer.projectSaved = true
	
	if funcCallback then
		funcCallback()
	end
	
	if not bSilent then
		Designer.print( "Saved to " .. path, "notify" )
	end
end

--| 							|--
--| Designer.loadCanvasFromFile
--| 							
--| Loads a canvas from a text file given a directory
--| 							|--
function Designer.loadCanvasFromFile( dir )
	
	--[[
		1	=	hud_designer
		2	=	saves
		3	=	save_HUD-203348.txt
	]]
	local tbl = string.Split( dir, "/" )
	local secondDir = tbl[2]
	local fileName = tbl[3]
	
	if secondDir == "exported" or string.find( fileName, "export_" ) then
		Designer.print( "Cannot load exported projects", "alert" )
		return
	end
	
	-- Read the json data and convert it back to a Lua table
	local json = file.Read( dir, "DATA" ) 
	local canvasData = util.JSONToTable( json )
	
	-- Get the date that the file was last modified
	local dateModified = os.date( "%Y%m", file.Time( dir, "DATA" ) )
	dateModified = tonumber(dateModified)
	
	-- The year and month when the new Designer was rolled out
	local NEWVERSION_CONST = 201704
	
	-- Change the project name to the one in the json
	Designer.projectName = canvasData.projectName
	
	-- Remove the project name key
	canvasData.projectName = nil
	
	-- Remove all current canvas elements
	Designer.clearCanvas()
	
	-- If the file was modified before overhaul update, we assume its
	-- in the legacy format
	if dateModified < NEWVERSION_CONST then
		Designer.loadLegacyFormat( canvasData )
	else
		-- Change the canvas element table to the loaded data
		Designer.canvasElements = canvasData
	end
	
	
end

--| 							|--
--| Designer.loadLegacyFormat
--| 							
--| Try our best to convert a save file from the previous Designer incarnation
--| to the new format
--| 							|--
function Designer.loadLegacyFormat( tbl )
	
	Designer.print( "Loading legacy Designer save, errors may occur", "alert" )
	
	local size = table.Count(tbl)

	for i = 1, size do
		-- Iterate through each layer
		for class, objects in pairs(tbl[i]) do
			-- Get each element 
			for id, data in pairs(objects) do
				
				-- The old format catalogs the elements by their function name ex: draw.Text
				class = string.lower(class)
				
				-- Align the x and y values to the new canvas
				--local x = math.floor(data.x / Designer.canvasConst.wratio)
				--local y = math.floor(data.y / Designer.canvasConst.hratio)
				
				Designer.screenToDesignerDim( data.x, data.y, data.w, data.h )
				
				-- Make sure the color exists otherwise errors will occur
				local col = Color( data.color.r or 255, data.color.g or 255, data.color.b or 255, data.color.a )
				
				if class == "draw.roundedbox" then
					--local w = data.width / Designer.canvasConst.wratio
					--local h = data.height / Designer.canvasConst.wratio
					
					Designer.addRect( x, y, w, h, col, i, data.corner )
				elseif class == "draw.drawtext" then
					Designer.addText( x, y, data.font, data.text, col, i )
				elseif class == "surface.DrawTexturedRect" then
					-- TODO: Convert textured rect
					print("Attempt to convert textured rect")
				else
					print( "Attempt to convert unknown class type ", class )
				end
			end
		end
	end

end


