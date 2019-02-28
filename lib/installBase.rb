#!/usr/bin/env ruby
# add -debug above to debug.

# vi:nu:et:sts=4 ts=4 sw=4

#  THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
#  AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
#  THE AUTHORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
#  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
#  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
#  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#



#----------------------------------------------------------------
#                       Global Variables
#----------------------------------------------------------------

#   IMPORTANT - Most Global Varialbles should only be defined
#   in the main script file.


    require "cliAppWithPhases"
    require "logger"
    require "optparse"
    require "ostruct"
    require "tempfile"




#################################################################
#                   Installation Base Class 
#################################################################

class InstallBase < CliAppWithPhases

    attr_reader :packageName, :packageVersion, :tarDirectory
    attr_writer :packageName, :packageVersion, :tarDirectory

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( packageName='', packageDisplayName='', packageVersion='' )

        super
        @packageName        = packageName
        @packageDisplayName = packageDisplayName
        @packageVersion     = packageVersion

    end


    #----------------------------------------------------------------
    #                   Check for a Prerequisite.
    #----------------------------------------------------------------

    def checkPrereq( prereqCmd )

        $olog.logDebug( "PackageInstall::checkPrereq( #{prereqCmd} )" )

        rc = $oCmd.cmd( "#{prereqCmd} isInstalled" )
        if 0 != rc
            die "prereq command, #{prereqCmd}, failed"
        end

    end


    #----------------------------------------------------------------
    #                    Configure the package. 
    #----------------------------------------------------------------

    def doConfigure( )

        $olog.logDebug(  "PackageInstall::doConfigure( )" )

        Dir.chdir( "#{@options.baseDirectoryFullPath}" ) do
            $olog.logInfo( "Making the System..." )
            rc = $oCmd.cmd( "#{@options.configureCmd} #{@options.configureOptions}" )
            if 0 != rc
                die "configure failed"
            end
        end
    end


    #----------------------------------------------------------------
    #                     Fetch the sources
    #----------------------------------------------------------------

    def doFetch( )

        $olog.logDebug( "PackageInstall::doFetch( )" )

        if @fQuiet
            parms = "--silent"
        else
            parms = ""
        end

    
        # Fetch the Sources.
        if !self.isExistingFile?( "#{@options.tarballPathName}" )
            Dir.chdir( "#{@options.tarballDirectory}" ) do
                $olog.logInfo( "Downloading the Package Tarball of #{@options.tarballFileName}..." )
                rc = $oCmd.cmd( "curl -C- -LO #{parms} \"#{@options.tarballURL}/#{@options.tarballFileName}\"" )
                if 0 != rc
                    die( "failed to fetch Latest Sources" )
                end
            end
        end
        rc = $oCmd.cmd( "md5 -q \"#{@options.tarballPathName}\"" )
        if 0 != rc
            die( "failed to create md5 checksum on Tarball, #{@options.tarballPathName}" )
        end
        if  "#{@options.tarballMD5}" != self.szOutput
            $olog.logDebug( "tarball MD5 = \"#{@options.tarballMD5}\"" )
            $olog.logDebug( "calculated MD5 = \"#{self.szOutput}\"" )
            die( "MD5 checksum failed on Source Tarball, #{@options.tarballFileName}" )
        end

     
        # Create the source library.
        if self.isExistingDirectory?( "#{@options.baseDirectoryFullPath}" )
            $olog.logInfo( "Removing previous source directory..." )
            rc = $oCmd.cmd( "rm -fr \"#{@options.baseDirectoryFullPath}\"" )
        end
        if self.isExistingFile?( "#{@options.tarballPathName}" )
            $olog.logInfo( "Restoring source directory..." )
            Dir.chdir( "#{@options.baseDirectory}" ) do
                case "#{@options.tarballSuffix}"
                    when '.tar.gz', '.tgz'
                        tarCmd = "tar xzvf"
                        ;;
                    when '.tar.bz2', '.tbz2'
                        tarCmd = "tar xjvf"
                        ;;
                    else
                        tarCmd = "tar xvf"
                end
                rc = $oCmd.cmd( "#{tarCmd} \"#{@options.tarbalPathName}\"" )
                if 0 != rc
                    die( "failed to extract Source Tarball from #{@options.tarballPathName}" )
                end
            end
        end

    end


    #----------------------------------------------------------------
    #                     Check the Build
    #----------------------------------------------------------------

    def doIsInstalled( )

        $olog.logDebug( "PackageInstall::doIsInstalled( )" )
        rc = 4                  # Default to no.

        @options.installedFiles.each do |file|
            if isExistingFile( file )
                $olog.logInfo( "is installed, found: #{file}" )
                rc = 0
                break
            end
        end

        return rc
    end


    #----------------------------------------------------------------
    #                    Make the package. 
    #----------------------------------------------------------------

    def doMakeAll( )

        $olog.logDebug(  "PackageInstall::doMakeAll( )" )

        Dir.chdir( "#{@options.baseDirectoryFullPath}" ) do
            # Compile the various modules.
            $olog.logInfo( "Performing Make All for the Package..." )
            rc = $oCmd.cmd( "#{@options.makeAllCmd} #{@options.makeAllOptions}" )
            if 0 != rc
                die "make all failed"
            end
        end
    end


    #----------------------------------------------------------------
    #                     Check the Build
    #----------------------------------------------------------------

    def doMakeCheck( )

        $olog.logDebug( "PackageInstall::doMakeCheck( )" )

        Dir.chdir( "#{@options.baseDirectoryFullPath}" ) do
            # Compile the various modules.
            self.infoMsg( "Performing Make Check for the Package..." )
            rc = $oCmd.cmd( "#{@options.makeCheckCmd} #{@options.makeCheckOptions}" )
            if 0 != rc
                die "make check failed"
            end
        end

    end


    #----------------------------------------------------------------
    #                     Install the Library
    #----------------------------------------------------------------

    def doMakeInstall( )

        $olog.logDebug( "PackageInstall::doMakeInstall( )" )

        # Notes
        #   *   We redirect the manpages to "/usr/local/share/man" since MacOSX
        #       expects them to be there rather than in "/usr/local/man".

        Dir.chdir( "#{@options.baseDirectoryFullPath}" ) do
            self.infoMsg( "Creating needed directories..." )
            puts "Please enter your password if requested..."
            $oCmd.cmd( 'sudo mkdir -p /usr/local/bin' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/bin/X11' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/include' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/include/X11' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/lib' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/lib/X11' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/info' )
            $oCmd.cmd( 'sudo ln -s    /usr/local/share/info /usr/local/info' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man1' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man2' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man3' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man4' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man5' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man6' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man7' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man8' )
            $oCmd.cmd( 'sudo mkdir -p /usr/local/share/man/man9' )
            $oCmd.cmd( 'sudo ln -s    /usr/local/share/man  /usr/local/man' )
            self.infoMsg( "Performing Make Install for the package..." )
            rc = $oCmd.cmd( "#{@options.makeInstallCmd} #{@options.makeInstallOpts}" )
            if 0 != rc
                die "make install failed"
            end
        end
    end


    #----------------------------------------------------------------
    #                     Uninstall the Build
    #----------------------------------------------------------------

    def doMakeUninstall( )

        $olog.logDebug( 'PackageInstall::doMakeUninstall( )' )

        die( 'Uninstall has not been implemented yet!' )

        Dir.chdir( "#{@options.baseDirectoryFullPath}" ) do
            # Compile the various modules.
            self.infoMsg( "Performing Make Uninstall for the Package..." )
            rc = $oCmd.cmd( "#{@options.makeUninstallCmd} #{@options.makeUninstallOptions}" )
            if 0 != rc
                die "make uninstall failed"
            end
        end

    end


    #----------------------------------------------------------------
    #                     Patch the sources
    #----------------------------------------------------------------

    def doPatch( )

        $olog.logDebug( "PackageInstall::doPatch( )" )

        Dir.chdir( "#{@options.baseDirectoryFullPath}" ) do
            self.infoMsg( "Applying specific patches..." )
            Dir[""].each do |patch|
                self.patchApply( szPatchPath )
            end
        end

        if @options.fApplyConfig.exist?
            self.patchConfig
        end

    end


    #----------------------------------------------------------------
    #                   Check for Prerequisites.
    #----------------------------------------------------------------

    def doPrereqs( )

        $olog.logDebug( "PackageInstall::doPrereqs( )" )

        $olog.logInfo( "Checking for all Prerequisites..." )
        if !defined? @options.fQuiet
            puts "Please enter your password if requested..."
        end
        @options.prereqCheckCmds.each do |prereqCmd|
            self.checkPrereq( prereqCmd )
        end

    end


    #----------------------------------------------------------------
    #                   Remove Package from System.
    #----------------------------------------------------------------

    def doRemove( )

        $olog.logDebug( "PackageInstall::doRemove( )" )


        $olog.logInfo( "Removing package data, programs and libraries..." )
        if !(defined? @fQuiet)
            puts "Please enter your password if requested..."
        end
        @options.installedFiles.each do |installedFile|
            self.removeInstalledFile( installedFile )
        end

    end


    #################################################################
    #                       Main Function
    #################################################################

    def main( )


        # Do initialization.
        @scriptStartupDirectory = Dir.getwd
        @timeStart = "#{self.getTime}"
        self.optionsSetup

        # Now scan off the options
        oParse = OptionParser.new do |oParse|
            oParse.banner( "packageInstaller for MacOSX" )
            oParse.separator( "Usage:" )
            oParse.separator( " #{$0} [see Flags below]* [see Phases below]*" )
            oParse.separator( "  This script builds #{@packageName} on MacOSX 10.4+." )
            oParse.separator( "  If the script is started without parameters, 'all' is assumed." )
            oParse.separator( "" )
            oParse.separator( "Phases:" )
            oParse.separator( "  all             Execute all phases in the order given below:" )
            oParse.separator( "  prereqs         Check for the prerequisites" )
            oParse.separator( "  fetch           Fetch the sources" )
            oParse.separator( "  patch           Patch the sources with local patches if needed" )
            oParse.separator( "  build           Build the libraries, executables, documentation, etc" )
            oParse.separator( "  check           Perform 'make check' to insure that the package works properly" )
            oParse.separator( "  remove          Remove the libraries, executables, etc by deleting them" )
            oParse.separator( "                  directly" )
            oParse.separator( "  install         Install the libraries, executables, documentation, etc" )
            oParse.separator( "  clean			Remove the sources and build products," )
            oParse.separator( "       			but not the initial source tar-balls" )
            oParse.separator( "" )
            oParse.separator( "Other Phases not normally executed:" )
            oParse.separator( "  uninstall       Uninstall the libraries, executables, documentation, etc" )
            oParse.separator( "                  (This uses 'make uninstall' which might not be implemented" )
            oParse.separator( "                  properly. See README and INSTALL for further information.)" )
            oParse.separator( "" )
            oParse.separator( "Options:" )
            oParse.on( "-b", "--base", "=dir", "display the usage help" ) do |dir|
                @options.baseDirectory = dir
                exit
            end
            oParse.on( "-c", "--cleanall", "in clean phase, force removal of tarball") do |x|
                @options.fCleanAll = x
            end
            oParse.on( "--home", "open the Package's Home Website") do |x|
                if @options.homeURL.length
                    self.cmd( "open -a Safari #{@options.homeURL}" )
                else
                    puts 'ERROR - no Home URL was specified!'
                    exit
                end
            end
            oParse.on( "--forceInstall", "force install even if previously installed") do |x|
                @options.fForceInstall = x
            end
            oParse.on( "-s", "--source", "=dir", 
                        "set the directory where patches and tarballs may be found") do |dir|
                @options.tarballDirectory = dir
                exit
            end
            oParse.on( "--version", "=dir", 
                        "set the version string") do |dir|
                @options.version = dir
                exit
            end
        end
        
        # Parse the phases specified.
        if 0 < ARGV.length
            ARGV.each do |phase|
                case phase
                    when "all" 
                        @options.fDoBuild=true
                        @options.fDoCheck=true
                        @options.fDoCheckInstalled=true
                        @options.fDoClean=true
                        @options.fDoFetch=true
                        @options.fDoInstall=true
                        @options.fDoPatch=true
                        @options.fDoPrereqs=true
                        @options.fDoRemove=true
                    when "build" 
                        @options.fDoBuild=true
                    when "check" 
                        @options.fDoCheck=true
                    when "checkInstalled" 
                        @options.fDoCheckInstalled=true
                    when "clean" 
                        @options.fDoClean=true
                    when "fetch"
                        @options.fDoFetch=true
                    when "install"
                        @options.fDoInstall=true
                    when "isInstalled"
                        @options.fDoIsInstalled=true
                    when "patch"
                        @options.fDoPatch=true
                    when "prereqs"
                        @options.fDoPrereqs=true
                    when "remove"
                        @options.fDoRemove=true
                    when "uninstall"
                        @options.fDoUninstall=true
                    else
                        puts "FATAL - found invalid phase: #{phase}"
                end
            end
        else
            @options.fDoBuild=true
            @options.fDoCheck=true
            @options.fDoCheckInstalled=true
            @options.fDoClean=true
            @options.fDoFetch=true
            @options.fDoInstall=true
            @options.fDoPatch=true
            @options.fDoPrereqs=true
            @options.fDoRemove=true
        end
        self.optionsOverride
        self.optionsValidate

        # Perform the main processing.
        @rc = self.run

        @timeEnd = Time.new
        if !@fQuiet
            if 0 == mainReturn
                puts           "Successful completion..."
            else
                puts           "Unsuccessful completion of #{@rc}"
            end
            puts            "   Started: #{@timeStart}"
            puts            "   Ended:   #{@timeEnd}"
        end

        return    @rc

    end


    #----------------------------------------------------------------
    #               Setup initial Options in @options.
    #----------------------------------------------------------------

    def optionsDefaultSetup( )

        @options.baseDirectory = ENV['HOME']
        @options.configureCmd = 'CFLAGS= ./configure'
        @options.configureOptions = '--prefix="/usr/local" --enable-shared --enable-static'
        @options.homeURL = ''
        @options.isInstalledFiles = [ ]
        @options.makeAllCmd = 'CFLAGS= make'
        @options.makeAllOptions = ''
        @options.makeCheckCmd = 'CFLAGS= make check'
        @options.makeCheckOptions = ''
        @options.makeInstallCmd = 'CFLAGS= make install'
        @options.makeInstallOptions = 'mandir=\"/usr/local/share/man\"'
        @options.makeUninstallCmd = 'CFLAGS= make uninstall'
        @options.makeUninstallOptions = ''
        @options.packageName = ''
        @options.prereqCheckCmds = [ ]
        @options.tarballDirectory = Dir.getwd
        @options.tarballMD5 = ''
        @options.tarballName = ''
        @options.tarballSuffix = '.tar.bz2'
        @options.tarballURL = ''
        @options.version = ''

    end


    #----------------------------------------------------------------
    #   Allow options to be overridden before processing begins.
    #----------------------------------------------------------------

    def optionsOverride( )

        @options.baseDirectoryName = "#{@options.packageName}-#{@options.packageVersion}"
        @options.baseDirectoryFullPath = "#{@options.baseDirectory}/#{@options.baseDirectoryName}"
        @options.tarballFileName = "#{@options.tarballName}-#{@options.packageVersion}#{@options.tarballSuffix}"
        @options.tarballPathName = "#{@options.tarballDirectory}/#{@options.tarballFileName}"

    end


    #----------------------------------------------------------------
    #                       Validate the options.
    #----------------------------------------------------------------

    def optionsValidate( )

        if !self.isExistingFile?( @options.tarballPathName )
            die "Tarball file, #{@options.tarballPathName} does not exist"
        end

    end


    #----------------------------------------------------------------
    #                   Apply the specified patch.
    #----------------------------------------------------------------

    def patchApply( szPatchPath )

        $olog.logDebug( "PackageInstall::patchApply( #{szPatchPath} )" )

        $oCmd.cmd( "patch -Nb -p2 --verbose -i \"#{szPatchPath}\"" )

    end


    #----------------------------------------------------------------
    #                   Setup config for patches.
    #----------------------------------------------------------------

    def patchConfig(  )

        $olog.logDebug( "PackageInstall::patchConfig( )" )

        # Set up to use GNU libtool properly.
        if self.isExistingDirectory?( '/usr/local/share/libtool' )
            $oCmd.cmd( "cp /usr/local/share/libtool/config.sub ." )
            $oCmd.cmd( "cp /usr/local/share/libtool/config.guess ." )
            $oCmd.cmd( "cp /usr/local/share/libtool/ltmain.sh ." )
        elsif self.isExistingDirectory?( '/usr/share/libtool' )
            $oCmd.cmd( "cp /usr/share/libtool/config.sub ." )
            $oCmd.cmd( "cp /usr/share/libtool/config.guess ." )
            $oCmd.cmd( "cp /usr/share/libtool/ltmain.sh ." )
        else
            die "Could not find libtool files in /usr/local or /usr"
        end
        darwinMatch = Regexp.new( ".*darwin.*" )
        if darwinMatch.match( RUBY_PLATFORM )
            toolize="glibtool"
        else
        end
        if self.isExistingFile?( './libtool' )
            $oCmd.cmd( "rm ./libtool" )
        end
        self.cmd( "ln -s `which #{toolize}` ./libtool" )

    end


    #----------------------------------------------------------------
    #                   Check for Prerequisites.
    #----------------------------------------------------------------

    def removeInstalledFile( installedFile )

        $olog.logDebug( "PackageInstall::removeInstalledFile( #{installedFile} )" )

        if isExistingDirectory?( installedFile )
                $oCmd.cmd( "sudo rm -fr \"#{installedFile}\"", true )
        else
                $oCmd.cmd( "sudo rm \"${installedFile}\"", true )
        end

    end


    #----------------------------------------------------------------
    #                     Do Main Processing
    #----------------------------------------------------------------

    def run( )

        $olog.logDebug( 'PackageInstall::run( )' )

        # Perform the various phases.
        if defined? @options.fDoIsInstalled
            $olog.logInfo( "Checking for already installed..." )
            rc = self.doIsInstalled
            return rc
        end
        if defined? @options.fDoCheckInstalled
            $olog.logInfo( "Checking for already installed..." )
            rc = self.doIsInstalled
            if (0 == rc ) && !(defined? @options.fForceInstall)
                return 0
            end
        end
        if defined? @options.fDoPrereqs
            $olog.logInfo( "Checking the prerequisites..." )
            self.doPrereqs
        end
        if defined? @options.fDoFetch
            $olog.logInfo( "Fetching the source..." )
            doFetch
        end
        if defined? @options.fDoPatch
            $olog.logInfo( "Patching the source..." )
            doPatch
        end
        if defined? @options.fRemoveBeforeMake
            $olog.logInfo( "Remove the package..." )
            doRemove
        end
        if defined? @options.fDoBuild
            $olog.logInfo( "Building the source..." )
            doBuild
        end
        if defined? @options.fDoCheck
            $olog.logInfo( "Checking the package..." )
            doCheck
        end
        if defined? @options.fDoRemove
            $olog.logInfo( "Remove the package..." )
            doRemove
        end
        if defined? @options.fDoInstall
            $olog.logInfo( "Installing the source..." )
            doInstall
        end
        if defined? @options.fDoUninstall
            $olog.logInfo( "Uninstalling the package..." )
            doUninstall
        end
        if defined? @options.fDoClean
            $olog.logInfo( "Cleaning up..." )
            doClean "${fCleanAll}"
        end
        
        return 0

    end


end




