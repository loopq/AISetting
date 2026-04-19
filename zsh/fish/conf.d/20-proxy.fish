function proxyhp
    set -gx http_proxy "http://127.0.0.1:7890"
    set -gx https_proxy "http://127.0.0.1:7890"
    set -gx all_proxy "socks5://127.0.0.1:7890"
    echo "终端代理已开启 (Port: 7890)"
end

function unproxyhp
    set -e http_proxy
    set -e https_proxy
    set -e all_proxy
    echo "终端代理已关闭"
end