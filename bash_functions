#! /bin/bash

# REQUIRED VARIABLES: manifestfile urlroot contentroot renderedroot thispage

quote-jq() {
    printf '"%s"' "${1//"/\\"}"
}

title() {
    local page=${1:-$thispage}
    cat "$manifestfile" | yq -r .$(quote-jq "$page")."Title"
}

page-to-path-slash() {
    local page=${1:-$thispage}
    local dn=$(dirname "$page")
    printf %s "${dn%%/}/"
}

child-indices() {
    local page=${1:-$thispage}
    cat "$manifestfile" | yq -r 'keys[] | select(test('$(quote-jq "^$(page-to-path-slash "$page")[^/]+/index\$")'))'
}

self-and-siblings() {
    local page=${1:-$thispage}
    cat "$manifestfile" | yq -r 'keys[] | select(test('$(quote-jq "^$(page-to-path-slash "$page")[^/]+\$")'))'
}

page-url() {
    local page=${1:-$thispage}
    if [[ "$page" = */index ]]; then
        printf %s%s "$urlroot" "${page%%index}"
    else
        printf %s%s "$urlroot" "$page"
    fi
}

content-filespec() {
    local page=${1:-$thispage}
    printf '%s/%s.md' "$contentroot" "$page"
}

page-exists() {
    local page=${1:-$thispage}
    [ "$(cat "$manifestfile" | yq -r 'has('$(quote-jq "$page")')')" = "true" ]
}

html-child-nav() {
    local page=${1:-$thispage}
    local atleastone=
    for child in $(child-indices "$page"); do
        [ -n "$atleastone" ] || printf '%s\n' "<ul>"
        printf '<li><a href="%s">%s</a></li>\n' "$(page-url "$child")" "$(title "$child")"
        atleastone=1
    done
    [ -z "$atleastone" ] || printf '</ul>\n'
}

html-sibling-nav() {
    local page=${1:-$thispage}
    local atleastone=
    for sibling in $(self-and-siblings "$page"); do
        [ "${sibling##*/}" != index ] || continue
        [ -n "$atleastone" ] || printf '%s\n' "<ul>"

        if [ "$sibling" = "$page" ]; then
            printf '<li class="current">%s\n' "$(title "$sibling")"
            html-child-nav "$sibling"
            printf '</li>\n'
        else
            printf '<li><a href="%s">%s</a></li>\n' "$(page-url "$sibling")" "$(title "$sibling")"
        fi
        atleastone=1
    done
    [ -z "$atleastone" ] || printf '%s\n' "</ul>"
}

html-nav-path() {
    local page=${1:-$thispage}
    local dn=$(dirname "$page")
    printf '<a href="%s">🏠</a>\n' "$(page-url /index)"
    if [ -z "${dn#/}" ]; then
        html-child-nav /
    else
        for d in ${dn//\// }; do
            printf '<ul>\n'
            ppath=$ppath/$d
            ppage=$ppath/index
            if page-exists "$ppage"; then
                if [ "$ppage" = "$page" ]; then
                    printf '<li class="current">'
                else
                    printf '<li>'
                fi
                printf '<a href="%s">%s</a>\n' "$(page-url "$ppage")" "$(title "$ppage")"
            else
                printf '%s\n' "$d"
            fi
        done
        html-sibling-nav "$page"
        for d in ${dn//\// }; do
            printf '</li></ul>\n'
        done
    fi
    printf '\n'
}

process-template() {
    while IFS= read -r line; do
        while [ -n "$line" -a -z "${line//*\{%bash *%\}*/}" ]; do
            pfx=${line%%\{%bash *}
            cmd=${line#*\{%bash }
            cmd=${cmd%%\%\}*}
            sfx=${line#*%\}}
            cmdout=$(eval $cmd)
            line="$pfx$cmdout$sfx"
        done
        printf '%s\n' "$line"
    done
}

render-content() {
    local page=${1:-$thispage}
    awk '/^---$$/ && c <= 1 { c++; next; }; c != 1' $(content-filespec "$page") | \
        process-template | \
        python -c 'import markdown; import sys; print(markdown.markdown(sys.stdin.read()));'
}

render-html-page() {
    local page=${1:-$thispage}
    cat base.html.tmpl | process-template
}
