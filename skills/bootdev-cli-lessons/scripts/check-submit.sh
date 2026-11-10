#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: bootdev-check-submit <lesson-uuid>" >&2
  exit 2
fi

lesson_id=$1
if ! bootdev run "$lesson_id"; then
  echo "Check failed; lesson was not submitted." >&2
  exit 1
fi

bootdev run -s "$lesson_id"
