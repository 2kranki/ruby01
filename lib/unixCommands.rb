#!/usr/bin/env ruby
# add -debug above to debug.

# vi:nu:et:sts=4 ts=4 sw=4

# Notes:
#    1. It is the caller's responsibility to enclose directory or file names
#       which contain spaces with quotes. These routines will not do so.


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

	require		"singleton"

#----------------------------------------------------------------
#                       Global Variables
#----------------------------------------------------------------

#   IMPORTANT - Most Global Varialbles should only be defined
#   in the main script file.


#################################################################
#                       Class Definition 
#################################################################

class UnixCommands

    RSYNC_OPTIONS = "-xrlptgoDEv"

	include		Singleton
	
    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #           apply a command to  a directory structure 
    #----------------------------------------------------------------

    def apply2DirsOnly( dstPath, command, fSudo=false )

        $oLog.logDebug( "#{self.class.name}::apply2DirsOnly( )" )

        self.apply2Match( dstPath, "-type d", command, fSudo )

    end


    #----------------------------------------------------------------
    #           chmod files only within a directory structure 
    #----------------------------------------------------------------

    def apply2FilesOnly( dstPath, command, fSudo=false )

        $oLog.logDebug( "#{self.class.name}::apply2FilesOnly( )" )

        self.apply2Match( dstPath, "-type f", command, fSudo )

    end


    #----------------------------------------------------------------
    #   apply a command to  a directory structure using a match
    #----------------------------------------------------------------

    def apply2Match( dstPath, match, command, fSudo=false )

        $oLog.logDebug( "#{self.class.name}::apply2DirsOnly( )" )

        self.verifyDestination( dstPath )
        self.verifyString( command, "Command" )
        self.verifyString( match, "Match expression" )

        if fSudo
            $oCmd.sys( "sudo find #{dstPath} #{match} -print0 | xargs -0 sudo #{command}" )
        else
            $oCmd.sys( "find #{dstPath} #{match} -print0 | xargs -0 #{command}" )
        end

    end


    #----------------------------------------------------------------
    #   chgrp on a directory, its subdirectories and their contents.
    #----------------------------------------------------------------

    def chgrpDirs( dstPath, group="" )

        $oCmd.sys( "sudo chgrp -R #{group} #{dstPath}" )

    end


    #----------------------------------------------------------------
    #           chmod on a directory and its subdirectories.
    #----------------------------------------------------------------

    def chmodDirs( dstPath, attr="755" )

        self.verifyString( attr, "Attributes" )

        $oCmd.sys( "sudo find #{dstPath} -type d -print0 | xargs -0 sudo chmod #{attr}" )

    end


    #----------------------------------------------------------------
    #           chmod dirs only within a directory structure 
    #----------------------------------------------------------------

    def chmodDirsOnly( dstPath, attr='644', fSudo=false )
        $oLog.logDebug( "#{self.class.name}::chmodDirsOnly( )" )

        self.verifyString( attr, "Attributes" )

        self.apply2DirsOnly( dstPath, "chmod #{attr}", fSudo )

    end


    #----------------------------------------------------------------
    #           chmod files only within a directory structure 
    #----------------------------------------------------------------

    def chmodFilesOnly( dstPath, attr='644', fSudo=false )
        $oLog.logDebug( "#{self.class.name}::chmodFilesOnly( )" )

        self.verifyString( attr, "Attributes" )

        self.apply2FilesOnly( dstPath, "chmod #{attr}", fSudo )

    end


    #----------------------------------------------------------------
    #   chown on a directory, its subdirectories and their contents.
    #----------------------------------------------------------------

    def chownDir( dstPath, owner, fSudo=false )

        self.verifyString( owner, "Owner" )

        $oCmd.sys( "sudo chown -R #{owner} #{dstPath}", false, fSudo )

    end


    #----------------------------------------------------------------
    #   chown recursively on a directory's files and subdirectories
    #----------------------------------------------------------------

    def chownDirsFiles( dstPath, owner, fSudo=false )

        self.verifyString( owner, "Owner" )
        self.verifyDestination( dstPath )
		if owner.nil?
			owner = ""
		end

        if owner.length > 0
            $oCmd.sys( "sudo chown -R #{owner} #{dstPath}", false, fSudo )
        end

    end


    #----------------------------------------------------------------
    #                       copy a file.
    #----------------------------------------------------------------

    def copyFile( srcPath, dstPath, attr=nil, owner=nil, group=nil, fSudo=false )

        self.verifyString( attr, "Flags" )
        if !attr.nil? && (attr.include? "\n")
            raise ArgumentError,"owner contains a new-line -- #{attr}"
        end
        if !owner.nil? && (owner.include? "\n")
            raise ArgumentError,"owner contains a new-line -- #{owner}"
        end
        if !group.nil? && (group.include? "\n")
            raise ArgumentError,"group contains a new-line -- #{group}"
        end
        self.verifyDestination( srcPath )
        self.verifyDestination( dstPath )

        $oCmd.sys( "cp  \"#{srcPath}\" \"#{dstPath}\"", false, fSudo )
		if owner.nil?
			ownerGroup = ""
		else
			ownerGroup = owner
		end
		if group.nil?
        else
			ownerGroup += ":#{group}"
		end
        if ownerGroup.length > 0
            $oCmd.sys( "chown -R #{ownerGroup} \"#{dstPath}\"", false, fSudo )
        end
        if attr.nil?
        else
            if attr.include? "\n"
                raise ArgumentError,"szCmd contains a new-line"
            end
            if dstPath.include? "\n"
                raise ArgumentError,"szCmd contains a new-line"
            end
            $oCmd.sys( "chmod -R #{attr} \"#{dstPath}\"", false, fSudo )
        end

    end


    #----------------------------------------------------------------
    #                       copy a directory structure.
    #----------------------------------------------------------------

    def copyDirsFiles( srcPath, dstPath, attr=nil, owner=nil, group=nil, copyParms="-R", fSudo=false )

        self.verifyString( attr, "Flags" )
        if !attr.nil? && (attr.include? "\n")
            raise ArgumentError,"owner contains a new-line -- #{attr}"
        end
        if !owner.nil? && (owner.include? "\n")
            raise ArgumentError,"owner contains a new-line -- #{owner}"
        end
        if !group.nil? && (group.include? "\n")
            raise ArgumentError,"group contains a new-line -- #{group}"
        end
        self.verifyDestination( srcPath )
        self.verifyDestination( dstPath )

        $oCmd.sys( "cp #{copyParms} #{srcPath} \"#{dstPath}\"", false, fSudo )
		if owner.nil?
			ownerGroup = ""
		else
			ownerGroup = owner
		end
		if group.nil?
        else
			ownerGroup += ":#{group}"
		end
        if ownerGroup.length > 0
            $oCmd.sys( "chown -R #{ownerGroup} \"#{dstPath}\"", false, fSudo )
        end
        if attr.nil?
        else
            if attr.include? "\n"
                raise ArgumentError,"szCmd contains a new-line"
            end
            if dstPath.include? "\n"
                raise ArgumentError,"szCmd contains a new-line"
            end
            $oCmd.sys( "chmod -R #{attr} \"#{dstPath}\"", false, fSudo )
        end

    end


    #----------------------------------------------------------------
    #                       create a new directory.
    #----------------------------------------------------------------

    def directoryCreateNew( dstPath, attr=nil, owner=nil, group=nil, fSudo=true )

        self.verifyDestination( dstPath )
 
        if File.directory?( dstPath )
            $oCmd.sys( "rm -fr \"#{dstPath}\"", false, fSudo )
        end
        $oCmd.sys( "mkdir -p \"#{dstPath}\"", false, fSudo )
        if !owner.nil?
            $oCmd.sys( "chown #{owner} \"#{dstPath}\"", false, fSudo )
        end
        if !group.nil?
            $oCmd.sys( "chgrp #{group} \"#{dstPath}\"", false, fSudo )
        end
        if !attr.nil?
            $oCmd.sys( "chmod #{attr} \"#{dstPath}\"", false, fSudo )
        end

    end


    #----------------------------------------------------------------
    #         create a MD5 Hash for a directory if it exists.
    #----------------------------------------------------------------

    def directoryMD5( path )

        md5code = ''
        if File.directory?( path )
            $oCmd.sys( "tar c \"#{path}\" | md5", true, true )
            md5code = $oCmd.szOutput.chomp!
        end
        return md5code
    end


    #----------------------------------------------------------------
    #               remove a directory if it exists.
    #----------------------------------------------------------------

    def directoryRemove( path, fSudo=true )

        if File.directory?( path )
            if File.symlink?( path )
                $oCmd.sys( "rm \"#{path}\"", true, fSudo )
            else
                $oCmd.sys( "rm -fr \"#{path}\"", true, fSudo )
            end
        end

    end


    #----------------------------------------------------------------
    #           get information on the mounted disks
    #----------------------------------------------------------------

     def disksMounted( path=nil, fLocalOnly=true )
        # call out to the underlying OS and figure out all the devices on the system
        dfLocal = ""
        if fLocalOnly
            dfLocal = "-P"
        end
        df_output = %x{df -l -h #{dfLocal} \"#{path}\"}
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
   #                   Make the /usr/local directories 
   #----------------------------------------------------------------

    def mkUsrLocalDirs( )

        $oLog.logDebug( "#{self.class.name}::mkUsrLocalDirs( )" )

        if !File.directory?( "/usr/local" )
            $oLog.logInfo( "Creating /usr/local directories..." )
            $oLog.logInfo( "Please enter your password if requested..." )
            $oCmd.sys( 'sudo mkdir -p /usr/local/bin' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/bin/X11' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/include' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/include/X11' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/lib' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/lib/X11' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/info' )
            $oCmd.sys( 'sudo ln -s    /usr/local/share/info /usr/local/info', true )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man1' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man2' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man3' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man4' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man5' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man6' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man7' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man8' )
            $oCmd.sys( 'sudo mkdir -p /usr/local/share/man/man9' )
			$oCmd.sys( 'sudo ln -s    /usr/local/share/man  /usr/local/man', true )
       end


    end


    #----------------------------------------------------------------
    #               remove a directory if it exists.
    #----------------------------------------------------------------

    def rm_fr( path, fSudo=true )

        if File.directory?( path )
            if File.symlink?( path )
                $oCmd.sys( "rm \"#{path}\"", true, fSudo )
            else
                $oCmd.sys( "rm -fr \"#{path}\"", true, fSudo )
            end
        end

    end


    #----------------------------------------------------------------
    #           Synchronize two directory structures.
    #----------------------------------------------------------------

    def rsyncDirectories( 
                srcDir,
                dstDir, 
                options=nil, 
                excludeFile=nil, 
                fIgnoreRC=false,
                fNeedSudo=false
        )

        # srcDir should be the directory that you want to sync such as "/usr"
        # dstDir should be the directory that will contain the srcDir directory,
        #   such as "/Volumes/rmwBackup"
        # If the examples were used, "/Volumes/rmwBackup/usr" would exist or be updated.
        # NOTE -- dstDir are used as provided, so they could contain
        #           additional rsync options if needed
        srcDir = File.expand_path( srcDir )  # get rid of symlinks if any

        optionsUsed = RSYNC_OPTIONS
        if !options.nil?
            optionsUsed = options
        end
        if !excludeFile.nil?
            optionsUsed = "#{optionsUsed} --exclude-file=#{excludeFile}"
        end

        # Options suggested by Mike Bombich are:
        #   x - one-file-system (Don't cross filesystem boundaries. ie
        #       look at other mounted drives.)
        #   r - recursive
        #   l - links (copy symlinks as symlinks)
        #   p - perms (preserve permissions)
        #   t - times (preserve times)
        #   g - group (preserves group)
        #   o - owner (preserve owner)
        #   D - same as --devices --specials
        #   E - extended-attributes
        #   v - verbose

        $oCmd.sys( 
                  "rsync #{optionsUsed} #{srcDir} #{dstDir}", 
                  fIgnoreRC, 
                  fNeedSudo
        )
        
    end


    #----------------------------------------------------------------
    #               Is path given one that tar can deal with
    #----------------------------------------------------------------

    def UnixCommands.tarOk?( filePath )

        $oLog.logDebug( "#{self.class.name}::tarOk?( #{filePath})" )
        fTarball = false

        # Untar the source library.
        if File.exist?( "#{filePath}" )
            case filePath
                when /^.*\.tar\.gz$/, /^.*\.tgz$/
                    fTarball = true
                    ;;
                when /^.*\.tar\.bz2$/, /^.*\.tbz2$/
                    fTarball = true
                    ;;
                when /^.*\.zip$/
                    fZip = true
                    ;;
            end
        end
        return fTarball

    end


    #----------------------------------------------------------------
    #               Create a Tarball from a directory
    #----------------------------------------------------------------

    def tarCreate( srcDir, tarballPath )

        $oLog.logDebug( "#{self.class.name}::tarballCreate( #{fileName} -> #{destDir})" )

        raise NotImplementedError

        fileName = fileName.chomp
        filePath = "#{@options.tarballDirectory}/#{fileName}"
    
        # Untar the source library.
        if File.exist?( "#{filePath}" )
            $oLog.logInfo( "Restoring source..." )
            case fileName
                when /^.*\.tar\.gz$/, /^.*\.tgz$/
                    tarCmd = "tar xzvf"
                    ;;
                when /^.*\.tar\.bz2$/, /^.*\.tbz2$/
                    tarCmd = "tar xjvf"
                    ;;
                else
                    die( "unknown file type for #{filePath}" )
            end
            rc = $oCmd.sys( "#{tarCmd} \"#{filePath}\" -C \"#{destDir}\"" )
            if 0 != rc
                die( "failed to extract Source Tarball from #{filePath}" )
            end
        else
            raise ArgumentError,"cannot find Source Tarball -- #{tarballPath}"
        end

    end


    #----------------------------------------------------------------
    #           Extract a directory from  a provided tarball
    #----------------------------------------------------------------

    def tarExtract( filelPath, destDir=nil, fSudo=false )

        $oLog.logDebug( "#{self.class.name}::tarballExtract( #{filelPath} -> #{destDir})" )
    
        # Untar the source library.
        if File.exist?( "#{filelPath}" )
            $oLog.logInfo( "Restoring source..." )
            destDirOpt = "-C"
            case filelPath
                when /^.*\.tar\.gz$/, /^.*\.tgz$/
                    tarCmd = "tar xzvf"
                    # tar xzvf filePath [-C destDir]
                    ;;
                when /^.*\.tar\.bz2?$/, /^.*\.tbz2?$/
                    tarCmd = "tar xjvf"
                    # tar xjvf filePath [-C destDir]
                    ;;
                when /^.*\.zip$/
                    destDirOpt = "-d"
                    tarCmd = "unzip"
                    # unzip filePath [-d destDir]
                    ;;
                else
                    die( "tar unsupported file type for #{filelPath}" )
            end
            optDestDir = ""
            if !(destDir.nil?)
                if File.directory?( destDir )
                    optDestDir = "#{destDirOpt} \"#{destDir}\""
                end
            end
            rc = $oCmd.sys( "#{tarCmd} \"#{filelPath}\" #{optDestDir}", false, fSudo )
            if 0 != rc
                raise RuntimeError,"tar failed to extract: #{filelPath}"
            end
        else
            raise ArgumentError,"cannot find source file: #{filelPath}"
        end

    end


    #----------------------------------------------------------------
    #                   verify an Destination.
    #----------------------------------------------------------------

    def verifyDestination( dstPath )

        self.verifyString( dstPath, "Destination" )
        if dstPath.include? "\n"
            raise ArgumentError,"Destination contains a new-line -- #{dstPath}"
        end

    end


    #----------------------------------------------------------------
    #                   verify an String.
    #----------------------------------------------------------------

    def verifyString( aString, aName )

        if aString.nil? || !(aString.class == String) || (aString.length == 0)
            raise ArgumentError,"#{aName} is missing or invalid -- #{aString}"
        end

    end


    #----------------------------------------------------------------
    #               Is path given a zip archive
    #----------------------------------------------------------------

    def zip?( filePath )

        $oLog.logDebug( "#{self.class.name}::tarball?( #{tarballPath})" )
        fZip = false

        # Untar the source library.
        if File.exist?( "#{filePath}" )
            case filePath
                when /^.*\.zip$/
                    fZip = true
                    ;;
            end
        end
        return fZip

    end


end



