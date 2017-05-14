require "http/server"
require "uri"
require "html"

require "artanis"
require "pg"

require "./crpaste/core_ext/enumerable"
require "./crpaste/core_ext/named_tuple"
require "./crpaste/core_ext/http/request"
require "./crpaste/paste"
require "./crpaste/version"

module Crpaste
  BASE_URL       = ENV["BASE_URL"]
  EXPIRE_DEFAULT = ENV["EXPIRES_DEFAULT"]?.try &.to_i || 6 * 3600 # 6 hours

  @@db : DB::Database?

  def self.db
    @@db ||= DB.open(ENV["DB"]? || "postgres:///crpaste")
  end

  class Web < Artanis::Application
    EXPIRE_UNITS  = {"s": 1, "m": 60, "h": 3600, "d": 3600*24, "w": 3600*24*7, "M": 3600*24*30, "y": 3600*24*365}
    EXPIRE_FORMAT = /(\d+)([#{EXPIRE_UNITS.keys.join}])?/

    def self.run
      port    = ENV["PORT"]?.try(&.to_i?) || 8000
      log_handler = HTTP::LogHandler.new
      static_file_handler = HTTP::StaticFileHandler.new(File.join(__DIR__, "..", "public"))
      static_file_handler.next = -> (context : HTTP::Server::Context) { Web.call(context) }
      log_handler.next = -> (context : HTTP::Server::Context) {
          path = context.request.path
          if path && (path.empty? || path.ends_with? "/")
            Web.call(context)
          else
            static_file_handler.call context
          end
      }
      server   = HTTP::Server.new("::", port) do |context|
        begin
          log_handler.call context
        rescue e
          e.inspect_with_backtrace(STDERR)
          context.response.status_code = 500
          context.response.content_type = "text/plain"
          context.response.puts "internal server error"
        end
      end

      puts "Crpaste listening on #{port}"
      server.listen
    end

    @id : String?
    @paste : Paste?

    post "/" do
      if query_params.has_key? "expire"
        expire = parse_expire query_params["expire"]
        return unprocessable("Invalid expire") unless expire
      else
        expire = EXPIRE_DEFAULT
      end

      expires_at = expire.seconds.from_now
      body       = request.body
      body       = body.gets_to_end if body
      if body && !body.empty?
        paste = Paste.new(URI.unescape(body, IO::Memory.new).to_slice, expires_at, client_ip)
        paste.make_private if query_params.has_key? "private"
        if paste.save
          id = paste.id.to_s(36)
          url = paste_url(paste)

          response.cookies << HTTP::Cookie.new("crpaste_#{id}", paste.owner_token, expires: paste.expires_at)

          if query_params.has_key? "redirect"
            redirect url
            301
          else
            status 201
            url
          end
        else
          unprocessable "Couldn't store paste"
        end
      else
        unprocessable "No body"
      end
    end

    private def parse_expire(expire)
      parsed = expire.match EXPIRE_FORMAT
      if parsed
        _, amount, unit = parsed
        unit = "m" if unit.empty?
        amount.to_i * EXPIRE_UNITS[unit]
      end
    end

    get "/:token/:id.txt" do
      find_paste(params["token"]) do |paste|
        response.content_type = "text/plain; charset=utf8"
        paste.text
      end
    end

    get "/:token/:id.:format" do
      find_paste(params["token"]) do |paste|
        response.content_type = "text/html; charset=utf8"
        ecr "paste"
      end
    end

    get "/:token/:id" do
      find_paste(params["token"]) do |paste|
        stream paste.content
      end
    end

    get "/:id.txt" do
      find_paste do |paste|
        response.content_type = "text/plain; charset=utf8"
        paste.text
      end
    end

    get "/:id.:format" do
      find_paste do |paste|
        response.content_type = "text/html; charset=utf8"
        ecr "paste"
      end
    end

    get "/:id" do
      find_paste do |paste|
        stream paste.content
      end
    end

    delete "/:id" do
      find_paste(true) do |paste|
        cookie = "crpaste_#{params["id"]}"
        if request.cookies.has_key? cookie
          if paste.destroy_with_token(request.cookies[cookie].value)
            "Deleted"
          else
            forbidden "Invalid token"
          end
        else
          forbidden "No cookie supplied"
        end
      end
    end

    private def paste_url(paste, format=nil)
      raise ArgumentError.new("no paste given") unless paste

      format ||= query_params["format"] if query_params.has_key? "format"
      url = BASE_URL
      url = File.join url, paste.token.not_nil! if paste.private?
      url = File.join url, paste.id.to_s(36)
      url += ".#{format}" if format
      url
    end

    private def find_paste(token=nil)
      @id = params["id"]
      id = params["id"].to_i?(36)
      return bad_request "Invalid id" unless id
      paste = token.nil? ? Paste.find(id) : Paste.find_with_token(id, token)
      if paste
        begin
          @paste = paste
          yield paste
        rescue InvalidByteSequenceError
          unprocessable "Not a UTF-8 paste"
        end
      else
        not_found
      end
    end

    private def stream(data : Slice(UInt8))
      headers({"Content-Length" => data.size, "Content-Type": "application/octet-stream"})
      response.write data
      200
    end

    private def client_ip
      headers = request.headers
      {"CLIENT_IP", "X_FORWARDED_FOR", "X_FORWARDED", "X_CLUSTER_CLIENT_IP", "FORWARDED"}.find_value {|header|
        dashed_header = header.tr("_", "-")
        headers[header]? || headers[dashed_header]? || headers["HTTP_#{header}"]? || headers["Http-#{dashed_header}"]?
      }.try &.split(',').first
    end

    private def query_params
      @query_params ||= HTTP::Params.parse(request.query || "") || HTTP::Params.new({} of String => Array(String))
    end

    private def not_found
      not_found { "Not found" }
      404
    end

    private def unprocessable(msg="Invalid submission")
      status 422
      body msg
      422
    end

    private def forbidden(msg="Forbidden")
      status 403
      body msg
      403
    end

    private def bad_request(msg="Bad request")
      status 400
      body msg
      400
    end
  end
end

Crpaste::Web.run
