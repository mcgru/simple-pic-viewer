#!/bin/sh
# Build Simple Pic Viewer as a portable Docker image
#
# Usage:
#   ./build-static.sh            — build Docker image only
#   ./build-static.sh extract    — build and extract binary + libs to ./portable/
#
set -e

IMAGE_NAME="${IMAGE_NAME:-simple-pic-viewer}"

echo "==> Building Docker image: ${IMAGE_NAME}"
docker build --network host -t "${IMAGE_NAME}" -f Dockerfile.static .

if [ "${1:-}" = "extract" ]; then
	echo "==> Extracting binary and libraries to ./portable/"
	rm -rf portable
	mkdir -p portable/lib

	# Extract the binary
	id=$(docker create "${IMAGE_NAME}")
	docker cp "${id}:/simple-pic-viewer" ./portable/
	docker rm "${id}" >/dev/null 2>&1

	# Extract all shared libraries from the image
	docker run --rm --entrypoint sh "${IMAGE_NAME}" -c '
		# Get list of all .so files
		find /usr/lib -name "*.so*" -type f -o -name "*.so.*" -type f | while read lib; do
			echo "$lib"
		done
		find /lib -name "*.so*" -type f -o -name "*.so.*" -type f | while read lib; do
			echo "$lib"
		done
	' > /tmp/spv_libs.txt

	# Copy each library
	docker run --rm --entrypoint sh -v "$(pwd)/portable/lib:/outlib" "${IMAGE_NAME}" -c '
		while IFS= read -r lib; do
			dir=$(dirname "$lib")
			mkdir -p "/outlib${dir}"
			cp "$lib" "/outlib${lib}" 2>/dev/null || true
		done < /dev/stdin
	' < /tmp/spv_libs.txt

	# Copy gdk-pixbuf loaders
	docker run --rm --entrypoint sh -v "$(pwd)/portable/lib:/outlib" "${IMAGE_NAME}" -c '
		cp -r /usr/lib/gdk-pixbuf-2.0 /outlib/usr/lib/ 2>/dev/null || true
	'

	# Create launcher script
	cat > portable/simple-pic-viewer.sh << 'LAUNCHER'

#!/bin/sh
# Portable launcher for Simple Pic Viewer
DIR="$(cd "$(dirname "$0")" && pwd)"  #"

export LD_LIBRARY_PATH="${DIR}/lib/usr/lib:${DIR}/lib/lib:${LD_LIBRARY_PATH}"
export GDK_PIXBUF_MODULE_FILE="${DIR}/lib/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
exec "${DIR}/simple-pic-viewer" "$@"
LAUNCHER
	chmod +x portable/simple-pic-viewer.sh

	rm -f /tmp/spv_libs.txt
	echo "==> Portable bundle created in ./portable/"
	echo "    Run: ./portable/simple-pic-viewer.sh [image-dir]"
fi

echo "==> Done"
echo "    Run container: docker run --rm -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=\$DISPLAY ${IMAGE_NAME}"
