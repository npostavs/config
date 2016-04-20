#!/bin/sh

if luaposix=$(nix-env -q --out-path lua5.3-luaposix-33.3.1 | awk '{print $2}'); then
    export LUA_PATH="$luaposix/share/lua/5.3/?/init.lua;${luaposix}/share/lua/5.3/?.lua;${HOME}/.config/i3/?.lua"
    export LUA_CPATH="${luaposix}/lib/lua/5.3/?.so"
fi
exec lua ~/.config/i3/stat.lua
