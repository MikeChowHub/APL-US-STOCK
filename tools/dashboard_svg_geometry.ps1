function ConvertTo-AplRequiredFiniteDouble {
  param([object]$Value, [string]$Name)
  if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { throw "$Name is required." }
  $number = 0.0
  if (-not [double]::TryParse([string]$Value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$number)) { throw "$Name must be a finite numeric value." }
  if ([double]::IsNaN($number) -or [double]::IsInfinity($number)) { throw "$Name must be finite." }
  return $number
}

function Get-AplValidatedDistributionWidth {
  param([object]$Numerator, [object]$Denominator, [double]$MaximumWidth, [string]$Name)
  $value = ConvertTo-AplRequiredFiniteDouble $Numerator "$Name numerator"
  $total = ConvertTo-AplRequiredFiniteDouble $Denominator "$Name denominator"
  if ($value -lt 0) { throw "$Name numerator cannot be negative." }
  if ($total -le 0) { throw "$Name denominator must be greater than zero." }
  $rawWidth = $MaximumWidth * $value / $total
  if ([double]::IsNaN($rawWidth) -or [double]::IsInfinity($rawWidth)) { throw "$Name width must be finite." }
  if ($rawWidth -lt 0 -or $rawWidth -gt $MaximumWidth) { throw "$Name width $rawWidth is outside 0..$MaximumWidth." }
  $width = [math]::Round($rawWidth, 0)
  if ($width -lt 0 -or $width -gt $MaximumWidth) { throw "$Name rounded width $width is outside 0..$MaximumWidth." }
  return $width
}
