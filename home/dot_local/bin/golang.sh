export GOPATH="${HOME}/ghq"

typeset -gU path
path=(
    ${GOPATH}/bin
    /usr/local/go/bin
    $path
)

export GOROOT=$(go env GOROOT)
