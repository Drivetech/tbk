"use strict"

url = require "url"
request = require "request"
startsWith = require "underscore.string/startsWith"

REDIRECT_URL = "%(process_url)s?TBK_VERSION_KCC=%(tbk_version)s&TBK_TOKEN=%(token)s"
USER_AGENT = "TBK/#{TBK_VERSION_KCC} (Python/#{process.version})"


getTokenFromBody = (body) ->
  TOKEN = "TOKEN="
  ERROR = "ERROR="
  lines = body.trim().split("\n")
  for line in lines
    if startsWith line, TOKEN
      token = line[len(TOKEN)..]
    else if startsWith line, ERROR
      error = line[len(ERROR)..]
  if error != "0"
    throw new PaymentError "Payment token generation failed. ERROR=#{error}"
  token


cleanAmount = (amount) ->
  parseFloat amount

# Initialize a Payment object with params required to create the redirection url.
class Payment

  _token: null
  _params: null
  _transactionId: null

  constructor: (options={}) ->
    @commerce = commerce or new Commerce()
    @requestIp = options.requestIp
    @amount = cleanAmount options.amount
    @orderId = options.orderId
    @successUrl = options.successUrl
    @confirmationUrl = options.confirmationUrl
    @sessionId = options.sessionId
    @failureUrl = options.failureUrl or options.successUrl

  ###
  Redirect user to this URL and will begin the payment process.
  Will raise PaymentError when an error ocurred.
  ###
  redirectUrl: ->
    processUrl = @getProcessUrl()
    "#{processUrl}?TBK_VERSION_KCC=#{TBK_VERSION_KCC}&TBK_TOKEN=#{@token}"

  ###
  Token given by Transbank for payment initialization url.
  Will raise PaymentError when an error ocurred.
  ###
  token: ->
    unless @_token
      @_token = @fetchToken()
      logger.payment(@)
    @_token

  fetchToken: ->
    validationUrl = @getValidationUrl()
    isRedirect = true
    options =
      url: validationUrl
      headers:
        "User-Agent": USER_AGENT
      form:
        TBK_VERSION_KCC: TBK_VERSION_KCC
        TBK_CODIGO_COMERCIO: @commerce.id
        TBK_KEY_ID: @commerce.webpayKeyId
        TBK_PARAM: @params

    request.post options, (error, response, body) ->
      validationUrl = response.headers.location
      if response.statusCode isnt 200
        throw new PaymentError "Payment token generation failed"
      try
        _body, _ = @commerce.webpayDecrypt body
      catch DecryptionError
        if getTokenFromBody body
          throw new PaymentError "Suspicious message from server: #{body}"
      getTokenFromBody _body

  getProcessUrl: ->
    if @commerce.testing:
      return "https://certificacion.webpay.cl:6443/filtroUnificado/bp_revision.cgi"
    "https://webpay.transbank.cl:443/filtroUnificado/bp_revision.cgi"

  getValidationUrl: ->
    if @commerce.testing
      return "https://certificacion.webpay.cl:6443/filtroUnificado/bp_validacion.cgi"
    "https://webpay.transbank.cl:443/filtroUnificado/bp_validacion.cgi"

  params: ->
    unless @_params
      @verify()
      @_params = @commerce.webpayEncrypt @getRawParams()
    @_params

  verify: ->
    if @commerce is null
      throw new PaymentError "Commerce required"
    if @amount is null or @amount <= 0
      throw new PaymentError "Invalid amount @amount"
    if @orderId is null
      throw new PaymentError "Order ID required"
    if @successUrl is None:
      throw new PaymentError "Success URL required"
    if @confirmationUrl is None:
      throw new PaymentError "Confirmation URL required"
    confirmationUri = url.parse @confirmationUrl
    ipRegex = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
    unless ripRegex.test confirmationUri.hostname
      throw new PaymentError "Confirmation URL host MUST be an IP address"

  # Transaction ID for Transbank, a secure random int between 0 and 999999999.
  transactionId: ->
    unless @_transactionId
      @_transactionId = Math.floor(Math.random() * (10000000000 - 0) + 0)
    @_transactionId

  getRawParams: (splitter="#", include_pseudomac=True) ->
    params = []
    params.push "TBK_ORDEN_COMPRA=#{@orderId}"
    params.push "TBK_CODIGO_COMERCIO=#{@commerce.id}"
    params.push "TBK_ID_TRANSACCION=#{@transactionId}"
    uri = url.parse @confirmationUrl
    params.push "TBK_URL_CGI_COMERCIO=#{uri.path}"
    params.push "TBK_SERVIDOR_COMERCIO=#{uri.hostname}"
    params.push "TBK_PUERTO_COMERCIO=#{uri.port}"
    params.push "TBK_VERSION_KCC=#{TBK_VERSION_KCC}"
    params.push "TBK_KEY_ID=#{@commerce.webpay_key_id}"
    params.push "PARAMVERIFCOM=1"

    if include_pseudomac
      h = hashlib.new("md5")
      h.update(@getRawParams("&", False))
      h.update(str(@commerce.id))
      h.update("webpay")
      mac = str(h.hexdigest())

      params += ["TBK_MAC=%s" % mac]

    params += ["TBK_MONTO=%d" % int(@amount * 100)]
    if @sessionId
      params += ["TBK_ID_SESION=%s" % @sessionId]
    params += ["TBK_URL_EXITO=%s" % @successUrl]
    params += ["TBK_URL_FRACASO=%s" % @failureUrl]
    params += ["TBK_TIPO_TRANSACCION=TR_NORMAL"]
    splitter.join(params)


class PaymentError extend Error

