class CGI
  module QueryExtension
    def read_multipart(boundary, content_length)
      # Ignore Flash 8 Corrupt 0-length multipart requests
      if content_length <= 0
        @multipart = false 
        return CGI::parse("")
      end
    
      params = Hash.new([])
      boundary = "--" + boundary
      buf = ""
      bufsize = 10 * 1024
      maxheadsize = 10 * 1024

      # start multipart/form-data
      stdinput.binmode if defined? stdinput.binmode
      boundary_size = boundary.size + EOL.size
      content_length -= boundary_size
      status = stdinput.read(boundary_size)


      if nil == status
        raise EOFError, "no content body"
      elsif boundary + EOL != status
        raise EOFError, "bad content body"
      end

      loop do
        head = nil
        if 10240 < content_length
          require "tempfile"
          body = Tempfile.new("CGI")
        else
          begin
            require "stringio"
            body = StringIO.new
          rescue LoadError
            require "tempfile"
            body = Tempfile.new("CGI")
          end
        end
        body.binmode if defined? body.binmode

        until head and /#{boundary}(?:#{EOL}|--)/n.match(buf)
          
          if (not head)
            if /#{EOL}#{EOL}/n.match(buf)
              buf = buf.sub(/\A((?:.|\n)*?#{EOL})#{EOL}/n) do
                head = $1.dup
                ""              
              end
              next
            else 
              if buf.size >= maxheadsize || content_length <= 0 
                # head is too big or corrupt.  let's set a fake one
                # For now, we're still accepting the POST, but we may want to
                # raise an error instead
                params["__corrupt_multipart_data"] = ['true']
                return params
              end
            end
          end

          if head and ( (EOL + boundary + EOL).size < buf.size )
            body.print buf[0 ... (buf.size - (EOL + boundary + EOL).size)]
            buf[0 ... (buf.size - (EOL + boundary + EOL).size)] = ""
          end

          c = if bufsize < content_length
                stdinput.read(bufsize)
              else
                stdinput.read(content_length)
              end
          if c.nil?
            raise EOFError, "bad content body"
          end
          buf.concat(c)
          content_length -= c.size
        end

        buf = buf.sub(/\A((?:.|\n)*?)(?:[\r\n]{1,2})?#{boundary}([\r\n]{1,2}|--)/n) do
          body.print $1
          if "--" == $2
            content_length = -1
          end
          ""
        end

        body.rewind

        /Content-Disposition:.* filename="?([^\";]*)"?/ni.match(head)
        filename = ($1 or "")
        if /Mac/ni.match(env_table['HTTP_USER_AGENT']) and
            /Mozilla/ni.match(env_table['HTTP_USER_AGENT']) and
            (not /MSIE/ni.match(env_table['HTTP_USER_AGENT']))
          filename = CGI::unescape(filename)
        end
        
        /Content-Type: (.*)/ni.match(head)
        content_type = ($1 or "")

        (class << body; self; end).class_eval do
          alias local_path path
          define_method(:original_filename) {filename.dup.taint}
          define_method(:content_type) {content_type.dup.taint}
        end

        /Content-Disposition:.* name="?([^\";]*)"?/ni.match(head)
        name = $1.dup

        if params.has_key?(name)
          params[name].push(body)
        else
          params[name] = [body]
        end
        break if buf.size == 0
        break if content_length === -1
      end

      params
    end
  end
end