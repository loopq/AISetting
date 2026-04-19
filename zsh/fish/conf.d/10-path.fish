# Homebrew（优先）
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# VS Code CLI
fish_add_path "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# 自定义 PATH
fish_add_path \
    "$HOME/bin" \
    "$JAVA_HOME/bin" \
    "$ANDROID_HOME/tools" \
    "$ANDROID_HOME/platform-tools" \
    "$FLUTTER_HOME/bin" \
    "$DART_HOME" \
    "$HOME/.bun/bin" \
    "$HOME/.local/bin"