:: PLEASE SOMEONE FIND THE TIME TO REPLACE THIS WITH ANOTHER SCRIPTING LANGUAGE :(

:: Argument %1: path to template folder
:: Argument %2: path to dynamo build directory
::

@echo off
if not "%2"=="" goto :harvestpathdefined

echo The path to the Dynamo dlls was not specified. Using the dlls in the harvest directory...
:: Get the bin release folder path for building symbol nupkg
set releasePath=..\..\bin\AnyCPU\Release
:: Get the harvest folder path for building rumtime nupkg
set harvestPath=..\..\src\DynamoInstall\harvest

if not exist %harvestPath% (
  echo Dynamo\src\DynamoInstall\harvest folder not found.
  echo Please build Dynamo\src\Install.sln before running this script!
  exit /b 1
)
goto :build

:: When the second argument for running the batch file exists, update both paths to use argument
:harvestpathdefined
set harvestPath=%2
set releasePath=%2

:build
:: Get version string from "DynamoCore.dll"
set count=1
for /f %%f in ('cscript //Nologo ..\install\GetFileVersion.vbs %harvestPath%\DynamoCore.dll') do (
  setlocal EnableDelayedExpansion
  if !count!==1 set Major=%%f
  if !count!==2 set Minor=%%f
  if !count!==3 set Build=%%f
  if !count!==4 set Revision=%%f
  set /a count=!count!+1
)
setlocal DisableDelayedExpansion
set version=%Major%.%Minor%.%Build%-beta%Revision%

for /f %%i in ('git rev-parse HEAD') do set COMMIT=%%i

echo %COMMIT%
:: Get target framework from build.xml
for /f %%f in ('cscript //Nologo .\GetTargetFramework.vbs ..\..\src\build.xml') do (
  setlocal EnableDelayedExpansion
  set targetFramework=%%f
)
setlocal DisableDelayedExpansion

:: Clean files generated from the previous run
if exist *.nupkg ( del *.nupkg )

echo %1|find ".nuspec" >nul
if errorlevel 1 (goto :packfolder) else (goto:packsingle_nuspec)

:packsingle_nuspec
nuget pack %1 -basepath %harvestPath% -properties gitcommitid=%COMMIT%;Version=%version%;TargetFramework=%targetFramework%
:packfolder
:: Pack .nupkg files based on each .nuspec in the "nuspec" folder
for %%f in (%1\*.nuspec) do (
  :: Check if nuspec file name containing "Symbols"
  echo %%f|find "Symbols" >nul
  :: When nuget pack symbols, set to release path where the symbol files live
  if errorlevel 1 ( nuget pack %%f -basepath %harvestPath% -properties gitcommitid=%COMMIT%;Version=%version%;TargetFramework=%targetFramework%) else (nuget pack %%f -basepath %releasePath% -properties Version=%version%;TargetFramework=%targetFramework%)
  if not exist %%~nf.%version%.nupkg (
    exit /b 1
  )
)
