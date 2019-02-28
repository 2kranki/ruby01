#!/usr/bin/env ruby
# add -debug above to debug.

# vi:nu:et:sts=4 ts=4 sw=4

# Create basically a push-down stack of a file with the last saved
# version being the highest numbered and baseFilePath being the
# latest version.  So, restoration would be to replace the baseFilePath
# with the highest numbered file.  Slightly different approach than
# if taken in "Ruby Cookbook", Lucas Carlson and Leonard Richardson,
# O'Reilly, 2006.


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


#################################################################
#                       Module Definition
#################################################################

class VersionedFile

    attr :versionedFileDir,true


    #################################################################
    #                       Methods
    #################################################################

    #----------------------------------------------------------------
    #                   Object Instantiation 
    #----------------------------------------------------------------

    def initialize( versionedFileDir=nil )


    end


    #----------------------------------------------------------------
    #                   Versioned File 
    #----------------------------------------------------------------

    def restore( fileName, versionedFileDir, newFileDir, deleteVersion=true )

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


    def save( fileName, baseFileDir, versionedFileDir )

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


    def top( fileName, versionedFileDir )

        if !File.exist?( versionedFileDir )
            raise RuntimeError, "versioned file directory: #{versionedFileDir} was not found!"
        end

        # Brute force find
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




