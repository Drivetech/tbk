'use strict';

const math = require('mathjs');
const pkg = require('../package.json');
const request = require('request');
const whilst = require('async/whilst');
const Commerce = require('./commerce').Commerce;
const logger = require('./logging').logger;

const getTokenFromBody = (body) => {
  const tokenRegex = /^TOKEN=([0-9A-Fa-f]+)/;
  const errorRegex = /^ERROR=([\d\w]+)/;
  let token, error;
  for (let line of body.trim().split('\n')) {
    if (tokenRegex.test(line)) {
      token = tokenRegex.exec(line)[1];
    } else if (errorRegex.test(line)) {
      error = errorRegex.exec(line)[0];
    }
  }
  if (error !== '0') throw new Error(`Payment token generation failed. ERROR=${error}`);
  return token;
};

const cleanAmount = (amount) => {
  math.round(parseFloat(amount), 2);
};

class Payment {

  constructor(requestIp, amount, orderId, successUrl, confirmationUrl, sessionId=null, failureUrl=null, commerce=null) {
    this._token = null;
    this._params = null;
    this._transaction_id = null;
    this.commerce = commerce || Commerce.create_commerce();
    this.requestIp = requestIp;
    this.amount = cleanAmount(amount);
    this.orderId = orderId;
    this.successUrl = successUrl;
    this.confirmationUrl = confirmationUrl;
    this.sessionId = sessionId;
    this.failureUrl = failureUrl || successUrl;
  }

  // @property
  redirectUrl() {
    return `${this.get_process_url()}?TBK_VERSION_KCC=${pkg.tbkVersionKcc}&TBK_TOKEN=${this.token}`;
  }

  // @property
  token() {
    if (!this._token) {
      this._token = this.fetchToken();
      logger.payment();
    }
    return this._token;
  }

  fetchToken(cb) {
    let validationUrl = this.getValidationUrl();
    let isRedirect = true;
    const requestOptions = {
      url: validationUrl,
      form: {
        TBK_VERSION_KCC: pkg.tbkVersionKcc,
        TBK_CODIGO_COMERCIO: this.commerce.id,
        TBK_KEY_ID: this.commerce.webpayKeyId,
        TBK_PARAM: this.params
      },
      headers: {
        'User-Agent': `TBK/${pkg.tbkVersionKcc} (NodeTbk/${pkg.version})`
      },
      followRedirect: false,
      encoding: null
    };
    whilst(
      () => isRedirect,
      (callback) => {
        request.post(requestOptions, (err, response, body) => {
          if (err) return callback(err);
          isRedirect = response.statusCode >= 300 && response.statusCode < 400;
          validationUrl = response.headers.location;
          callback(null, response.statusCode, body);
        });
      },
      (err, statusCode, body) => {
        if (err) return cb(err);
        if (statusCode !== 200) return cb(new Error('Payment token generation failed'));
        let _body;
        try {
          const dataDecrypted = this.commerce.webpayDecrypt(body);
          _body = dataDecrypted.body;
        } catch (err) {
          if (getTokenFromBody(body)) cb(new Error(`Suspicious message from server: ${body.toString()}`));
        }
        cb(null, getTokenFromBody(_body));
      }
    );
  }
}

module.exports = {
  getTokenFromBody: getTokenFromBody,
  cleanAmount: cleanAmount,
  Payment: Payment
};
