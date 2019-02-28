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
    require		"singleton"
    require		"tempfile"




#################################################################
#						Class Definition 
#################################################################

class SystemCommands

    attr_reader     :szOutput
    attr_reader     :rc

	include Singleton

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize

        super

        $oLog = LogMessages.instance

    end


    #----------------------------------------------------------------
    #           Issue a one-line command.
    #----------------------------------------------------------------

    def cmd( szCmd, fIgnoreRC=false, fNeedSudo=false, fIgnoreOutput=false )

        $oLog.logDebug( "SystemCommands::cmd( #{szCmd} )" )

        if fNeedSudo
            szCmd = "sudo #{szCmd}"
        end

        if $fNoop
            $oLog.logDebug( "cmd:#{szCmd} ==> skipped since noop is set" )
            @szOutput = ''
            @rc = 0
            return @rc
        end

        szCmd = "#{szCmd} 2>&1"
        if fIgnoreOutput
            szCmd = szCmd + ' 1>/dev/null'
            @szOutput = ''
            %x{#{szCmd}}
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

    def cmds( arrayCmds, fIgnoreRC=false, fNeedSudo=false, fIgnoreOutput=false )

        $oLog.logDebug( "SystemCommands::cmds( #{arrayCmds} )" )

        if $fNoop
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
        if $fDebug
            tempFile << '#!/bin/bash -xv' << endl
        else
            tempFile << '#!/bin/bash' << endl
        arrayCmds.each { |szCmd| tempFile << szCmd << endl }
        tempFile << '\texit\t$?' << endl
        tempFile.close
        File.chmod( 0750, szPath )
        begin
            self.cmd( szPath, fIgnoreRC, fNeedSudo, fIgnoreOutput )
            rescue RuntimeError
                File.delete( szPath )
                raise
            end
        end
        File.delete( szPath )
        return @rc

    end


    #----------------------------------------------------------------
    #       Issue a one-line command with output to terminal.
    #----------------------------------------------------------------

    def sys( szCmd, fIgnoreRC=false, fNeedSudo=false )

        $oLog.logDebug( "SystemCommands::sys( #{szCmd} )" )

        if fNeedSudo
            szCmd = "sudo #{szCmd}"
        end

        if szCmd.include? "\n"
            raise ArgumentError,"szCmd contains a new-line"
        end
        if $fQuiet
            return self.cmd( szCmd, fIgnoreRC )
        else
            $oLog.logInfo( "#{szCmd}" )
        end

        if $fNoop
            $oLog.logDebug( "cmd:#{szCmd} ==> skipped since noop is set" )
            @szOutput = ''
            @rc = 0
            return @rc
        end

        system( "#{szCmd} 2>&1" )
        @rc = $?.to_i
        $oLog.logDebug( "...ReturnCode = #{@rc}" )
        if !fIgnoreRC and (@rc != 0)
            raise RuntimeError,"invalid return code of #{@rc}"
        end

        return @rc
    end


    #----------------------------------------------------------------
    #           Issue a multiple-line command.
    #----------------------------------------------------------------

    def syss( arrayCmds, fIgnoreRC=false, fNeedSudo=false )

        $oLog.logDebug( "SystemCommands::syss( #{arrayCmds} )" )

        if $fNoop
            @rc = 0
            return @rc
        end

        if arrayCmds.class != Array
            raise RuntimeError,'BashCommand:syss requires an array!'
        end
        tempFile = File.new( 'bashscript.sh', "w" )
        szPath = tempFile.path
        $oLog.logDebug( "...Setting up bash script file, #{szPath}" )
        endl = "\n"
        if $fDebug
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
            $oLog.logDebug( "...executing #{szCmd} as root" )
        else
            szCmd = "./#{szPath}"
            $oLog.logDebug( "...executing #{szCmd} as current user" )
        end

        system( "#{szCmd} 2>&1" )
        @rc = $?.to_i
        $oLog.logDebug( "...ReturnCode = #{@rc}" )
        if File.exist?( szPath )
            $oLog.logDebug( "...deleting file, #{szPath}" )
            File.delete( szPath )
        end
        if !fIgnoreRC and (@rc != 0)
            raise RuntimeError,"invalid return code of #{@rc}"
        end

        return @rc

    end


end



