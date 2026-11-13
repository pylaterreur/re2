#!/bin/bash
set -eux

# Disable MSYS/MSYS2 path conversion, which interferes with Bazel.
export MSYS_NO_PATHCONV='1'
export MSYS2_ARG_CONV_EXCL='*'

LIMITED_API="${PY_LIMITED_API:-unset}"

# For a free-threaded Python (e.g. 3.15t), build the extension with
# NB_FREE_THREADED, as python/setup.py does.
FREE_THREADED=no
if [[ "$(python -c 'import sysconfig; print(sysconfig.get_config_var("Py_GIL_DISABLED") or 0)')" == 1 ]]
then
  FREE_THREADED=yes
fi

for compilation_mode in dbg opt
do
  bazel clean
  bazel build \
    --extra_toolchains=//python/toolchains:all \
    --@nanobind_bazel//:py-limited-api="${LIMITED_API}" \
    --@rules_python//python/config_settings:py_freethreaded="${FREE_THREADED}" \
    --compilation_mode=${compilation_mode} -- \
    //:re2 \
    //python:re2
  bazel test \
    --extra_toolchains=//python/toolchains:all \
    --@nanobind_bazel//:py-limited-api="${LIMITED_API}" \
    --@rules_python//python/config_settings:py_freethreaded="${FREE_THREADED}" \
    --compilation_mode=${compilation_mode} -- \
    //:small_tests \
    //python:all
done

exit 0
