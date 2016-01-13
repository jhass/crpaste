require "secure_random"

module Crpaste
  class Paste
    getter! id
    getter content
    getter client_ip
    getter token
    getter expires_at
    getter created_at

    def self.find(id)
      find_with_token id, nil
    end

    def self.find_with_token(id, token)
      result = Crpaste.db.exec(
        "SELECT id, content, expires_at, client_ip, token, owner_token, created_at
         FROM pastes
         WHERE id = $1 AND (token IS NULL OR token = $2 OR owner_token = $2 OR $3)",
        [id, token, token == true]
      )
      unless result.rows.empty?
        row = result.to_hash.first
        paste = new row["id"] as Int32,
            row["content"] as Slice(UInt8),
            row["expires_at"] as Time,
            row["client_ip"] as String?,
            row["token"] as String?,
            row["owner_token"] as String,
            row["created_at"] as Time

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
      expires_at <= Time.now
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
      result = Crpaste.db.exec({Int32, Time},
        "INSERT INTO pastes (content, client_ip, token, owner_token, expires_at)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, created_at AT TIME ZONE 'UTC' AS created_at",
        [content, client_ip, token, owner_token, expires_at]
      ).rows.first
      @id         = result[0]
      @created_at = result[1]
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
      SecureRandom.uuid.delete('-')
    end
  end
end
