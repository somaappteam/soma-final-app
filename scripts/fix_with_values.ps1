Get-ChildItem -Recurse -Include *.dart | ForEach-Object {
    $path = $_.FullName
    $content = [System.IO.File]::ReadAllText($path)
    if ($content -match 'alpha: \)') {
        $content = $content -replace 'alpha: \)', 'alpha: 0.1)'
        [System.IO.File]::WriteAllText($path, $content)
        Write-Host "Fixed $path"
    }
}
