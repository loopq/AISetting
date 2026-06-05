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

# --- 编程语言与开发工具 (从 .bash_profile 迁入) ---
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
    "/opt/homebrew/opt/ffmpeg-full/bin",
    "/opt/homebrew/bin/python3.11",
    "$HOME/.antigravity/antigravity/bin"
    "$HOME/.bun/bin"
    "$HOME/.local/bin",
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
    export http_proxy=http://127.0.0.1:7890;
    export https_proxy=http://127.0.0.1:7890;
    export all_proxy=socks5://127.0.0.1:7890;
    echo "终端代理已开启 (Port: 7890)"
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

alias "/neku"="cd /Users/loopq/dev/git/zthd/avatar/Avatar-Android"
alias "/oc"="cd /Users/loopq/dev/git/zthd/avatar/OC_Avatar"
# alias "/zthd"="cd /Users/loopq/dev/git/zthd"
alias "/zthd"="node .claude/skills/zthd/scripts/zthd.js"
# CoolVibe
export PATH="$HOME/.coolvibe/bin:$PATH"

. "$HOME/.local/bin/env"

# Claude alias
alias ccd="claude --dangerously-skip-permissions"
alias ccrc="caffeinate -ims -t 14400 claude --remote-control"
csleep() {
  local pid=$(pgrep -n claude)
  if [[ -z "$pid" ]]; then
    echo "❌ no claude running — csleep needs a target" >&2
    return 1
  fi
  caffeinate -ims -t 14400 -w "$pid" &!
  echo "✅ caffeinate bg, watching claude PID=$pid, 4h cap"
}
alias cclear='pkill -x caffeinate && echo "✅ caffeinate cleared" || echo "nothing to clear"'

export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

# Codex alias
alias cxd="codex --dangerously-bypass-approvals-and-sandbox"
alias cxr="codex -a never -s read-only"
alias cxw="codex -a never -s workspace-write"

# Added by Antigravity
export PATH="/Users/loopq/.antigravity/antigravity/bin:$PATH"
# export DISABLE_TELEMETRY=1 影响 remote-control
# 敏感信息（token 等）统一放 ai-secrets.env，不进 git
[ -f "$HOME/.config/ai-secrets.env" ] && source "$HOME/.config/ai-secrets.env"
# 太慢了，收益不大
# export CLAUDE_CODE_EFFORT_LEVEL=max
export CLAUDE_CODE_EFFORT_LEVEL=xhigh

# ================================================= #
# Git Worktree 工具链（create / apply / destroy）
# ================================================= #
source ~/.config/worktree-tools/worktree.zsh