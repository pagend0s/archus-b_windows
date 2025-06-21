$script_path1 = Split-Path -Path (Split-Path $PSScriptRoot -Parent) -Parent

$imtToKeymap = @{
    "00000409" = "us"
    "00000407" = "de-latin1"
    "00000415" = "pl"
    "0000040c" = "fr"
    "00000410" = "it"
    "00000809" = "uk"
    "00000413" = "nl"
    "00000419" = "ru"
    "0000040a" = "es"
    "00000416" = "br-abnt2"
    "00000411" = "jp106"
    "00000412" = "kr104"
    "00000408" = "gr"
    "00000414" = "no"
    "0000041d" = "sv-latin1"
    "0000041f" = "trq"
    "00000424" = "slovene"
    "00000427" = "lt"
    "0000042b" = "hy"
    "0000042c" = "az"
    "0000042f" = "mk"
    "0000043e" = "ms"
    "00000443" = "uz"
    "00000444" = "tt"
    "00000445" = "bn"
    "00000446" = "pa"
    "00000447" = "gu"
    "00000449" = "ta"
    "0000044a" = "te"
    "0000044b" = "kn"
    "0000044c" = "ml"
    "0000044d" = "mr"
    "0000044e" = "sa"
    "00000450" = "mn"
    "00000456" = "gl"
    "00000457" = "kok"
    "0000045a" = "syr"
    "00000465" = "div"
}

$validKeymaps = @(
    'uk',
    'gu',
    'ml',
    'tt',
    'us',
    'cz-lat2',
    'te',
    'sa',
    'de-latin1',
    'gr',
    'pl',
    'hy',
    'ru',
    'et',
    'ta',
    'bn',
    'trq',
    'ms',
    'az',
    'mr',
    'es',
    'it',
    'kk',
    'div',
    'lv',
    'kok',
    'pa',
    'uz',
    'nl',
    'slovene',
    'sv-latin1',
    'syr',
    'no',
    'lt',
    'mk',
    'kn',
    'ur',
    'fr',
    'gl',
    'br-abnt2'
)

$defaultIMT = ((Get-WinUserLanguageList).InputMethodTips -split ":")[1]

$keymap = $imtToKeymap[$defaultIMT]

if ($validKeymaps -contains $keymap) {
    $output = "KEYMAP=$keymap"
    $output | Out-File -FilePath "$script_path1\resources\Files\keyboard_layout.inf" -Encoding ascii
} else {
    $output = "# Warning: '$keymap' is not a valid Arch Linux keymap. Falling back to 'us.`nKEYMAP=us"
    $output | Out-File -FilePath "$script_path1\resources\Files\keyboard_layout.inf" -Encoding ascii
}
