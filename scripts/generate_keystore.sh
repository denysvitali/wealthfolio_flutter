#!/usr/bin/env bash
# Generate an upload keystore for Android release builds and output the
# values needed as GitHub Actions secrets.
#
# Usage:  devenv shell -- bash scripts/generate_keystore.sh
#
# Requires: keytool (provided by jdk21 in devenv), base64, openssl

set -euo pipefail

# ---- Configuration ----
KEYSTORE_NAME='upload-keystore.p12'
KEY_ALIAS='upload'
VALIDITY_DAYS=10000
KEYSTORE_DIR=$(pwd)

# ---- Colors (only if terminal supports them) ----
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BOLD='' RESET=''
fi

info()  { printf "${GREEN}[INFO]${RESET}  %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${RESET}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; exit 1; }

# ---- Preflight checks ----
command -v keytool >/dev/null 2>&1 || error "keytool not found. Run inside: devenv shell -- bash $0"
command -v base64  >/dev/null 2>&1 || error "base64 not found."
command -v openssl >/dev/null 2>&1 || error "openssl not found."

KEYSTORE_PATH="${KEYSTORE_DIR}/${KEYSTORE_NAME}"

if [ -f "$KEYSTORE_PATH" ]; then
  error "Keystore already exists at ${KEYSTORE_PATH}. Remove it first if you want to regenerate."
fi

# ---- Collect passwords ----
# Use KEYSTORE_PASSWORD env var if set, otherwise generate a random one.
if [ -n "${KEYSTORE_PASSWORD:-}" ]; then
  STORE_PASS="$KEYSTORE_PASSWORD"
else
  STORE_PASS=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 16)
  if [ ${#STORE_PASS} -lt 6 ]; then
    STORE_PASS=$(openssl rand -hex 12)
  fi
fi

if [ ${#STORE_PASS} -lt 6 ]; then
  error "Password must be at least 6 characters."
fi

KEY_PASS="$STORE_PASS"

# ---- Generate keystore ----
info "Generating PKCS#12 keystore at ${KEYSTORE_PATH} ..."

keytool -genkeypair \
  -v \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity "$VALIDITY_DAYS" \
  -storetype PKCS12 \
  -keystore "$KEYSTORE_PATH" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "CN=Upload, O=Wealthfolio, L=Unknown, ST=Unknown, C=US"

info "Verifying keystore ..."
keytool -list -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASS" -alias "$KEY_ALIAS" >/dev/null 2>&1 \
  || error "Keystore verification failed. The generated file may be corrupt."

info "Keystore fingerprint:"
keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASS" -alias "$KEY_ALIAS" 2>/dev/null \
  | grep -E '(SHA1|SHA256)' || true

# ---- Encode as base64 ----
KEYSTORE_BASE64=$(base64 -w 0 "$KEYSTORE_PATH")

# ---- Output secrets ----
printf "\n${BOLD}========================================${RESET}\n"
printf "${BOLD}  GitHub Actions Secrets${RESET}\n"
printf "${BOLD}========================================${RESET}\n\n"

printf "  ${GREEN}KEYSTORE_BASE64${RESET}    (paste the full value below)\n"
printf "  %s\n\n" "$KEYSTORE_BASE64"

printf "  ${GREEN}KEYSTORE_PASSWORD${RESET}   %s\n" "$STORE_PASS"
printf "  ${GREEN}KEY_PASSWORD${RESET}        %s\n\n" "$KEY_PASS"

printf "${BOLD}========================================${RESET}\n"
printf "${YELLOW}Next steps:${RESET}\n"
printf "  1. Go to GitHub → Settings → Secrets and variables → Actions\n"
printf "  2. Add the three secrets above\n"
printf "  3. DO NOT commit %s to the repository\n" "$KEYSTORE_NAME"
printf "${BOLD}========================================${RESET}\n"

warn "Add ${KEYSTORE_NAME} to .gitignore if it isn't already."
printf "\nDone.\n"
