local composer = require( "composer" )
local dlc = require('dlc')

local scene = composer.newScene()


local text, progressBar, progressBg

function scene:create( event )
    local sceneGroup = self.view
    display.newText( sceneGroup, "Downloading Textures", display.contentCenterX, 80, nil, 25 )
    display.newText( sceneGroup, "Wi-Fi connection in strongly recommended", display.contentCenterX, 109, nil, 15 )
    text = display.newText( sceneGroup, "Welcome!", display.contentCenterX, display.contentCenterY+60, nil, 16 )
    progressBg = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, 400, 60 )
    progressBar = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, 396, 59 )
end

-- this would set progress bar and message
local function setProgress( progress, message )
    if text and message then
        text.text = message
    end
    if progressBar then
        progress = math.min( 1, math.max(0, progress) )
        local w = 396*(1-progress)
        progressBar.width = w
        -- progressBar.x = display.contentCenterX - (w-396)/2
    end
end

-- this callback track download progress and when it is done, transfers to next scene
local function dlcDownloadListener( event )
    setProgress( event.progress, event.message )
    if event.done then
        composer.setVariable( 'filenames', event.files )
        composer.gotoScene( 'demo' , {time=400, effect='fade'} )
        progressBar:setFillColor( 0,1,0,1 )
    end
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        progressBar:setFillColor( 0,0,0 )
    elseif ( phase == "did" ) then
        -- statrt downloading textures immidiatelly, progress would be reported to dlcDownloadListener
        dlc.download( composer.getVariable( 'dlcUrl' ), dlcDownloadListener )
    end
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-- -------------------------------------------------------------------------------

return scene
