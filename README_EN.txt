* README_EN.txt
* 2021.01.24
* tacklebar--external_tools

1. DESCRIPTION
2. LICENSE
3. DEPENDENCIES
4. REPOSITORIES
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

NOTE:
  The installation does not required particulary an installation directory
  because the script does installation into 3dparty installation directories.
  But because the files there can be rewrited or erase the tacklebar
  installation directory still required to be pointed here to backup those
  3dparty files and directories.

1. To install into a directory do run the `_install.bat` with the first
   argument - path to the installation root:

    >
    mkdir c:\totalcmd\scripts
    _install.bat c:\totalcmd\scripts

   NOTE:
      You can call `_install.bat` without the destination path argument in case
      if the `tacklebar` installation script (not one from this project) has
      been already called at least once. In that case it would use the
      destination path from the already registered `COMMANDER_SCRIPTS_ROOT`
      variable.

------------------------------------------------------------------------------
5.1. Windows XP support
------------------------------------------------------------------------------

The default codepage in the `config.system.vars` configuration file is
`1251` (Windows codepage). You can change it:

(DOS codepage)

  >
  mkdir c:\totalcmd\scripts
  _install.bat -chcp 866 c:\totalcmd\scripts

------------------------------------------------------------------------------
6. KNOWN ISSUES
------------------------------------------------------------------------------

See details in the `README_EN.txt` file of the `tacklebar` project.

-------------------------------------------------------------------------------
7. AUTHOR
-------------------------------------------------------------------------------
andry at inbox dot ru
