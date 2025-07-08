#!/bin/sh
echo -ne '\033c\033]0;Genesis\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Genesis 1.0.x86_64 [Linux].x86_64" "$@"
