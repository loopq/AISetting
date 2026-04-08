# ================================================= #
# 1. Oh My Zsh 核心配置
# ================================================= #
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="sunrise"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# ================================================= #
# 2. 环境变量与路径 (PATH) 管理
# ================================================= #
typeset -U path # 自动去重

# --- 编程语言与开发工具 ---
# Java (JDK 17)
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
export CLASSPATH="$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:."

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"

# Flutter & Dart
export FLUTTER_HOME="$HOME/dev/tools/flutter"
export DART_HOME="$FLUTTER_HOME/bin/cache/dart-sdk/bin"
# Flutter 国内镜像
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"

# --- 统一构建 PATH ---
path=(
    "$HOME/bin"
    "$JAVA_HOME/bin"
    "$ANDROID_HOME/tools"
    "$ANDROID_HOME/platform-tools"
    "$FLUTTER_HOME/bin"
    "$DART_HOME"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/opt/ruby/bin"
    "/opt/homebrew/opt/ffmpeg-full/bin"
    "/opt/homebrew/bin/python3.11"
    "$HOME/.antigravity/antigravity/bin"
    "$HOME/.bun/bin"
    "$HOME/.local/bin"
    $path
)
export PATH

# Bun 环境变量
export BUN_INSTALL="$HOME/.bun"

# ================================================= #
# 3. 代理设置 (针对 Claude Code 等 AI 工具)
# ================================================= #
export no_proxy="localhost,127.0.0.1"

alias proxyhp='
    export http_proxy=http://127.0.0.1:52019;
    export https_proxy=http://127.0.0.1:52019;
    export all_proxy=socks5://127.0.0.1:52019;
    echo "终端代理已开启 (Port: 52019)"
'
alias unproxyhp='
    unset http_proxy https_proxy all_proxy;
    echo "终端代理已关闭"
'

# ================================================= #
# 4. 别名与补全
# ================================================= #
alias zshconfig="code ~/.zshrc"
alias reload="source ~/.zshrc"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# 项目路径别名（根据实际项目调整）
alias "/neku"="cd $HOME/dev/git/zthd/avatar/Avatar-Android"
alias "/oc"="cd $HOME/dev/git/zthd/avatar/OC_Avatar"
alias "/zthd"="cd $HOME/dev/git/zthd"

# CoolVibe
export PATH="$HOME/.coolvibe/bin:$PATH"

. "$HOME/.local/bin/env"

# Claude alias
alias ccd="claude --dangerously-skip-permissions"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

# ================================================= #
# 5. AI 工具环境变量
# ================================================= #
# 加载敏感信息（在新机器上需要配置）
[ -f "$HOME/.config/ai-secrets.env" ] && source "$HOME/.config/ai-secrets.env"

# ================================================= #
# 6. 自定义函数
# ================================================= #
function zg-switch() {
    local ZG="$HOME/bin/zg"
    local ZG_DIR="$HOME/dev/tools/zerogravity"

    if [ -z "$1" ]; then
        echo "Usage: zg-switch <email>"
        return 1
    fi

    "$ZG" accounts set "$1"
    (cd "$ZG_DIR" && docker compose restart)

    # 等待容器真正运行
    echo "Waiting for container to be ready..."
    local max_wait=30
    local i=0
    while [ $i -lt $max_wait ]; do
        local state=$(docker inspect --format='{{.State.Status}}' zerogravity 2>/dev/null)
        if [ "$state" = "running" ]; then
            break
        fi
        sleep 1
        i=$((i + 1))
    done

    "$ZG" status
}

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
