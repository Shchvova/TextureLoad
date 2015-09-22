local composer = require( "composer" )
local widget = require( "widget" )

local scene = composer.newScene()

-- this comes from donwloading textures
local filenames = composer.getVariable( 'filenames' )

local textures = {}

local function preloadTextures( )
    -- preloading textures is handled in separate scene.
    -- basically it just calls graphics.newTexture({type="image", ... })
    -- and shows progress bar
    composer.gotoScene( 'preloadTextures' , {time=400, effect='fade'} )
end

local function releaseTextures( )
    -- release textures one by one
    if textures then
        for i = 1, #textures do
            local t = textures[i]
            if t then
                t:releaseSelf()
            end
        end
    end
    -- alternatively, release them all by type:
    -- graphics.releaseTextures('image')

    textures = {}
end

function scene:create( event )
    local sceneGroup = self.view

    -- creating buttons which would ackquire/release textures on pres
    local button1 = widget.newButton
    {
        label = "Preload",
        onEvent = function( event )
            if event.phase == 'ended' then
                preloadTextures() 
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

local splatters = {}
local function createSplatter(group, x, y, img)
    local splatter = {stop=false}
    local function splatDown(group, x, y, img)
        if splatter.stop then
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
    splatDown(group, x, y, img)
    splatters[#splatters+1] = splatter
    return splatter
end

local function stopSplatters( )
    for i = 1,#splatters do
        local splat = splatters[i]
        if splat then
            splat.stop = true
        end
    end
    splatters = {}
end

function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase
    if ( phase == "will" ) then
        -- create 3 "splat" game objects. They would destroy themselves as quickly 
        -- as possible and create another objects lower. See splatDown function for detail
        textures = composer.getVariable( 'textures' )
        if not textures then 
            textures = {}
        end
        createSplatter(sceneGroup, display.contentWidth*0.5,  display.contentHeight*0.0, 1+0*#filenames/3)
        createSplatter(sceneGroup, display.contentWidth*0.25, display.contentHeight*0.3, 1+1*#filenames/3)
        createSplatter(sceneGroup, display.contentWidth*0.75, display.contentHeight*0.6, 1+2*#filenames/3)
    elseif ( phase == "did" ) then
    end
end

function scene:hide( event )
    local phase = event.phase
    if ( phase == "will" ) then
        stopSplatters()
    elseif ( phase == "did" ) then
    end
end


function scene:destroy( event )
    -- don't forget to release textures when we don't need them:
    releaseTextures()
    stopSplatters()
end



-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )


return scene
