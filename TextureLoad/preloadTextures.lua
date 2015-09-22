local composer = require( "composer" )

local scene = composer.newScene()

local dlc = require('dlc')

local text, progressBar, progressBg

function scene:create( event )
    local sceneGroup = self.view
    display.newText( sceneGroup, "Loading...", display.contentCenterX, 80, nil, 25 )
    text = display.newText( sceneGroup, "", display.contentCenterX, display.contentCenterY+60, nil, 16 )
    progressBg = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, 400, 60 )
    progressBar = display.newRect( sceneGroup, display.contentCenterX, display.contentCenterY, 396, 59 )
    progressBar:setFillColor( 0,1,0,1 )
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

-- this function would create texture objects with `graphics.newTexture` 
-- it would do it 1 by 1
local function preloadTextures( )

    local filenames = composer.getVariable( 'filenames' )
    local textures = {}

    -- this function load a single texture, than schedules to load a next texture on next frame
    local function preloadTexture(i)
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
        setProgress( 1-i/#filenames, "" )

        -- schedule to load next texture on next frame
        timer.performWithDelay( 1, function( )
            -- if all textures was loaded, report it to onComplete callback
            -- as well as set 'textures' variable to composer to expose loaded textures
            if i >= #filenames then
                composer.setVariable( 'textures', textures )
                composer.gotoScene( 'demo' , {time=400, effect='fade'} )
            else
                preloadTexture(i+1)
            end
        end )
    end
    
    -- acquire first texture    
    preloadTexture(1)
end


function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        preloadTextures()
    end
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

-- -------------------------------------------------------------------------------

return scene
