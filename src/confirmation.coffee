"use strict"

CONFIRMATION_TIMEOUT = 25

# A convenient class to handle Webpay Transaction Payload.
module.exports = class ConfirmationPayload

  RESPONSE_CODES =
    "0": "Transacción aprobada."
    "-1": "Rechazo de tx. en B24, No autorizada"
    "-2": "Transacción debe reintentarse."
    "-3": "Error en tx."
    "-4": "Rechazo de tx. En B24, No autorizada"
    "-5": "Rechazo por error de tasa."
    "-6": "Excede cupo máximo mensual."
    "-7": "Excede límite diario por transacción."
    "-8": "Rubro no autorizado."
  SUCCESS_RESPONSE_CODE = 0
  PAYMENT_TYPES =
    "VN": "Venta Normal"
    "VC": "Venta Cuotas"
    "SI": "Tres Cuotas Sin Interés"
    "S2": "Dos Cuotas Sin Interés"
    "CI": "Cuotas Comercio"
    "VD": "Redcompra"

  constructor: (@data) ->

  # Localized at America/Santiago datetime of TBK_FECHA_TRANSACCION
  paidAt: ->
    date = @data.TBK_FECHA_TRANSACCION
    time = @data.TBK_HORA_TRANSACCION
    year = moment.tz("America/Santiago").format "YYYY"
    moment.tz("#{year}#{date} #{time}", "YYYYMMDD HHmmss", "UTC")

  # Message corresponding to response code TBK_RESPUESTA
  message: ->
    @RESPONSE_CODES[@response]

  # Amount sent in TBK_MONTO as a Float
  amount: ->
    parseInt(@data.TBK_MONTO, 10) / 100.0

  # Transaction ID as int
  transactionId: ->
    parseInt @data.TBK_ID_TRANSACCION, 10

  # Order ID from TBK_ORDEN_COMPRA as string
  orderId: ->
    @data.TBK_ORDEN_COMPRA

  # Response code as string TBK_RESPUESTA
  response: ->
    @data.TBK_RESPUESTA

  # Last 4 digits of the card used by customer
  creditCardLastDigits: ->
    @data.TBK_FINAL_NUMERO_TARJETA

  # 12 digits credit card string, only showing last digits
  creditCardNumber: ->
    "XXXX-XXXX-XXXX-#{@creditCardLastDigits}"

  # Transaction authorization code.
  authorizationCode: ->
    @data.TBK_CODIGO_AUTORIZACION

  # Accountable date of transaction, localized as America/Santiago
  accountableDate: ->
    date = @data.TBK_FECHA_CONTABLE
    year = parseInt moment.tz("America/Santiago").format("YYYY"), 10
    if @paidAt().month() is 11 and parseInt(date.slice(0, 2), 10) is 1
      year += 1
    moment.tz("#{year}#{date} #{time}", "YYYYMMDD HHmmss", "UTC")

  # Session id, if "null" then null
  sessionId: ->
    sessionId = @data.TBK_ID_SESION
    return if sessionId is "null" then null else sessionId

  # Quantity of installments
  installments: ->
    parseInt @data.TBK_NUMERO_CUOTAS, 10

  # Payment Type according to TBK_TIPO_PAGO
  paymentType: ->
    @PAYMENT_TYPES[@paymentTypeCode]

  # Payment type code according to TBK_TIPO_PAGO
  paymentTypeCode: ->
    @data.TBK_TIPO_PAGO


###
Create a confirmation instance which handle callback data from transbank.

Given that Webpay accept acknowledge response only in less than 30 seconds,
there is a timeout of 25 seconds (by default) for suceed the answer.
###
module.exports = class Confirmation

  constructor: (options={}) ->
    @initTime = moment.tz("America/Santiago")
    @timeout = options.timeout or CONFIRMATION_TIMEOUT
    @commerce = options.commerce
    @requestIp = options.requestIp
    @payload = new ConfirmationPayload @parse options.data.TBK_PARAM
    logger.confirmation(@)

  parse: (tbkParam) ->
    decryptedParams, signature = @commerce.webpayDecrypt(tbkParam)
    params = {}
    for line in decryptedParams.split("#")
      index = line.indexOf "="
      params[line.slice[0, index]] = line[index + 1]
    params.TBK_MAC = signature
    params

  ###
  Check if Webpay response TBK_RESPUESTA is equal to 0 and if the lapse between
  initialization and this call is less than @timeout when checkTimeout is true (default).
  ###
  isSuccess: (checkTimeout=True) ->
    return False if checkTimeout and @isTimeout()
    @payload.response is @payload.SUCCESS_RESPONSE_CODE

  # Check if the lapse between initialization and now is more than @timeout
  isTimeout: ->
    lapse = moment.tz("America/Santiago").diff @initTime
    lapse > @timeout

  # Amount sent by Webpay
  amount: ->
    @payload.amount

  # Order id sent by Webpay
  orderId: ->
    @payload.orderId

  # DEPRECATED
  acknowledge: ->
    console.log(
      "Deprecated for commerce.acknowledge. " +
      "Will not be longer available at v1.0.0.")
    @commerce.acknowledge

  reject: ->
    console.log(
      "Deprecated for commerce.reject. " +
      "Will not be longer available at v1.0.0.")
    @commerce.reject

  message: ->
    console.log(
      "Deprecated for payload.message. " +
      "Will not be longer available at v1.0.0.")
    @payload.message

  paidAt: ->
    console.log(
      "Deprecated for payload.paidAt. " +
      "Will not be longer available at v1.0.0.")
    @payload.paidAt

  transactionId: ->
    console.log(
      "Deprecated for payload.transactionId. " +
      "Will not be longer available at v1.0.0.")
    @payload.transactionId

  params: ->
    console.log(
      "Deprecated for payload.params. " +
      "Will not be longer available at v1.0.0.")
    @payload.data
