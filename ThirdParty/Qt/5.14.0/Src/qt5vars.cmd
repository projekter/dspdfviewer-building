REM Set up Microsoft Visual Studio 2017, where <arch> is amd64, x86, etc.
CALL "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x86
SET _ROOT=D:\MSVC\ThirdParty\Qt\5.14.0\Src
SET PATH=%_ROOT%\qtbase\bin;%_ROOT%\gnuwin32\bin;%PATH%
SET _ROOT=