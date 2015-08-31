TextureLoad
===========

Focus of this example is caching images in memory (preloading textures) to remove lag when DisplayObjects are create using them.

Used API is `graphics.newTexture{type='image', ...}` in `loadingScreen.lua`.

This example consists of several display objects flipping through 6 hi-res textures on maximum possible speed (limited to 60 fps). It is easy to see than with preloaded textures performance is much better.

This example also includes code which download textures from the Web before using them. Please, check out how textures are downloaded using `network.download()` api.

Structure
---------
* `TextureLoad` - this folder have actual Corona app code, which would download resources from `dlc` folder in order to perform demo.
* `dlc` - this folder contains `manifest.json` with description list of images to download, total size to indicate progress and actual image files to me downloaded.
