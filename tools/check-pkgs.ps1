param([string]$Sources, [string]$Suite = "noble")
foreach ($s in ($Sources -split ",")) {
    try {
        $u = "https://api.launchpad.net/devel/ubuntu/+archive/primary?ws.op=getPublishedSources&source_name=$s&exact_match=true&distro_series=https%3A//api.launchpad.net/devel/ubuntu/$Suite&status=Published"
        $j = Invoke-RestMethod -Uri $u -TimeoutSec 30
        if ($j.entries.Count -eq 0) { Write-Output ("{0,-34} NOT FOUND in {1}" -f $s, $Suite) }
        else { foreach ($e in $j.entries) { Write-Output ("{0,-34} {1} [{2}/{3}]" -f $s, $e.source_package_version, $e.pocket, $e.component_name) } }
    } catch { Write-Output ("{0,-34} ERR {1}" -f $s, $_.Exception.Message) }
}
