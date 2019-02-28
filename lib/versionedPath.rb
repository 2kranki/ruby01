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



#----------------------------------------------------------------
#                       Global Variables
#----------------------------------------------------------------

#   IMPORTANT - Most Global Varialbles should only be defined
#   in the main script file.


	require		"logMessages"
	require		"singleton"
	require		"unixCommands"


=begin
#################################################################################
#                               macroExpansion Object
#################################################################################

#


class       macroExpansion:

    def __init__( self ):
        self.listDelims     = [ '<*', '*>' ]
        self.dictEnv        = { }
        self.oOutput        = None
        self.dictPrefixMap  = { }

    def __repr__( self ):
        return self.__str__( )


    def __str__( self ):
        szString = '<macroExpansion::'
        szString += "%s," % ( self.listDelims )
        szString += "%s," % ( self.dictEnv )
        szString += '>'
        return szString


#-------------------------------------------------------------------------------
#                               Get/Set Methods
#-------------------------------------------------------------------------------

    def getDelims( self ):
        return self.listDelims


    def setDelims( self, listData ):
        if listData and 2 == len(listData):
            self.listDelims = listData
            return
        raise ValueError


    def getEnv( self ):
        return self.dictEnv


    def setEnv( self, dictData ):
        if dictData:
            self.dictEnv = dictData
            return
        raise ValueError


    def getOutput( self ):
        return self.oOutput


    def setOutput( self, oData ):
        if oData:
            self.oOutput = oData
            return
        raise ValueError


#-------------------------------------------------------------------------------
#                               General Methods
#-------------------------------------------------------------------------------

    def addEnvEntry( self, szKey, szData ):
        "add an entry to the Environment."
        if fDebug:
            print "addEnvEntry(%s,%s)" % ( szKey, szData )
        if szKey:
            if szKey in self.dictEnv:
                raise KeyError,szKey
            else:
                self.dictEnv[szKey] = szData
                return
        raise ValueError


    def addPrefixMapEntry( self, szKey, szData ):
        "add an entry to the PrefixMap."
        if fDebug:
            print "addPrefixMapEntry(%s,%s)" % ( szKey, szData )
        if szKey:
            if szKey in self.dictPrefixMap:
                raise KeyError,szKey
            else:
                self.dictPrefixMap[szKey] = szData
                return
        raise ValueError


    def expandTextUsingEval( self, text ):
        """ Replaces all the Python code expressions in the string 'text'
            with their output, and writes the resulting string to
            self.oOutput.

            The environment that the code is executed in is provided by
            this object.  You can add to it using the addEnv( ) method.

            All the code fragments are executed in 'env'. This namespace
            is empty by default. You can supply values using the addEnv( )
            method.  Please note that if you leave it empty, then the first
            call to eval will populate it with all the globals, because
            '__builtins__' isn't defined.  If you do not want this, then
            you must do addEnv( '__builtins__', None ).
        """

        (szBegin,szEnd) = self.listDelims
        cBegin = len( szBegin )
        cEnd = len( szEnd )
        if len( text ) <= cBegin + cEnd:
            self.oOutput.write( text )
        else:
            idxPos = 0
            idxStart = string.find( text, szBegin, idxPos )
            while idxStart >= 0:
                idxStop = string.find( text, szEnd, idxStart+cBegin )
                if idxStop < 0:
                    raise ValueError, "ERROR - Unterminated python macro at %d in '%10s'" % ( idxStart, string[idxStart:] )
                out.append( text[idxPos:idxStart] )
                szExpr = string.strip( text[ idxStart+cBegin : idxStop ] )
                prefix = self.dictPrefixMap.get( szExpr[0] )
#                print "\tstart=%i stop=%i exp=%s prefix=%s" % ( idxStart, idxStop, szExpr, prefix )
                try:
                    if prefix:
                        len_pr = len( prefix[0] )
                        if len(szExpr) >= len_pr and szExpr[:len_pr] == prefix[0]:
                            value = eval( prefix[1]+szExpr[len_pr:], self.dictEnv, self.dictEnv )
                        else:
                            raise KeyError,"ERROR: illegal prefix '%s'" % szExpr[:len_pr]
                    else:
                        value = eval( szExpr, self.dictEnv, self.dictEnv )
                except Exception, error:
                    raise
                self.expandTextUsingEval( str(value) )
                idxPos = idxStop + cEnd
                idxStart = string.find( text, szBegin, idxPos )
            szRemainder = text[ idxPos : ]
            if len(szRemainder) > 0:
                self.oOutput.write( szRemainder )


    def getEnvEntry( self, szKey ):
        "get an entry in the Environment."
        if fDebug:
            print "getEnvEntry(%s)" % ( szKey )
        if szKey:
            if szKey in self.dictEnv:
                return self.dictEnv[szKey]
            else:
                raise KeyError,szKey
        raise ValueError


    def updateEnvEntry( self, szKey, szData ):
        "update an entry in the Environment."
        if fDebug:
            print "updateEnvEntry(%s,%s)" % ( szKey, szData )
        if szKey:
            if szKey in self.dictEnv:
                self.dictEnv[szKey] = szData
                return
            else:
                raise KeyError,szKey
        raise ValueError




    def versionedTextFileCopy( self, szSrc, dictEnvPrm=None, szDest=None, szPerms=None, szUser=None, szGroup=None ):
        """Copy a text file to its destination using Version Information
        found on the front of the file.  Substitute Environment values
        in each line of text using the string formatting operator.  So,
        '%(xxx)s' would substitute the dictionary key, xxx, of dictEnv
        as a string.  %% would just substitute % into the output string.
        """
        if fDebug:
            print "fileCopyTextVersion(%s,%s)" % ( szSrc, szDestOrDict )
        dictFile =  {
                        "FILE_PATH":"",
                        "FILE_PERMS":"640",
                        "FILE_USER":"root",
                        "FILE_GROUP":"root"
                    }
        if dictEnvPrm:
            dictEnv = dictEnvPrm
        else:
            dictEnv = self.dictEnv

        # Set up paths.
        szWrkSrcPath = self.versionedPath( szSrc )
        if not szWrkSrcPath:
            if fDebug or iVerbose:
                print   "ERROR - Failed to find a versioned path for %s!" % ( szSrc )
            return
        szWrkSrcPath = rmwCmn.getAbsolutePath( szWrkSrcPath )
        if fDebug:
            print "\tVersionedSourcePath=%s" % ( szWrkSrcPath )

        # Read the source file processing the special file parameters denoted by
        # "##:" starting in column 1 and followed by <name>=<value>.  These lines
        # must be at the head of the file.
        lineNum = 0
        inputFile = open( szWrkSrcPath, 'r' )
        while 1:
            szLine = inputFile.readline( )
            ++lineNum
            if not szLine:
                break
            szLine2 = szLine.rstrip( )
            if fDebug:
                print "  Looking line len: %d data: '%s'" % ( len(szLine2), szLine2 )
            if "##:" == szLine2[0:3]:
                szLine2 = szLine2[3:]
                szLine2 = szLine2.lstrip( )
                if len(szLine2):
                    iEqual = szLine2.find( "=", 1 )
                    if fDebug:
                        print "  Looking for '=' data: '%s' found at: %d" % ( szLine2, iEqual )
                    if iEqual < 0:
                        pass
                    else:
                        szName = szLine2[:iEqual]
                        try:
                            szValue = szLine2[iEqual+1:] % dictEnv
                        except:
                            if fDebug:
                                print ">>>szLine=",szLine2
                                print ">>>dictEnv=",dictEnv
                            print "ERROR: %s, line %d - invalid python substitution!" % ( szWrkSrcPath, lineNum )
                            raise
                        if fDebug:
                            print "  found Name: '%s' Data: '%s'" % ( szName, szValue )
                        dictFile[szName] = szValue
            else:
                if 0 == len(szLine2):
                    pass
                else:
                    break
        if fDebug:
            print "\tdictFile=%s" % ( dictFile )
            print ">>>dictEnv=",dictEnv
        #Parse off the rest of the file.
        listFile = [ ]
        while 1:
            if not szLine:
                break
            try:
                szLine = szLine % dictEnv
            except:
                if fDebug:
                    print ">>>szLine=",szLine
                    print ">>>dictEnv=",dictEnv
                print "ERROR: %s, line %d - invalid python substitution!" % ( szWrkSrcPath, lineNum )
                raise
            listFile.append( szLine )
            if fDebug:
                print "  Appending line len: %d data: '%s'" % ( len(szLine), szLine )
            szLine = inputFile.readline( )
            ++lineNum
        inputFile.close( )

        # Set up overrides if present.
        if szDest:
            dictFile["FILE_PATH"]=szDest
        if szPerms:
            dictFile["FILE_PERMS"]=szPerms
        if szUser:
            dictFile["FILE_USER"]=szUser
        if szGroup:
            dictFile["FILE_GROUP"]=szGroup

        # Now, write the file out to its destination.
        szWrkDstPath = dictFile["FILE_PATH"]
        szWrkDstPath = os.path.normpath( self.getRootPath( ) + szWrkDstPath )
        if not szWrkDstPath:
            print "ERROR - no destination path found!"
            print "\tThe source file path is %s." % ( szWrkSrcPath )
            print "\tThe dictionary scanned off is %s." % ( dictFile )
            raise ValueError
        try:
            szWrkDstPathNew = rmwCmn.getAbsolutePath( szWrkDstPath )
        except:
            print   "EXCEPTION new file path not valid:"
            print   "    szWrkDstPath=",szWrkDstPath
            print   "    szWrkDstPathNew=",szWrkDstPathNew
            raise
        szWrkDstDirNew = os.path.dirname( szWrkDstPathNew )
        if not os.path.isdir( szWrkDstDirNew ):
            szCmd = "sudo -u %s mkdir -p \"%s\"" % ( dictFile["FILE_USER"], szWrkDstDirNew )
            try:
                self.execChroot( [ szCmd ] )
            except OSError:
                print "OSError Exception:"
                print "   cmd=",szCmd
                print "   rc=%s" % (oCmd.iRC)
                print "   output=%s" % (oCmd.szOutput)
                raise
        try:
            if os.path.isfile( szWrkDstPathNew ):
                rmwCmn.renameFileForVersionBackup( szWrkDstPathNew )
        except:
            print   "EXCEPTION renaming old file:"
            print   "    szWrkDstPath=",szWrkDstPath
            print   "    szWrkDstPath=",szWrkDstPathNew
            raise
        try:
            outputFile = open( szWrkDstPathNew, "w" )
            outputFile.writelines( listFile )
            outputFile.close( )
        except:
            print   "EXCEPTION writing file:"
            print   "    szWrkDstPath=",szWrkDstPathNew
            raise
        if self.iVerbose or fDebug:
            print   "\tCopied %s to %s" % ( szWrkSrcPath, szWrkDstPathNew )
        szWrkDstPathNew = dictFile["FILE_PATH"]
        szCmd = "chmod %s \"%s\" " % ( dictFile["FILE_PERMS"], szWrkDstPathNew )
        try:
            self.execChroot( [ szCmd ] )
        except OSError:
            print "OSError Exception:"
            print "   cmd=",szCmd
            print "   rc=%s" % (oCmd.iRC)
            print "   output=%s" % (oCmd.szOutput)
            raise
        if self.iVerbose or fDebug:
            print   "\tPermissions set to %s" % ( dictFile["FILE_PERMS"] )
        szCmd = "chown %s:%s \"%s\" " % ( dictFile["FILE_USER"], dictFile["FILE_GROUP"], szWrkDstPathNew )
        try:
            self.execChroot( [ szCmd ] )
        except OSError:
            print "OSError Exception:"
            print "   cmd=",szCmd
            print "   rc=%s" % (oCmd.iRC)
            print "   output=%s" % (oCmd.szOutput)
            raise
        if self.iVerbose or fDebug:
            print   "\tOwner set to %s:%s" % ( dictFile["FILE_USER"], dictFile["FILE_GROUP"] )

        # Return to caller.
        return



=end


#################################################################
#                       Module Definition
#################################################################

class VersionedPath

    attr :osDir,true
    attr :osName,true
    attr :osVersion,true
    attr :osType,true
    attr :computerName,true

    include		Singleton

    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize

		$oLog = LogMessages.instance
		$oUnix = UnixCommands.instance

    end


    #----------------------------------------------------------------
    #                       copy a file.
    #----------------------------------------------------------------

    def copyFile( srcName, destPath, attr=nil, owner=nil, group=nil, fSudo=false )

        $oLog.logDebug(  "#{self.class.name}::copyFile( #{srcName}, #{destPath} )" )

        srcPath = self.find( srcName )
        $oUnix.copyFile( srcPath, destPath, attr, owner, group, fSudo )

    end


    #----------------------------------------------------------------
    #                     Get a versioned path.
    #----------------------------------------------------------------

    def find( fileName )

        $oLog.logDebug(  "#{self.class.name}::find( #{fileName} )" )

        szVersionedPath = self.findvp( @osDir, @osName, @osVersion, @osType, @computerName, fileName )
        return szVersionedPath

    end


    #----------------------------------------------------------------
    #                     Get a versioned path.
    #----------------------------------------------------------------

    def findvp( osDir, osName, osVersion, osType, computerName, fileName )

        $oLog.logDebug(  "#{self.class.name}::findvp( )" )
        $oLog.logDebug(  "#{self.class.name}::findvp    osDir = #{osDir}" )     # Base Directory
        $oLog.logDebug(  "#{self.class.name}::findvp    osName = #{osName}" )
        $oLog.logDebug(  "#{self.class.name}::findvp    osVersion = #{osVersion.join('.')}" )
        $oLog.logDebug(  "#{self.class.name}::findvp    osType = #{osType}" )
        $oLog.logDebug(  "#{self.class.name}::findvp    computerName = #{computerName}" )
        $oLog.logDebug(  "#{self.class.name}::findvp    fileName = #{fileName}" )

        if !(osVersion.is_a? Array)
            raise ArgumentError.new( "osVersion, #{osVersion} is not an array!" )
        end
        if !((osType == "client") || (osType == "server"))
            raise ArgumentError.new( "osVersion, #{osVersion} is not client or server!" )
        end
        osNameDir = "#{osDir}/#{osName}"
        $oLog.logDebug( "VersionedPath.find:  osNameDir = #{osNameDir}" )
        if (computerName.length > 0)
            deviceDir = "devices/#{computerName}"
        else
            deviceDir = ""
        end
        if (osVersion.length > 0)
            osVersion1 = "#{osVersion[0]}"
        else
            osVersion1 = ""
        end
        if (osVersion.length > 1)
            osVersion2 = "#{osVersion[0]}.#{osVersion[1]}"
        else
            osVersion2 = ""
        end
        if (osVersion.length == 3)
            osVersion3 = "#{osVersion[0]}.#{osVersion[1]}.#{osVersion[2]}"
        else
            osVersion3 = ""
        end

        if (osVersion.length == 3) && (deviceDir.length > 0)
            szVersionedPath = "#{osNameDir}/#{deviceDir}/#{osVersion3}/#{osType}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{deviceDir}/#{osVersion3}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
        end
        if (osVersion.length > 1) && (deviceDir.length > 0)
            szVersionedPath = "#{osNameDir}/#{deviceDir}/#{osVersion2}/#{osType}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{deviceDir}/#{osVersion2}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
        end
        if (osVersion.length > 0) && (deviceDir.length > 0)
            szVersionedPath = "#{osNameDir}/#{deviceDir}/#{osVersion1}/#{osType}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{deviceDir}/#{osVersion1}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
        end
        if  (deviceDir.length > 0)
            szVersionedPath = "#{osNameDir}/#{deviceDir}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
        end
        if (osVersion.length == 3)
            szVersionedPath = "#{osNameDir}/#{osVersion3}/#{osType}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{osVersion3}/#{computerName}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{osVersion3}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
        end
        if (osVersion.length > 1)
            szVersionedPath = "#{osNameDir}/#{osVersion2}/#{osType}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{osVersion2}/#{computerName}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{osVersion2}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
        end
        if (osVersion.length > 0)
            szVersionedPath = "#{osNameDir}/#{osVersion1}/#{osType}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{osVersion1}/#{computerName}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
            szVersionedPath = "#{osNameDir}/#{osVersion1}/#{fileName}"
            $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
            if File.file?( szVersionedPath )
                return szVersionedPath
            end
        end
        szVersionedPath = "#{osNameDir}/#{fileName}"
        $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
        if File.file?( szVersionedPath )
            return szVersionedPath
        end
        szVersionedPath = "#{osNameDir}/#{computerName}/#{fileName}"
        $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
        if File.file?( szVersionedPath )
            return szVersionedPath
        end
        szVersionedPath = "#{osDir}/#{computerName}/#{fileName}"
        $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
        if File.file?( szVersionedPath )
            return szVersionedPath
        end
        szVersionedPath = "#{osDir}/#{fileName}"
        $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
        if File.file?( szVersionedPath )
            return szVersionedPath
        end
        szVersionedPath = "#{Dir.getwd}/#{fileName}"
        $oLog.logDebug( "VersionedPath.find:  looking for #{szVersionedPath}" )
        if File.file?( szVersionedPath )
            return szVersionedPath
        end
        
        raise ArgumentError.new( "Versioned path for #{fileName} was not found!" )

    end


    #----------------------------------------------------------------
    #           Extract a directory from  a provided tarball
    #----------------------------------------------------------------

    def tarballExtract( tarballName, destDir=Dir.getwd, fSudo=false )

        $oLog.logDebug( "#{self.class.name}::tarballExtract( #{tarballName} -> #{destDir})" )
 
        srcPath = self.find( tarballName )
        $oUnix.tarballExtract( srcPath, destDir, fSudo )

    end


    #----------------------------------------------------------------
    #                   Versioned File 
    #----------------------------------------------------------------

    # Create basically a push-down stack of a file with the last saved
    # version being the highest numbered and baseFilePath being the
    # latest version.  So, restoration would be to replace the baseFilePath
    # with the highest numbered file.  Slightly different approach than
    # if taken in "Ruby Cookbook", Lucas Carlson and Leonard Richardson,
    # O'Reilly, 2006.


    def self.versionedFileRestore( fileName, versionedFileDir, newFileDir, deleteVersion=true )

        if !File.exist?( versionedFileDir )
            raise RuntimeError, "versioned file directory: #{versionedFileDir} was not found!"
        end
        if !File.exist?( newFileDir )
            raise RuntimeError, "file directory: #{newFileDir} was not found!"
        end

        suffix = 1000
        loop do
            suffix = suffix - 1
            if suffix < 1
                puts "...baseFilePath before this: #{baseFilePath}"
                raise RuntimeError, "versioned file: #{fileName} not found in #{versionedFileDir}!"
            end
            baseFilePath = File.join( versionedFileDir, fileName+'.'+suffix.to_s.rjust(3,'0') )
            if File.exist?( baseFilePath )
                puts "...Found: #{baseFilePath} and copying"
                FileUtils.copy_file( baseFilePath, File.join( newFileDir, fileName ) )
                if deleteVersion
                    puts "...deleting: #{baseFilePath}"
                    File.delete( baseFilePath )
                end
                return suffix
            end
        end
        raise RuntimeError, "versioned file: #{fileName} not found in #{versionedFileDir}!"

    end


    def self.versionedFileSave( fileName, baseFileDir, versionedFileDir )

        if !File.exist?( versionedFileDir )
            raise RuntimeError, "versioned file directory: #{versionedFileDir} was not found!"
        end
        if !File.exist?( baseFileDir )
            raise RuntimeError, "file directory: #{baseFileDir} was not found!"
        end
        baseFilePath = File.join( baseFileDir, fileName )
        if !File.exist?( baseFilePath )
            raise RuntimeError, "file: #{baseFilePath} was not found!"
        end

        suffix = 0
        loop do
            suffix = suffix + 1
            if suffix > 999
                raise RuntimeError,'Suffix is too large'
            end
            verFilePath = File.join( versionedFileDir, fileName+'.'+suffix.to_s.rjust(3,'0') )
            unless File.exist?( verFilePath )
                FileUtils.copy_file( baseFilePath, verFilePath )
                return suffix
            end
        end
        raise RuntimeError, "Too many versioned files: #{fileName} in #{versionedFileDir}!"

    end


    def self.versionedFileTop( fileName, versionedFileDir )

        if !File.exist?( versionedFileDir )
            raise RuntimeError, "versioned file directory: #{versionedFileDir} was not found!"
        end

        suffix = 1000
        loop do
            suffix = suffix - 1
            if suffix < 1
                return nil
            end
            baseFilePath = File.join( versionedFileDir, fileName+'.'+suffix.to_s.rjust(3,'0') )
            if File.exist?( baseFilePath )
                return baseFilePath
            end
        end
        return nil

    end


end




