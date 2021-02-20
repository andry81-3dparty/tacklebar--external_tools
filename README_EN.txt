* README_EN.txt
* 2021.02.20
* tacklebar--external_tools

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. INSTALLATION
4.1. Windows XP support
5. KNOWN ISSUES
6. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
External application tools:
  * Notepad++
  * Notepad++ PythonScript plugin
  * WinMerge

The latest version is here: https://sf.net/p/tacklebar

WARNING:
  Use the SVN access to find out new functionality and bug fixes.
  See the REPOSITORIES section.

------------------------------------------------------------------------------
2. LICENSE
------------------------------------------------------------------------------
The MIT license (see included text file "license.txt" or
https://en.wikipedia.org/wiki/MIT_License)

-------------------------------------------------------------------------------
3. REPOSITORIES
-------------------------------------------------------------------------------
Primary:
  * https://sf.net/p/tacklebar/external_tools/HEAD/tree/trunk
  * https://svn.code.sf.net/p/tacklebar/external_tools/trunk
First mirror:
  * https://github.com/andry81/tacklebar--external_tools/tree/trunk
  * https://github.com/andry81/tacklebar--external_tools.git
Second mirror:
  * https://bitbucket.org/andry81/tacklebar-external_tools/src/trunk
  * https://bitbucket.org/andry81/tacklebar-external_tools.git

------------------------------------------------------------------------------
4. INSTALLATION
------------------------------------------------------------------------------

NOTE:
  The installation does not require an installation directory because the
  script does installation of 3rd party applications

>
_install.bat

------------------------------------------------------------------------------
4.1. Windows XP support
------------------------------------------------------------------------------

For the Windows XP the initial codepage in the `config.system.vars`
configuration file is taken from the registry on the moment of the
installation. You can change it:

(DOS codepage)

>
_install.bat -chcp 866

------------------------------------------------------------------------------
5. KNOWN ISSUES
------------------------------------------------------------------------------

See details in the `README_EN.txt` file of the `tacklebar` project.

-------------------------------------------------------------------------------
6. AUTHOR
-------------------------------------------------------------------------------
andry at inbox dot ru
