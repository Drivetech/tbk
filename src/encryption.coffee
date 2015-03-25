"use strict"

crypto = require "crypto"

Encryption = class Encryption

  constructor: (@senderKey, @recipientKey) ->

  keyBytes: =>
    @key.keyPair.cache.keyByteLength

  webpayKeyLength: =>
    @webpayKey.keyPair.cache.keyByteLength

  getKey: ->
    crypto.randomBytes 32

  getIv: ->
    crypto.randomBytes 16

  encryptKey: (key) ->
    @recipientKey.encrypt key

  signMessage: (message) ->
    @senderKey.sign crypto.createHash("sha256").update(message).digest()

  encryptMessage: (signedMessage, message, key, iv) ->
    messageToEncrypt = new Buffer signedMessage + message
    cipher = crypto.createCipheriv "aes-256-cbc", key, iv
    cipher.setAutoPadding true
    cipher.update messageToEncrypt

  encrypt: (message) ->
    key = @getKey()
    iv = @getIv()
    encryptedKey = @encryptKey key
    signedMessage = @signMessage message
    encryptedMessage = @encryptMessage signedMessage, message, key, iv
    new Buffer(iv + encryptedKey + encryptedMessage).toString "base64"

Decryption = class Decryption

  constructor: (@recipientKey, @senderKey) ->

  decrypt: (message) ->
    raw = message.toString()

    iv = @getIv raw
    key = @getKey raw

    decryptedMessage = @getDecryptedMessage iv, key, raw

    signature = @getSignature decryptedMessage
    message = @getMessage decryptedMessage

    if @verify signature, message
      return [message, signature.toString()[0]]

    throw new InvalidMessageException "Invalid message signature"

  getIv: (raw) ->
    raw.slice 0, 16

  getKey: (raw) ->
    try
      recipientKeyKytes = @recipientKey.keyPair.cache.keyBitLength / 8
      encryptedKey = raw.slice 16, 16 + recipientKeyKytes
      @recipientKey.decrypt(encryptedKey)
    catch
      throw new DecryptionError "Incorrect message length."

  getDecryptedMessage: (iv, key, raw) ->
    recipientKeyKytes = @recipientKey.keyPair.cache.keyBitLength / 8
    encryptedMessage = raw.slice 16 + recipientKeyKytes, raw.length
    decipher = crypto.createDecipheriv "aes-256-cbc", key, iv
    decipher.setAutoPadding true
    decipher.update encryptedMessage

  getSignature: (decryptedMessage) ->
    senderKeyBytes = @senderKey.keyPair.cache.keyBitLength / 8
    decryptedMessage.slice 0, senderKeyBytes

  getMessage: (decryptedMessage) ->
    senderKeyBytes = @senderKey.keyPair.cache.keyBitLength / 8
    decryptedMessage.slice senderKeyBytes, decryptedMessage.length

  verify: (signature, message) ->
    hash = crypto.createHash("sha512").update(message).digest()
    @senderKey.verify hash, signature

class InvalidMessageException extends Error

class DecryptionError extends Error

class EncryptionError extends Error

module.exports =
  Encryption: Encryption
  Decryption: Decryption
  InvalidMessageException: InvalidMessageException
  DecryptionError: DecryptionError
  EncryptionError: EncryptionError
