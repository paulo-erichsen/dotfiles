# https://github.com/BurntSushi/ripgrep#setup-function-alias
function grep {
    $count = @($input).Count
    $input.Reset()

    if ($count) {
        $input | rg.exe --hidden --colors 'match:fg:white' --colors 'match:bg:red' $args
    }
    else {
        rg.exe --hidden --colors 'match:fg:white' --colors 'match:bg:red' $args
    }
}
