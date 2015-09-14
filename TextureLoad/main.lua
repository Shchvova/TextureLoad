-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
local composer = require('composer')

display.setStatusBar( display.HiddenStatusBar )


-- setup download link for textures
-- later, dlc module would look for where to download file there
composer.setVariable( 'dlcUrl', 'https://raw.githubusercontent.com/Shchvova/test/master/dlc/' )


-- move to loadingScreen scene
composer.gotoScene( 'loadingScreen' )


