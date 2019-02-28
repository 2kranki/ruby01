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


    require     "cliAppWithPhases"
    require     "macosxComputerProfile"
    require     "consoleSupport"
    require     "unixCommands"
    require     "versionedPath"




#################################################################
#                       MacOSX Base Class 
#################################################################

class MacOSXBasePhases < CliAppWithPhases


    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize

        super

        $oConsole = ConsoleSupport.instance
		$oUnix = UnixCommands.instance
        $oVerPath = VersionedPath.instance
        
        @computerProfile = MacOSXComputerProfile.new
        @computerName    = @computerProfile.computerName
        @osArch          = @computerProfile.osArchitecture
        @osName          = @computerProfile.osName
        @osRelease       = @computerProfile.osRelease
        @osType          = @computerProfile.osType
        @osVersion       = @computerProfile.osVersion
        
        @baseDir = Dir.getwd
        @macosxDir = "#{@baseDir}/macosx"
        @tarballDir = "#{@macosxDir}/unixTars"

        @todaysDate = `date +%G%m%d`
        @todaysTime = `date +%H%M%S`
        @todaysDateTime = "${todaysDate}_${todaysTime}"
        
        $oVerPath.osDir = @baseDir
        $oVerPath.osName = @computerProfile.osName
        $oVerPath.osVersion = @computerProfile.osVersion
        $oVerPath.osType = @computerProfile.osType
        $oVerPath.computerName = @computerProfile.computerName

    end


end




