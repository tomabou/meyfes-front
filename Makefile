build: app/meyfes.elm
	elm make app/meyfes.elm --output=./js/index.js

may3: src/may3.cpp
	em++ src/may3.cpp -o js/may3.js \
	-s WASM=1   \
	-s EXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
	-std=c++11 -s ALLOW_MEMORY_GROWTH=1 \
	-s EXPORTED_FUNCTIONS="['_create_maze']" \
	-s TOTAL_MEMORY=268435456