require "openssl_ext"

class Authorizer::Client
  def initialize(certificate_pem : String)
    @cert = OpenSSL::X509::Certificate.new(certificate_pem)
  end

  def authorization_token()
    encrypted_token = @cert.public_key.public_encrypt(Authorizer::TOKEN)
    Authorizer.bin_to_hex(encrypted_token)
  end
end

class Authorizer::Server
  def initialize(private_key_content)
    @rsa = OpenSSL::RSA.new(private_key_content, is_private: true)
  end

  def authorized?(encrypted_token)
    bin_token = Authorizer.hex_to_bin(encrypted_token)

    String.new(@rsa.private_decrypt(bin_token)) == Authorizer::TOKEN
  end
end

module Authorizer
  TOKEN = "mob"

  def self.bin_to_hex(data : Slice(UInt8))
    String.build do |str|
      data.each do |byte|
        if byte <= 0xf
          str << "0"
        end
        str << byte.to_s(16)
      end
    end
  end

  def self.hex_to_bin(hex : String) : Slice(UInt8)
    out = Slice(UInt8).new((hex.size/2).to_i)

    pair = ""
    hex.each_char_with_index do |char, index|
      pair += char

      if index == 1
        out[index - 1] = pair.to_u8(16)
        pair = ""
      elsif (index + 1) % 2 == 0
        out[(index / 2).to_i] = pair.to_u8(16)
        pair = ""
      end
    end

    out
  end
end
