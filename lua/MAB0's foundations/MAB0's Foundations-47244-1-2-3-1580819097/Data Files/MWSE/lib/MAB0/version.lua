local this = {
  version = {
    major = 1,
    minor = 2,
    patch = 3
  }
}

this.toString = function( version )
  return string.format( "%d.%d.%d", version.major, version.minor, version.patch )
end

this.areRequiredAndProvidedVersionsCompatible = function( requiredVersion, otherVersion )
  if( requiredVersion.major > otherVersion.major ) then return false end
  if( requiredVersion.major < otherVersion.major ) then return true end

  if( requiredVersion.minor > otherVersion.minor ) then return false end
  if( requiredVersion.minor < otherVersion.minor ) then return true end

  if( requiredVersion.patch > otherVersion.patch ) then return false end

  return true
end

return this