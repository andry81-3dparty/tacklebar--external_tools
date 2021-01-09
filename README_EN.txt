* README_EN.txt
* 2021.01.09
* tacklebar--external_tools

1. DESCRIPTION
2. LICENSE
3. DEPENDENCIES
4. REPOSITORIES
5. INSTALLATION
5.1. Windows XP support
6. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
External application tools:
  * Notepad++
  * Notepad++ PythonScript plugin
  * Notepad++ PythonScript plugin startup scripts
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
3. DEPENDENCIES
-------------------------------------------------------------------------------
Currently all 3dparty applications runs without any other external dependecy.

But here is some links to start search from in case if such dependencies would
be revealed.

External dependencies:
  * Microsoft Visual C++ 2010 Runtime:

    ** Microsoft Visual C++ 2010 SP1 Redistributable Package (x86):
      https://www.microsoft.com/en-US/download/details.aspx?id=8328

    ** Microsoft Visual C++ 2010 SP1 Redistributable Package (x64):
      https://www.microsoft.com/en-US/download/details.aspx?id=13523

    ** Microsoft Visual C++ 2010 Service Pack 1 Redistributable Package MFC
       Security Update:
      https://www.microsoft.com/en-US/download/details.aspx?id=26999

-------------------------------------------------------------------------------
4. REPOSITORIES
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
5. INSTALLATION
------------------------------------------------------------------------------

To install all 3dparty aplications, plugins and extensions altogether:

  >
  _install.bat

------------------------------------------------------------------------------
5.1. Windows XP support
------------------------------------------------------------------------------

To be able to install under the Window XP you can avoid switch to a broken
codepage 65001 (utf-8) as used by default:

(DOS codepage)

  >
  _install.bat -chcp 866


Or

(Windows codepage)

  >
  _install.bat -chcp 1251

-------------------------------------------------------------------------------
6. AUTHOR
-------------------------------------------------------------------------------
andry at inbox dot ru
