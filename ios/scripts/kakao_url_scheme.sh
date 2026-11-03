#!/bin/sh
set -e

ENV_FILE="${SRCROOT}/../.env"
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [ ! -f "$PLIST" ]; then
  exit 0
fi

KEY=""
if [ -f "$ENV_FILE" ]; then
  KEY=$(grep -E '^KAKAO_NATIVE_APP_KEY=' "$ENV_FILE" | head -n 1 | cut -d= -f2- | tr -d '[:space:]')
fi
if [ -z "$KEY" ]; then
  exit 0
fi

/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string kakao${KEY}" "$PLIST"
