"use strict"

crypto = require "crypto"
Errors = require "./errors"

module.exports = class Encryption

  constructor: (@key, @webpayKey) ->

  keyBytes: =>
    @key.keyPair.cache.keyByteLength

  webpayKeyLength: =>
    @webpayKey.keyPair.cache.keyByteLength

  encrypt: (text) =>
    try
      signature = @key.sign crypto.createHash("sha256").update(text).digest()
      key = crypto.randomBytes 32
      encripted_key = @webpayKey.encrypt key
      iv = crypto.randomBytes 16
      cipher = crypto.createCipheriv "aes-256-cbc", key, iv
      encripted_text = cipher.update(
        new Buffer(signature + text)) + cipher.final()
      return new Buffer(iv + encripted_key + encripted_text).toString "base64"
    catch e
      throw new Errors.EncryptionError "Encryption failed: #{e}"

  decrypt: (encripted_text) =>
    try
      data = new Buffer encripted_text, "base64"
      iv = data.slice 0, 16
      encripted_key = data.slice 16, 16 + @keyBytes
      key = @key.decrypt encripted_key
      cipher = crypto.createCipheriv "aes-256-cbc", key, iv
      decrypted_text = cipher.update(
        data.slice(16 + @keyBytes, -1)) + cipher.final()
      signature = decrypted_text.slice 0, @webpayKeyLength
      text = decrypted_text.slice @webpayKeyLength, -1
      unless @webpayKey.verify text, signature
        throw new Errors.EncryptionError "Invalid message signature"
      return {
        body: text
        signature: signature.toString()[0]
      }
    catch e
      throw new Errors.EncryptionError "Decryption failed: #{e}"
