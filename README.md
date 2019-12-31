This gives an exhaustive manual of how to build `dspdfviewer` from almost scratch under Windows. This means that all third-party libraries need to be obtained as source code.
# Requirements
- I compiled everything with **Microsoft Visual Studio Community 2019**.
This compiler complies with C++17, so there should be no issues in this regards. However, compilation will also work for older versions (even 2013 with adjustments). For the MSVC 2015, see an older version of this document.
- The **CMake** build system is required and needs to be properly set up.
- A **diff program** for inspecting the differences between files is highly recommended, for example [WinMerge](https://winmerge.org/).
- All of the builds are done in **32-bit mode**. Some of the third-party software might not run in 64-bit mode, while others will do. Mixing is of course not possible, but if someone is interested only in a standalone library of some of the dependencies, the 64-bit mode may be tried.
- The manual gives instructions for building **Release mode** only, but compiling in Debug mode will also work. See the previous version of this document that explicitly talks about Debug mode.
- The build is performed in the **static mode**. This means that **no DLLs** are produced, but instead LIB files. Those files are compiler-specific - hence, if you don't want to build some of the libraries because you have found a pre-compiled version in the Internet, be sure that it targets exactly the same compiler version.
Under Windows, there is also a problem related to runtime-libraries, namely the `MD` and `MT` mode. In general, dynamic libraries, should be compiled in the `MD` mode and static libraries in the `MT` mode. However, this is not enforced by the linker. If you have a source which uses a different compilation, you will _in the best case_ get linker warnings about multiply-defined functions. All libraries here are build in the `MT` mode. This is not native to most of them. Therefore, some lines will need to be inserted into the `CMakeLists.txt` at appropriate positions, which ensure that they are compiled correctly:
  ```cmake
  foreach(var CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
    CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO)
    if(${var} MATCHES "/MD")
      string(REGEX REPLACE "/MD" "/MT" ${var} "${${var}}")
    endif()
  endforeach()
  ```
    This should ideally be placed within some `if(MSVC)` section. When these lines are inserted, the line endings should be conserved!
    More on this also in the next bullet.
- The third-party libraries are **not included in this repository**, because I don't want to keep them updated, and perhaps also because of licensing issues. All of the following instructions contains a link to the original sources which at the time of this writing was valid. If it no longer is, just search for the library name.
The subdirectories provided in this repository mimic the directory structure as it is supposed to be - apart from the version numbers, which will of course increase as time passes - in the end. The directories also contain files, mostly `CMakeLists.txt`, which _serve as an illustration_. You process should be as follows:
  - Clone this repository somewhere
  - Create a root folder where you wish to put all your dependencies to. If you use this manual for compiling `dspdfviewer` and do not just want to find an explanation for one of the third-party libraries, I **recommend that you call this root folder `ThirdParty` and that you clone `dspdfviewer` such that its main folder is on the same level as `ThirdParty`**.
  - While following this manual, download the dependencies into a subfolder of you root, which should be called something like `[name]-[version]`.
  - If you are supposed to adjust something in a file, this is described in the manual. Run a diff between the file in this repository and the one you downloaded. Search for the adjustment that is described in the manual and merge it appropriately. For example, you can find recommendations where to put the `MD > MT` replacement. If you are asked to change it via the Visual Studio property page, it is under `C/C++ > Code generation > Runtime library`; remember to select the correct build environment and platform (all platforms is best, if you want to try the x64-version as well). Do not just copy the illustrative files from this repository unless the version is exactly the same as the one you downloaded!
  - When entering the given console commands, the **current working directory is supposed to be the one you extracted the library to**. Lots of lines given here are terminated with `^`; this indicates a continued command in the Windows cmd. Hence, most of the times you can directly copy-and-paste the whole command-line block to the prompt. For this purpose, I use `%cd:\=/%` lots of times, which actually evaluates to the current absolute path - typically, you do not have to adjust anything in the command, regardless of absolute path you are really in; otherwise, you will be instructed to do so. (This is why it is important that you change the cwd before correctly!)
  - I usually say 

    > compile `ALL_BUILD` and `INSTALL` in `Release` mode

    This means that you should first switch to `Release` mode (because `Debug` is selected by default), then compile `ALL_BUILD` and `INSTALL`.
- The paths which I give are either relative to the current library directory or, if they begin with `compiled`, to the `compiled` directory which is a subdirectory of your chosen root (i.e. on the same level as the library directory).

# Third party libraries
1. [Boost](https://www.boost.org/)
  This is the second largest library, compilation will take some time. This task may run in the background, the results are not required before the final compilation step.
    - ```console
      bootstrap
      b2 variant=release link=static runtime-link=static
      ```
      We use the standard boost toolchain for the compilation.
    - The "installation" is done manually. Move (or better, [create a junction](https://schinagl.priv.at/nt/hardlinkshellext/linkshellextension.html)) the `stage/lib` folder to `compiled/boost`.
      Create the folder `compiled/boost/include` and move the subdirectory `boost` into it.

2. Build [zlib](https://zlib.net/)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`
    - ```console
      mkdir build && cd build
      cmake -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/zlib -A Win32 ..
      ```
    - open `build/zlib.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode (note that both zlib and zlibstatic are built with MT)
    - delete `compiled/zlib/lib/zlib.lib` and remove the `static` suffix from the other
    - change `compiled/zlib/include/zconf.h`: change `#define ZEXTERN` (probably l. 379) to an empty define

3. Build [libpng](http://www.libpng.org/pub/png/libpng.html)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`
    - ```console
      mkdir build && cd build
      cmake ^
         -DZLIB_ROOT:PATH=%cd:\=/%/../../compiled/zlib ^
         -DPNG_SHARED:BOOL=OFF -DPNG_STATIC:BOOL=ON ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/libpng ^
         -A Win32 ^
         ..
      ```
    - open `build/libpng.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode

4. Build [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo)

  **optional, not needed:** `poppler` will not work with `libjpeg` (or this replacement) and none of the following steps use this library anywhere. Therefore, this step can be skipped. However, if the problem described later on is someday fixed, that's how to build it. _In principle_, the following libraries can be configured to use `libjpeg`, therefore this would be the correct position for building.
  Requires [nasm](http://www.nasm.us/) for the "turbo"!
    - ```console
      mkdir build && cd build
      cmake -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/libjpeg-turbo -A Win32 ..
      ```
    - open `build/libjpeg-turbo.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode

5. Build [freetype](http://download.savannah.gnu.org/releases/freetype/)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`. Keep the Linux line endings!
    - ```console
      mkdir build && cd build
      cmake ^
         -DZLIB_ROOT:PATH=%cd:\=/%/../../compiled/zlib ^
         -DPNG_PNG_INCLUDE_DIR=%cd:\=/%/../../compiled/libpng/include ^
         -DPNG_LIBRARY=%cd:\=/%/../../compiled/libpng/lib/libpng16_static.lib ^
         -DCMAKE_DISABLE_FIND_PACKAGE_BZip2:BOOL=ON ^
         -DBUILD_SHARED_LIBS:BOOL=OFF ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/freetype ^
         -A Win32 ^
         ..
      ```
    - open `build/freetype.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode

6. Build [XZ (LZMA)](https://tukaani.org/xz/)
    - open `windows/vs2017/xz_win.sln` (use the automatic upgrade)
    - build `liblzma` in `Release_MT` mode
    - move `windows/ReleaseMT/Win32/liblzma.lib` to `compiled/lzma/lib/liblzma.lib`
    - copy the content of `src/liblzma/api` to `compiled/lzma/include`
    - add `#define LZMA_API_STATIC` to `compiled/lzma/include/lzma.h`

7. Build [TIFF](http://download.osgeo.org/libtiff/)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`.
    - ```console
      cd build
      cmake ^
         -DZLIB_ROOT:PATH=%cd:\=/%/../../compiled/zlib ^
         -Djpeg12:BOOL=OFF ^
         -Djbig:BOOL=OFF ^
         -Djpeg:BOOL=OFF ^
         -DLIBLZMA_INCLUDE_DIR=%cd:\=/%/../../compiled/lzma/include ^
         -DLIBLZMA_LIBRARY=%cd:\=/%/../../compiled/lzma/lib/liblzma.lib ^
         -DBUILD_SHARED_LIBS:BOOL=OFF ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/tiff ^
         -A Win32 ^
         ..
      ```
    - open `build/tiff.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode

8. Build [libiconv](https://www.gnu.org/software/libiconv/#downloading)

  This is going to be bad, as the GNU projects still use the old `configure`/`make` mechanism instead of `cmake`.
  You can download the [Visual Studio project folder and the patch file on GitHub](https://github.com/winlibs/libiconv).
  Now there are two ways:
  - You can find the `libiconv.diff` which essentially should do everything that `configure` does.
    If you want to take this path, first overwrite the `source` folder with the current `libiconv` (leaving old files present).
    Then apply the patch ([GnuWin](http://gnuwin32.sourceforge.net/packages.html) contains `patch.exe`) in the following way:
      - Convert all files that are about to be patched to Windows line endings, including the patch file itself (all better editors will have a function for this, a nice free one is [Programmer's Notepad](http://www.pnotepad.org/)). `patch` will report any file which is not in the proper ending, or just fail with an assertion failure.
        The list of all files can be found right at the beginning of the patch file.
      - ```console
        patch -i libiconv.diff
        ```
    - Some files used by the patch were based on the old versions - the ones that originally had a `.in` ending and should have been created via `configure`.
      Do a three-way-comparison with you diff program with the files `config.h`, `iconv.h` and `localcharset.h` (first: `.in` file of the GitHub archive; second: patched version of the GitHub archive; third: `.in` file of the most recent version). They are located in `source/`, `source/include/`, and `source/lib/`, respectively (the patch wrongly creates all of them in the current folder).
      Check which definitions have to be adapted and merge accordingly. This will take some time, especially for the `config.h`. The files in this repository is what I made out of the steps above for the version of the library indicated by the directory name.
  - Alternatively, if you have Cygwin, you can run `configure` by yourself.
    For this path, _replace_ the `source` folder with the current `libiconv` (removing all previous files).
    - Keep in mind that you are in a cmd with the Visual Studio variables properly set. In this command line, now run Cygwin.
    - Go to the `source/build-aux` folder.
    - ```console
      chmod a+x ar-lib compile
      cd ..
      win32_target=_WIN32_WINNT_WIN10
      ./configure --host=i686-w64-mingw32 \
            CC="cl -nologo" \
            CFLAGS="-MT" \
            CXX="cl -nologo" \
            CXXFLAGS="-MT" \
            CPPFLAGS="-D_WIN32_WINNT=$win32_target" \
            LD="link" \
            NM="dumpbin -symbols" \
            STRIP=":" \
            AR="<full path to source>/build-aux/ar-lib lib" \
            RANLIB=":"
      ```
      where you have to replace `<full path to source>` accordingly. This will create all necessary files.
    - Proceed as described below; the include path is not set up properly, so that the `localcharset.h` is not found. It is located in `source/libcharset/include`; adjust the two `#includes` and the project file accordingly.
  - open `MSVC16/libiconv.sln`
  - change `libiconv_static` build properties toand `MT` for both `Release` mode
  - compile `libiconv_static` in `Release` mode
  - copy `source/include/iconv.h` to `compiled/libiconv/include/`
  - copy `MSVC16/Win32/lib/libiconv_a.lib` to `compiled/libiconv/lib`

9. [Qt](https://www.qt.io/download)

  This step will take most time, as Qt is a huge library. It is best to use a separate cmd and let it continue in the background.
  Apart from Boost (whose compilation will probably still run in the background), all packages previously compiled are required, so this is the earliest point at which you can compile Qt. (Note that strictly speaking, you need none, but then Qt will duplicate functionality, and this may not only be redundant but in fact lead to problems, see #99.)
    - Download the online installer, then use it to download the Qt sources into `ThirdParty/Qt`.
    - The downloader will create a subdirectory `<version>/Src/`. You have to create `<version>/build/` and `<version>/install/` by yourself.
    - The working directory will be `<version>/build`.
    - As described on the [Qt for Windows](https://doc.qt.io/qt-5/windows-building.html) page, create an appropriate `qt5vars.cmd` script. Be sure to point to the correct version of Visual Studio (here, 2019 and x86). Also adjust the _ROOT variable appropriately. Then run this script.
    - Replace `-MD` with `-MT` in `Src/qtbase/mkspecs/common/msvc-destkop.conf`
    - ```console
      ..\Src\configure ^
         -prefix %cd:\=/%/../../../compiled/qt5 ^
         -static ^
         -release ^
         -platform win32-msvc ^
         -nomake tools ^
         -nomake examples ^
         -nomake tests ^
         -silent ^
         ZLIB_PREFIX=%cd:\=/%/../../../compiled/zlib ^
         ICONV_PREFIX=%cd:\=/%/../../../compiled/libiconv ^
         FREETYPE_PREFIX=%cd:\=/%/../../../compiled/freetype ^
         LIBJPEG_PREFIX=%cd:\=/%/../../../compiled/libjpeg-turbo ^
         LIBPNG_PREFIX=%cd:\=/%/../../../compiled/libpng ^
         TIFF_PREFIX=%cd:\=/%/../../../compiled/tiff
      nmake
      nmake install
      ```
      The first line configures Qt to build without tools, examples, and tests. You may also want to exclude other irrelevant parts of the library, but I didn't investigate which ones are required for poppler.
      It also specifies not to use the built-in libraries but the ones we built by ourselves - there's no need for Qt to duplicate parts that we need anyways.
      
      Note that the second command will take several hours. You may try to speed it up by giving the additional `configure` option `-mp`, which then makes use of all processors.

10. Build [expat](https://github.com/libexpat/libexpat) (`expat` subdirectory)
    - ```console
      mkdir build && cd build
      cmake ^
         -DEXPAT_SHARED_LIBS:BOOL=OFF ^
         -DEXPAT_BUILD_EXAMPLES:BOOL=OFF ^
         -DEXPAT_BUILD_TESTS:BOOL=OFF ^
         -DEXPAT_MSVC_STATIC_CRT:BOOL=ON ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/expat ^
         -A Win32 ^
         ..
      ```
    - open `build/expat.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode

11. Build [LCMS2](http://www.littlecms.com/download.html)
    - open `Projects/VC2017/lcms2.sln` (use the automatic upgrade)
    - change `lcms2_static` build properties to `MT` for `Release` mode
    - build `lcms2_static` in `Release` mode
    - move `Lib/MS/*` to `compiled/lcms2/lib`
    - copy `include` folder to `compiled/lcms2`
   
12. Build [OpenJPEG](https://github.com/uclouvain/openjpeg)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`.
    - In order to compile the executables, the dependence on `LZMA` needs to be made explicit. Go to `src/bin/jp2/CMakeLists.txt` and add
      ```cmake
      find_package(LibLZMA)
      ```
      before the foreach loop and
      ```cmake
      ${LIBLZMA_LIBRARIES}
      ```
      to the first `target_link_libraries` line within the loop.
    - ```console
      mkdir build && cd build
      cmake ^
         -DZLIB_ROOT:PATH=%cd:\=/%/../../compiled/zlib ^
         -DPNG_PNG_INCLUDE_DIR=%cd:\=/%/../../compiled/libpng/include ^
         -DPNG_LIBRARY=%cd:\=/%/../../compiled/libpng/lib/libpng16_static.lib ^
         -DCMAKE_MODULE_PATH=%cd:\=/%/../../compiled/libpng/lib/libpng ^
         -DLCMS2_LIBRARY=%cd:\=/%/../../compiled/lcms2/lib/lcms2_static.lib ^
         -DLCMS2_INCLUDE_DIR=%cd:\=/%/../../compiled/lcms2/include ^
         -DTIFF_INCLUDE_DIR=%cd:\=/%/../../compiled/tiff/include ^
         -DTIFF_LIBRARY=%cd:\=/%/../../compiled/tiff/lib/tiff.lib ^
         -DLIBLZMA_INCLUDE_DIR=%cd:\=/%/../../compiled/lzma/include ^
         -DLIBLZMA_LIBRARY=%cd:\=/%/../../compiled/lzma/lib/liblzma.lib ^
         -DBUILD_SHARED_LIBS:BOOL=OFF ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/openjpeg ^
         -A Win32 ^
         ..
      ```
    - open `build/OPENJPEG.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode

13. Build [pixman](https://www.cairographics.org/releases/)
    - download the [MSVC solution](https://github.com/DomAmato/Cairo-VS)
    - create `build` folder and copy the files from `projects/pixman/` to it
    - open `build/pixman.vcxproj` and `build/pixman.vcxproj.filters` with a text editor and remove the string `..\pixman\` from it (replace with empty string)
    - open `build/pixman.vcxproj` with a text editor. Change `<RootNamespace>` tag to `<ProjectName>`, remove `<TargetPlatformVersion>`.
    - open `build/pixman.vcxproj` (use the automatic upgrade)
    - change `pixman` build properties to `MT` for `Release` mode
    - compile `pixman_[version]` both in `Release` mode
    - copy `pixman/pixman.h` and `pixman/pixman-version.h` to `compiled/pixman/include/`
    - copy `build/Release/pixman_[version].lib` to `compiled/pixman/lib/pixman-1.lib`

14. Build [cairo](https://www.cairographics.org/releases/)
    - use the MSVC solution from `pixman`
    - copy the files from `projects/cairo/` to `build`, `projects/cairo/src/` to `src`
    - open `build/cairo.vcxproj` and `build/cairo.vcxproj.filters` with a text editor and remove the string `..\cairo\` from it. `cairo-features.h` is listed twice; neither is correct. Remove one, change the other to `..\src\cairo-features.h`.
    - open `build/cairo.vcxproj` with a text editor. Change `<RootNamespace>` tag to `<ProjectName>`, remove `<TargetPlatformVersion>`.
    - open `build/cairo.vcxproj`
    - change `cairo` build properties to `MT` for `Release` mode, for all platforms
    - change `cairo` VC++ directories to point to the appropriate `include` in `compiled` (change `src` to `..\src`; `freetype` needs to point to the `freetype2`-subdirectory)
    - compile `cairo` in `Release` mode
    - copy `build/Release/cairo.lib` to `compiled/cairo/lib/`
    - copy to `compiled/cairo/include/cairo` from `src/`:
      - `cairo.h`
      - `cairo-deprecated.h`
      - `cairo-features.h`
      - `cairo-ft.h`
      - `cairo-pdf.h`
      - `cairo-ps.h`
      - `cairo-script.h`
      - `cairo-svg.h`
      - `cairo-version.h`
      - `cairo-win32.h`

15. Build [curl](https://curl.haxx.se/download.html)
    
    CURL is not strictly required by poppler, but may be used if present.
    - ```console
      cmake ^
         -DCURL_STATIC_CRT:BOOL=ON ^
         -DBUILD_SHARED_LIBS:BOOL=OFF ^
         -DBUILD_TESTING:BOOL=OFF ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/curl ^
         -A Win32 ^
         ..
      ```
    - open `build/CURL.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode

16. Build [poppler](https://poppler.freedesktop.org/)
    - Change some sources:
      - `qt5/src/poppler-export.h`
        remove all `dllimport/export` and keep only the empty defines
      - `poppler/JPEG2000Stream.h`
        before the first include, add
        ```c
        #define OPJ_STATIC
        ```
      - `CMakeLists.txt`
        before `target_link_libraries(poppler ...)`
        ```cmake
        set(poppler_LIBS ${poppler_LIBS} optimized "${CMAKE_SOURCE_DIR}/../compiled/qt5/lib/qtpcre2.lib"
                                         optimized "${CMAKE_SOURCE_DIR}/../compiled/qt5/lib/qtharfbuzz.lib"
                                         optimized "${CMAKE_SOURCE_DIR}/../compiled/qt5/plugins/platforms/qwindows.lib"
                                         optimized "${CMAKE_SOURCE_DIR}/../compiled/lzma/lib/liblzma.lib"
                                         "WS2_32.Lib"
                                         "OpenGL32.Lib"
                                         "MSImg32.Lib"
                                         "Imm32.lib"
                                         "Winmm.lib")
        ```
    - checkout the poppler test data to `testdata`
      ```console
      git clone git://git.freedesktop.org/git/poppler/test
      ```
      (move so that the `test` subdirectory disappears)
    - note adding the `MD > MT` patch does not seem to work, therefore it is done manually on the
   command line.
    - ```console
      mkdir build && cd build
      cmake -DBUILD_CPP_TESTS=OFF ^
         -DBUILD_QT5_TESTS:BOOL=OFF ^
         -DBUILD_GTK_TESTS:BOOL=OFF ^
         -DENABLE_CPP:BOOL=OFF ^
         -DENABLE_GLIB:BOOL=OFF ^
         -DENABLE_UTILS:BOOL=OFF ^
         -DBUILD_SHARED_LIBS:BOOL=OFF ^
         -DCMAKE_CXX_FLAGS_DEBUG:STRING="/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1" ^
         -DCMAKE_CXX_FLAGS_MINSIZEREL:STRING="/MT /O1 /Ob1 /D NDEBUG -DQT_NO_DEBUG" ^
         -DCMAKE_CXX_FLAGS_RELEASE:STRING="/MT /O2 /Ob2 /D NDEBUG -DQT_NO_DEBUG" ^
         -DCMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING="/MT /Zi /O2 /Ob1 /D NDEBUG -DQT_NO_DEBUG" ^
         -DBoost_INCLUDE_DIR:PATH=%cd:\=/%/../../compiled/boost/include ^
         -DCAIRO_INCLUDE_DIR:FILEPATH=%cd:\=/%/../../compiled/cairo/include ^
         -DCAIRO_LIBRARY:FILEPATH=%cd:\=/%/../../compiled/cairo/lib/cairo.lib ^
         -DFONT_CONFIGURATION:STRING=win32 ^
         -DFREETYPE_INCLUDE_DIR_freetype2:PATH=%cd:\=/%/../../compiled/freetype/include/freetype2 ^
         -DFREETYPE_INCLUDE_DIR_ft2build:PATH=%cd:\=/%/../../compiled/freetype/include/ ^
         -DFREETYPE_LIBRARY:FILEPATH=%cd:\=/%/../../compiled/freetype/lib/freetype.lib ^
         -DLCMS2_INCLUDE_DIR:PATH=%cd:\=/%/../../compiled/lcms2/include ^
         -DLCMS2_LIBRARIES:FILEPATH=%cd:\=/%/../../compiled/lcms2/lib/lcms2_static.lib ^
         -DPNG_PNG_INCLUDE_DIR=%cd:\=/%/../../compiled/libpng/include ^
         -DPNG_LIBRARY=%cd:\=/%/../../compiled/libpng/lib/libpng16_static.lib ^
         -DTIFF_INCLUDE_DIR:PATH=%cd:\=/%/../../compiled/tiff/include ^
         -DTIFF_LIBRARY:FILEPATH=%cd:\=/%/../../compiled/tiff/lib/tiff.lib ^
         -DJPEG_INCLUDE_DIR:PATH=%cd:\=/%/../../compiled/libjpeg-turbo/include ^
         -DJPEG_LIBRARY:FILEPATH=%cd:\=/%/../../compiled/libjpeg-turbo/lib/jpeg-static.lib ^
         -DOpenJPEG_DIR:PATH=%cd:\=/%/../../compiled/openjpeg/lib/openjpeg-2.3 ^
         -DCURL_INCLUDE_DIR:PATH=%cd:\=/%/../../compiled/curl/include ^
         -DCURL_LIBRARY:FILEPATH=%cd:\=/%/../../compiled/curl/lib/libcurl.lib ^
         -DZLIB_ROOT:PATH=%cd:\=/%/../../compiled/zlib ^
         -DQt5Core_DIR:PATH=%cd:\=/%/../../compiled/qt5/lib/cmake/Qt5Core ^
         -DQt5Gui_DIR:PATH=%cd:\=/%/../../compiled/qt5/lib/cmake/Qt5Gui ^
         -DQt5Test_DIR:PATH=%cd:\=/%/../../compiled/qt5/lib/cmake/Qt5Test ^
         -DQt5Widgets_DIR:PATH=%cd:\=/%/../../compiled/qt5/lib/cmake/Qt5Widgets ^
         -DQt5Xml_DIR:PATH=%cd:\=/%/../../compiled/qt5/lib/cmake/Qt5Xml ^
         -DPOPPLER_DATADIR:STRING=./share/poppler/ ^
         -DTESTDATADIR:STRING=%cd:\=/%/../testdata/ ^
         -DENABLE_LIBOPENJPEG:STRING=openjpeg2 ^
         -Wno-dev ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/poppler ^
         -A Win32 ^
         ..
      ```
    - open `build/poppler.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Release` mode

17. Use [poppler-data](https://poppler.freedesktop.org/)

    Do not forget that the poppler encoding data are necessary for some encodings. Download them, but this is nothing to be compiled, they need to be provided with the application in the subdirectory `share/poppler` (so the four folders `cidToUnicode`, `cMap`, `nameToUnicode` and `unicodeMap` need to be in `[exe folder]/share/poppler`).

# dspdfviewer
Finally, we are ready. The `compiled`-subdirectory now holds the precious libraries.
Clone my `dspdfviewer` fork such that the `dspdfviewer` folder is located at the same level as the third-party folder.
Go to the directory where you cloned my `dspdfviewer` fork. If this directory is at the same level as the third-party root directory which is named `ThirdParty` as I suggested above, nothing needs to be changed. Else, adjust `cmake/external_libraries.cmake` and `cmake/filelists.cmake` appropriately to contain the correct folders pointing to poppler and all the other libraries. After that, generate the projects (where probably the names of the Boost libraries need to be adjusted):
```console
cmake ^
   -DBoostStaticLink:BOOL=ON ^
   -DBoost_INCLUDE_DIR=%cd:\=/%/../../ThirdParty/compiled/boost/include ^
   -DBoost_LIBRARY_DIR_RELEASE=%cd:\=/%/../../ThirdParty/compiled/boost/lib ^
   -DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE=%cd:\=/%/../../ThirdParty/compiled/boost/lib/libboost_program_options-vc142-mt-s-x32-1_72.lib ^
   -DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_DEBUG=%cd:\=/%/../../ThirdParty/compiled/boost/lib/libboost_unit_test_framework-vc142-mt-s-x32-1_72.lib ^
   -DQt5Core_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5Core ^
   -DQt5Gui_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5Gui ^
   -DQt5LinguistTools_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5LinguistTools ^
   -DQt5Widgets_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5Widgets ^
   -DQt5Xml_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5Xml ^
   -A Win32 ^
   ..
```
Open `build/dspdfviewer.sln` and compile `ALL_BUILD` in `Release` mode. The `INSTALL` project just copies the exe (which you can find in `build\Release`) and some files that are of little use under Windows to `C:\Program Files (x86)\dspdfviewer`. Neither the Qt translations files nor the poppler data files are provided with dspdfviewer and have to be downloaded manually; the setup that I provide in my Releases page contains all of them.

## Compiling the help file
If you want to compile the documentation by yourself, you will need the [HTML Help Workshop](http://go.microsoft.com/fwlink/p/?linkid=14188), which is quite an ancient piece of software that still works. Open the `docs\Windows\Help.hhp` from my `dspdfviewer`-fork and compile the help file using this tool.