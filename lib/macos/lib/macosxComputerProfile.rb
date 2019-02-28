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

# Tested Hardware:

# G4
#   'Model Name':       'PowerBookG4'      <=== ???
#   'cpu_type:          'PowerPC G4 (3.2)'
#   'machine_model':    'PowerMac7,2'      <=== ???
#   'machine_name':     'PowerMacG5'      <=== ???
# G5
#   'cpu_type:          'PowerPC 970 (2.2)'
#   'machine_model':    'PowerMac7,2'
#   'machine_name':     'PowerMacG5'

# MacBook Pro
#   'cpu_type:          'Intel Core Duo'
#   'machine_model':    'MacBookPro1,2'
#   'machine_name':     'MacBook Pro'
# MacBook Pro - Core 2 Duo
#   'cpu_type:          'Intel Core 2 Duo'
#   'machine_model':    'MacBookPro5,2'
#   'machine_name':     'MacBook Pro'
# Mac
#   'cpu_type:          'Quad-core Intel Xeon'
#   'machine_model':    '???'
#   'machine_name':     'MacPro' <= ???



#----------------------------------------------------------------
#                       Global Variables
#----------------------------------------------------------------

#   IMPORTANT - Most Global Varialbles should only be defined
#   in the main script file.

    localLib = File.join( File.dirname(__FILE__), "..", "..", "lib" )
    if File.directory?( localLib )
        $:.unshift( localLib )
    end

    require			"plist"



#################################################################
#                       MacOSX Base Class
#################################################################

class MacOSXComputerProfile

    attr_reader :hardwareDescription, :softwareDescription

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation
    #----------------------------------------------------------------

    def initialize

        docText = %x{system_profiler -xml SPHardwareDataType}.strip
        @hardwareDescription = Plist::parse_xml( docText )
        @hardwareDescription = @hardwareDescription[0]['_items'][0]
        docText = %x{system_profiler -xml SPSoftwareDataType}.strip
        @softwareDescription = Plist::parse_xml( docText )
        @softwareDescription = @softwareDescription[0]['_items'][0]
        self.osArchitecture
        self.osRelease
        self.osVersion
        if self.osServer?
            @osType = "server"
        else
            @osType = "client"
        end
    end


    #----------------------------------------------------------------
    #                       Computer Name
    #----------------------------------------------------------------

    def computerName
        @softwareDescription['local_host_name']
    end


    #----------------------------------------------------------------
    #                       CPU Type
    #----------------------------------------------------------------

    def cpuType
        @hardwareDescription['cpu_type']
    end


    #----------------------------------------------------------------
    #                       Machine Architecture
    #----------------------------------------------------------------

    def osArchitecture
        if !defined? @osArchitecture
            ct = @hardwareDescription['cpu_type']
            mm = @hardwareDescription['machine_model']
            mn = @hardwareDescription['machine_name']
            @osArchitecture = "x86_64"
            if ct == "Intel Core Duo"
                @osArchitecture = "i386"
            elsif (mn =~ /.*\b[G|g]5.*/)
                @osArchitecture = "ppc64"
            elsif (ct =~ /PowerPC.*/)
                @osArchitecture = "ppc"
                if (mn =~ /.*\b[G|g]5.*/)
                    @osArchitecture = "ppc64"
                end
            #else
                #raise RuntimeError.new( "Unknown Machine Model of #{osVersion}!" )
            end
        end
        return @osArchitecture
    end


    #----------------------------------------------------------------
    #                       Machine Model
    #----------------------------------------------------------------

    def machineModel
        @hardwareDescription['machine_model']
    end


    #----------------------------------------------------------------
    #                       Machine Name
    #----------------------------------------------------------------

    def machineName
        @hardwareDescription['machine_name']
    end


    #----------------------------------------------------------------
    #               OS Name - client or server
    #----------------------------------------------------------------

    def osName
        'macosx'
    end


    #----------------------------------------------------------------
    #                           release
    #----------------------------------------------------------------

    def osRelease
        if !defined? @osRelease
            if !defined? @osVersion
                self.osVersion
            end
            if ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 3) )
                @osRelease = "Panther"
                @osPanther = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 4) )
                @osRelease = "Tiger"
                @osTiger = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 5) )
                @osRelease = "Leopard"
                @osLeopard = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 6) )
                @osRelease = "SnowLeopard"
                @osSnowLeopard = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 7) )
                @osRelease = "Lion"
                @osLion = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 8) )
                @osRelease = "Mountain Lion"
                @osLion = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 9) )
                @osRelease = "Mavericks"
                @osMavericks = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 10) )
                @osRelease = "Yosemite"
                @osYosemite = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 11) )
                @osRelease = "El Capitan"
                @osElCapitan = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 12) )
                  @osRelease = "Sierra"
                  @osSierra = true
            elsif ( (Integer(@osVersion[0]) == 10) && (Integer(@osVersion[1]) == 14) )
                    @osRelease = "Mojave"
                    @osMojave = true
              else
                raise RuntimeError.new( "MacOSX Version name not known for #{osVersion}!" )
            end
        end
        return @osRelease
    end


    #----------------------------------------------------------------
    #                       MacOSX Server Software?
    #----------------------------------------------------------------

    def osServer?
        if !defined? @fOsServer
            @fOsServer = false
            @softwareDescription['os_version'].split.each do |x|
                if 'Server' == x
                    @fOsServer = true
                    break
                end
            end
        end
        return @fOsServer
    end


    #----------------------------------------------------------------
    #               OS Type - client or server
    #----------------------------------------------------------------

    def osType
        @osType
    end


    #----------------------------------------------------------------
    #                           version
    #----------------------------------------------------------------

    def osVersion
        if !defined? @osVersion
            @softwareDescription['os_version'].split.each do |x|
                if x.match( "([0-9]{1,2})(\.([0-9]{1,2}))*" )
                    @osVersion = x.split( '.' )
                    if @osVersion.length == 2
                        @osVersion[2] = '0'
                    end
                    break
                end
            end
        end
        @osVersion[0] = Integer(@osVersion[0])
        @osVersion[1] = Integer(@osVersion[1])
        @osVersion[2] = Integer(@osVersion[2])
        return @osVersion
    end


end




#----------------------------------------------------------------
#                       Main Program
#----------------------------------------------------------------

if __FILE__ == $0

    oApp = MacOSXComputerProfile.new
    puts "computerName: "+oApp.computerName
    puts "osArchitecture: "+oApp.osArchitecture
    puts "osName: "+oApp.osName
    puts "osType: "+oApp.osType
    puts "osVersion: "+oApp.osVersion.join('.')

end
