local composer = require( "composer" )

local scene = composer.newScene()

local dlc = require('dlc')


local text, progressBar, progressBg


function scene:create( event )
    local sceneGroup = self.view
    text = display.newText( sceneGroup, "Welcome!", display.contentCenterX, display.contentCenterY+60, nil, 16 )
    progressBg = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, 400, 60 )
    progressBar = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, 396, 59 )

end

local globalLoadLock = false

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


local function releaseTextures( forceLoad )

    if globalLoadLock and not forceLoad then
        return
    end

    if not forceLoad then
        globalLoadLock = true
    end

    local textures = composer.getVariable( 'textures' )
    composer.setVariable( 'textures', {} )

    if textures and #textures > 0 then
        for i = 1,#textures do
            textures[i]:releaseSelf()
        end
        -- alternatevily we could just call following to release all at once
        -- graphics.releaseTextures{type='image'}
        if not forceLoad then
            timer.performWithDelay( 1, function (  )
                globalLoadLock = false
            end )
        end
    end
end 

local function preloadTextures( setProgressLocal, onComplete, forceLoad )
    if globalLoadLock and not forceLoad then
        return
    end
    if not forceLoad then
        globalLoadLock = true
    end

    releaseTextures( true )
    local filenames = composer.getVariable( 'filenames' )
    local textures = {}

    local function ackquireTexture(i)
        local texture = graphics.newTexture{
            type = 'image',
            filename = filenames[i],
            baseDir = system.CachesDirectory
        }
        if texture then
            texture:preload()
            textures[i] = texture
        end

        if setProgressLocal then
            setProgressLocal( 1-i/#filenames, "" )
        end

        timer.performWithDelay( 1, function( )
            if i >= #filenames then
                composer.setVariable( 'textures', textures )
                if onComplete then
                    onComplete()
                    if not forceLoad then
                        globalLoadLock = false
                    end                    
                end
            else
                ackquireTexture(i+1)
            end
        end )
    end
    
    composer.setVariable( 'textures', textures )
    ackquireTexture(1)
end

function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        progressBar:setFillColor( 0,0,0 )
    elseif ( phase == "did" ) then
        function dlcListener( event )
            setProgress( event.progress, event.message )
            if event.done then
                composer.setVariable( 'filenames', event.files )
                composer.setVariable( 'preloadTextures', preloadTextures )
                composer.setVariable( 'releaseTextures', releaseTextures )
                preloadTextures( setProgress, function ( )
                    composer.gotoScene( 'demo' , {time=400, effect='fade'} )
                end )
                progressBar:setFillColor( 0,1,0,1 )
            end
        end
        dlc.download( composer.getVariable( 'dlcUrl' ), dlcListener )

    end
end


function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
    elseif ( phase == "did" ) then
    end
end


function scene:destroy( event )

    local sceneGroup = self.view

end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene
