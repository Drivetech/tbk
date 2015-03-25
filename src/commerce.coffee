"use strict"

url = require "url"
NodeRSA = require "node-rsa"
encryption = require "./encryption"

TEST_COMMERCE_KEY = """
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAn3HzPC1ZBzCO3edUCf/XJiwj3bzJpjjTi/zBO9O+DDzZCaMp
14aspxQryvJhv8644E19Q+NHfxtz1cxd2wnSYKvay1gJx30ZlTOAkzUj4QMimR16
vomLlQ3T2MAz1znt/PVPVU7T/JOG9R+EbiHNVKa/hUjwJEFVXLQNME97nHoLjb3v
V5yV2aVhmox7b54n6F3UVPHvCsHKbJpXpE+vnLpVmdETbNpFVrDygXyG+mnEvyiO
BLIwEY3XTMrgXvS069groLi5Gg8C5LDaYOWjE9084T4fiWGrHhn2781R1rykunTu
77wiWPuQHMS0+YC7mhnsk8Z/ilD+aWz/vhsgHwIDAQABAoIBAQCM+Nrt4cpNKQmn
+Ne8348CGRS9ACXp6WRg6OCQXO4zM7lRZAminVgZgSQXE6aJR+T9rIWMeG7GWydX
aJGzEEQJZOjV0MkUr+7mk9qiTOGkGHmGlyHnRQU8jDU59vXe3UEl3l5+NmwHbQht
waf9F7XLmoLK/WoVJA6tICRpCl1oQrpziqN+gjdmMpz9i8I1sMFE7+Y7xf+7S2u7
c1MRPUWqgdS9yViQVh3vZi25m5CyKRVnOB0hpNuZ7nrJymtADYSWt9wV2W1fX+MX
UUoYfxyQQvWryHhGdedU7GGAnoEdblUcDkBuAaFmsm1P8K4HQZLWP4v6pYlW2JLa
Zoaerb3BAoGBANCRevl0CLB0HBU7sCs0eN9fTkIEsh3OVIxPSBqDnKsynJrIWovK
cs37Vb6phzdQO3ADoFJvR9ck8+v6Cv0KR8IOFl9wfC4ZoxkKBBeq94ZLN+YhE2PW
KiRFybqcgCtzxKS3MyWgpIcT9xFtHVjlorZ8Jk51fgLZbGzamtLhderVAoGBAMO0
mIiiV4l2vXzu4tFfkpu/GOx/D9/vAic3X9FOky09BNCyuMXMQgI8e3wWsGEZghls
Vg9KDV5EPxAmpumcdPFK2IMACaH41ac7vys3ZD8kMK0INQkuDAcG4YsxMaTwEPo0
p1i3zwwEWwknw1yJkOyozz0EcIzS9NrZZEjnBHEjAoGAQ81XdeqzvHEyg/CQd6sq
NCtubGXMZYYi1C4d2Yi5kKn2YRcK4HDi23V+TWodK+0oNWToZIQKjbVUmn0Bv3rt
EvezbDlMFUx+SfCIng0VRJIFTQmpnQYNUxdg2gpwXC/ZWFa6CNxtQABMjFy1cqXM
PJild1IYseJurgBu3mkvBTUCgYBqA/T1X2woLUis2wPIBAv5juXDh3lkB6eU8uxX
CEe2I+3t2EM781B2wajrKadWkmjluMhN9AGV5UZ8S1P0DStUYwUywdx1/8RNmZIP
qSwHAGXV9jI0zNr7G4Em0/leriWkRM26w6fHjLx8EyxDfsohSbkqBrOptcWqoEUx
MOQ5HQKBgAS4sbddOas2MapuhKU2surEb3Kz3RCIpta4bXgTQMt9wawcZSSpvnfT
zs5sehYvBFszL3MV98Uc50HXMf7gykRCmPRmB9S+f+kiVRvQDHfc9nRNg2XgcotU
KAE16PQM8GihQ0C+EcXHouyud5CRJGfyurokRlH/jY3BiRAG5c+6
-----END RSA PRIVATE KEY-----
""".trim()

TEST_WEBPAY_KEY = """
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtKe3HHWwRcizAfkbS92V
fQr8cUb94TRjQPzNTqBduvvj65AD5J98Cn1htE3NzOz+PjPRcnfVe53V4f3+YlIb
6nnxyeuYLByiwoPkCmpOFBxNp04/Yh3dxN4xgOANXA37rNbDeO4WIEMG6zbdQMNJ
7RqQUlJSmui8gt3YxtqWBhBVW79qDCYVzxFrv3SH7pRuYEr+cxDvzRylxnJgr6ee
N7gmjoSMqF16f9aGdQ12obzV0A35BqpN6pRFoS/NvICbEeedS9g5gyUHf54a+juB
OV2HH5VJsCCgcb7I7Sio/xXTyP+QjIGJfpukkE8F+ohwRiChZ9jMXofPtuZYZiFQ
/gX08s5Qdpaph65UINP7crYbzpVJdrT2J0etyMcZbEanEkoX8YakLEBpPhyyR7mC
73fWd9sTuBEkG6kzCuG2JAyo6V8eyISnlKDEVd+/6G/Zpb5cUdBCERTYz5gvNoZN
zkuq4isiXh5MOLGs91H8ermuhdQe/lqvXf8Op/EYrAuxcdrZK0orI4LbPdUrC0Jc
Fl02qgXRrSpXo72anOlFc9P0blD4CMevW2+1wvIPA0DaJPsTnwBWOUqcfa7GAFH5
KGs3zCiZ5YTLDlnaps8koSssTVRi7LVT8HhiC5mjBklxmZjBv6ckgQeFWgp18kuU
ve5Elj5HSV7x2PCz8RKB4XcCAwEAAQ==
-----END PUBLIC KEY-----
""".trim()

WEBPAY_KEY = """
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxKKjroxE7X44TQovh9A9
ZpntP7LrdoyFsnJbDKjOOCoiid92FydN5qemyQCeXhsc7QHUXwGdth22fB8xJr3a
MZBEUJ+BKFrL+W6yE5V+F5Bj0Uq3lL0QMAIftGhLpgqw0ZMtU89kyd9Q4Rclq4r8
p2m/ZD7Pn5EmTOFSeyoWTMZQDl7OEoCKh/cZH5NJdWL08lCI+sGLOghRmFzkve4h
F9JCwKA7NYG7j3BWh39Oj2NIXEY/TO1Y3Y2WfNv9nvTpr46SpFlyp0KOhSiqgvXX
DgeXlebyqS82ch2DzOV9fjDAw7t71WXJBAev8Gd6HXwIXE/JP6AnLCa2Y+b6Wv8K
GWBCMIBXWL0m7WHeCaJ9Hx2yXZmHJh8FgeKffFKCwn3X90JiMocOSGsOE+Sfo85S
h/39Vc7vZS3i7kJDDoz9ab9/vFy30RuJf4p8Erh7kWtERVoG6/EhR+j4N3mgIOBZ
SHfzDAoOnqP5l7t2RXYcEbRLVN6o+XgUtalX33EJxJRsXoz9a6PxYlesIwPbKteD
BZ/xyJDwTc2gU2YzSH8G9anKrcvITBDULSAuxQUkYOiLbkb7vSKWDYKe0do6ibO3
RY/KXI63Q7bGKYaI2aa/8GnqVJ2G1U2s59NpqX0aaWjn59gsA8trA0YKOZP4xJIh
CvLM94G4V7lxe2IHKPqLscMCAwEAAQ==
-----END PUBLIC KEY-----
""".trim()

TEST_COMMERCE_ID = "597026007976"

module.exports = class Commerce

  TEST_COMMERCE_KEY: TEST_COMMERCE_KEY
  TEST_COMMERCE_ID: "597026007976"
  webpayKeyId: 101

  constructor: (options={}) ->
    @testing = options.testing or false
    @id = @getId options.id or process.env.TBK_COMMERCE_ID
    @key = @getKey options.key or process.env.TBK_COMMERCE_KEY

  getId: (id) ->
    unless id
      return @TEST_COMMERCE_ID if @testing
      throw new Error "Commerce needs an id"
    id

  getKey: (key) ->
    unless key
      return @TEST_COMMERCE_KEY if @testing
      throw new Error "Commerce needs a key"
    key

  getCommerceKey: ->
    new NodeRSA @key

  getWebpayKey: ->
    new NodeRSA if @testing then TEST_WEBPAY_KEY else WEBPAY_KEY

  webpayEncrypt: (decrypted) ->
    commerceKey = @getCommerceKey()
    webpayKey = @getWebpayKey()
    encrypt = encryption.Encryption commerceKey, webpayKey
    encrypt.encrypt decrypted

  webpayDecrypt: (encrypted) ->
    commerceKey = @getCommerceKey()
    webpayKey = @getWebpayKey()
    decryption = encryption.Decryption commerceKey, webpayKey
    decryption.decrypt encrypted

  getPublicKey: ->
    # Returns Commerce public key from PEM private key.
    @getCommerceKey().exportKey "public"

  getConfigTbk: (confirmationUrl) ->
    # Returns a string with the TBK_CONFIG.dat
    confirmationUri = url.parse confirmationUrl
    if @testing
      webpayServer = "https://certificacion.webpay.cl"
    else
      webpayServer = "https://webpay.transbank.cl"
    webpayPort = if @testing then 6443 else 443
    whitelistcom = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz " +
      "0123456789./:=&?_"
    config = """
      IDCOMERCIO = #{@id}
      MEDCOM = 1
      TBK_KEY_ID = 101
      PARAMVERIFCOM = 1\n"
      URLCGICOM = #{confirmationUri.path}
      SERVERCOM = #{confirmationUri.hostname}
      PORTCOM = #{confirmationUri.port}
      WHITELISTCOM = #{whitelistcom}
      HOST = #{confirmationUri.hostname}
      WPORT = #{confirmationUri.port}
      URLCGITRA = /filtroUnificado/bp_revision.cgi
      URLCGIMEDTRA = /filtroUnificado/bp_validacion.cgi
      SERVERTRA = #{webpayServer}
      PORTTRA = #{webpayPort}
      PREFIJO_CONF_TR = HTML_
      HTML_TR_NORMAL = http://127.0.0.1/notify
      """
    config

  acknowledge: ->
    # The **ACK** string encrypted for succes response on confirmation to
    # Transbank.
    @webpayEncrypt "ACK"

  reject: ->
    # The **ERR** string encrypted for reject response on confirmation to
    # Transbank.
    @webpayEncrypt "ERR"
