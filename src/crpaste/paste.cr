require "random/secure"

module Crpaste
  class Paste
    getter! id : Int32
    getter content : Slice(UInt8)
    getter client_ip : String?
    getter token : String?
    getter expires_at : Time
    getter created_at : Time?
    @owner_token : String?

    def self.find(id)
      find_with_token id, nil
    end

    def self.find_with_token(id, token)
      result = Crpaste.db.query_one?(
        "SELECT id, content, expires_at, client_ip, token, owner_token, created_at
         FROM pastes
         WHERE id = $1 AND (token IS NULL OR token = $2 OR owner_token = $2 OR $3)",
        [id, token, token == true]
      ) do |result|
          paste = new result.read(Int32),
              result.read(Slice(UInt8)),
              result.read(Time),
              result.read(String?),
              result.read(String?),
              result.read(String),
              result.read(Time)

        if paste.expired?
          paste.destroy
          nil
        else
          paste
        end
      end
    end

    def initialize(@content : Slice(UInt8), @expires_at, @client_ip)
    end

    def initialize(@id : Int32,
                   @content : Slice(UInt8),
                   @expires_at,
                   @client_ip,
                   @token,
                   @owner_token,
                   @created_at)
    end

    def private?
      !token.nil?
    end

    def public?
      token.nil?
    end

    def expired?
      expires_at <= Time.local
    end

    def persisted?
      !@id.nil?
    end

    def owner_token
      @owner_token ||= generate_token
    end

    def text
      String.new(content)
    end

    def make_private
      @token ||= generate_token
    end

    def save
      result = Crpaste.db.query_one(
        "INSERT INTO pastes (content, client_ip, token, owner_token, expires_at)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, created_at AT TIME ZONE 'UTC' AS created_at",
        [content, client_ip, token, owner_token, expires_at]
      ) do |result|
        @id         = result.read(Int32)
        @created_at = result.read(Time)
      end
      true
    end

    def destroy_with_token(token)
      if owner_token == token
        destroy
      else
        false
      end
    end

    def destroy
      if persisted?
        Crpaste.db.exec("DELETE FROM pastes WHERE id = $1", [id])
        @id = nil
        true
      else
        false
      end
    end

    private def generate_token
      Random::Secure.random_bytes(16).hexstring
    end
  end
end
