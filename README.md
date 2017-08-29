This gives an exhaustive manual of how to build `dspdfviewer` from almost scratch under Windows. This means that all third-party libraries need to be obtained as source code.
# Requirements
- I compiled everything with **Microsoft Visual Studio Community 2015**.
When I did the first builds and releases, I used 2013, so this compiler is also sufficient. However, there might be different adjustments that need to be made in the code, as the 2013 compiler does not support the newer C++ standards as exhausive as the 2015 one.
Without having tried this, I expect that the 2017 compiler should not complain about anything.
As the Intel compiler is mostly compatible with MSVC, I also assume that it works without too much of a headache.
Probably GNU will also work, since the developers of the third-party components might rather have had GNU in mind when designing their software, but this is not integrated in the Visual Studio Front-End. Therefore, the compilation steps will be different, though the CMake command lines should be similar and the manual can still be helpful.
- The **CMake** build system is required and needs to be properly set up.
- A **diff program** for inspecting the differences between files is highly recommended.
- All of the builds are done in **32-bit mode**. Some of the third-party software might not run in 64-bit mode, while others will do. Mixing is of course not possible, but if someone is interested only in a standalone library of some of the dependencies, the 64-bit mode may be tried.
- The manual gives instructions for building **both Debug and Release mode**. If not needed, the Debug-mode-releated steps can be skipped.
- The build is performed in the **static mode**. This means that **no DLLs** are produced, but instead LIB files. Those files are compiler-specific - hence, if you don't want to build some of the libraries because you have found a pre-compiled version in the Internet, be sure that it targets exactly the same compiler version. Under Windows, there is also a problem related to runtime-libraries, namely the `MD` and `MT` mode. In general, dynamic libraries, should be compiled in the `MD` or `MDd` mode and static libraries in the `MT` or `MTd` mode. However, this is not enforced. If you have a source which uses a different compilation, you will _in the best case_ get linker warnings about multiply-defined functions. All libraries here are build in the `MT` or `MTd` mode. This is not native to most of them. Therefore, some lines will need to be inserted into the `CMakeLists.txt` at appropriate positions, which ensure that they are compiled correctly:
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
  - If you should adjust something in a file, this is described in the manual. Run a diff between the file in this repository and the one you downloaded. Search for the adjustment that is described in the manual and merge it appropriately. For example, you can find recommendations where to put the `MD > MT` replacement. If you are asked to change it via the Visual Studio property page, it is under `(C/C++ > Code generation > Runtime library`; remember to select the correct build environment and platform (all platforms is best, if you want to try the x64-version as well). Do not just copy the illustrative files from this repository unless the version is exactly the same as the one you downloaded!
  - When entering the given console commands, the **current working directory is supposed to be the one you extracted the library to**. Lots of lines given here are terminated with `^`; this indicates a continued command in the Windows cmd. Hence, most of the times you can directly copy-and-paste the whole command-line block to the prompt. For this purpose, I use `%cd:\=/%` lots of times, which actually evaluates to the current absolute path - typically, you do not have to adjust anything in the command, regardless of absolute path you are really in; otherwise, you will be instructed to do so. (This is why it is important that you change the cwd before correctly!)
  - I usually say 

    > compile `ALL_BUILD` and `INSTALL` in `Debug` and `Release` mode

    This means that you [ first should ensure that the compilation mode is set to `Debug`. Then, right-click on the `ALL_BUILD` metaproject in the Project Explorer and compile it. After this, do the same for `INSTALL`. This will copy all relevant files to the `compiled`-subdirectory. If I also tell you to rename certain files, do it _now_. ] _Then_, change to the `Release` mode, compile `ALL_BUILD` and `INSTALL`.
If you don't want the debug version, you may leave out the steps within [ ... ].
The reason for this particular order is that sometimes, the files generated by the two builds will overwrite each other. Therefore, it is important that the installation copies the correct files.
- The paths which I give are either relative to the current library directory or, if they begin with `compiled`, to the `compiled` directory which is a subdirectory of your chosen root (i.e. on the same level as the library directory).

# Third party libraries
1. Qt and Boost
It is very cumbersome to build Qt and partly also Boost. Not because you have to adjust much, but just because these libraries are so large. I did it once for MSVC2013 and Qt alone took about one day to compile. You may do so if you wish.
However, luckily a very nice person provides an exhaustive set of precompiled _static_ versions of these libraries (the dynamic ones can of course be downloaded from the developers themselves, but we are not interested in them) for lots of different compiler versions.
Qt: https://www.npcglib.org/~stathis/blog/precompiled-qt4-qt5/
Boost: https://www.npcglib.org/~stathis/blog/precompiled-boost/
They should go in the folder `compiled/qt5` (containing `bin`, `doc`, `include`, ...) and `compiled/boost` (containing `include` and `lib`).
The release and debug version of Qt can be merged: Keep the `bin` folder of `release`; copy the `lib/`, `tools/` and `qml/` folders from `debug` into `release`. After that, merge the `lib/cmake` files appropriately.

2. Build [zlib](https://zlib.net/)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`
    - ```console
      mkdir build && cd build
      cmake -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/zlib ..
      ```
    - open `build/zlib.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Debug` and `Release` mode (note that both zlib and zlibstatic are built with MT)
    - delete `compiled/zlib/lib/zlib[d].lib` and remove the `static` suffix from the others
    - change `compiled/zlib/include/zconf.h`: change `#define ZEXTERN` (probably l. 379) to an empty define

3. Build [libpng](http://www.libpng.org/pub/png/libpng.html)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`
    - ```console
      mkdir build && cd build
      cmake ^
         -DZLIB_ROOT:PATH=%cd:\=/%/../../compiled/zlib ^
         -DPNG_SHARED:BOOL=OFF -DPNG_STATIC:BOOL=ON ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/libpng ^
         ..
      ```
    - open `build/libpng.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Debug` and `Release` mode

4. Build [expat](https://github.com/libexpat/libexpat)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`
    - only before commit `2275720`/version 2.2.2: remove the pre-build command containing `$(MAKE)` from `CMakeLists.txt`
    - ```console
      mkdir build && cd build
      cmake ^
         -DBUILD_shared:BOOL=OFF -DBUILD_examples:BOOL=OFF ^
         -DBUILD_tests:BOOL=OFF ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/expat ^
         ..
      ```
    - open `build/expat.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Debug` and `Release` mode

5. Build [LCMS2](http://www.littlecms.com/download.html)
    - open `Projects/VC2015/lcms2.sln`
    -  change `lcms2_static` build properties to `MTd` and `MT` for both `Debug` and `Release` mode
    - build `lcms2_static` in `Debug` mode
    - move `Lib/MS/*` to `compiled/lcms2/lib` and add `d` suffix to the file names (before the extension, obviously)
    - build `lcms2_static` in `Release` mode
    - move `Lib/MS/*` to `compiled/lcms2/lib`
    - copy `include` folder to `compiled/lcms2`

6. Build [libiconv](https://www.gnu.org/software/libiconv/#downloading)
    - download the [Visual Studio project folder and the patch file on GitHub](https://github.com/winlibs/libiconv). The `libiconv` version in the source folder there might not be the most recent version, replace it with the current one.
    - Apply the patch ([GnuWin](http://gnuwin32.sourceforge.net/packages.html) contains `patch.exe`):
      - Convert all files that are about to be patched to Windows line endings (all better editors will have a function for this, a nice free one is [Programmer's Notepad](http://www.pnotepad.org/)). `patch` will report any file which is not in the proper ending. They should be:
        - `source/lib/hz.h`
        - `source/lib/iconv.c`
        - `source/lib/loop_unicode.h`
        - `source/lib/relocatable.c`
        - `source/lib/utf7.h`

        Any file not converted will be reported as "can't find", but they can be given while patching.
      - ```console
        patch -i libiconv.diff
        ```
    - The files newly created by the patch do not use the current `.in` source. Do a three-way-comparison with you diff program with the files `config.h`, `iconv.h` and `localcharset.h` (first: `.in` file of the GitHub archive; second: patched version of the GitHub archive; third: `.in` file of the most recent version). They are located in `source/`, `source/include/`, and `source/lib/`, respectively (the patch wrongly creates all of them in the current folder).
      Check which definitions have to be adapted and merge accordingly. This will take some time, especially for the `config.h`. The files in this repository is what I made out of the steps above for the version of the library indicated by the directory name.
    - open `MSVC14/libiconv.sln`
    - change `libiconv_static` build properties to `MTd` and `MT` for both `Debug` and `Release` mode
    - compile `libiconv_static` in `Debug` and `Release` mode
    - copy `source/include/iconv.h` to `compiled/libiconv/include/`
    - copy `MSVC14/libiconv_static/Debug|Release/libiconv_a.lib|libiconv_a_debug.lib` to `compiled/libiconv/lib` (probably also `.pdb`)

7. Build [freetype](http://download.savannah.gnu.org/releases/freetype/)
    - add the `MD > MT` replacement from the old `CMakeLists.txt`. Keep the Linux line endings!
    - ```console
      mkdir build && cd build
      cmake ^
         -DZLIB_ROOT:PATH=%cd:\=/%/../../compiled/zlib ^
         -DPNG_PNG_INCLUDE_DIR=%cd:\=/%/../../compiled/libpng/include ^
         -DPNG_LIBRARY=%cd:\=/%/../../compiled/libpng/lib/libpng16_static.lib ^
         -DWITH_BZip2:BOOL=OFF ^
         -DBUILD_SHARED_LIBS:BOOL=OFF ^
         -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/freetype ^
         ..
      ```
    - open `build/freetype.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Debug` and `Release` mode

8. Build [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo)
  **optional, not needed:** `poppler` will not work with `libjpeg` (or this replacement) and none of the following steps use this library anywhere. Therefore, this step can be skipped. However, if the problem described later on is someday fixed, that's how to build it. _In principle_, the following libraries can be configured to use `libjpeg`, therefore this would be the correct position for building.
  Requires [nasm](http://www.nasm.us/) for the "turbo"!
    - ```console
      mkdir build && cd build
      cmake -DCMAKE_INSTALL_PREFIX=%cd:\=/%/../../compiled/libjpeg-turbo ..
      ```
    - open `build/libjpeg-turbo.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Debug` mode; add `d` suffix to libraries in `compiled/libjpeg-turbo/lib`; then build in `Release` mode

9. Build [XZ (LZMA)](https://tukaani.org/xz/)
    - open `windows/xz_win.sln`
    - change `liblzma` build properties to `MTd` and `MT` for both `Debug` and `Release` mode
    - build `liblzma` in `Debug` and `Release` mode
    - move `windows/Debug/Win32/liblzma.lib` to `compiled/lzma/lib/liblzmad.lib`
    - move `windows/Release/Win32/liblzma.lib` to `compiled/lzma/lib/liblzma.lib`
    - copy `src/api` to `compiled/lzma/include`
    - add `#define LZMA_API_STATIC` to `compiled/lzma/include/lzma.h`

10. Build TIFF (ftp://download.osgeo.org/libtiff/)
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
         ..
      ```
    - open `build/tiff.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Debug` and `Release` mode
   
11. Build [OpenJPEG](https://github.com/uclouvain/openjpeg)
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
         ..
      ```
    - open `build/OPENJPEG.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Debug` mode; add `d` suffix to library in `compiled/openjpeg/lib` and change the path in the `compiled/openjpeg/lib/openjpeg-2.x/OpenJPEGTargets-debug.cmake` appropriately; then build in `Release` mode

12. Build [pixman](https://www.cairographics.org/releases/)
    - download the [MSVC solution](https://github.com/DomAmato/Cairo-VS)
    - create `build` folder and copy the files from `projects/pixman/` to it
    - open `build/pixman.vcxproj` and `build/pixman.vcxproj.filters` with a text editor and remove the string `..\pixman\` from it (replace with empty string)
    - open `build/pixman.vcxproj` with a text editor. Change `<RootNamespace>` tag to `<ProjectName>`, remove `<TargetPlatformVersion>`.
    - open `build/pixman.vcxproj`
    - change `pixman` build properties to `MTd` and `MT` for both `Debug` and `Release` mode
    - compile `pixman_[version]` both in `Debug` and `Release` mode
    - copy `pixman/pixman.h` and `pixman/pixman-version.h` to `compiled/pixman/include/`
    - copy `build/Debug/pixman_[version].lib` to `compiled/pixman/lib/pixman-1d.lib`
    - copy `build/Release/pixman_[version].lib` to `compiled/pixman/lib/pixman-1.lib`

14. Build [cairo](https://www.cairographics.org/releases/)
    - use the MSVC solution from `pixman`
    - copy the files from `projects/cairo/` to `build`, `projects/cairo/src/` to `src`
    - open `build/cairo.vcxproj` and `build/cairo.vcxproj.filters` with a text editor and remove the string `..\cairo\` from it. `cairo-features.h` is listed twice; neither is correct. Remove one, change the other to `..\src\cairo-features.h`.
    - open `build/cairo.vcxproj` with a text editor. Change `<RootNamespace>` tag to `<ProjectName>`, remove `<TargetPlatformVersion>`.
    - open `build/cairo.vcxproj`
    - change `cairo` build properties to `MTd` and `MT` for `Debug` and `Release` mode, respectively, for all platforms
    - change `cairo` VC++ directories to point to the appropriate `include` in `compiled` (remove `build\src`; `freetype` needs to point to the `freetype2`-subdirectory)
    - compile `cairo` both in `Debug` and `Release` mode
    - copy `build/Debug/cairo.lib` to `compiled/cairo/lib/cairod.lib`
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

15. Build [poppler](https://poppler.freedesktop.org/)
    - Change some sources:
      - `qt5/src/CMakeLists.txt`
        ```cmake
        add_library(poppler-qt5
        ```
        remove `SHARED` or replace by `STATIC`
      - `qt5/src/poppler-export.h`
        remove all `dllimport/export` and keep only the empty defines
      - `poppler/JPEG2000Stream.h`
        before the first include, add
        ```c
        #define OPJ_STATIC
        ```
      -  `cmake/modules/FindLIBOPENJPEG2.cmake`
        replace with file in this repository
      - `CMakeLists.txt`
        before `target_link_libraries(poppler ...)`
        ```cmake
        set(poppler_LIBS ${poppler_LIBS} optimized "${CMAKE_SOURCE_DIR}/../compiled/qt5/lib/qtpcre.lib"
                                         debug "${CMAKE_SOURCE_DIR}/../compiled/qt5/lib/qtpcred.lib"
                                         optimized "${CMAKE_SOURCE_DIR}/../compiled/qt5/lib/qtharfbuzzng.lib"
                                         debug "${CMAKE_SOURCE_DIR}/../compiled/qt5/lib/qtharfbuzzngd.lib"
                                         optimized "${CMAKE_SOURCE_DIR}/../compiled/qt5/lib/Qt5PlatformSupport.lib"
                                         debug "${CMAKE_SOURCE_DIR}/../compiled/qt5/lib/Qt5PlatformSupportd.lib"
                                         optimized "${CMAKE_SOURCE_DIR}/../compiled/qt5/plugins/platforms/qwindows.lib"
                                         debug "${CMAKE_SOURCE_DIR}/../compiled/qt5/plugins/platforms/qwindowsd.lib"
                                         optimized "${CMAKE_SOURCE_DIR}/../compiled/lzma/lib/liblzma.lib"
                                         debug "${CMAKE_SOURCE_DIR}/../compiled/lzma/lib/liblzmad.lib"
                                         "WS2_32.Lib"
                                         "OpenGL32.Lib"
                                         "MSImg32.Lib"
                                         "Imm32.lib"
                                         "Winmm.lib")
        ```
        comment out `macro_optional_find_package(JPEG)`: `libjpeg/turbojpeg` does not work together with `QtGUI`. The JPEGs that use the DCTDecoder are simply not displayed. I provide some background in #99. If anyone finds a fix for this, let me know. Meanwhile, we use the unmaintained internal DCTDecoder, for which I did not find any issue.
      - to run a check/test/any of the standalone programs, add
        ```c
        #include <QtPlugin>
        Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin);
        ```
        to the respective main cpp file after the includes
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
         -DBUILD_QT5_TESTS:BOOL=ON ^
         -DENABLE_CPP:BOOL=OFF ^
         -DENABLE_UTILS:BOOL=OFF ^
         -DCMAKE_CXX_FLAGS_DEBUG:STRING="/D_DEBUG /MTd /Zi /Ob0 /Od /RTC1" ^
         -DCMAKE_CXX_FLAGS_MINSIZEREL:STRING="/MT /O1 /Ob1 /D NDEBUG -DQT_NO_DEBUG" ^
         -DCMAKE_CXX_FLAGS_RELEASE:STRING="/MT /O2 /Ob2 /D NDEBUG -DQT_NO_DEBUG" ^
         -DCMAKE_CXX_FLAGS_RELWITHDEBINFO:STRING="/MT /Zi /O2 /Ob1 /D NDEBUG -DQT_NO_DEBUG" ^
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
         -DENABLE_DCTDECODER:STRING=unmaintained ^
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
         ..
      ```
      If the JPEG issue is fixed - or to check whether it is still present - add the commands
      ```console
        -DJPEG_INCLUDE_DIR:PATH=%cd:\=/%/../../compiled/libjpeg-turbo/include ^
        -DJPEG_LIBRARY:FILEPATH=%cd:\=/%/../../compiled/libjpeg-turbo/lib/jpeg-static.lib ^
      ```
      somewhere and change the `ENABLE_DCTDECODER` to `libjpeg`.
    - open `build/poppler.sln`
    - compile `ALL_BUILD` and `INSTALL` in `Debug` mode; add `d` suffix to libraries in `compiled/poppler/lib`; then build in `Release` mode

16. Use [poppler-data](https://poppler.freedesktop.org/)
Do not forget that the poppler encoding data are necessary for some encodings. Download them, but this is nothing to be compiled, they need to be provided with the application in the subdirectory `share/poppler` (so the four folders `cidToUnicode`, `cMap`, `nameToUnicode` and `unicodeMap` need to be in `[exe folder]/share/poppler`).

# dspdfviewer
Finally, we are ready. The `compiled`-subdirectory now holds the precious libraries.
Clone my `dspdfviewer` fork such that the `dspdfviewer` folder is located at the same level as the third-party folder.
Go to the directory where you cloned my `dspdfviewer` fork. If this directory is at the same level as the third-party root directory which is named `ThirdParty` as I suggested above, nothing needs to be changed. Else, adjust `cmake/external_libraries.cmake` and `cmake/filelists.cmake` appropriately to contain the correct folders pointing to poppler and all the other libraries. After that, generate the projects:
```console
cmake ^
   -DBoostStaticLink:BOOL=ON ^
   -DBoost_INCLUDE_DIR=%cd:\=/%/../../ThirdParty/compiled/boost/include/boost-1_61 ^
   -DBoost_LIBRARY_DIR_DEBUG=%cd:\=/%/../../ThirdParty/compiled/boost/lib ^
   -DBoost_LIBRARY_DIR_RELEASE=%cd:\=/%/../../ThirdParty/compiled/boost/lib ^
   -DBoost_PROGRAM_OPTIONS_LIBRARY_DEBUG=%cd:\=/%/../../ThirdParty/compiled/boost/lib/libboost_program_options-vc140-mt-sgd-1_61.lib ^
   -DBoost_PROGRAM_OPTIONS_LIBRARY_RELEASE=%cd:\=/%/../../ThirdParty/compiled/boost/lib/libboost_program_options-vc140-mt-s-1_61.lib ^
   -DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_DEBUG=%cd:\=/%/../../ThirdParty/compiled/boost/lib/libboost_unit_test_framework-vc140-mt-sgd-1_61.lib ^
   -DBoost_UNIT_TEST_FRAMEWORK_LIBRARY_RELEASE=%cd:\=/%/../../ThirdParty/compiled/boost/lib/libboost_unit_test_framework-vc140-mt-s-1_61.lib ^
   -DQt5Core_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5Core ^
   -DQt5Gui_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5Gui ^
   -DQt5LinguistTools_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5LinguistTools ^
   -DQt5Widgets_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5Widgets ^
   -DQt5Xml_DIR=%cd:\=/%/../../ThirdParty/compiled/qt5/lib/cmake/Qt5Xml ^
   ..
```
Open `build/dspdfviewer.sln` and compile `ALL_BUILD` it in `Release` mode. If you like, you can also compile the `Debug` version. The `INSTALL` project just copies the exe (which you can find in `build\Release`) and some files that are of little use under Windows to `C:\Program Files (x86)\dspdfviewer`. Neither the Qt translations files nor the poppler data files are provided with dspdfviewer and have to be downloaded manually; the setup that I provide in my Releases page contains all of them.

## Compiling the help file
If you want to compile the documentation by yourself, you will need the [HTML Help Workshop](http://go.microsoft.com/fwlink/p/?linkid=14188), which is quite an ancient piece of software that still works. Open the `docs\Windows\Help.hhp` from my `dspdfviewer`-fork and compile the help file using this tool.