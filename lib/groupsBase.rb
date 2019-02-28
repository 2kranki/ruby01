#!/usr/bin/env ruby
# add -debug above to debug.

# vi:nu:et:sts=4 ts=4 sw=4
#
# TODO:
#   *   xyzzy


# group.rb
# 
#
# Created by bob on 3/21/10.

#  LICENSE: PUBLIC DOMAIN

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
 
    require     "logMessages"
    require     "systemCommands"

	# Singleton Instances
	$oCmd = nil
    $oLog = nil




#################################################################
#						UserGroupBase Class 
#################################################################

class UserGroupBase

    attr_accessor :exists :gid :longName :shortName :subGroups

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( )

        super
		
		@exists = false
		@gid = nil
		@longName = nil
		@shortName = nil
		@subgroups = []

    end


    #----------------------------------------------------------------
    #						debug string
    #----------------------------------------------------------------

    def toPlist( )

        $oLog.logDebug( "#{self.class.name}::toPlist( )" )

        super

		szString  = "<key>group</key>\n<dict>\n"
		szString += "\t<key>gid</key>\n\t<integer>#{gid}</integer>"
		szString += "\t<key>long name</key>\n\t<string>#{longName}</string>"
		szString += "\t<key>exists</key>\n\t"
		if self.exists
			szString += "<true/>\n"
		else
			szString += "<false/>"
		end
		szString += "</dict>"

    end

	return szString
end




#################################################################
#----------------------------------------------------------------
#						Main Program 
#----------------------------------------------------------------
#################################################################

if __FILE__ == $0

	oApp = UserGroupBase.new
    #oApp.fNoop = true
    rc = oApp.main( ARGV )
    exit rc

end

