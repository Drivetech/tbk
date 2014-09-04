"use strict"

Errors = require "./errors"
Config = require "./config"
Encryption = require "./encryption"
parseKey = require("./keys")
NodeRSA = require "node-rsa"

module.exports = class Commerce

  constructor: (@id, key, @testing=false) ->
    @KEY_ID = 101
    @KEY = parseKey("webpay.101")
    @TEST_KEY = parseKey("webpay_test.101")
    @IV_PADDING = "\x10\xBB\xFF\xBF\x00\x00\x00\x00\x00\x00\x00\x00\xF4\xBF"
    throw new Errors.CommerceError "Missing commerce id" unless @id
    @key = if key then new NodeRSA(key) else parseKey("test_commerce")
    @webpayKey = if @testing then @TEST_KEY else @KEY
    throw new Errors.CommerceError "Missing commerce key" unless @key
    unless @key.isPrivate()
      throw new Errors.CommerceError "Commerce key must be a RSA private key"
    @encryption = new Encryption @key, @webpayKey

  webpayEncrypt: (text) =>
    @encryption.encrypt text

  webpayDecrypt: (encripted_text) =>
    @encryption.decrypt encripted_text
