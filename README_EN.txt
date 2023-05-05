* README_EN.txt
* 2023.05.05
* tacklebar--external_tools

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. EXTERNALS
5. INSTALLATION
5.1. Windows XP support
6. KNOWN ISSUES
7. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
External application tools:
  * Notepad++
  * Notepad++ PythonScript plugin
  * WinMerge

------------------------------------------------------------------------------
2. LICENSE
------------------------------------------------------------------------------
The MIT license (see included text file "license.txt" or
https://en.wikipedia.org/wiki/MIT_License)

-------------------------------------------------------------------------------
3. REPOSITORIES
-------------------------------------------------------------------------------
Primary:
  * https://github.com/andry81-3dparty/tacklebar--external_tools/branches
  * https://github.com/andry81-3dparty/tacklebar--external_tools.git
First mirror:
  * https://sf.net/p/external-tools/tacklebar--external_tools/ci/master/tree
  * https://git.code.sf.net/p/tacklebar/external_tools
Second mirror:
  * https://bitbucket.org/andry81/tacklebar-external_tools/branches
  * https://bitbucket.org/andry81/tacklebar-external_tools.git

-------------------------------------------------------------------------------
4. EXTERNALS
-------------------------------------------------------------------------------
To checkout externals you must use the
[vcstool](https://github.com/dirk-thomas/vcstool) python module.

NOTE:
  To install the module from the git repository:

  >
  python -m pip install git+https://github.com/dirk-thomas/vcstool

CAUTION:
  To use the sparse checkout feature you must use a forked repository:

  >
  python -m pip install git+https://github.com/aaronplusone/vcstool@feature-sparse-checkouts

    Or

  >
  python -m pip install git+https://github.com/plusone-robotics/vcstool@por_master

------------------------------------------------------------------------------
5. INSTALLATION
------------------------------------------------------------------------------

NOTE:
  The installation does not require an installation directory because the
  script does installation of 3rd party applications

>
_install.bat

------------------------------------------------------------------------------
5.1. Windows XP support
------------------------------------------------------------------------------

For the Windows XP the initial codepage in the `config.system.vars`
configuration file is taken from the registry on the moment of the
installation. You can change it:

(DOS codepage)

>
_install.bat -chcp 866

------------------------------------------------------------------------------
6. KNOWN ISSUES
------------------------------------------------------------------------------

See details in the `README_EN.txt` file of the `tacklebar` project.

-------------------------------------------------------------------------------
7. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
