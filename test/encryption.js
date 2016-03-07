'use strict';

import fs from 'fs';
import path from 'path';
import ursa from 'ursa';
import crypto from 'crypto';
import {expect} from 'chai';
import {Encryption} from '../lib/encryption';

describe('encryption', () => {
  it('expect encypted message', () => {
    const message = 'Hola mundo';
    const senderKey = ursa.createPrivateKey(fs.readFileSync(path.join(__dirname, '..', 'keys', 'commerce_test.pem')));
    const recipientKey = ursa.createPublicKey(fs.readFileSync(path.join(__dirname, '..', 'keys', 'webpay_test_public.pem')));
    const encryption = new Encryption(senderKey, recipientKey);
    const senderKeyBytes = senderKey.getModulus().length;
    const encryptMessage = crypto.randomBytes(message.length).toString('base64');
    const encryptKey = crypto.randomBytes(senderKeyBytes).toString('base64');
    const getIv = crypto.randomBytes(16).toString('base64');
    let encryptedMessage = encryption.encrypt(message);
    const iv = encryptedMessage.substr(0, 16);
    const encryptedKey = encryptedMessage.substr(16, (16 + senderKeyBytes));
    encryptedMessage = encryptedMessage.substr(16 + senderKeyBytes);
    expect(encryptMessage).to.eql(encryptedMessage);
    expect(encryptKey).to.eql(encryptedKey);
    expect(getIv).to.eql(iv);
  });
});
