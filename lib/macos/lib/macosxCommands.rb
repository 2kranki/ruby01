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


    require     "macosxDMG"
    require     "singleton"
    require     "systemCommands"


#################################################################
#                       Module Definition
#################################################################

class MacosxCommands


	include		Singleton

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize

		$oCmd = SystemCommands.instance

    end


    #----------------------------------------------------------------
    #                   Read a default value.
    #----------------------------------------------------------------

    def defaultsRead( domain="NSGlobalDomain", key="" )
        $oCmd.sys( "defaults -currentHost read #{domain} #{key}" )
    end


    #----------------------------------------------------------------
    #           Add/update the appropriate default value.
    #----------------------------------------------------------------

    def defaultsWrite( domain="NSGlobalDomain", key="", value="" )
        # We have to use sudo in case we are really writing to 
        # NSGlobalDomain.
        $oCmd.sys( "sudo defaults -currentHost write #{domain} #{key} #{value}" )
    end


    def defaultsWriteBool( domain="NSGlobalDomain", key="", value="FALSE" )
        # Valid values are: FALSE, TRUE, YES, NO
        # We have to use sudo in case we are really writing to 
        # NSGlobalDomain.
        if !(value.kind_of? String )
            if !(value.casecmp( "FALSE" )) && !(value.casecmp( "TRUE" )) \
            && !(value.casecmp( "YES" )) && !(value.casecmp( "NO" ))
                raise ArgumentError.new( "\"value\" is not a valid boolean" )
            end
        elsif !(value.kind_of? Bool )
            if value
                value = "true"
            else
                value = "false"
            end
        end
        newValue = "-bool #{value}"
        defaultsWrite( domain, key, newValue )
    end


    def defaultsWriteFloat( domain="NSGlobalDomain", key="", value=0.0 )
        # We have to use sudo in case we are really writing to 
        # NSGlobalDomain.
        if !(value.kind_of? Float )
            raise ArgumentError.new( "\"value\" is not a Float" )
        end
        newValue = "-float #{value}"
        defaultsWrite( domain, key, newValue )
    end


    def defaultsWriteInteger( domain="NSGlobalDomain", key="", value=0 )
        # We have to use sudo in case we are really writing to 
        # NSGlobalDomain.
        if !(value.kind_of? Integer )
            raise ArgumentError.new( "\"value\" is not an Integer" )
        end
        newValue = "-integer #{value}"
        defaultsWrite( domain, key, newValue )
    end


    #----------------------------------------------------------------
    #                   Macosx Disk Control
    #----------------------------------------------------------------

    def diskMounted?( devicePath=nil )
        
        $oLog.logDebug( "MacosxCommands::diskMounted?( #{path})" )
        
        if @devicePath.nil? || !File.exist?( @devicePath )
            self.abort( "Missing or incorrect device path" )
        end
        
        df_output = %x{diskutil info -plist #{devicePath}}
        # Now we need to pull out the info for mount if we got a plist back.
        df_vals = df_output.split(/\n/)
        devices = []
        df_vals.each do |val|
            next unless val =~ /(.+)\s+(.+)\s+(.+)\s+(.+)\s+(.+)\s+(.+)/
            device, total, used, avail, percentage, mount_point = $1, $2, $3, $4, $5, $6
            devices.push({
                         :device => device,
                         :total => total,
                         :used => used,
                         :avail => avail,
                         :percentage => percentage,
                         :mount_point => mount_point
                         })
        end
        return devices
    end   
    


    #----------------------------------------------------------------
    #                   Macosx General Control
    #----------------------------------------------------------------
    
    def networkStoresOff
        self.defaultsWriteBool( 
                               "/Library/Preferences/com.apple.desktopservices",
                               "DSDontWriteNetworkStores",
                               "TRUE"
                               )
    end
    
    
    #----------------------------------------------------------------
    #                   Macosx Application Support
    #----------------------------------------------------------------

    def installAppFromDMG( 
                szDmgFilePath,      # Full File Path Name for DMG
                szAppDmgDir=nil,    # directory within DMG for app
                szAppName=nil,
                szAppDestDir="/Applications",
                fForce=false,       # true == delete current installation if present
                szGrp='admin'
        )

        destAppPath = File.join( szAppDestDir, szAppName )
        if File.exist?(destAppPath)
            if fForce
                $oCmd.sys( "rm -fr \"#{destAppPath}\"", false, true )
            else
                return
            end
        end

        oDmg = MacosxDMG.new( szDmgFilePath )
        if szAppDmgDir
            srcAppDmgDir = File.join(
                                    oDmg.mountedVolume,
                                    szAppDmgDir 
                        )
        else
            srcAppDmgDir = File.join( oDmg.mountedVolume )
        end

        # Need to add support for MacOSX packages pkg/mpkg
        #   sudo installer -pkg xx/yy/zz -tgt "/"
        srcAppPath = File.join( srcAppDmgDir, szAppName )
        dstAppPath = szAppDestDir + File::SEPARATOR
        $oCmd.sys( "sudo cp -R \"#{srcAppPath}\" \"#{dstAppPath}\"" )
        dstAppPath = File.join( szAppDestDir, szAppName )
        $oCmd.sys( "sudo chgrp -R  #{szGrp}  \"#{dstAppPath}\"" )
        oDmg.detach
    end


    #----------------------------------------------------------------
    #   Check to see if a user is an administrator
    #----------------------------------------------------------------

    def isAdmin( user )

        rc = $oCmd.sys( "dscl localhost read " +
						"/Local/Default/Groups/admin" +
                        " | grep \"GroupMembership\" " +
                        " | grep \"#{user}\"",
                        true
            )
        return (rc == 0)

    end


    #----------------------------------------------------------------
    #   install a Macosx program package.
    #----------------------------------------------------------------

    def packageInstall( pkg=nil, tgt="LocalSystem" )
        $oCmd.sys( "sudo installer -verbose -package #{pkg} -Target #{tgt}" )
    end


    #----------------------------------------------------------------
    #   Try to have TimeMachine skip looking at a volume.
    #----------------------------------------------------------------

    def timeMachineDoNotPresent
        $oCmd.sys(  "sudo defaults write " +
                    "/Library/Preferences/com.apple.TimeMachine " +
                    "DoNotOfferNewDisksForBackup -bool YES"
        )
    end


    #----------------------------------------------------------------
    #                       Volume Methods
    #----------------------------------------------------------------

    def volumeBless( volumeName )
        $oCmd.sys( "sudo bless --folder \"/Volumes/#{volumeName}/System/Library/CoreServices\" --bootinfo --bootefi" )
    end

    def volumeEraseJHFSPlus( deviceName, volumeName )
        $oCmd.sys( "sudo diskutil eraseVolume \"Journaled HFS+\" #{volumeName} #{deviceName}" )
    end

    def volumePermissionsDisable( volumeName )
        $oCmd.sys( "sudo diskutil disableOwnership /Volumes/#{volumeName}" )
    end

    def volumePermissionsEnable( volumeName )
        $oCmd.sys( "sudo diskutil enableOwnership /Volumes/#{volumeName}" )
    end

    def volumeSpotLightStop( volumeName )
        $oCmd.sys( "sudo touch /Volumes/#{volumeName}/.metadata_never_index" )
        $oCmd.sys( "sudo mdutil -i off /Volumes/#{volumeName}" )
        $oCmd.sys( "sudo mdutil -E /Volumes/#{volumeName}" )
    end

    def volumeTimeMachineStop( volumeName )
        $oCmd.sys( "sudo touch /Volumes/#{volumeName}/.com.apple.timemachine.donotpresent" )
    end


end




