-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
local composer = require('composer')

display.setStatusBar( display.HiddenStatusBar )


composer.setVariable( 'dlcUrl', 'https://raw.githubusercontent.com/Shchvova/test/master/dlc/' )
composer.setVariable( 'dlcUrl', 'http://localhost/dcl/dlc/' )


composer.gotoScene( 'loadingScreen' )


