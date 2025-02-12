local executable_name = arg[ 1 ] or "app"
local package_name = arg[ 2 ] or "release"
local lovr_directory = arg[ 3 ] or "D:\\dev\\lovr"

local exclude = {
	".gitignore",
	".gitattributes",
	".git",
	".vscode",
	"build",
	"build.lua"
}

local function GetFilesAndFolders( directory, excl )
	local str = ""
	for element in io.popen( "dir " .. directory .. " /b /a" ):lines() do
		local exists = false
		for i, v in ipairs( excl ) do
			if v == element then
				exists = true
				break
			end
		end

		if not exists then
			str = str .. " " .. directory .. element
		end
	end
	return str
end

local filenames = GetFilesAndFolders( "", exclude )
os.execute( "cls" )
os.execute( "if not exist build mkdir build" )
os.execute( "del /q build\\*.*" )
os.execute( "tar.exe -acf build\\out.zip " .. filenames )
os.execute( "copy /b /Y " .. lovr_directory .. "\\lovr.exe+build\\out.zip build\\" .. executable_name .. ".exe" )
os.execute( "copy " .. lovr_directory .. "\\*.dll build" )
os.execute( "del build\\out.zip" )

local filenames = GetFilesAndFolders( "build\\", exclude )
os.execute( "tar.exe -acf build\\" .. package_name .. ".zip " .. filenames )
