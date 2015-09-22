-------------------------------------------------------------------------------------------
--- this module download manifest file, and then download all files in it
--- reporting progress while doing it
-------------------------------------------------------------------------------------------


local json = require('json')
local function dbg(t) print("Debug Table ", json.encode( t , {indent=true} ) ) end


-- only funciton in dlc module. It takes url, and function to call on progress update, erros or success
local function downloadDlc( rootUrl, listener)

	local useRelativeLinks = true
	local filesToDownload
	local totalSize = 0
	local downloaded = 0
	local downloadedFiles = {}


	local function report( message, isError, progress, done, files )
		listener{ message=message, isError=isError, progress=progress, done=done, files=files }
	end

	-- this function would be called to download next file.
	-- it would check if file was already downloaded and report back to listener on status updates
	local function downloadNextFile( )
		-- if all files are downloaded (no files left to download) report sucess and exit
		if #filesToDownload == 0 then
			report("Done!", false, 1, true, downloadedFiles)
			return
		end

		-- get next file to download and remove it from donwload list
		local nextFile = table.remove( filesToDownload )
		local file = nextFile.file

		-- check if file was downloaded
		local filePath = system.pathForFile( file, system.CachesDirectory )
		local f = io.open( filePath, 'r' )
		if f then
			-- if file exists, report it's size as progress ...
			downloaded = downloaded + f:seek('end')
			f:close( )
			report("Already downloaded " .. file, false, downloaded/totalSize )
			downloadedFiles[#downloadedFiles+1] = file
			-- ... and move to next file
			timer.performWithDelay( 100, downloadNextFile )
			return
		end

		-- if manifest contains relative urls, prepend root url to it
		local url = nextFile.url
		if useRelativeLinks then
			url = rootUrl .. url
		end

		-- network.donwload listener. It will report to listener:
		local function downloadListener(event)
			if event.isError then
				-- errors. If error occures, interrupt process
				report("Error downloading " .. file, true, 0)
			elseif event.phase == "progress" then
				-- progress. When we downloaded part of the file report back download progress
				report("Downloading " .. file, false, (downloaded+event.bytesTransferred)/totalSize )
			elseif event.phase == "ended" then
				-- success. If we finished downloading file, report it and ...
				report("Download complete for " .. file, false, (downloaded+event.bytesTransferred)/totalSize )
				downloaded = downloaded+event.bytesTransferred
				downloadedFiles[#downloadedFiles+1] = file
				-- ... and move to next file			
				downloadNextFile()
			end
		end

		-- report & initiate donwloading file
		report("Downloading " .. file, false, downloaded/totalSize )
		network.download( url, 'GET', downloadListener, {progress=true}, file ,system.CachesDirectory )
	end

	local function processManifest(fullPath)
		local mf = io.open( fullPath, "r" )
		local manifest = json.decode( mf:read( "*all" ) )
		mf:close( )
		filesToDownload = manifest.files
		totalSize = manifest.size
		useRelativeLinks = manifest.relative
		downloadNextFile()
	end

	
	-- listener to report on manifest downloading. Manifests are small, so we don't need progress for them
	local function manifestDownload(event)
		if event.isError then
			-- just report an error in case of failure
			report("Error downloading manifest", true, 0)
		elseif event.phase == "ended" then
			-- in case manifest is downloaded, parse it with "json" module
			report("Received manifest", false, 0)
			processManifest(event.response.fullPath)
		end
	end

	
	local manifestFile = "manifest.json"
	local manifestFilePath = system.pathForFile( manifestFile, system.CachesDirectory )
	local f = io.open( manifestFilePath, 'r' )
	if f then
		f:close( )
		report("Manifest already downloaded", false, 0 )
		timer.performWithDelay( 1, function() processManifest(manifestFilePath) end )
	else
		report("Downloading manifest", false, 0)
		network.download( rootUrl .. manifestFile, 'GET', manifestDownload, 'manifest.json', system.CachesDirectory )
	end

end

return {download=downloadDlc}
