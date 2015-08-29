local json = require('json')
local function dbg(t) print("Debug Table ", json.encode( t , {indent=true} ) ) end

local function downloadDlc( rootUrl, listener)

	local useRelativeLinks = true
	local filesToDownload
	local totalSize = 0
	local downloaded = 0
	local downloadedFiles = {}


	local function report( message, isError, progress, done, files )
		listener{ message=message, isError=isError, progress=progress, done=done, files=files }
	end

	local function downloadNextFile( )
		if #filesToDownload == 0 then
			report("Done!", false, 1, true, downloadedFiles)
			return
		end
		local nextFile = table.remove( filesToDownload )
		local file = nextFile.file

		local filePath = system.pathForFile( file, system.CachesDirectory )
		local f = io.open( filePath, 'r' )
		if f then
			downloaded = downloaded + f:seek('end')
			f:close( )
			report("Already downloaded " .. file, false, downloaded/totalSize )
			downloadedFiles[#downloadedFiles+1] = file
			timer.performWithDelay( 100, downloadNextFile )
			return
		end

		local url = nextFile.url
		if useRelativeLinks then
			url = rootUrl .. url
		end

		local function downloadListener(event)
			if event.isError then
				report("Error downloading " .. file, true, 0)
			elseif event.phase == "progress" then
				report("Downloading " .. file, false, (downloaded+event.bytesTransferred)/totalSize )
			elseif event.phase == "ended" then
				report("Download complete for " .. file, false, (downloaded+event.bytesTransferred)/totalSize )
				downloaded = downloaded+event.bytesTransferred
				downloadedFiles[#downloadedFiles+1] = file
				downloadNextFile()
			end
		end

		report("Downloading " .. file, false, downloaded/totalSize )
		network.download( url, 'GET', downloadListener, {progress=true}, file ,system.CachesDirectory )
	end

	local function manifestDownload(event)
		if event.isError then
			report("Error downloading manifest", true, 0)
		elseif event.phase == "ended" then
			report("Received manifest", false, 0)
			local mf = io.open( event.response.fullPath, "r" )
			local manifest = json.decode( mf:read( "*all" ) )
			mf:close( )
			filesToDownload = manifest.files
			totalSize = manifest.size
			useRelativeLinks = manifest.relative
			downloadNextFile()
		end
	end

	report("Downloading manifest", false, 0)
	network.download( rootUrl .. 'manifest.json', 'GET', manifestDownload, 'manifest.json', system.CachesDirectory )
end

return {download=downloadDlc}