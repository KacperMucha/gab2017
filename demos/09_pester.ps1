function Build ($version) {
  write-host "A build was run for version: $version"
}

function BuildIfChanged {
  $thisVersion=Get-Version
  $nextVersion=Get-NextVersion
  if($thisVersion -ne $nextVersion) {Build $nextVersion}
  return $nextVersion
}

# Imagine that the following functions have heavy side-effect
function Get-Version {
  throw New-Object NotImplementedException
}

function Get-NextVersion {
  throw New-Object NotImplementedException
}