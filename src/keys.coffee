"use strict"

fs = require "fs"
path = require "path"
NodeRSA = require "node-rsa"
KEYS_DIR = path.normalize "#{__dirname}/../keys"

module.exports = (name) ->
  data = fs.readFileSync path.join KEYS_DIR, "#{name}.pem"
  new NodeRSA data.toString()
