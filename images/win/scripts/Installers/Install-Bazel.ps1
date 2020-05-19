################################################################################
##  File:  Install-Bazel.ps1
##  Desc:  Install Bazel and Bazelisk (A user-friendly launcher for Bazel)
################################################################################

npm install -g @bazel/bazelisk

# Invoke bazel to download the latest version via bazelisk
$null = & cmd /c "bazel 2>&1"
