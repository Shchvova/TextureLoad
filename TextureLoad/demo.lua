-------------------------------------------------------------------------------------------
--- Demo scene is very simple - it would create and destroy display objects from 
--- hi-res textures. It ahso has buttons to preload textures and release preloaded textures
-------------------------------------------------------------------------------------------


local composer = require( "composer" )
local widget = require( "widget" )

local scene = composer.newScene()

local preloadTextures = composer.getVariable( 'preloadTextures' )
local releaseTextures = composer.getVariable( 'releaseTextures' )
local filenames = composer.getVariable( 'filenames' )
local textures = composer.getVariable( 'textures' )

function scene:create( event )
    local sceneGroup = self.view
    local button1 = widget.newButton
    {
        label = "Preload",
        onEvent = function( event )
            if event.phase == 'ended' then
                textures = {}
                preloadTextures(nil, function( )
                    textures = composer.getVariable( 'textures' )
                end) 
            end
        end,
        emboss = false,
        shape="roundedRect",
        width = 200,
        height = 40,
        cornerRadius = 2,
        fillColor = { default={ 1, 0, 0, 1 }, over={ 1, 0.1, 0.7, 0.4 } },
        strokeColor = { default={ 1, 0.4, 0, 1 }, over={ 0.8, 0.8, 1, 1 } },
        strokeWidth = 4
    }
    button1.x = display.contentWidth*0.25

    local button2 = widget.newButton
    {
        label = "Release",
        onEvent = function( event )
            if event.phase == 'ended' then
                textures = {}
                releaseTextures( )
            end
        end,
        emboss = false,
        shape="roundedRect",
        width = 200,
        height = 40,
        cornerRadius = 2,
        fillColor = { default={ 1, 0, 0, 1 }, over={ 1, 0.1, 0.7, 0.4 } },
        strokeColor = { default={ 1, 0.4, 0, 1 }, over={ 0.8, 0.8, 1, 1 } },
        strokeWidth = 4,
    }
    button2.x = display.contentWidth*0.75

    sceneGroup:insert( button1 )
    sceneGroup:insert( button2 )
end


local function getSplatterObject( group, splat )
    local texture = textures[splat]
    if texture then
        -- using preloaded textures
        return display.newImageRect( group, texture.filename, texture.baseDir, 50, 50 )
    else
        -- if preloaded textures are not availiable
        return display.newImageRect( group, filenames[splat], system.CachesDirectory, 50, 50 )
    end
end

local stopSplatters = false
local function splatDown(group, x, y, img)
    if stopSplatters then
        return
    end
    if img > #filenames then
        img = 1
    end
    if y > display.contentHeight then
        y = 0
    end
    local obj = getSplatterObject(group, img)
    if obj then
        obj.x = x
        obj.y = y
        timer.performWithDelay( 10, function( )
            obj:removeSelf( ) -- destroy previous object
            splatDown(group, x, y+10, img + 1); -- create new object little lower and with next image (img+1)
        end )
    end
end



function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        splatDown(sceneGroup, display.contentWidth*0.5,  display.contentHeight*0.0, 1+0*#filenames/3)
        splatDown(sceneGroup, display.contentWidth*0.25, display.contentHeight*0.3, 1+1*#filenames/3)
        splatDown(sceneGroup, display.contentWidth*0.75, display.contentHeight*0.6, 1+2*#filenames/3)
    elseif ( phase == "did" ) then
    end
end

function scene:hide( event )

    local phase = event.phase

    if ( phase == "will" ) then
    elseif ( phase == "did" ) then
        -- we don't need this textures outside the scene
        stopSplatters = true
        releaseTextures()
    end
end


-- "scene:destroy()"
function scene:destroy( event )
    stopSplatters = true
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene
