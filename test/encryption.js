'use strict';

import fs from 'fs';
import path from 'path';
import ursa from 'ursa';
import crypto from 'crypto';
import {expect} from 'chai';
import {Encryption, Decryption} from '../lib/encryption';

describe('encryption', () => {
  let commercePrivate, commercePublic, webpayPrivate, webpayPublic;

  before(() => {
    commercePrivate = ursa.createPrivateKey(fs.readFileSync(path.join(__dirname, 'keys', 'commerce.pem')));
    commercePublic = ursa.createPublicKey(fs.readFileSync(path.join(__dirname, 'keys', 'commerce_public.pem')));
    webpayPrivate = ursa.createPrivateKey(fs.readFileSync(path.join(__dirname, 'keys', 'webpay.pem')));
    webpayPublic = ursa.createPublicKey(fs.readFileSync(path.join(__dirname, 'keys', 'webpay_public.pem')));
  });

  it('expect decrypted message equal to message', () => {
    const message = crypto.randomBytes(16).toString('utf8');
    const encryption = new Encryption(commercePrivate, webpayPublic);
    const decryption = new Decryption(webpayPrivate, commercePublic);
    let encryptedMessage = encryption.encrypt(message);
    const decryptedMessage = decryption.decrypt(encryptedMessage);
    expect(decryptedMessage.message).to.eql(message);
  });
});
