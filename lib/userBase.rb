#!/usr/bin/env ruby
# add -debug above to debug.

# vi:nu:et:sts=4 ts=4 sw=4
#
# TODO:
#   *   xyzzy


# user.rb
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
#						UserBase Class 
#################################################################

class UserBase

    attr_accessor :exists, :gid, :homeDirectory, :longName, :otherData, :otherGroups, :shell
    attr_accessor :shortName, :uid, :uuid

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( )

        super
		
		@name = nil
		@gid = nil
        @otherData = {}
        @otherGroups = []

    end


    #----------------------------------------------------------------
    #                   Do something.
    #----------------------------------------------------------------

    def doSomething( )

        $oLog.logDebug( "#{self.class.name}::doSomething( )" )

        super

       raise NotImplementedError

    end


end




#################################################################
#----------------------------------------------------------------
#						Main Program 
#----------------------------------------------------------------
#################################################################

if __FILE__ == $0

	oApp = Xyzzy.new
    #oApp.fNoop = true
    rc = oApp.main( ARGV )
    exit rc

end

