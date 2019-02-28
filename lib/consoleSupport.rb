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


    require		"logMessages"
    require     "readline"          # not implemented in MacOSX 10.4
    require		"singleton"


	# Singleton Instances
    $oLog = nil


#################################################################
#                       Console Base Class 
#################################################################

class ConsoleSupport

    attr_accessor :data

    #################################################################
    #                       Methods
    #################################################################

	include Singleton

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize

        super

        $oLog = LogMessages.instance
    
    end

    #----------------------------------------------------------------
    #           Ask for a non-echoed Response from the console
    #----------------------------------------------------------------

    def getPassword( szMsg="" )

        $oLog.logDebug( "#{self.class.name}::getPassword( )" )

        szMsg = "Please enter password#{szMsg}"
        answer = self.getReply_noecho( szMsg )

        return answer
    end


    #----------------------------------------------------------------
    #           Ask for a non-echoed Response from the console
    #----------------------------------------------------------------

    def getReply_noecho( szMsg )

        $oLog.logDebug( "#{self.class.name}::getReply_noecho( )" )

        print "#{szMsg}: "
        begin
            system('stty cbreak -echo')
            answer = STDIN.gets.chomp
        ensure
            system('stty -cbreak echo')
            puts
        end

        return answer
    end


    #----------------------------------------------------------------
    #           Ask for a Response from the console
    #----------------------------------------------------------------

    def getReply( szMsg="" )

        $oLog.logDebug( "#{self.class.name}::getReply( )" )

        if szMsg.length > 0
            print "#{szMsg}: "
        end
        answer = STDIN.gets.chomp
        puts

        return answer
    end


    #----------------------------------------------------------------
    #           Get an integer from the console
    #----------------------------------------------------------------

    def getReplyInt( szMsg="", default=0, low=0, high=0 )

        $oLog.logDebug( "#{self.class.name}::getReplyInt( )" )
        num = default
        if (low == 0) && (high == 0)
        else
            if (default >= low) && (default <= high)
            else
                raise ArgumentError, "default, #{default}, is not within #{low} and #{high}"
            end
        end

        loop do
            if szMsg.is_a?(String) && (szMsg.length > 0)
                puts "#{szMsg}"
            end
            if (low == 0) && (high == 0)
                getMsg = "Please enter a number (default is #{default})"
            else
                getMsg = "Please enter a number >= #{low} and <= #{high} (default is #{default})"
            end
            answer = self.getReply( getMsg )
            if answer.length > 0
                begin
                    answer = Integer(answer)
                    rescue
                        puts "ERROR - #{answer} is not an integer!"
                        next
                end
            else
                answer = default
            end
            if (low == 0) && (high == 0)
            else
                if (answer >= low) && (answer <= high)
                else
                    puts "ERROR - #{answer} is out of range (#{low},#{high})!"
                    next
                end
            end
            return answer
        end

    end


    #----------------------------------------------------------------
    #           Ask for a Yes | No Response from the console
    #----------------------------------------------------------------

    def getReplyYN( szMsg, szDefault='y' )

        $oLog.logDebug( "#{self.class.name}::getReplyYN( )" )

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
    #           Ask for a Response from the console
    #----------------------------------------------------------------

    def getSelection( szMsg, selections )

        $oLog.logDebug( "#{self.class.name}::getSelection( )" )

        puts "#{szMsg}: "
        i = 1
        selections.each { |x|
            puts "\t%2d  #{x}" % i
            i = i + 1
        }
        puts "enter a number for selection or 0 to abort."
        answer = self.getReplyInt( "", 0, 0, selections.length )
        if answer == 0
           raise ArgumentError
        end 

        return answer
    end


    #----------------------------------------------------------------
    #          Issue not implemented message with pause 
    #----------------------------------------------------------------

    def notImplemented( szMsg )

        $oLog.logDebug( "#{self.class.name}::notImplemented( )" )

        puts
        puts "###### #{szMsg} is not implemented! ######"
        puts "Please add this to your todo list."
        puts "Press <enter> to continue or q<enter> to quit:"
        answer = STDIN.gets.chomp
        if answer == 'q'
            if $fDebug
                puts "...quit chosen"
            end
            exit( 8 )
        end

    end


end


#################################################################
#                       Class Testing
#################################################################

if __FILE__ == $0

    oConsole = ConsoleSupport.instance
    $fDebug = true

    if false
        oConsole.notImplemented( "xyzzy" )
    end

    if false
        xx = oConsole.getReply_noecho( "Enter non-echoed data" )
        puts "\tnon-echoed data => "+xx
        xx = oConsole.getPassword( "(xyzzy)" )
        puts "\tPassword => "+xx
    end

    if false
        xx = oConsole.getReplyInt( )
        puts "\tInteger => "+String(xx)+" #{xx.class.name}"
        xx = oConsole.getReplyInt( "xyzzy" )
        puts "\tInteger => "+String(xx)+" #{xx.class.name}"
        xx = oConsole.getReplyInt( "xyzzy", 12 )
        puts "\tInteger => "+String(xx)+" #{xx.class.name}"
        xx = oConsole.getReplyInt( "xyzzy", 3, 2, 5 )
        puts "\tInteger => "+String(xx)+" #{xx.class.name}"
    end

    if true
        xx = oConsole.getSelection( "xyzzy", ['A', 'B', 'C' ] )
        puts "\tAnswer => "+String(xx)
    end

end

