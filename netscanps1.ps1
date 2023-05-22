$network = "192.168.1."
$hosts = 1..255 | ForEach-Object { $network + $_ }

$jobs = @()
$totalHosts = $hosts.Count
$completedHosts = 0

$progressPreference = 'Continue'

foreach ($targetHost in $hosts) {
    $job = Start-Job -ScriptBlock {
        param($target)
        $result = Test-Connection -ComputerName $target -Count 1 -Quiet
        if ($result) {
            return $target
        }
    } -ArgumentList $targetHost

    $jobs += $job
}

while ($jobs.State -contains 'Running') {
    $completedJobs = $jobs | Where-Object { $_.State -eq 'Completed' }
    foreach ($job in $completedJobs) {
        $results = $job | Receive-Job

        if ($results) {
            Write-Host "Available host: $results"
        }

        $completedHosts++
        $percentComplete = ($completedHosts / $totalHosts) * 100

        if ($percentComplete -gt 100) {
            $percentComplete = 100
        }

        Write-Progress -Activity "Scanning hosts" -Status "Progress" -PercentComplete $percentComplete

        $job | Remove-Job
    }
    Start-Sleep -Milliseconds 100
}

Write-Host "`nScanning completed."
