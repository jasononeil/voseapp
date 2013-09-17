# VoseApp

To run:

    cd out
    nw .

### NPMs

https://github.com/rogerwang/node-webkit
https://github.com/LearnBoost/kue/
https://github.com/schaermu/node-fluent-ffmpeg

https://github.com/rogerwang/node-webkit/wiki/Using-Node-modules#3rd-party-modules-with-cc-addons

**Errors with 3rd party modules with C++ addons**

This applies to kue->redis->hiredis.

    cd out/node_modules/kue/node_modules/redis/node_modules/hiredis
    nw-gyp rebuild --target=0.7.3 

Or whatever version of Node-Webkit you are using.