# Java
set -gx JAVA_HOME "/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
set -gx CLASSPATH "$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:."

# Android
set -gx ANDROID_HOME "$HOME/Library/Android/sdk"

# Bun
set -gx BUN_INSTALL "$HOME/.bun"

# no_proxy
set -gx no_proxy "localhost,127.0.0.1"