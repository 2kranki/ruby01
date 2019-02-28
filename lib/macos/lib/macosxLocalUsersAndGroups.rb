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

    require			"macosxLocalGroups"
    require			"macosxLocalUsers"
    require			"plist"
    require         "systemCommands"


#################################################################
#                       Class Definition
#################################################################

class	MacosxLocalUsersAndGroups

	attr_reader		:groups, :users


    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize
        $oCmds = SystemCommands.instance
		#self.groupsInfo
		#self.usersInfo
    end


    #----------------------------------------------------------------
    #               Add a Group if it does not exist.
    #----------------------------------------------------------------

    def groupAdd( groupName, groupID, groupPW="'*'" )

        $oLog.logDebug( "MacOSXBase::groupAdd( #{groupName}, #{groupID}, #{groupPW} )" )

        if !self.groupExists?( groupName )
            rc = $oCmd.sys( "dscl localhost create /Local/Default/Groups/#{groupName} gid #{groupID}", true, true )
            if rc != 0
                return false
            end
            rc = $oCmd.sys( "dscl localhost create /Local/Default/Groups/#{groupName} passwd #{groupPW}", true, true )
            if rc != 0
                return false
            end
            return true
        end
        return false

    end


    #----------------------------------------------------------------
    #               Add a User to a Group if it exists.
    #----------------------------------------------------------------

    def groupAddUserTo( groupName, userName )

        $oLog.logDebug( "MacOSXBase::groupAddUserTo( #{groupName}, #{userName} )" )

        if self.groupExists?( groupName )
            rc = $oCmd.sys( "dscl localhost merge /Local/Default/Groups/#{groupName} users #{userName}", true, true )
            if rc != 0
                return false
            end
            return true
        end
        return false

    end


    #----------------------------------------------------------------
    #               Delete a Group if it exists.
    #----------------------------------------------------------------

    def groupDelete( groupName )

        $oLog.logDebug( "MacOSXBase::groupDelete( #{groupName} )" )

        if self.groupExists?( groupName )
            rc = $oCmd.sys( "dscl localhost delete /Local/Default/Groups/#{groupName}", true, true )
            if rc != 0
                return false
            end
            return true
        end
        return false

    end


    #----------------------------------------------------------------
    #               Check for a Group's existance.
    #----------------------------------------------------------------

    def groupExists?( groupName )

        $oLog.logDebug( "MacOSXBase::groupExists?( #{groupName} )" )

        rc = $oCmd.cmd( "dscl localhost read /Local/Default/Groups/#{groupName}", true )
        if rc == 0
            return true
        else
            return false
        end

    end


    #----------------------------------------------------------------
    #               Add all Groups if they don't exist.
    #----------------------------------------------------------------

    def groupsAdd( )

        $oLog.logDebug( "MacOSXBase::groupsAdd( )" )

        @guTree.root.elements['groups'].each_element do |grp|
            pw = grp.attributes['pw'] ? grp.attributes['pw'] : "'*'"
            rc = self.groupAdd(
                    grp.attributes['name'],
                    grp.attributes['gid'],
                    pw 
                 )
            if rc
                $oLog.logInfo( "\tAdded group: #{grp.attributes['name']}" )
            end
        end

    end


    #----------------------------------------------------------------
    #                       Group  UID 
    #----------------------------------------------------------------

    def groupUID( name )

        $oLog.logDebug( "groupUID( )" )

        if @uid.nil?
            $oCmd.cmd( "dscl localhost read /Local/Default/Groups/#{name} GeneratedUID" )
            @uid = $oCmd.szOutput.split[1]
        end

        return @uid
    end


    #----------------------------------------------------------------
    #               Get Information on all current groups.
    #----------------------------------------------------------------

    def groupsInfo

        $oLog.logDebug( "MacosxLocalUsersAndGroups::groupsInfo )" )

        docText = %x{dscl -plist localhost readall /Local/Default/Groups}.strip
        plist = Plist::parse_xml( docText )
        @groups = MacosxLocalGroups.fromPlist( plist )
        return @groups
    end


    #----------------------------------------------------------------
    #               Add a User if it does not exist.
    #----------------------------------------------------------------

    def userAdd( name, uid, gid, home='', realName='', shell='/bin/bash' )

        $oLog.logDebug( "MacOSXBase::userAdd( #{name}, #{uid}, #{gid}, #{home}, #{realName}, #{shell} )" )

        if !self.userExists?( name )
            rc = $oCmd.sys( "dscl localhost create /Local/Default/Users/#{name} uid #{uid}", true, true )
            if rc != 0
                return false
            end
            rc = $oCmd.sys( "dscl localhost create /Local/Default/Users/#{name} gid #{gid}", true, true )
            if rc != 0
                return false
            end
            if home.length == 0
                home = "/Users/#{name}"
            end
            rc = $oCmd.sys( "dscl localhost create /Local/Default/Users/#{name} home #{home}", true, true )
            if rc != 0
                return false
            end
            rc = $oCmd.sys( "dscl localhost create /Local/Default/Users/#{name} shell #{shell}", true, true )
            if rc != 0
                return false
            end
            if realName.length == 0
                realName = "#{name}"
            end
            rc = $oCmd.sys( "dscl localhost create /Local/Default/Users/#{name} realname '#{realName}'", true, true )
            if rc != 0
                return false
            end
            if !File.exist?( home )
                rc = $oCmd.sys( "createhomedir -c -u #{name}", true, true )
                if rc != 0
                    return false
                end
            end
            return true
        end
        return false

    end


    #----------------------------------------------------------------
    #               Delete a User if it exists.
    #----------------------------------------------------------------

    def userDelete( userName )

        $oLog.logDebug( "MacOSXBase::userDelete( #{userName} )" )

        if self.userExists?( userName )
            rc = $oCmd.sys( "sudo dscl localhost delete /Local/Default/Users/#{userName}", true )
            if rc != 0
                return false
            end
            return true
        end
        return false

    end


    #----------------------------------------------------------------
    #               Check for a User's existance.
    #----------------------------------------------------------------

    def userExists?( userName )

        $oLog.logDebug( "MacOSXBase::userExists?( #{userName} )" )

        rc = $oCmd.cmd( "dscl localhost read /Local/Default/Users/#{userName}", true )
        if rc == 0
            return true
        else
            return false
        end

    end


     #----------------------------------------------------------------
    #               Delete a User if it exists.
    #----------------------------------------------------------------

    def userPasswordSet( userName, pw=nil )

        $oLog.logDebug( "MacOSXBase::userPasswordSet( #{userName} )" )

        if self.userExists?( userName )
            Dir[ '/Volumes/*' ].each do |subdir|
                if subdir[0] == '.'
                    next
                end
                if File.directory?( "#{subdir}/spcl" )
                    filePath = "#{subdir}/spcl/#{userName}/pw.txt"
                    if File.file?( filePath )
                        pw = open( filePath ).readline.chomp 
                        rc = $oCmd.cmd( "dscl localhost passwd /Local/Default/Users/#{userName} \"#{pw}\"", true, true )
                        if rc != 0
                            return false
                        end
                        return true
                    end
                end
            end
            rc = $oCmd.sys( "dscl localhost passwd /Local/Default/Users/{userName}", true, true )
            if rc != 0
                return false
            end
            return true
        end
        return false

    end


    def userPasswordSetSpcl( userName, spclDir )

        $oLog.logDebug( "MacOSXBase::userPasswordSetSpcl( #{userName} )" )

        filePath = "#{spclDir}/users/#{userName}/pw.txt"
        if File.file?( filePath )
            pw = open( filePath ).readline.chomp 
            rc = $oCmd.cmd( "dscl localhost passwd /Local/Default/Users/#{userName} \"#{pw}\"", true, true )
            if rc != 0
                return false
            end
            return true
        end
        return false

    end


    #----------------------------------------------------------------
    #                       User  UID 
    #----------------------------------------------------------------

    def userUID( name )

        $oLog.logDebug( "userUID( )" )

        if @uid.nil?
            $oCmd.cmd( "dscl localhost read /Local/Default/Users/#{name} GeneratedUID" )
            @uid = $oCmd.szOutput.split[1]
        end

        return @uid
    end


    #----------------------------------------------------------------
    #               Get Information on all current groups.
    #----------------------------------------------------------------

    def usersInfo

        $oLog.logDebug( "MacosxLocalUsersAndGroups::usersInfo )" )

        docText = %x{dscl -plist localhost readall /Local/Default/Users}.strip
        plist = Plist::parse_xml( docText )
        @users = MacosxLocalUsers.fromPlist( plist )
        return @users

    end


end




