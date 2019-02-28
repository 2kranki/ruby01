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


    require "logger"
    require "find"
    require "optparse"
    require "ostruct"
    require "rexml/document"
    require 'rexml/streamlistener'
    require "tempfile"

    require "plist"


    tmpDirName = "/tmp"
    wrkDmgName = "mkdmg.work.dmg"
    wrkDmgMountName = "mkdmg.work"


#################################################################
#               Command Line Application Class 
#################################################################

class CommonBase

    attr_reader :fDebug, :fVerbose, :fQuiet,
                :rc, :szOutput, :fNoop
    attr_writer :fDebug, :fNoop, :fQuiet, :fVerbose

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( )

        @fDebug             = false
        @fForce             = false
        @fNoop              = false
        @fQuiet             = false
        @fVerbose           = false
        @dateTime           = Time.new.strftime( "%Y%m%d-%H%M%S" )
        @rc                 = 0
        @szOutput           = ' '

        @scriptStartupDirectory = Dir.getwd
        @timeStart = Time.new

    end


    #----------------------------------------------------------------
    #           Issue a one-line command.
    #----------------------------------------------------------------

    def cmd( szCmd, fIgnoreRC=false, fIgnoreOutput=false )

        $LOG.debug( "CommonBase::cmd( #{szCmd} )" )

        if @fNoop
            $LOG.debug( "cmd:#{szCmd} ==> skipped since noop is set" )
            @szOutput = ''
            @rc = 0
            return @rc
        end

        szCmd = "#{szCmd} 2>&1"
        if fIgnoreOutput
            szCmd = szCmd + ' 1>/dev/null'
            %x{#{szCmd}}
            @szOutput = ''
        else
            @szOutput = %x{#{szCmd}}
        end
        @rc = $?.to_i
        if !fIgnoreRC and (@rc != 0)
            raise RuntimeError,"invalid return code of #{@rc}"
        end
        return @rc
    end


    #----------------------------------------------------------------
    #           Issue a multiple-line command.
    #----------------------------------------------------------------

    def cmds( arrayCmds, fIgnoreRC=false, fIgnoreOutput=false )

        $LOG.debug( "CommonBase::cmds( #{arrayCmds} )" )

        if @fNoop
            @szOutput = ''
            @rc = 0
            return @rc
        end

        if arrayCmds.class != Array
            raise RuntimeError,'BashCommand:cmds requres an array!'
        end
        tempFile = Tempfile.new( 'bashscript' )
        szPath = tempFile.path
        endl = '\n'
        if @fDebug
            tempFile << '#!/bin/bash -xv' << endl
        else
            tempFile << '#!/bin/bash' << endl
        arrayCmds.each { |szCmd| tempFile << szCmd << endl }
        tempFile << '\texit\t$?' << endl
        tempFile.close
        File.chmod( 0750, szPath )
        begin
            self.cmd( szPath, fIgnoreOutput, fIgnoreRC )
            rescue RuntimeError
                File.delete( szPath )
                raise
            end
        end
        File.delete( szPath )
        return @rc

    end


    #----------------------------------------------------------------
    #   Issue an error message and exit with error.
    #----------------------------------------------------------------

    def die( szMsg, fDisplayUsage=false )

        $LOG.debug( "CommonBase::die( #{szMsg} )" )

        $LOG.fatal( "#{szMsg}!" )
        if fDisplayUsage && !@fQuiet
            $LOG.info @argvParser
        end
        @rc = 256
        @timeEnd = Time.new
        self.msgTerm
        exit( @rc )

    end


    #----------------------------------------------------------------
    #   Find the size of a directory/file in K.
    #----------------------------------------------------------------

    def dirSize( inputPath )

        $LOG.debug( "CommonBase::dirSize( #{inputPath} )" )

        accumSize = 0
        Find.find( inputPath ) do |curPath|
            if !FileTest.directory?(curPath)
                accumSize += FileTest.size(curPath)
            end
        end

        return (accumSize + 1023) / 1024

    end


    #----------------------------------------------------------------
    #           Ask for a Yes | No Response from the console
    #----------------------------------------------------------------

    def getReplyYN( szMsg, szDefault='y' )

        $LOG.debug( "CommonBase::getReplyYN( )" )

        if szDefault == 'y'
            szYN = 'Yn'
        else
            szYN = 'Ny'
        end

        while true
            puts "#{szMsg} #{szYN} <enter> or q<enter> to quit:"
            answer = STDIN.gets.chomp
            if answer == 'q'
                exit( 8 )
            end
            if answer == ''
                if szDefault == 'y'
                    return true
                else
                    return false
                end
            end
            if (answer == 'y') or (answer == 'Y')
                return true
            end
            if (answer == 'n') or (answer == 'N')
                return false
            end
            puts 'ERROR - invalid response,' + 
                 'please enter y | n | q followed by <enter>...'
        end

    end


    #----------------------------------------------------------------
    #           Simple File and Directory Routines
    #----------------------------------------------------------------

    def matchingFilesOrDir?( szPathPattern )

        $LOG.debug( "CommonBase::matchingFilesOrDir?( #{szPathPattern} )" )

        files = Dir.glob( szPathPattern )
        if 0 == files.length
            if File.directory?( szPathPattern )
                return true
            end
            return false
        else
            return true
        end

    end


    #----------------------------------------------------------------
    #               Display the startup message. 
    #----------------------------------------------------------------

    def msgStart( )

        if @fDebug
            $LOG.debug "CommonBase::msgStart( )"
        end

        if !@fQuiet || @fDebug
            $LOG.info(     "   Started: #{@timeStart}" )
        end
    end


    #----------------------------------------------------------------
    #               Display the termination message. 
    #----------------------------------------------------------------

    def msgTerm( )

        if @fDebug
            $LOG.debug "CommonBase::msgTerm( )"
        end

        if !@fQuiet || @fDebug
            $LOG.info(     "   Ended:   #{@timeEnd}" )
            if 0 == @rc
                $LOG.info( "Successful completion..." )
            else
                $LOG.info( "Unsuccessful completion of #{@rc}" )
            end
        end
    end


    #----------------------------------------------------------------
    #       Issue a one-line command with output to terminal.
    #----------------------------------------------------------------

    def sys( szCmd, fIgnoreRC=false )

        $LOG.debug( "CommonBase::sys( #{szCmd} )" )

        if @fQuiet
            return self.cmd( szCmd, fIgnoreRC )
        else
            $LOG.info( "executing: #{szCmd}" )
        end

        if @fNoop
            $LOG.debug( "cmd:#{szCmd} ==> skipped since noop is set" )
            @szOutput = ''
            @rc = 0
            return @rc
        end

        system( "#{szCmd} 2>&1" )
        @rc = $?.to_i
        $LOG.debug( "...ReturnCode = #{@rc}" )
        if !fIgnoreRC and (@rc != 0)
            raise RuntimeError,"invalid return code of #{@rc}"
        end

        return @rc
    end


    #----------------------------------------------------------------
    #           Issue a multiple-line command.
    #----------------------------------------------------------------

    def syss( arrayCmds, fIgnoreRC=false, fNeedSudo=false )

        $LOG.debug( "CommonBase::syss( #{arrayCmds} )" )

        if @fNoop
            @rc = 0
            return @rc
        end

        if arrayCmds.class != Array
            raise RuntimeError,'BashCommand:syss requires an array!'
        end
        tempFile = File.new( 'bashscript.sh', "w" )
        szPath = tempFile.path
        $LOG.debug( "...Setting up bash script file, #{szPath}" )
        endl = "\n"
        if @fDebug
            tempFile << '#!/bin/bash -xv' << endl
        else
            tempFile << '#!/bin/bash' << endl
        end
        arrayCmds.each { |szCmd| tempFile << szCmd << endl }
        tempFile << "\texit\t$?" << endl
        tempFile.close
        File.chmod( 0750, szPath )
        if fNeedSudo
            szCmd = "sudo ./#{szPath}"
            $LOG.debug( "...executing #{szCmd} as root" )
        else
            szCmd = "./#{szPath}"
            $LOG.debug( "...executing #{szCmd} as current user" )
        end

        system( "#{szCmd} 2>&1" )
        @rc = $?.to_i
        $LOG.debug( "...ReturnCode = #{@rc}" )
        if File.exist?( szPath )
            $LOG.debug( "...deleting file, #{szPath}" )
            File.delete( szPath )
        end
        if !fIgnoreRC and (@rc != 0)
            raise RuntimeError,"invalid return code of #{@rc}"
        end

        return @rc

    end


end




#################################################################
#                           DMG File Class 
#################################################################

class SparseImage < CommonBase

    attr_reader :fAttached, :fCreated,
                :device, :mountPoint,
                :path

    #################################################################
    #                       Methods
    #################################################################


    def initialize( )

        @fAttached = false
        @fCreated = false
        @device = ''
        @mountPoint = ''
        @path = ''

    end


    def attach( path='' )

        $LOG.debug(  "SparseImage::attach( #{path} )" )
        @fAttached = false
        if path.length > 0
            @path = path
        end

        $LOG.info( "...attaching #{@path}...")
        szCmd = "hdiutil attach -plist"
        szCmd <<= " \"#{@path}\""
        self.cmd( szCmd )
        $LOG.debug( @szOutput )
        returnedPlist = Plist::parse_xml( @szOutput )
        p returnedPlist

        @device = ''
        @mountPoint = ''
        @fAttached = true
        returnedPlist["system-entities"].each do |xx|
            if xx.has_key?("content-hint")
                if xx["content-hint"] == "Apple_HFS"
                    @device = xx["dev-entry"]
                    @mountPoint = xx["mount-point"]
                end
            end
        end

        $LOG.debug( "device = #{@device}" )
        $LOG.debug( "mountPoint = #{@mountPoint}" )

    end


    def chmod( options, destPath )

        $LOG.debug(  "SparseImage::chmod( #{options}, #{destPath) )" )

        if !((destPath.length > 0) && FileTest.exist?("\"#{@moutPoint}\#{destPath}\""))
            raise RuntimeError,"ERROR - SparseImage::dittoPath - bad input!"
        end


        $LOG.info( "...chmod #{options} on #{@moutPoint}\#{destPath}...")
        szCmd = "chmod #{options} \"#{@moutPoint}\#{destPath}\""
        self.cmd( szCmd )

    end


    def convertToCompressedImage( newImagePath )

        $LOG.debug(  "SparseImage::convertToCompressedImage( #{newImagePath}, #{volName} )" )

        if !((newImagePath.length > 0) && (@path.length > 0) && FileTest.exist?(@path))
            raise RuntimeError,"ERROR - SparseImage::convertToCompressedImage - bad input!"
        end

        $LOG.info( "...creating #{newImagePath}, a compressed image of #{@path}...")
        szCmdA = "hdiutil convert \"#{@path}\""
        szCmdB = " -format UDZO -plist -imagekey zlib-level=9 -o "
        szCmdC = " \"#{newImagePath}\""
        szCmd = szCmdA << szCmdB << szCmdC
        self.cmd( szCmd )
        $LOG.debug( @szOutput )
        returnedPlist = Plist::parse_xml( @szOutput )
        #p returnedPlist
        @compressedImagePath = returnedPlist[0]
        $LOG.debug( "compressedImagePath = #{@compressedImagePath}" )

    end


    def create( tempFileFullPath, volumeName, imageSize, fAttach=false )

        $LOG.debug(  "SparseImage::createSparseImage( #{tempFileFullPath}, " <<
                        "#{volumeName}, #{imageSize} )"
        )

        if imageSize <= 0
            raise RuntimeError,"ERROR - SparseImage::create received an invalid size!"
        end
        iSizeM = ((2 * imageSize) + 1024 - 1) / 1024          # add some extra space in while converting.

        $LOG.info( "...creating a #{iSizeM}M SparseImage...")
        if fAttach
            hdiutilOptions = "-attach"
        else
            hdiutilOptions = ""
        end
        szCmdA = "hdiutil create #{hdiutilOptions} \"#{tempFileFullPath}\""
        szCmdB = " -volname \"#{volumeName}\" -plist "
        szCmdC = " -megabytes #{iSizeM} -type SPARSE -fs HFS+ -autostretch"
        szCmd = szCmdA << szCmdB << szCmdC
        self.cmd( szCmd )
        $LOG.debug( @szOutput )
        returnedPlist = Plist::parse_xml( @szOutput )
        #p returnedPlist
        @fAttached = false
        @device = ''
        @mountPoint = ''
        if fAttach
            @path = returnedPlist["image-components"]
            @fAttached = true
            returnedPlist["system-entities"].each do |xx|
                if xx.has_key?("content-hint")
                    if xx["content-hint"] == "Apple_HFS"
                        @device = xx["dev-entry"]
                        @mountPoint = xx["mount-point"]
                    end
                end
            end
        else
            @path = returnedPlist[0]
        end
        $LOG.debug( "path = #{@path}" )
        $LOG.debug( "device = #{@device}" )
        $LOG.debug( "mountPoint = #{@mountPoint}" )
        @fCreated = true

    end


    def detach( )

        $LOG.debug(  "SparseImage::detach( )" )

        if !@fAttached
            raise RuntimeError,"ERROR - SparseImage::detach - no attached image!"
        end

        $LOG.info( "...detaching a #{@path} as #{@mountPoint}...")
        szCmd = "hdiutil detach #{@device}"
        self.cmd( szCmd )
        $LOG.debug( @szOutput )
        @fAttached = false
        @device = ''
        @mountPoint = ''

    end


    def dittoPath( srcPath, destPath='' )

        $LOG.debug(  "SparseImage::dittoPath( #{srcPath}, #{destPath) )" )

        if !((srcPath.length > 0) && @fAttached)
            raise RuntimeError,"ERROR - SparseImage::dittoPath - bad input!"
        end
        if !((destPath.length > 0) && FileTest.exist?("\"#{@moutPoint}\#{destPath}\""))
            raise RuntimeError,"ERROR - SparseImage::dittoPath - bad input!"
        end


        $LOG.info( "...copying #{sourcePath} to #{@moutPoint}\#{destPath}...")
        szCmd = "ditto -rsrc \"sourcePath\" \"#{@moutPoint}\#{destPath}\""
        self.cmd( szCmd )

    end


    def mkdir( newPath )

        $LOG.debug(  "SparseImage::mkdir( #{newPath} )" )

        if !((newPath.length > 0) && @fAttached)
            raise RuntimeError,"ERROR - SparseImage::mkdir - bad input!"
        end

        $LOG.info( "...creating #{newPath} in #{@path}...")
        szCmd = "mkdir -P \"#{@moutPoint}\#{newPath}\""
        self.cmd( szCmd )

    end


end




#################################################################
#               Command Line Application Class 
#################################################################

class CliApp < CommonBase

    attr_reader :fDebug, :fLog, :fVerbose, :fQuiet,
                :rc, :szOutput, :fNoop, :fShellMore
    attr_writer :fDebug, :fLog, :fNoop, :fShellMore, :fQuiet, :fVerbose

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( )

        @fDebug             = false
        @fForce             = false
        @fLog               = false
        @fNoop              = false
        @fQuiet             = false
        @fShellMore         = true
        @fSkipOutput        = false
        @fVerbose           = false
        @fileDateTime       = Time.new.strftime( "%Y%m%d-%H%M%S" )
        @options            = OpenStruct.new
        @rc                 = 0
        @szOutput           = [ ]

        @scriptStartupDirectory = Dir.getwd
        @timeStart = Time.new
        self.optionsDefaultSetup

    end


    #----------------------------------------------------------------
    #                   Set up ARGV parser.
    #----------------------------------------------------------------

    def argvParseArguments( )

        $LOG.debug( "CliApp::argvParseArguments( #{@args} )" )

=begin
        if 0 < @args.length
            @args.each do |phase|
                case phase
                    when "all" 
                        @options.fDoBuild=true
                    when "build" 
                        @options.fDoBuild=true
                    else
                        die "FATAL - found invalid phase: #{phase}"
                end
            end
        else
            @options.fDoBuild=true
        end
=end

    end


    #----------------------------------------------------------------
    #                   Set up ARGV parser.
    #----------------------------------------------------------------

    def argvParserSetup( )

        $LOG.debug( "CliApp::argvParserSetup( )" )

        @argvParser = OptionParser.new
        self.argvParserSetupBegin
        self.argvParserSetupOptions

    end


    #----------------------------------------------------------------
    #                   Set up ARGV parser.
    #----------------------------------------------------------------

    def argvParserSetupBegin( )

        $LOG.debug( "CliApp::argvParserSetupBegin( )" )

=begin
        @argvParser.banner = "xyzzy"
        @argvParser.separator( "Usage:" )
        @argvParser.separator( " #{$0} [see Flags below]* [see Arguments below]*" )
        @argvParser.separator( "  This script does nothing right now!" )
        @argvParser.separator( "  If the script is started without parameters, 'all' is assumed." )
        @argvParser.separator( "" )
        @argvParser.separator( "Arguments:" )
        @argvParser.separator( "  all             Execute all phases in the order given below:" )
        @argvParser.separator( "" )
=end

    end


    #----------------------------------------------------------------
    #                   Set up ARGV parser.
    #----------------------------------------------------------------

    def argvParserSetupOptions( )

        $LOG.debug( "CliApp::argvParserSetupOptions( )" )

        @argvParser.separator( "Options:" )
        @argvParser.on( "-d", "--[no-]debug", "set debugging mode") do |x|
            @fDebug = x
            $LOG.level = Logger::DEBUG
        end
        @argvParser.on( "-f", "--[no-]force", "force actions") do |x|
            @fForce = x
        end
        @argvParser.on( "-h", "--help", "display this usage help") do |x|
            $LOG.info @argvParser.to_s
            exit( 256 )
        end
        @argvParser.on( "--[no-]noop", "just simulate actions") do |x|
            @fNoop = x
        end
        @argvParser.on( "-q", "--[no-]quiet", "set quiet option") do |x|
            @fQuiet = x
        end
        @argvParser.on( "-v", "--[no-]verbose", "set verbose option") do |x|
            @fVerbose = x
            $LOG.level = Logger::DEBUG
        end

    end


    #----------------------------------------------------------------
    #           Simple File and Directory Routines
    #----------------------------------------------------------------

    def matchingFilesOrDir?( szPathPattern )

        $LOG.debug( "CliApp::matchingFilesOrDir?( #{szPathPattern} )" )

        files = Dir.glob( szPathPattern )
        if 0 == files.length
            if File.directory?( szPathPattern )
                return true
            end
            return false
        else
            return true
        end

    end


    #----------------------------------------------------------------
    #                       Main Procedure
    #----------------------------------------------------------------

    def main( argv )

        $LOG.debug( "CliApp::main( #{argv} )" )

        # Do initialization.
        @argv = argv
        @timeStart = Time.new
        self.msgStart
        self.optionsDefaultSetup

        # Now parse the command line.
        self.argvParserSetup
        begin
            @args = @argvParser.parse( @argv )
        rescue OptionParser::ParseError => error
            die( "argument error: #{error}", true )
        end
        self.argvParseArguments
        self.optionsOverride
        self.optionsValidate

        @rc = self.run

        @timeEnd = Time.new
        self.msgTerm
        return @rc

    end


    #----------------------------------------------------------------
    #               Setup initial Options in @options.
    #----------------------------------------------------------------

    def optionsDefaultSetup( )

        $LOG.debug( "CliApp::optionsDefaultSetup( )" )

        if $DEBUG
            @fDebug = true
            $LOG.level = Logger::DEBUG
        end
        if $VERBOSE
            @fVerbose = true
        end

    end


    #----------------------------------------------------------------
    #   Allow options to be overridden before processing begins.
    #----------------------------------------------------------------

    def optionsOverride( )

        $LOG.debug( "CliApp::optionsOverride( )" )

    end


    #----------------------------------------------------------------
    #                       Validate the options.
    #----------------------------------------------------------------

    def optionsValidate( )

        $LOG.debug( "CliApp::optionsValidate( )" )

    end


    #----------------------------------------------------------------
    #                   Execute the Application Logic.
    #----------------------------------------------------------------

    def run( )

        $LOG.debug( "CliApp::run( )" )

        return( 0 )

    end


    #----------------------------------------------------------------
    #               Create a shell for user input.
    #----------------------------------------------------------------

    def shell( szPrompt='>' )

        while @fShellMore and cmdline = Readline.readline( szPrompt, true )
            cmd, *args = Shellwords.shellwords( cmdline )
            next if cmd.to_s.chomp == ''
            @fShellMore = self.shellParse( cmd, *args )
        end

    end


    #----------------------------------------------------------------
    #                   Perform 'exit' command.
    #----------------------------------------------------------------

    def shellExit( *args )

        return false

    end


    #----------------------------------------------------------------
    #                   Perform 'help' command.
    #----------------------------------------------------------------

    def shellHelp( *args )

        return true

    end


    #----------------------------------------------------------------
    #               Parse and execute a shell command.
    #----------------------------------------------------------------

    def shellParse( cmd, *args )

        case args[0]
        when 'exit', 'x'
            return self.shellExit( *args )
        when 'help', 'h', '?'
            return self.shellHelp( *args )
        else
            return self.shellParseMore( cmd, *args )
        end

        return true

    end


    #----------------------------------------------------------------
    #               Parse and execute a shell command.
    #----------------------------------------------------------------

    def shellParseMore( cmd, *args )

        return true

    end


end




#################################################################
#                       File Additions 
#################################################################

class File


    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Versioned File 
    #----------------------------------------------------------------

    # Create basically a push-down stack of a file with the last saved
    # version being the highest numbered and baseFilePath being the
    # latest version.  So, restoration would be to replace the baseFilePath
    # with the highest numbered file.  Slightly different approach than
    # was taken in "Ruby Cookbook", Lucas Carlson and Leonard Richardson,
    # O'Reilly, 2006.


    def versionedFileRestore( baseFilePath )

        suffix = 1000
        loop do
            suffix = suffix - 1
            if suffix < 1
                raise RuntimeError,'Suffix is too large'
            end
            newFileName = baseFilePath + '.' + suffix.to_s.rjust(3,'0')
            if File.exist?( newFilePath )
                FileUtils.cp( newFilePath, baseFilePath )
                File.delete( newFilePath )
                return suffix
            end
        end

    end


    def versionedFileSave( baseFilePath )

        suffix = 0
        loop do
            suffix = suffix + 1
            if suffix > 999
                raise RuntimeError,'Suffix is too large'
            end
            newFileName = baseFilePath + '.' + suffix.to_s.rjust(3,'0')
            unless File.exist?( newFilePath )
                FileUtils.cp( baseFilePath, newFilePath )
                return suffix
            end
        end

    end


end



#################################################################
#                       Main Class 
#################################################################

class ApplicationMain < CliApp


    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( )

        super

        @baseDir            = Dir.getwd
        @macosxDir          = "#{@baseDir}/macosx"
        @tarballDir         = "#{@macosxDir}/unixTars"
        @userTemplateDir    = "/System/Library/User Template/English.lproj"

    end


    #----------------------------------------------------------------
    #                   Set up ARGV parser.
    #----------------------------------------------------------------

    def argvParseArguments( )

        $LOG.debug( "Setup01App::argvParseArguments( #{@args} )" )
        super

        if 0 < @args.length
            @args.each do |phase|
                case phase
                    when "all" 
                        @options.fDoApps=true
                        @options.fDoBash=true
                        @options.fDoDesktop=true
                        @options.fDoFinder=true
                        @options.fDoGroups=true
                        @options.fDoHttpd=true
                        @options.fDoSafari=true
                        @options.fDoShared=true
                        @options.fDoSoftwareUpdate=true
                        @options.fDoUsers=true
                        @options.fDoXcode=true
                    when "apps" 
                        @options.fDoApps=true
                    when "apps_no" 
                        @options.fDoApps=false
                    when "bash" 
                        @options.fDoBash=true
                    when "bash_no" 
                        @options.fDoBash=false
                    when "desktop" 
                        @options.fDoDesktop=true
                    when "desktop_no" 
                        @options.fDoDesktop=false
                    when "finder" 
                        @options.fDoFinder=true
                    when "finder_no" 
                        @options.fDoFinder=false
                    when "groups" 
                        @options.fDoGroups=true
                    when "groups_no" 
                        @options.fDoGroups=false
                    when "httpd" 
                        @options.fDoHttpd=true
                    when "httpd_no" 
                        @options.fDoHttpd=false
                    when "safari" 
                        @options.fDoSafari=true
                    when "safari_no" 
                        @options.fDoSafari=false
                    when "shared" 
                        @options.fDoShared=true
                    when "shared_no" 
                        @options.fDoShared=false
                    when "softwareupdate" 
                        @options.fDoSoftwareUpdate=true
                    when "softwareupdate_no" 
                        @options.fDoSoftwareUpdate=false
                    when "users" 
                        @options.fDoUsers=true
                    when "users_no" 
                        @options.fDoUsers=false
                    when "xcode" 
                        @options.fDoXcode=true
                    when "xcode_no" 
                        @options.fDoXcode=false
                    else
                        die "FATAL - found invalid phase: #{phase}"
                end
            end
        else
            @options.fDoApps=true
            @options.fDoBash=true
            @options.fDoDesktop=true
            @options.fDoFinder=true
            @options.fDoGroups=true
            @options.fDoHttpd=true
            @options.fDoSafari=true
            @options.fDoShared=true
            @options.fDoSoftwareUpdate=true
            @options.fDoUsers=true
            @options.fDoXcode=true
        end

    end


    #----------------------------------------------------------------
    #               Set up ARGV parser. 
    #----------------------------------------------------------------

    def argvParserSetupBegin( )

        $LOG.debug( "Setup01App::argvParserSetupBegin( )" )

        super

        @argvParser.banner = "Setup Phase 1 for MacOSX"
        @argvParser.separator( "Usage:" )
        @argvParser.separator( " #{$0} [see Flags below]* [see Phases below]*" )
        @argvParser.separator( "  This script initializes the common parameters and" )
        @argvParser.separator( "  installs the base applications for MacOSX 10.4+." )
        @argvParser.separator( "  If the script is started without parameters, 'all' is assumed." )
        @argvParser.separator( "" )
        @argvParser.separator( "Phases:" )
        @argvParser.separator( "  all             Execute all phases in the order given below:" )
        @argvParser.separator( "  apps            Set up Applications" )
        @argvParser.separator( "  bash            Set up Bash parameters and files" )
        @argvParser.separator( "  desktop         Set up Desktop Services" )
        @argvParser.separator( "  finder          Set up Finder.app" )
        @argvParser.separator( "  groups          Set up Groups" )
        @argvParser.separator( "  httpd           Set up httpd" )
        @argvParser.separator( "  safari          Set up Safari.app" )
        @argvParser.separator( "  shared          Set up Shared User" )
        @argvParser.separator( "  softwareupdate  Set up Software Update" )
        @argvParser.separator( "  xcode           Set up Xcode" )
        @argvParser.separator( "  users           Set up Users" )
        @argvParser.separator( "" )
        @argvParser.separator( "  If a phase name has a suffix of '_no', then that" )
        @argvParser.separator( "  phase is not executed." )
        @argvParser.separator( "" )

    end


    #----------------------------------------------------------------
    #                   Set up ARGV parser.
    #----------------------------------------------------------------

    def argvParserSetupOptions( )

        $LOG.debug( "ThisApp::argvParserSetupOptions( )" )

        super

        @argvParser.on( "-b", "--base", "set base directory") do |x|
            @baseDir = x
        end

    end


    #----------------------------------------------------------------
    #               Create /usr/local so we can use it. 
    #----------------------------------------------------------------

    def createUsrLocal( )

        $LOG.debug(  "Setup01App::createUsrLocal( )" )

        self.msgInfo( "Creating /usr/local directories..." )
        self.msgInfo( "Please enter your password if requested..." )
        self.sys( 'sudo mkdir -p /usr/local/bin' )
        self.sys( 'sudo mkdir -p /usr/local/bin/X11' )
        self.sys( 'sudo mkdir -p /usr/local/include' )
        self.sys( 'sudo mkdir -p /usr/local/include/X11' )
        self.sys( 'sudo mkdir -p /usr/local/lib' )
        self.sys( 'sudo mkdir -p /usr/local/lib/X11' )
        self.sys( 'sudo mkdir -p /usr/local/share/info' )
        self.sys( 'sudo ln -s    /usr/local/share/info /usr/local/info', true )
        self.sys( 'sudo mkdir -p /usr/local/share/man' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man1' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man2' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man3' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man4' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man5' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man6' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man7' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man8' )
        self.sys( 'sudo mkdir -p /usr/local/share/man/man9' )
        self.sys( 'sudo ln -s    /usr/local/share/man  /usr/local/man', true )
        self.sys( "sudo mkdir -p \"#{@userTemplateDir}/Library/Preferences\"" )
        ENV['PATHOLD'] = ENV['PATH']
        ENV['PATH'] = "/usr/local/bin:#{ENV['PATH']}"

    end


    #----------------------------------------------------------------
    #               Set up required Libraries and Applications. 
    #----------------------------------------------------------------

    def doApps( )

        $LOG.debug( "Setup01App::doApps( )" )

        self.msgInfo( "Installing required libraries and applications..." )
        Dir.chdir( "/Applications" ) do
            if !File.directory?( "Freecell.app" )
                self.sys( "tar xjvf #{@tarballDir}/Freecell.tar.bz2" )
            end
# Gimp now has several different distributions according intel vs ppc and 10.4 vs 10.5.
#            if !File.directory?( "Gimp.app" )
#                self.sys( "tar xjvf #{@tarballDir}/Gimp.tar.bz2" )
#            end
            if !File.directory?( "HandBrake-0.9.2" )
                self.sys( "tar xjvf #{@tarballDir}/HandBrake-0.9.2.tar.bz2" )
            end
            if !File.directory?( "Macdoku.app" )
                self.sys( "tar xjvf #{@tarballDir}/macdoku.0.5.tar.bz2" )
            end
            if !File.directory?( "MacSolitaire" )
                self.sys( "tar xjvf #{@tarballDir}/MacSolitaire.tar.bz2" )
            end
            if !File.directory?( "MacTheRipper.app" )
                self.sys( "tar xjvf #{@tarballDir}/MacTheRipper.tar.bz2" )
            end
#            if !File.directory?( "Chicken of the VNC.app" )
#                self.sys( "tar xjvf #{@tarballDir}/chickenofthevnc.tar.bz2" )
#            end
            if !File.directory?( "iStumbler.app" )
                self.sys( "tar xjvf #{@tarballDir}/istumbler.tar.bz2" )
            end
            if !File.directory?( "MPlayer OSX.app" )
                self.sys( "tar xjvf #{@tarballDir}/mplayerOSX-1.0.rc2.tar.bz2" )
            end
            if !File.directory?( "Ocean Waves.app" )
                self.sys( "tar xjvf #{@tarballDir}/oceanWaves-1.4.tar.bz2" )
            end
            if !File.directory?( "serverAdmin" )
                self.sys( "tar xjvf #{@tarballDir}/serverAdmin-10.5.tar.bz2" )
            end
            if !File.directory?( "vim70" )
                self.sys( "tar xjvf #{@tarballDir}/vim7.0.tar.bz2" )
            end
        end

        begin
            lookFor = "org_wasters_Freecell_plist.txt"
            filePath = self.versionedPath( lookFor )
        rescue
            print "Warning: could not find file: " + lookFor + "!"
        else
            self.sys( "cp \"#{filePath}\" \"#{ENV['HOME']}/Library/Preferences/org.wasters.Freecell.plist\"" )
            self.sys( "sudo cp \"#{filePath}\" \"#{@userTemplateDir}/Library/Preferences/org.wasters.Freecell.plist\"" )
        end

        begin
            lookFor = "com_apple_Terminal_plist.txt"
            filePath = self.versionedPath( lookFor )
        rescue
            print "Warning: could not find file: " + lookFor + "!"
        else
            self.sys( "cp \"#{filePath}\" \"#{ENV['HOME']}/Library/Preferences/com.apple.Terminal.plist\"" )
            self.sys( "sudo cp \"#{filePath}\" \"#{@userTemplateDir}/Library/Preferences/com.apple.Terminal.plist\"" )
        end

        begin
            lookFor = "vimSetup.tar.bz2"
            filePath = self.versionedPath( lookFor )
        rescue
            print "Warning: could not find file: " + lookFor + "!"
        else
            self.sys( "tar xjvf #{filePath} --directory #{ENV['HOME']}" )
            self.sys( "sudo tar xjvf #{filePath} --directory \"#{@userTemplateDir}\"" )
        end

        Dir.chdir( "#{@macosxDir}" ) do
            # The installation of the autotools was determined by
            # running 'make check' until they all worked.
            if ( @osPanther || @osTiger )
                self.sys( "./mkM4.rb all" )
                self.sys( "./mkAutomake.rb all" )
                self.sys( "./mkAutoconf.rb all" )
                self.sys( "./mkLibtool.rb all" )
            end
            # Now let's do a bunch of libraries
            if ( @osPanther || @osTiger )
                self.sys( "./mkLibreadline.rb all" )
                self.sys( "./mkLibexpat.rb all" )
            end
            self.sys( "./mkLibjpeg.rb all" )
            self.sys( "./mkLiblame.rb all" )
            self.sys( "./mkLibpng.rb all" )
            self.sys( "./mkLibrsync.rb all" )
            self.sys( "./mkLibtiff.rb all" )
            #self.sys( "./mkLibxpm.sh all" )    # currently fails, found imake in /usr/X11R6/bin
            self.sys( "./mkLibgd.rb all" )
            #self.sys( "./mkLibSDL.rb all" )	# might need a new version; in Leopard, coreaudio doesnt compile
            # Now let's start installing applications.
            self.sys( "./mkGit.rb all" )
            self.sys( "./mkGnupg.rb all" )
            self.sys( "./mkPkgconfig.rb all" )
            if ( @osPanther || @osTiger )
                self.sys( "./mkRuby.rb all" )
                #self.sys( "./mkSvn.rb all" )
            end
            self.sys( "./mkXMahjongg.rb all" )
            #self.sys( "./mkLibx264.rb all" )
            #self.sys( "./mkMplayer.rb all" )
            #self.sys( "./mkMacVim.rb all" )
        end

    end


    #----------------------------------------------------------------
    #                       Set up Bash. 
    #----------------------------------------------------------------

    def doBash( )

        $LOG.debug(  "Setup01App::doBash( )" )

        if ( @osPanther || @osTiger )
            begin
                lookFor = "etc_profile_patch.txt"
                filePath = self.versionedPath( lookFor )
            rescue
                print "Warning: could not find file: " + lookFor + "!"
            else
               self.sys( "sudo patch -b /etc/profile \"#{filePath}\"" )
            end
        end

        begin
            lookFor = "bash_profile.txt"
            filePath = self.versionedPath( lookFor )
        rescue
            print "Warning: could not find file: " + lookFor + "!"
        else
            self.sys( "cp \"#{filePath}\" \"#{ENV['HOME']}/.bash_profile\"" )
            self.sys( "sudo cp \"#{filePath}\" \"#{@userTemplateDir}/.bash_profile\"" )
        end

        begin
            lookFor = "bashrc.txt"
            filePath = self.versionedPath( lookFor )
        rescue
            print "Warning: could not find file: " + lookFor + "!"
        else
            self.sys( "cp \"#{filePath}\" \"#{ENV['HOME']}/.bashrc\"" )
            self.sys( "sudo cp \"#{filePath}\" \"#{@userTemplateDir}/.bashrc\"" )
        end

    end


    #----------------------------------------------------------------
    #                       Set up Desktop Services. 
    #----------------------------------------------------------------

    def doDesktop( )

        $LOG.debug(  "Setup01App::doDesktop( )" )

        self.sys( "defaults write /Library/Preferences/com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE" )

    end


    #----------------------------------------------------------------
    #                       Set up Dock. 
    #----------------------------------------------------------------

    def doDock( )

        $LOG.debug(  "Setup01App::doDock( )" )

        raise NotImplementedError, "doDock is not finished!"

        begin
            lookFor = "com_apple_dock_plist.txt"
            filePath = self.versionedPath( lookFor )
        rescue
            print "Warning: could not find file: " + lookFor + "!"
        else
            self.sys( "cp \"#{filePath}\" \"#{ENV['HOME']}/Library/Preferences/com.apple.dock.plist\"" )
            self.sys( "sudo cp \"#{filePath}\" \"#{@userTemplateDir}/Library/Preferences/com.apple.dock.plist\"" )
        end

    end


    #----------------------------------------------------------------
    #                       Set up Finder.app. 
    #----------------------------------------------------------------

    def doFinder( )

        $LOG.debug(  "Setup01App::doFinder( )" )

        self.sys( "defaults write /Library/Preferences/.GlobalPreferences AppleShowAllExtensions -int 1" )
        self.sys( "defaults write /Library/Preferences/.GlobalPreferences com.apple.mouse.tapBehavior -int 2" )
        self.sys( "defaults write /Library/Preferences/.GlobalPreferences com.apple.trackpad.enableSecondaryClick -int 1" )
        self.sys( "defaults write /Library/Preferences/.GlobalPreferences com.apple.trackpad.scrollBehavior -int 2" )
        self.sys( "defaults write /Library/Preferences/finder AlwaysOpenWindowsInColumnView -int 1" )
        self.sys( "defaults write /Library/Preferences/finder WarnOnEmptyTrash -int 0" )

    end


    #----------------------------------------------------------------
    #                       Set up our groups. 
    #----------------------------------------------------------------

    def doGroups( )

        $LOG.debug(  "Setup01App::doGroups( )" )

        self.groupsAdd

    end


    #----------------------------------------------------------------
    #                       Set up httpd. 
    #----------------------------------------------------------------

    def doHttpd( )

        $LOG.debug(  "Setup01App::doHttpd( )" )

        if !@osServer
            begin
                lookFor = "etc_httpd_httpd_conf_patch_client.txt"
                filePath = self.versionedPath( lookFor )
            rescue
                print "Warning: could not find file: " + lookFor + "!"
            else
                self.sys( "sudo patch -b /etc/httpd/httpd.conf \"#{filePath}\"" )
            end
            begin
                lookFor = "etc_php_ini.txt"
                filePath = self.versionedPath( lookFor )
            rescue
                print "Warning: could not find file: " + lookFor + "!"
            else
                self.sys( "sudo cp \"#{filePath}\" /etc/php.ini" )
            end
            begin
                lookFor = "etc_my_cnf.txt"
                filePath = self.versionedPath( lookFor )
            rescue
                print "Warning: could not find file: " + lookFor + "!"
            else
                self.sys( "sudo cp \"#{filePath}\" /etc/my.cnf" )
            end
        end

    end


    #----------------------------------------------------------------
    #                     Do Main Processing
    #----------------------------------------------------------------

    def run( )

        $LOG.debug( "ApplicationMain::run( )" )


        oSparseImage = SparseImage.new
        oSparseImage.create( "xyzzy.dmg", "xyzzy", 2048, true )
        oSparseImage.detach
        oSparseImage.attach( oSparseImage.path )
        oSparseImage.detach
        oSparseImage.attach( )
        oSparseImage.detach
        exit 0


        # Perform the various phases.
        self.createUsrLocal
        if defined? @options.fDoApps
            self.msgInfo( "Setting up Apps..." )
            self.doApps
        end
        
        return 0

    end


end




#----------------------------------------------------------------
#                       Main Program
#----------------------------------------------------------------

    $LOG = Logger.new( $stderr )
    $LOG.level = Logger::INFO
    if $DEBUG
        $LOG.level = Logger::DEBUG
    end

    oApp = ApplicationMain.new
    #oApp.fNoop = true
    rc = oApp.main( ARGV )
    exit rc


