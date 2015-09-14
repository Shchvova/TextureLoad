
-- this scene initiates and shows progress of downloading textures
-- as well as loading them into memory and moving on to main scene


local composer = require( "composer" )
local scene = composer.newScene()
local dlc = require('dlc')


local text, progressBar, progressBg

-- this variable is used to prevent simultaneous tasks for downloading and releasing textures
local globalLoadLock = false

function scene:create( event )
    local sceneGroup = self.view
    text = display.newText( sceneGroup, "Welcome!", display.contentCenterX, display.contentCenterY+60, nil, 16 )
    progressBg = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, 400, 60 )
    progressBar = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, 396, 59 )
end


-- this would set progress bar and update message
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


-- this function would release loaded with `graphics.newTexture` textures.
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


-- this function would create texture objects with `graphics.newTexture` 
-- it would do it 1 by 1
local function preloadTextures( setProgressLocal, onComplete, forceLoad )
    if globalLoadLock and not forceLoad then
        return
    end
    if not forceLoad then
        globalLoadLock = true
    end

    -- if there were any textures loaded, release them first
    releaseTextures( true )
    local filenames = composer.getVariable( 'filenames' )
    local textures = {}

    -- this function load a texture, than schedules to load a next texture on next frame
    local function acquireTexture(i)
        -- load a texture
        local texture = graphics.newTexture{
            type = 'image',
            filename = filenames[i],
            baseDir = system.CachesDirectory
        }
        if texture then
            texture:preload()
            textures[i] = texture
        end

        -- report progress
        if setProgressLocal then
            setProgressLocal( 1-i/#filenames, "" )
        end

        -- schedule to load next texture on next frame
        timer.performWithDelay( 1, function( )
            -- if all textures was loaded, report it to onComplete callback
            -- as well as set 'textures' variable to composer to expose loaded textures
            if i >= #filenames then
                composer.setVariable( 'textures', textures )
                if onComplete then
                    onComplete()
                    if not forceLoad then
                        globalLoadLock = false
                    end                    
                end
            else
                acquireTexture(i+1)
            end
        end )
    end
    
    -- acquire first texture    
    acquireTexture(1)
end


-- this callback track download progress and when it is done, transfers to next scene
local function dlcDownloadListener( event )
    setProgress( event.progress, event.message )
    if event.done then
        -- dlc listener event has "done" property, it means we're done downloading textures
        -- it is time to expose filenames and functions to other scenes with composer.serVariable
        composer.setVariable( 'filenames', event.files )
        composer.setVariable( 'preloadTextures', preloadTextures )
        composer.setVariable( 'releaseTextures', releaseTextures )
        -- as well as preload textures.
        -- last parameter to preload textures is completed callbac. When we're done loading textures
        -- to memory, we can proceed to next scene.
        preloadTextures( setProgress, function ( )
            composer.gotoScene( 'demo' , {time=400, effect='fade'} )
        end )
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
