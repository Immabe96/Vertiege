#!/bin/sh
# Embeds WebRTC-SDK xcframework (livekit / flutter_webrtc). Required because
# static CocoaPods linkage skips [CP] Embed Pods Frameworks for this dependency.
set -e

WEBRTC_SRC="${PODS_XCFRAMEWORKS_BUILD_DIR}/WebRTC/WebRTC.framework"
if [ ! -d "${WEBRTC_SRC}" ]; then
  WEBRTC_SRC="${BUILT_PRODUCTS_DIR}/XCFrameworkIntermediates/WebRTC/WebRTC.framework"
fi

if [ ! -d "${WEBRTC_SRC}" ]; then
  echo "warning: WebRTC.framework not found; skipping embed"
  exit 0
fi

DEST="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "${DEST}"
echo "Embedding WebRTC from ${WEBRTC_SRC} -> ${DEST}"
rsync -a "${WEBRTC_SRC}" "${DEST}/"

if [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] && [ "${CODE_SIGNING_REQUIRED}" != "NO" ] && [ "${CODE_SIGNING_ALLOWED}" != "NO" ]; then
  /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
    ${OTHER_CODE_SIGN_FLAGS:-} --preserve-metadata=identifier,entitlements \
    "${DEST}/WebRTC.framework"
fi
