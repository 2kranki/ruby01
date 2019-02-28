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


    require         "plist"
    require         "systemCommands"


#################################################################
#                       Module Definition
#################################################################

class MacosxDMG

    attr_reader     :attachPlist, :mountData
    attr            :filePath, :pw

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( dmgPath=nil, pw="" )

        $oCmds = SystemCommands.instance
        @attachPlist = nil
        @filePathBase = "macosxDMG.mountdata.marshal"
        @mountData = { }
        @fMounted = false
        @pw = pw

        if !dmgPath.nil?
            @filePath = File.join( dmgPath, @filePathBase ).gsub( File::SEPARATOR, '_' )
            self.attach( dmgPath )
        end

    end

	# Create DMG (one method for each flavor of dmg creation

    #----------------------------------------------------------------
    #                       attach/mount a DMG
    #----------------------------------------------------------------

    def attachDmg( dmgPath=nil )

        pwOpt = ""
        if @pw.length
            pwOpt = "<<<'#{@pw}'"
        end
        if !dmgPath.nil?
            @filePath = File.join( dmgPath, @filePathBase ).gsub( File::SEPARATOR, '_' )
        end
        if File.file?( @filePath )
            begin
                self.restoreMountInfo
            rescue
            else
                if File.directory?( self.mountedVolume )
                    self.restoreMountInfo
                    @fMounted = true
                    return 
                else
                    self.deleteMountInfo
                end
            end
        end

        $oCmd.cmd( "hdiutil attach -plist \"#{dmgPath}\" #{pwOpt}" )
        @attachPlist = Plist::parse_xml( $oCmd.szOutput )
        @mountData = { }
        @fMounted = false
        @attachPlist["system-entities"].each do |entry|
            if entry.has_key?("mount-point")
                @mountData = entry
                @fMounted = true
                self.saveMountInfo
                break
            end
        end
    end


    #----------------------------------------------------------------
    #                       attach/mount a DMG
    #----------------------------------------------------------------

    def attach( dmgPath )

        # Try attaching the dmg without a password
        begin
            self.attachDmg( dmgPath )
        rescue
        else
            return
        end

        # Didn't work try with a password.
        self.getPassword
        self.attachDmg( dmgPath )

    end


    #----------------------------------------------------------------
    #                   detach/unmount a mounted DMG
    #----------------------------------------------------------------

    def detach
        if !@fMounted
            raise RuntimeError
        end
        if  @mountData.is_a?( Hash ) && @mountData.has_key?("dev-entry")
            $oCmd.sys( "hdiutil detach -force #{@mountData["dev-entry"]}" )
            @attachPlist = nil
            @mountData = { }
            @fMounted = false
            self.deleteMountInfo
        end
    end


    #----------------------------------------------------------------
    #               check to see if a file is a DMG
    #----------------------------------------------------------------

    def MacosxDMG.dmg?( filePath )
        $oLog.logDebug( "#{self.class.name}::dmg?( #{filePath})" )
        fRc = false

        if File.exist?( "#{filePath}" )
            case filePath
                when /^.*\.[Dd][Mm][Gg]$/
                    fRc = true
                    ;;
            end
        end

        return fRc
    end


    #----------------------------------------------------------------
    #                   get the Password if needed
    #----------------------------------------------------------------

    def getPassword

    end


    #----------------------------------------------------------------
    #                       Mount Data Access
    #----------------------------------------------------------------

    def mountedDevice
        if @mountData.is_a?( Hash ) && @mountData.has_key?("dev-entry")
            return @mountData["dev-entry"]
        else
            raise IndexError
        end
    end

    def mountedVolume
        if  @mountData.is_a?( Hash ) && @mountData.has_key?("mount-point")
            return @mountData["mount-point"]
        else
            raise IndexError
        end
    end


    #----------------------------------------------------------------
    #                   delete Mount Information
    #----------------------------------------------------------------

    def deleteMountInfo

        if File.file?( @filePath )
            File.delete( @filePath )
        end

    end


    #----------------------------------------------------------------
    #                   restore Mount Information
    #----------------------------------------------------------------

    def restoreMountInfo

        file = File.new( @filePath,'r' )
        marshalData = file.read
        file.close
        @mountData = Marshal.load( marshalData )
        @fMounted = true

    end


    #----------------------------------------------------------------
    #                   save Mount Information
    #----------------------------------------------------------------

    def saveMountInfo

        if !@fMounted
            raise RuntimeError
        end

        if  @mountData.is_a?( Hash ) && @mountData.has_key?("dev-entry")
            marshalData = Marshal.dump( @mountData )
            file = File.new( @filePath, 'w' )
            file.write( marshalData )
            file.close
        end

    end



end




