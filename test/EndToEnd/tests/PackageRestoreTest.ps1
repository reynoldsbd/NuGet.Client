
function Test-NuGetPackagesConfigNamespace
{
    param($context)

    # Arrange
    $p = New-ConsoleApplication
    
    $projectDirectoryPath = $p.Properties.Item("FullPath").Value
    $projectName = Split-Path -Path $projectDirectoryPath -Leaf
    $projectPath = Join-Path $projectDirectoryPath $projectName".csproj"

    $packagesConfigPath = Join-Path $projectDirectoryPath 'packages.config'
    # Write a file to disk, but do not add it to project
    '<packages>
        <package id="Contoso.MVC.ASP" version="1.0.0" targetFramework="net461" />
        <package id="Contoso.Opensource.Buffers" version="2.0.0" targetFramework="net461" />
        <package id="Foo" version="1.0.0" targetFramework="net461" />
</packages>' | out-file $packagesConfigPath

    $solutionDirectory = Split-Path -Path $projectDirectoryPath -Parent
    $opensourceRepo = Join-Path $solutionDirectory "opensourceRepo"
    $privateRepo = Join-Path $solutionDirectory "privateRepo"

    $nugetConfigPath = Join-Path $solutionDirectory 'nuget.config'

	$settingFileContent =@"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
    <clear />
    <add key="PublicRepository" value="{0}" />
    <add key="PrivateRepository" value="{1}" />
    </packageSources>
    <packageNamespaces>
        <packageSource key="PublicRepository"> 
            <namespace id="Contoso.Opensource.*" />
        </packageSource>
        <packageSource key="PrivateRepository">
            <namespace id="Contoso.MVC.*" />
        </packageSource>
    </packageNamespaces>
</configuration>
"@

	$settingFileContent -f $opensourceRepo,$privateRepo | Out-File -Encoding "UTF8" $nugetConfigPath

    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $privateRepo
    CreateTestPackage "Contoso.Opensource.Buffers" "2.0.0" $opensourceRepo
    CreateTestPackage "Foo" "1.0.0" $opensourceRepo
    # Act
    & $context.NuGetExe restore -SolutionDirectory $solutionDirectory $projectPath

    # Assert
    $packagesFolder = Join-Path $solutionDirectory "packages"
    $contosoMVCNupkgFolder = Join-Path $packagesFolder "Contoso.MVC.ASP.1.0.0"
    Assert-PathExists(Join-Path $contosoMVCNupkgFolder "Contoso.MVC.ASP.1.0.0.nupkg")
    $contosoOpenSourceNupkgFolder = Join-Path $packagesFolder "Contoso.Opensource.Buffers.2.0.0"
    Assert-PathExists(Join-Path $contosoOpenSourceNupkgFolder "Contoso.Opensource.Buffers.2.0.0.nupkg")

    $errorlist = Get-Errors
    Assert-AreEqual 0 $errorlist.Count    

    $warninglist = Get-Warnings
    Assert-AreEqual 0 $warninglist.Count 
}

function Test-NuGetPackagesConfigNamespace2
{
    param($context)

    # Arrange
    $p = New-ConsoleApplication
    
    $projectDirectoryPath = $p.Properties.Item("FullPath").Value
    $projectName = Split-Path -Path $projectDirectoryPath -Leaf
    $projectPath = Join-Path $projectDirectoryPath $projectName".csproj"

    $packagesConfigPath = Join-Path $projectDirectoryPath 'packages.config'
    # Write a file to disk, but do not add it to project
    '<packages>
        <package id="Contoso.MVC.ASP" version="1.0.0" targetFramework="net461" />
</packages>' | out-file $packagesConfigPath

    $solutionDirectory = Split-Path -Path $projectDirectoryPath -Parent
    $opensourceRepo = Join-Path $solutionDirectory "opensourceRepo"
    $privateRepo = Join-Path $solutionDirectory "privateRepo"

    $nugetConfigPath = Join-Path $solutionDirectory 'nuget.config'

	$settingFileContent =@"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
    <clear />
    <add key="OpensourceRepository" value="{0}" />
    <add key="PrivateRepository" value="{1}" />
    </packageSources>
    <packageNamespaces>
        <packageSource key="PrivateRepository">
            <namespace id="Contoso.MVC.*" />
        </packageSource>
    </packageNamespaces>
</configuration>
"@

	$settingFileContent -f $opensourceRepo,$privateRepo | Out-File -Encoding "UTF8" $nugetConfigPath

    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $privateRepo "Thisisfromprivaterepo.txt"
    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $opensourceRepo "Thisisfromopensourcerepo.txt"

    # Act
    & $context.NuGetExe restore -SolutionDirectory $solutionDirectory $projectPath

    # Assert
    $packagesFolder = Join-Path $solutionDirectory "packages"
    $contosoNupkgFolder = Join-Path $packagesFolder "Contoso.MVC.ASP.1.0.0"
    Assert-PathExists(Join-Path $contosoNupkgFolder "Contoso.MVC.ASP.1.0.0.nupkg")
    # Make sure name squatting package from public repo not restored.
    $contentFolder = Join-Path $contosoNupkgFolder "content"
    Assert-PathExists(Join-Path $contentFolder "Thisisfromprivaterepo.txt")

    $errorlist = Get-Errors
    Assert-AreEqual 0 $errorlist.Count    
}

function Test-NuGetPackagesConfigNamespace3
{
    param($context)

    # Arrange
    $p = New-ConsoleApplication
    
    $projectDirectoryPath = $p.Properties.Item("FullPath").Value
    $projectName = Split-Path -Path $projectDirectoryPath -Leaf
    $projectPath = Join-Path $projectDirectoryPath $projectName".csproj"

    $packagesConfigPath = Join-Path $projectDirectoryPath 'packages.config'
    # Write a file to disk, but do not add it to project
    '<packages>
        <package id="Contoso.MVC.ASP" version="1.0.0" targetFramework="net461" />
</packages>' | out-file $packagesConfigPath

    $solutionDirectory = Split-Path -Path $projectDirectoryPath -Parent
    $opensourceRepo = Join-Path $solutionDirectory "opensourceRepo"
    $privateRepo = Join-Path $solutionDirectory "privateRepo"

    $nugetConfigPath = Join-Path $solutionDirectory 'nuget.config'

	$settingFileContent =@"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
    <clear />
    <add key="OpensourceRepository" value="{0}" />
    <add key="PrivateRepository" value="{1}" />
    </packageSources>
</configuration>
"@

	$settingFileContent -f $opensourceRepo,$privateRepo | Out-File -Encoding "UTF8" $nugetConfigPath

    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $privateRepo "Thisisfromprivaterepo.txt"
    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $opensourceRepo "Thisisfromopensourcerepo.txt"

    # Act
    & $context.NuGetExe restore -SolutionDirectory $solutionDirectory $projectPath

    # Assert
    $packagesFolder = Join-Path $solutionDirectory "packages"
    $contosoNupkgFolder = Join-Path $packagesFolder "Contoso.MVC.ASP.1.0.0"
    Assert-PathExists(Join-Path $contosoNupkgFolder "Contoso.MVC.ASP.1.0.0.nupkg")

    $errorlist = Get-Errors
    Assert-AreEqual 0 $errorlist.Count
}

function Test-MSbuildPackagesConfigNamespace
{
    param($context)

    # Arrange
    $p = New-ConsoleApplication
    
    $projectDirectoryPath = $p.Properties.Item("FullPath").Value
    $packagesConfigPath = Join-Path $projectDirectoryPath 'packages.config'
    # Write a file to disk, but do not add it to project
    '<packages>
        <package id="Contoso.MVC.ASP" version="1.0.0" targetFramework="net461" />
        <package id="Contoso.Opensource.Buffers" version="2.0.0" targetFramework="net461" />
        <package id="Foo" version="1.0.0" targetFramework="net461" />
</packages>' | out-file $packagesConfigPath

    $solutionDirectory = Split-Path -Path $projectDirectoryPath -Parent
    $opensourceRepo = Join-Path $solutionDirectory "opensourceRepo"
    $privateRepo = Join-Path $solutionDirectory "privateRepo"

    $testDirectory = Split-Path -Path $solutionDirectory -Parent
    $nugetConfigPath = Join-Path $solutionDirectory 'nuget.config'

	$settingFileContent =@"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
    <clear />
    <add key="PublicRepository" value="{0}" />
    <add key="PrivateRepository" value="{1}" />
    </packageSources>
    <packageNamespaces>
        <packageSource key="PublicRepository"> 
            <namespace id="Contoso.Opensource.*" />
        </packageSource>
        <packageSource key="PrivateRepository">
            <namespace id="Contoso.MVC.*" />
        </packageSource>
    </packageNamespaces>
</configuration>
"@

	$settingFileContent -f $opensourceRepo,$privateRepo | Out-File -Encoding "UTF8" $nugetConfigPath

    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $privateRepo "Thisisfromprivaterepo.txt"
    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $opensourceRepo "Thisisfromopensourcerepo.txt"
    CreateTestPackage "Contoso.Opensource.Buffers" "2.0.0" $opensourceRepo
    CreateTestPackage "Foo" "1.0.0" $opensourceRepo

    # Act
    $MSBuildExe = Get-MSBuildExe
    & "$MSBuildExe" -p:RestorePackagesConfig=true /t:restore    
    Build-Solution

    # Assert
    $packagesFolder = Join-Path $solutionDirectory "packages"
    $contosoMVCNupkgFolder = Join-Path $packagesFolder "Contoso.MVC.ASP.1.0.0"
    Assert-PathExists(Join-Path $contosoMVCNupkgFolder "Contoso.MVC.ASP.1.0.0.nupkg")
    # Make sure name squatting package from public repo not restored.
    $contentFolder = Join-Path $contosoMVCNupkgFolder "content"
    # Assert-PathExists(Join-Path $contentFolder "Thisisfromprivaterepo.txt")
    $contosoOpenSourceNupkgFolder = Join-Path $packagesFolder "Contoso.Opensource.Buffers.2.0.0"
    Assert-PathExists(Join-Path $contosoOpenSourceNupkgFolder "Contoso.Opensource.Buffers.2.0.0.nupkg")
    $fooNupkgFolder = Join-Path $packagesFolder "Foo.1.0.0"
    Assert-PathExists(Join-Path $fooNupkgFolder "Foo.1.0.0.nupkg")

    $errorlist = Get-Errors
    Assert-AreEqual 0 $errorlist.Count    
}

function Test-MSBuildPackagesConfigNamespace2
{
    param($context)

    # Arrange
    $p = New-ConsoleApplication
    
    $projectDirectoryPath = $p.Properties.Item("FullPath").Value
    $projectName = Split-Path -Path $projectDirectoryPath -Leaf
    $projectPath = Join-Path $projectDirectoryPath $projectName".csproj"

    $packagesConfigPath = Join-Path $projectDirectoryPath 'packages.config'
    # Write a file to disk, but do not add it to project
    '<packages>
        <package id="Contoso.MVC.ASP" version="1.0.0" targetFramework="net461" />
</packages>' | out-file $packagesConfigPath

    $solutionDirectory = Split-Path -Path $projectDirectoryPath -Parent
    $opensourceRepo = Join-Path $solutionDirectory "opensourceRepo"
    $privateRepo = Join-Path $solutionDirectory "privateRepo"

    $nugetConfigPath = Join-Path $solutionDirectory 'nuget.config'

	$settingFileContent =@"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
    <clear />
    <add key="OpensourceRepository" value="{0}" />
    <add key="PrivateRepository" value="{1}" />
    </packageSources>
</configuration>
"@

	$settingFileContent -f $opensourceRepo,$privateRepo | Out-File -Encoding "UTF8" $nugetConfigPath

    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $privateRepo "Thisisfromprivaterepo.txt"
    CreateTestPackage "Contoso.MVC.ASP" "1.0.0" $opensourceRepo "Thisisfromopensourcerepo.txt"
    
    # Act
    $MSBuildExe = Get-MSBuildExe   
    & "$MSBuildExe" -p:RestorePackagesConfig=true /t:restore
    Build-Solution

    Assert
    $packagesFolder = Join-Path $solutionDirectory "packages"
    $contosoNupkgFolder = Join-Path $packagesFolder "Contoso.MVC.ASP.1.0.0"
    Assert-PathExists(Join-Path $contosoNupkgFolder "Contoso.MVC.ASP.1.0.0.nupkg")

    $errorlist = Get-Errors
    Assert-AreEqual 0 $errorlist.Count
}

# Tests that packages are restored on build
function Test-PackageRestore-SimpleTest {
    param($context)

    # Arrange
    $p1 = New-ClassLibrary	
    $p1 | Install-Package FakeItEasy -version 1.8.0
    
    $p2 = New-ClassLibrary
    $p2 | Install-Package elmah -Version 1.1

    $p3 = New-ClassLibrary
    $p3 | Install-Package Newtonsoft.Json -Version 5.0.6

    $p4 = New-ClassLibrary
    $p4 | Install-Package Ninject

    # delete the packages folder
    $packagesDir = Get-PackagesDir
    RemoveDirectory $packagesDir
    Assert-False (Test-Path $packagesDir)

    # Act
    Build-Solution

    # Assert
    Assert-True (Test-Path $packagesDir)
    Assert-Package $p1 FakeItEasy
    Assert-Package $p2 elmah
    Assert-Package $p3 Newtonsoft.Json
    Assert-Package $p4 Ninject
}

# Tests that package restore honors PackageSaveMode in config
<#
function Test-PackageRestore-PackageSaveMode {
    param($context)

    try {
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageSaveMode', 'nuspec')

        # Arrange
        $p1 = New-ClassLibrary	
        $p1 | Install-Package FakeItEasy -version 1.8.0
    
        # delete the packages folder
        $packagesDir = Get-PackagesDir
        RemoveDirectory $packagesDir
        Assert-False (Test-Path $packagesDir)
    
        # Act
        Build-Solution

        # Assert	    
        # the nuspec file should exist
        $nuspecFile = Join-Path $packagesDir "FakeItEasy.1.8.0\FakeItEasy.1.8.0.nuspec"
        Assert-PathExists $nuspecFile

        # while the nupkg file should not
        $nupkgFile = Join-Path $packagesDir "FakeItEasy.1.8.0\FakeItEasy.1.8.0.nupkg"
        Assert-False (Test-Path $nupkgFile)
    }
    finally {
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageSaveMode', $null)
    }
    
}
#>

# Tests that package restore works for website project
function Test-PackageRestore-Website {
    param($context)

    # Arrange
    $p = New-WebSite	
    $p | Install-Package JQuery
    
    # delete the packages folder
    $packagesDir = Get-PackagesDir
    Remove-Item -Recurse -Force $packagesDir
    Assert-False (Test-Path $packagesDir)

    # Act
    Build-Solution

    # Assert
    Assert-True (Test-Path $packagesDir)
    Assert-Package $p JQuery
}

# Tests that package restore works for JavaScript Windows Store app project
function Test-PackageRestore-JavaScriptMetroProject {
    param($context)

    if ((Get-VSVersion) -eq '10.0') {
        return
    }

    # Arrange
    $p = New-JavaScriptApplication	
    Install-Package JQuery -projectName $p.Name
    
    # delete the packages folder
    $packagesDir = Get-PackagesDir
    Remove-Item -Recurse -Force $packagesDir
    Assert-False (Test-Path $packagesDir)

    # Act
    Build-Solution

    # Assert
    Assert-True (Test-Path $packagesDir)
    Assert-Package $p JQuery
}

# Tests that package restore works for unloaded projects, as long as
# there is at least one loaded project.
function Test-PackageRestore-UnloadedProjects{
    param($context)

    # Arrange
    $p1 = New-ClassLibrary	
    $p1 | Install-Package Microsoft.Bcl.Build -version 1.0.8
    
    $p2 = New-ClassLibrary

    $solutionFile = Get-SolutionFullName
    $packagesDir = Get-PackagesDir
    SaveAs-Solution($solutionFile)
    Close-Solution

    # delete the packages folder
    Remove-Item -Recurse -Force $packagesDir
    Assert-False (Test-Path $packagesDir)

    # reopen the solution. Now the project that references Microsoft.Bcl.Build
    # will not be loaded because of missing targets file
    Open-Solution $solutionFile

    # Act
    Build-Solution

    # Assert
    $dir = Join-Path $packagesDir "Microsoft.Bcl.Build.1.0.8"
    Assert-PathExists $dir
}

# Tests that an error will be generated if package restore fails
function Test-PackageRestore-ErrorMessage {
    param($context)

    # Arrange
    $p = New-ClassLibrary	
    Install-Package -Source $context.RepositoryRoot -Project $p.Name NonStrongNameB
    
    # delete the packages folder
    $packagesDir = Get-PackagesDir
    Remove-Item -Recurse -Force $packagesDir
    Assert-False (Test-Path $packagesDir)

    # Act
    # package restore will fail because the source $context.RepositoryRoot is not
    # listed in the settings.
    Build-Solution

    # Assert
    $errorlist = Get-Errors
    Assert-AreEqual 1 $errorlist.Count

    $error = $errorlist[$errorlist.Count-1]
    Assert-True ($error.Contains('NuGet Package restore failed for project'))

    $output = Get-BuildOutput
    Assert-True ($output.Contains('NuGet package restore failed.'))
}

# Tests that output does not contain package restore finished
# when there are no missing packages
function Test-PackageRestore-PackageAlreadyInstalled {
    param($context)

    # Arrange
    $p = New-ClassLibrary	
    $p | Install-Package jQuery.Validation

    # Act
    # package restore will just exit as there are no missing packages
    Build-Solution

    # Assert
    $output = Get-BuildOutput
    Assert-True ($output.Contains('All packages are already installed and there is nothing to restore.'))
	Assert-False ($output.Contains('NuGet package restore finished.'))
}

# Test that package restore will check for missing packages when consent is not granted,
# while IsAutomatic is true.
function Test-PackageRestore-CheckForMissingPackages {
    param($context)

    # Arrange
    $p1 = New-ClassLibrary	
    $p1 | Install-Package Newtonsoft.Json -Version 5.0.6
    
    New-SolutionFolder 'Folder1'
    $p2 = New-ClassLibrary 'Folder1'
    $p2 | Install-Package elmah -Version 1.1

    New-SolutionFolder 'Folder1\Folder2'
    $p3 = New-ClassLibrary 'Folder1\Folder2'
    $p3 | Install-Package Ninject

    # delete the packages folder
    $packagesDir = Get-PackagesDir
    RemoveDirectory $packagesDir
    Assert-False (Test-Path $packagesDir)
    
    try {
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageRestoreConsentGranted', 'false')
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageRestoreIsAutomatic', 'true')

        # Act
        Build-Solution

        # Assert
        $errorlist = Get-Errors
        Assert-AreEqual 1 $errorlist.Count

        $error = $errorlist[$errorlist.Count-1]
        Assert-True ($error.Contains('One or more NuGet packages need to be restored but couldn''t be because consent has not been granted.'))
        Assert-True ($error.Contains('Newtonsoft.Json 5.0.6'))
        Assert-True ($error.Contains('elmah 1.1'))
        Assert-True ($error.Contains('Ninject'))
    }
    finally {
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageRestoreConsentGranted', 'true')
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageRestoreIsAutomatic', 'true')
    }
}	

# Tests that package restore is a no-op when setting PackageRestoreIsAutomatic is false.
function Test-PackageRestore-IsAutomaticIsFalse {
    param($context)

    # Arrange
    $p1 = New-ClassLibrary	
    $p1 | Install-Package FakeItEasy -version 1.8.0
    
    $p2 = New-ClassLibrary
    $p2 | Install-Package elmah -Version 1.1

    New-SolutionFolder 'Folder1'
    $p3 = New-ClassLibrary 'Folder1'
    $p3 | Install-Package Newtonsoft.Json -Version 5.0.6

    # delete the packages folder
    $packagesDir = Get-PackagesDir
    RemoveDirectory $packagesDir
    Assert-False (Test-Path $packagesDir)

    try {
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageRestoreIsAutomatic', 'false')

        # Act
        Build-Solution

        # Assert		
        Assert-False (Test-Path $packagesDir)
    }
    finally {
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageRestoreConsentGranted', 'true')
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::Set('PackageRestoreIsAutomatic', 'true')
    }
}

# Test that during package restore, all sources are used.
function Test-PackageRestore-AllSourcesAreUsed {
    param($context)
    
    $tempDirectory = $Env:temp
    $source1 = Join-Path $tempDirectory ([System.IO.Path]::GetRandomFileName())
    $source2 = Join-Path $tempDirectory ([System.IO.Path]::GetRandomFileName())

    try {
        # Arrange		
        New-Item $source1 -ItemType directory
        New-Item $source2 -ItemType directory
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::AddSource('testSource1', $source1);
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::AddSource('testSource2', $source2);	
        CreateTestPackage 'p1' '1.0' $source1
        CreateTestPackage 'p2' '1.0' $source2
        
        # Arrange
        # create project and install packages
        $proj = New-ClassLibrary
        $proj | Install-Package p1 -source testSource1
        $proj | Install-Package p2 -source testSource2
        Assert-Package $proj p1
        Assert-Package $proj p2

        # Arrange
        # delete the packages folder
        $packagesDir = Get-PackagesDir
        RemoveDirectory $packagesDir
        Assert-False (Test-Path $packagesDir)

        # Act
        Build-Solution

        # Assert
        # both p1 and p2 are restored
        Assert-True (Test-Path (Join-Path $packagesDir 'p1.1.0' ))
        Assert-True (Test-Path (Join-Path $packagesDir 'p2.1.0' ))

        Write-Host 'It is done!'
    }
    finally
    {
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::RemoveSource('testSource1')
        [NuGet.PackageManagement.VisualStudio.SettingsHelper]::RemoveSource('testSource2')		
        RemoveDirectory $source1
        RemoveDirectory $source2

        # change active package source to "All"
        # $componentService = Get-VSComponentModel
        #$packageSourceProvider = $componentService.GetService([NuGet.PackageManagement.VisualStudio.IVsPackageSourceProvider])
        #$packageSourceProvider.ActivePackageSource = [NuGet.PackageManagement.VisualStudio.AggregatePackageSource]::Instance
    }
}

# Create a test package 
function CreateTestPackage {
    param(
        [string]$id,
        [string]$version,
        [string]$outputDirectory,
        [string]$requestAdditionalContent
    )

    $builder = New-Object NuGet.Packaging.PackageBuilder
    $builder.Authors.Add("test_author")
    $builder.Id = $id
    $builder.Version = [NuGet.Versioning.NuGetVersion]::Parse($version)
    $builder.Description = "description" 

    # add one content file
    $tempFile = [IO.Path]::GetTempFileName()
    "test" >> $tempFile
    $packageFile = New-Object NuGet.Packaging.PhysicalPackageFile
    $packageFile.SourcePath = $tempFile
    $packageFile.TargetPath = "content\$id-test1.txt"
    $builder.Files.Add($packageFile)

    if($requestAdditionalContent)
    {
        # add one content file
        $tempFile2 = [IO.Path]::GetTempFileName()
        "test" >> $tempFile2        
        $packageFile = New-Object NuGet.Packaging.PhysicalPackageFile
        $packageFile.SourcePath = $tempFile2
        $packageFile.TargetPath = "content\$requestAdditionalContent"
        $builder.Files.Add($packageFile)
    }

    if(-not(Test-Path $outputDirectory))
    {
        New-Item -Path $outputDirectory -ItemType Directory
    }

    $outputFileName = Join-Path $outputDirectory "$id.$version.nupkg"
    $outputStream = New-Object IO.FileStream($outputFileName, [System.IO.FileMode]::Create)
    try {
        $builder.Save($outputStream)
    }
    finally
    {
        $outputStream.Dispose()
        Remove-Item $tempFile
        if($tempFile2)
        {
            Remove-Item $tempFile2
        }
    }
}

function RemoveDirectory {
    param($dir)

    $iteration = 0
    while ($iteration++ -lt 10)
    {
        if (Test-Path $dir)
        {
            # because -Recurse parameter in Remove-Item has a known issue so using Get-ChildItem to
            # first delete all the children and then delete the folder.
            Get-ChildItem $dir -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
        }
        else 
        {
            break;
        }
    }
}