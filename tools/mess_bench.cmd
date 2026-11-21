@echo off
rem The Mess benchmark on this PC (core/31; docs/human/mess-benchmark.md). Double-click it, or run
rem it from a terminal in the game's folder. It runs every scenario in a window (so draw calls and
rem whole frames are measured on the real graphics card), with Godot's worker threads capped at 4
rem (an override.cfg beside project.godot, removed afterwards), and writes
rem builds\mess-bench\report.md. Leave the PC alone while it runs (a few minutes).
rem
rem   tools\mess_bench.cmd                         every scenario
rem   tools\mess_bench.cmd --only=idle_500,sweep   those scenarios
rem   tools\mess_bench.cmd --list                  the scenarios
rem   tools\mess_bench.cmd --label=my-pc           the run's name in the report (default "pc")
rem
rem The engine: set GODOT to the Godot 4.7 console exe, or put it in extras\ (any
rem Godot_v4.7*win64*console.exe there is taken).
setlocal enabledelayedexpansion
cd /d "%~dp0.."
if not defined GODOT (
	for %%f in (extras\Godot_v4.7*win64*console.exe) do set "GODOT=%%f"
)
if not defined GODOT (
	for %%f in (extras\Godot_v4.7*win64*.exe) do set "GODOT=%%f"
)
if not defined GODOT (
	echo No Godot 4.7 found: set GODOT to its exe, or put Godot_v4.7.x-stable_win64.exe and its console exe in extras\
	pause
	exit /b 2
)
if exist override.cfg (
	echo There is an override.cfg beside project.godot already; move it away first.
	pause
	exit /b 2
)
set "LABEL=--label=pc"
for %%a in (%*) do (
	set "ARG=%%~a"
	if "!ARG:~0,8!"=="--label=" set "LABEL="
)
set "COMMIT="
for /f %%c in ('git rev-parse --short HEAD 2^>nul') do set "COMMIT=--commit=%%c"
(
echo [threading]
echo worker_pool/max_threads=4
) > override.cfg
if not exist builds\mess-bench mkdir builds\mess-bench
"%GODOT%" --path . --fixed-fps 10 --resolution 1280x720 res://game/debug/mess_bench.tscn -- --out=builds/mess-bench %LABEL% %COMMIT% %*
set "CODE=%ERRORLEVEL%"
del override.cfg
echo.
echo Report: "%CD%\builds\mess-bench\report.md"
pause
exit /b %CODE%
