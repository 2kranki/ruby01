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

    localLib = File.join( File.dirname(__FILE__), "..", "lib" )
    if File.directory?( localLib )
        $:.unshift( localLib )
    end
    localLib = File.join( File.dirname(__FILE__), "lib" )
    if File.directory?( localLib )
        $:.unshift( localLib )
    end
    localLib = File.join( File.dirname(__FILE__), "macosx", "lib" )
    if File.directory?( localLib )
        $:.unshift( localLib )
    end


    require     "consoleSupport"
    require     "macosxBasePhases"
    require     "macosxDMG"
    require     "macosxLocalUsersAndGroups"
    require     "versionedPath"



#################################################################
#                   Package Installation Class 
#################################################################

class ThisApp < MacOSXBasePhases


    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( )

        super

        $oConsole = ConsoleSupport.instance
		$oUnix = UnixCommands.instance
		$oVerPath = VersionedPath.instance


        #   For up-to-date documentation on the following three variables,
        #   @cliTitle, @cliDesc and @cliPhases, see CliApp::initialize.

        #   The title string providing a very synopsis of the program
		@cliTitle = "a title sentence for this program"

        #   An array of strings which describe the program in
        #   more detail than @cliTitle.
        @cliDesc  = [
						"This does something, but",
						"I am not sure what."
					]

		#   An arrary of arrays that describes each phase.
        #   The sub-array must have at least the following
        #   elements:
        #       [0] == Phase Name
        #       [1] == Phase Description
        #       [2] == Include in run phasess
        @cli_run_phases = [
						[ "bash", "set up bash" ],
						[ "battery_percentage", "Show battery percentage" ],
						[ "dsstore", "turn off .DSStore on network disks" ],
						[ "finder", "set up finder" ],
						[ "library", "unhide Library Directory" ],
						[ "safari", "set up safari" ],
						[ "ssh", "set up ssh certificates" ],
						[ "terminal", "set up Terminal.app" ],
						[ "timemachine", "set up TimeMachine" ],
						[ "vim", "set up vi/vim/macvim" ],
						[ "xcode4", "set up Xcode 4" ],
						[ "xcode5", "set up Xcode 5" ],
					 ]

        @cli_postrun_phases = [
						[ "create", "creates all our Groups and Users" ],
                        [ "safari_save", "save off the current Safari defaults" ],
					 ]

		@baseDir = Dir.getwd
        @macosxDir = "#{@baseDir}/macosx"
        @tarballDir = "#{@macosxDir}/unixTars"
        @templateDir = "/System/Library/User\\ Template/English.lproj"
        @fTemplate = false

        $oVerPath.osDir = @baseDir
        $oVerPath.osName = @computerProfile.osName
        $oVerPath.osVersion = @computerProfile.osVersion
        $oVerPath.osType = @computerProfile.osType
        $oVerPath.computerName = @computerProfile.computerName
    end


    #----------------------------------------------------------------
    #                   Set up ARGV parser.
    #----------------------------------------------------------------

    def argvParserSetupOptions( )

        $oLog.logDebug( "#{self.class.name}::argvParserSetupOptions( )" )

        super

        @argvParser.on( "-b", "--base", "=PATH", "setup base directory for output file" ) do |dir|
            @baseDir = dir
        end
        @argvParser.on( "--spcl", "=PATH", "set base of rmwSpcl") do |x|
            @spclDir = x
        end
        @argvParser.on( "--[no-]template", "use English Template rather than current user") do |x|
            @fTemplate = x
        end

    end


    #----------------------------------------------------------------
    #               Setup the Application, Freecell
    #----------------------------------------------------------------

    def copyPreference( sourceName, plistName )

        $oLog.logDebug( "#{self.class.name}::copyPreference( )" )

        plistPath = "#{@homeDir}/Library/Preferences/#{plistName}"
        if !File.exist?( sourceName )
            $oVerPath.copyFile( sourceName, plistPath, "600", @owner, @group, @fSudo )
        end

    end


    #----------------------------------------------------------------
    #                     Main Pre Processing
    #----------------------------------------------------------------

    def mainPre( )

        $oLog.logDebug( "#{self.class.name}::mainPre( )" )

    end


    #----------------------------------------------------------------
    #                     Main Post Processing
    #----------------------------------------------------------------

    def mainPost( )

        $oLog.logDebug( "#{self.class.name}::mainPost( )" )

        if defined? @spclDmg
            @spclDmg = nil
        end

    end


    #----------------------------------------------------------------
    #                     Mount the Special DMG
    #----------------------------------------------------------------

    def mountSpecialDMG( )

        $oLog.logDebug( "#{self.class.name}::mountSpecialDMG( )" )

        if defined? @spclDmg
        else
            @spclDmg = MacosxDMG.new
            @spclDmg.attach( File.join(@macosxDir, "rmwSpcl.sparseimage") )
            @spclMount = @spclDmg.mountedVolume
            $oLog.logDebug( "\tspclMount = #{@spclMount}" )
        end


    end


    #----------------------------------------------------------------
    #				        Set up Bash
    #----------------------------------------------------------------

    def phase_bash( )
        $oLog.logDebug( "#{self.class.name}::phase_bash( )" )

        begin
            $oVerPath.copyFile( 
                    "bash_profile.txt",
                    "#{@homeDir}/.bash_profile",
                    "600",
                    @owner,
                    @group,
                    @fSudo
            )
        rescue
            raise RuntimeError, "could not find file: bash_profile.txt!"
        end

        begin
            $oVerPath.copyFile( 
                    "bashrc.txt",
                    "#{@homeDir}/.bashrc",
                    "600",
                    @owner,
                    @group,
                    @fSudo
            )
        rescue
            raise RuntimeError, "could not find file: bashrc.txt!"
        end

        $oLog.logInfo( "You must restart Terminal.app to utilize these changes!" )
    end


    #----------------------------------------------------------------
    #               Turn on Percentage Display on Battery 
    #----------------------------------------------------------------

    def phase_battery_percentage( )

        $oLog.logDebug(  "#{self.class.name}::phase_battery_percentage( )" )

        szCmd = "defaults write #{@homeDir}/Library/Preferences/"
        szCmd = "#{szCmd}com.apple.menuextra.battery"
        $oCmd.sys( "#{szCmd} ShowPercent YES", false, @fSudo )

    end


    #----------------------------------------------------------------
    #                 Create all our groups and users. 
    #----------------------------------------------------------------

    def phase_create( )

        $oLog.logDebug(  "#{self.class.name}::phase_create( )" )

        groupPlist = Plist::parse_xml( File.join(@baseDir,"users","groups.xml") )
        userPlist = Plist::parse_xml( File.join(@baseDir,"users","users.xml") )
        grpsUsrs = MacosxLocalUsersAndGroups.new
        usersAdded = []

        # Create our groups
        groupPlist.each do |group|
            grpsUsrs.groupAdd( group['name'], group['gid'] )
        end

        # Create our users
        userPlist.each do |user|
            rc =    grpsUsrs.userAdd( 
                        user['name'],
                        user['uid'],
                        user['gid']
                    )
            if rc
                usersAdded << user['name']
            end
        end

        # Now set the password for the added users
        if defined? @spclDir
            usersAdded.each do |user|
                grpsUsrs.userPasswordSetSpcl( 
                    user,
                    @spclDir
                )
            end
        else
            self.mountSpecialDMG
            usersAdded.each do |user|
                grpsUsrs.userPasswordSetSpcl( 
                    user,
                    @spclDmg.mountedVolume
                )
            end
        end

        # Now add the users to the appropriate secondary groups
        userPlist.each do |user|
            user['secondary_groups'].each do |group|
                grpsUsrs.groupAddUserTo( 
                    group,
                    user['name']
                )
            end
        end

    end


    #----------------------------------------------------------------
    #				        Set up Dock			
    #----------------------------------------------------------------

    def phase_dock( )
        $oLog.logDebug(  "#{self.class.name}::phase_dock( )" )

        self.copyPreference( 
                            "com_apple_dock_plist.txt",
                            "com.apple.dock.plist"
        )

    end


    #----------------------------------------------------------------
    #               Turn off .DS_Store on Network Stores
    #----------------------------------------------------------------

    def phase_dsstore( )

        $oLog.logDebug(  "#{self.class.name}::phase_dsstore( )" )

        szCmd = "defaults write #{@homeDir}/Library/Preferences/"
        szCmd = "#{szCmd}com.apple.desktopservices"
        $oCmd.sys( "#{szCmd} DSDontWriteNetworkStores -bool TRUE", false, @fSudo )

    end


    #----------------------------------------------------------------
    #                       Set up Finder. 
    #----------------------------------------------------------------

    def phase_finder( )
        $oLog.logDebug(  "#{self.class.name}::phase_finder( )" )

        szCmd = "defaults write #{@homeDir}/Library/Preferences/.GlobalPreferences"
        $oCmd.sys( "#{szCmd} AppleShowAllExtensions -int 1", false, @fSudo )
        $oCmd.sys( "#{szCmd} com.apple.mouse.tapBehavior -int 2", false, @fSudo )
        $oCmd.sys( "#{szCmd} com.apple.trackpad.enableSecondaryClick -int 1", false, @fSudo )
        $oCmd.sys( "#{szCmd} com.apple.trackpad.scrollBehavior -int 2", false, @fSudo )
 
        szCmd = "defaults write #{@homeDir}/Library/Preferences/com.apple.finder"
        $oCmd.sys( "#{szCmd} AlwaysOpenWindowsInColumnView -int 1", false, @fSudo )
        $oCmd.sys( "#{szCmd} ShowHardDrivesOnDesktop -int 1", false, @fSudo )
        $oCmd.sys( "#{szCmd} ShowMountedServersOnDesktop -int 1", false, @fSudo )
        $oCmd.sys( "#{szCmd} WarnOnEmptyTrash -int 0", false, @fSudo )
        $oCmd.sys( "#{szCmd} FXEnableExtensionChangeWarning -int 0", false, @fSudo )

    end


    #----------------------------------------------------------------
    #                        Set up iTerm
    #----------------------------------------------------------------

    def phase_iterm( )
        $oLog.logDebug(  "#{self.class.name}::phase_terminal( )" )
        fn = "com.googlecode.iterm2"
        
        if ENV['TERM_PROGRAM'] == 'iTerm.app'
            raise RuntimeError, "You can not run this in iTerm.app!"
        end
        
        begin
            $oVerPath.copyFile(
                               "#{fn}.plist.xml.txt",
                               "#{@homeDir}/Library/Preferences/#{fn}.plist",
                               "600",
                               @owner,
                               @group,
                               @fSudo
            )
            szCmd = "defaults read #{@homeDir}/Library/Preferences/"
            $oCmd.sys( "#{szCmd}#{fn}", false, @fSudo )
        rescue
            raise RuntimeError, "could not find file: #{fn}.plist.xml!"
        end
        
    end


    #----------------------------------------------------------------
    #               Handle ~/Library setup
    #----------------------------------------------------------------

    def phase_library( )

        $oLog.logDebug(  "#{self.class.name}::phase_library( )" )

        $oCmd.sys( "chflags nohidden  #{@homeDir}/Library", false, @fSudo )
        # To reverse above, do:
        #$oCmd.sys( "chflags hidden  #{@homeDir}/Library", false, @fSudo )

    end


    #----------------------------------------------------------------
    #				        Set up Safari
    #----------------------------------------------------------------

    def phase_safari( )

        $oLog.logDebug(  "#{self.class.name}::phase_safari( )" )

        dest = "#{@homeDir}/Library/Safari/Bookmarks.plist"
        source = "Library_Safari_Bookmarks_20130620.plist"
        Dir.chdir( @macosxDir ) do
            $oCmd.sys( "cp  #{source} #{dest}", false, @fSudo )
        end
        
        $oConsole.notImplemented( "phase_safari - partially" )
        return

        szCmd = "defaults write #{@homeDir}/Library/Preferences/com.apple.Safari"
        $oCmd.sys( "#{szCmd} AlwaysShowTabBar -bool TRUE", false, @fSudo )
        $oCmd.sys( "#{szCmd} AutoFillPasswords -bool TRUE", false, @fSudo )
        $oCmd.sys( "#{szCmd} AutoOpenSafeDownloads -bool FALSE", false, @fSudo )
        $oCmd.sys( "#{szCmd} DownloadsClearingPolicy -int 2", false, @fSudo )
        $oCmd.sys( "#{szCmd} DownloadsPath \"~/Desktop\"", false, @fSudo )
        $oCmd.sys( "#{szCmd} ConfirmClosingMultiplePages -bool FALSE", @fSudo )
        $oCmd.sys( "#{szCmd} OpenNewTabsInFront -bool TRUE", false, @fSudo )
        $oCmd.sys( "#{szCmd} TabbedBrowsing -bool TRUE", false, @fSudo )
        $oCmd.sys( "#{szCmd} WebKitMinimumFontSize -int 14", false, @fSudo )

        # To block caching of websites:
        #$oCmd.sys( "mkdir -p #{@homeDir}/Caches", false, @fSudo )
        #$oCmd.sys( "touch #{@homeDir}/Caches/Safari", false, @fSudo )

    end


    #----------------------------------------------------------------
    #				        Save Safari Defaults
    #----------------------------------------------------------------
    
    def phase_safari_save( )
        
        $oLog.logDebug(  "#{self.class.name}::phase_safari_save( )" )
        
        source = "#{@homeDir}/Library/Safari/Bookmarks.plist"
        dest = "Library_Safari_Bookmarks.plist"
        Dir.chdir( @macosxDir ) do
            $oCmd.sys( "cp  #{source} #{dest}", false, @fSudo )
            $oCmd.sys( "plutil -convert xml1 #{dest}", false, @fSudo )
        end

    end
    
    
    #----------------------------------------------------------------
    #				        Set up SSH
    #----------------------------------------------------------------

    def phase_ssh( )

        $oLog.logDebug(  "#{self.class.name}::phase_ssh( )" )

        $oConsole.notImplemented( "phase_ssh" )
        return

        if !@fTemplate
            spclDmg = MacosxDMG.new
            spclDmg.restoreMountInfo
            Dir.chdir( spclDmg.mountedVolume ) do
                $oCmd.sys( "./sshSetupFlash.sh", false, @fSudo )
            end
            spclDmg = nil
        end

    end


    #----------------------------------------------------------------
    #				        Set up Terminal			
    #----------------------------------------------------------------

    def phase_terminal( )
        $oLog.logDebug(  "#{self.class.name}::phase_terminal( )" )

        if ENV['TERM_PROGRAM'] == 'Apple_Terminal'
            raise RuntimeError, "You can not run this in Terminal.app!"
        end

        begin
            $oVerPath.copyFile( 
                    "com.apple.Terminal.plist.xml.txt",
                    "#{@homeDir}/Library/Preferences/com.apple.Terminal.plist",
                    "600",
                    @owner,
                    @group,
                    @fSudo
            )
            szCmd = "defaults read #{@homeDir}/Library/Preferences/"
            $oCmd.sys( "#{szCmd}com.apple.Terminal", false, @fSudo )
        rescue
            raise RuntimeError, "could not find file: com.apple.Terminal.plist.xml!"
        end

    end


    #----------------------------------------------------------------
    #                       Set up Time Machine. 
    #----------------------------------------------------------------

    def phase_timemachine( )
        $oLog.logDebug(  "#{self.class.name}::phase_timemachine( )" )

        szCmd = "defaults write #{@homeDir}/Library/Preferences/"
        $oCmd.sys( "#{szCmd}com.apple.TimeMachine DoNotOfferNewDisksForbackup -bool YES", false, @fSudo )

    end


    #----------------------------------------------------------------
    #					    Set up Vim
    #----------------------------------------------------------------

    def phase_vim( )
        $oLog.logDebug(  "#{self.class.name}::phase_vim( )" )

        Dir.chdir( "#{@macosxDir}" ) do
            if false
                $oUnix.copyFile( "./vimSetup/gvimrc", "#{@homeDir}/.gvimrc", "600", @owner, @group, @fSudo )
                $oUnix.copyFile( "./vimSetup/vimrc", "#{@homeDir}/.vimrc", "600", @owner, @group, @fSudo )
                if File.exist?( "#{@homeDir}/.vim" )
                    rc = $oCmd.sys( "#{@szSudo} rm -fr \"#{@homeDir}/.vim\"" )
                end
                $oCmd.sys( "cp -R ./vimSetup/vim \"#{@homeDir}/\"", false, @fSudo )
                $oCmd.sys( "mv \"#{@homeDir}/vim\" \"#{@homeDir}/.vim\"", false, @fSudo )
                $oUnix.chmodDirsOnly( "#{@homeDir}/.vim", "700", @fSudo )
                $oUnix.chmodFilesOnly( "#{@homeDir}/.vim", "600", @fSudo )
            else
                $oUnix.copyFile( "./gvimrc.txt", "#{@homeDir}/.gvimrc", "600", @owner, @group, @fSudo )
                if File.exist?( "#{@homeDir}/.vim" )
                    rc = $oCmd.sys( "rm -fr \"#{@homeDir}/.vim\"" )
                end
                rc = $oCmd.sys( "mkdir -p \"#{@homeDir}/.vim/plugin\"" )
                $oUnix.copyFile( "./vim_plugin_cscope_maps.vim.txt", "#{@homeDir}/.vim/plugin/cscope_maps.vim", "600", @owner, @group )
            end
        end

    end


    #----------------------------------------------------------------
    #					    Set up Xcode4
    #----------------------------------------------------------------

    def phase_xcode4( )
        $oLog.logDebug(  "#{self.class.name}::phase_xcode4( )" )

        szCmd = "defaults write \"#{@homeDir}\"/Library/Preferences/"
        $oCmd.sys( "#{szCmd}com.apple.Xcode IndentWidth -int 4", false, @fSudo )
        $oCmd.sys( "#{szCmd}com.apple.Xcode \"PBXDebugger.LazySymbolLoading\" -int 0", false, @fSudo )
        $oCmd.sys( "#{szCmd}com.apple.Xcode PBXShowLineNumbers -bool TRUE", false, @fSudo )
        $oCmd.sys( "#{szCmd}com.apple.Xcode TabWidth -int 4", false, @fSudo )
        
        # Set up Xcode 4 customized data.
        xcodeUserLibrary = "#{@homeDir}/Library/Developer/Xcode"
        $oCmd.sys( "mkdir -p \"#{xcodeUserLibrary}\"", true )
        $oCmd.sys( "cp -R #{@macosxDir}/xcode/xcode4/* \"#{xcodeUserLibrary}\"/", true )

    end


    #----------------------------------------------------------------
    #					    Set up Xcode5
    #----------------------------------------------------------------

    def phase_xcode5( )
        $oLog.logDebug(  "#{self.class.name}::phase_xcode4( )" )

        szCmd = "defaults write #{@homeDir}/Library/Preferences/"
        $oCmd.sys( "#{szCmd}com.apple.Xcode IndentWidth -int 4", false, @fSudo )
        $oCmd.sys( "#{szCmd}com.apple.Xcode \"PBXDebugger.LazySymbolLoading\" -int 0", false, @fSudo )
        $oCmd.sys( "#{szCmd}com.apple.Xcode PBXShowLineNumbers -bool TRUE", false, @fSudo )
        $oCmd.sys( "#{szCmd}com.apple.Xcode TabWidth -int 4", false, @fSudo )
        
        # Set up Xcode 4 customized data.
        xcodeUserLibrary = "#{@homeDir}/Library/Developer/Xcode"
        $oCmd.sys( "mkdir -p #{xcodeUserLibrary}", true )
        $oCmd.sys( "cp -R #{@macosxDir}/xcode/xcode4/* #{xcodeUserLibrary}/", true )

    end


    #----------------------------------------------------------------
    #   Allow options to be overridden before processing begins.
    #----------------------------------------------------------------

    def optionsOverride( )

        $oLog.logDebug( "#{self.class.name}::optionsOverride( )" )
        if @fTemplate
            @fSudo = true
            @homeDir = @templateDir
            @owner = "root"
            @group = "wheel"
        else
            @fSudo = false
            @homeDir = ENV['HOME'].strip
            @owner = ENV['USER'].strip
            @group = `id -gn`.strip
        end
        if !((@homeDir.class == String) && (@homeDir.length > 0))
            die( "Missing Home Directory argument: #{@homeDir}", true )
        end
        rc = $oCmd.sys( "test -d \"#{@homeDir}\"", false, @fSudo )
        if !(rc == 0)
            die( "Home Directory specified, #{@homeDir}, does not exist", true )
        end

        if !(@owner.nil?) && (@owner.class == String) && !(@owner.include? "\n")
        else
            die( "Home Directory specified, #{@homeDir}, does not exist", true )
        end

    end


end




#----------------------------------------------------------------
#                       Main Program
#----------------------------------------------------------------

if __FILE__ == $0 

    oApp = ThisApp.new
    rc = oApp.main( ARGV )
    exit rc

end

