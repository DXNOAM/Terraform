#!/bin/bash
# Work from the project folder, stop on errors, and create owner-only files.
set -e
cd -- "$(dirname -- "$0")"
umask 077

# Define the SSH key paths and create the local key directory.
KEY_DIR="./ssh"
KEY_NAME="terraform-key"
KEY_PATH="${KEY_DIR}/${KEY_NAME}"
mkdir -p "$KEY_DIR"

# Generate an RSA key for automated SSH only if no private key exists.
if [ ! -f "$KEY_PATH" ]; then
  [ ! -e "${KEY_PATH}.pub" ] || { echo "Restore the matching private key first." >&2; exit 1; }
  ssh-keygen -t rsa -b 4096 -m PEM -f "$KEY_PATH" -N ""
fi

# Restrict private-key access to the current user with Windows or Unix permissions.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    OWNER_SID=$(powershell.exe -NoProfile -NonInteractive -Command '[System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value' | tr -d '\r')
    MSYS2_ARG_CONV_EXCL='*' icacls.exe "$(cygpath -w "$KEY_PATH")" /reset >/dev/null
    MSYS2_ARG_CONV_EXCL='*' icacls.exe "$(cygpath -w "$KEY_PATH")" /inheritance:r /grant:r "*${OWNER_SID}:(R)" >/dev/null
    ;;
  *) chmod 600 "$KEY_PATH" ;;
esac

# Restore a missing public key and display the paths of the ready key pair.
if [ ! -f "${KEY_PATH}.pub" ]; then
  ssh-keygen -y -P "" -f "$KEY_PATH" > "${KEY_PATH}.pub"
fi
echo "SSH key pair ready at ${KEY_PATH} and ${KEY_PATH}.pub"
