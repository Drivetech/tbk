"use strict"

fs = require "fs"
env = require "node-env-file"
env "#{__dirname}/../.env" if fs.existsSync "#{__dirname}/../.env"

module.exports = class Config

  constructor: (commerce_id, commerce_key, environment) ->
    @commerce_id = commerce_id or process.env.TBK_COMMERCE_ID
    @commerce_key = commerce_key or process.env.TBK_COMMERCE_KEY
    @environment = environment or process.env.TBK_COMMERCE_ENVIRONMENT or
      "production"
