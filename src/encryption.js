'use strict';

import crypto from 'crypto';

class Encryption {

  constructor(senderKey, recipientKey) {
    this.senderKey = senderKey;
    this.recipientKey = recipientKey;
  }

  encrypt(message) {
    try {
      const signature = this.senderKey.hashAndSign('sha512', message, 'utf8', 'hex');
      const key = crypto.randomBytes(32);
      const encryptedKey = this.recipientKey.encrypt(key, 'hex', 'hex');
      const iv = crypto.randomBytes(16);
      const raw = signature + new Buffer(message).toString('hex');
      const blockSize = 16;
      const pad = (s) => s.toString('hex') + new Buffer(Array((blockSize - s.length % blockSize) + 1).join(String.fromCharCode(blockSize - s.length % blockSize))).toString('hex');
      const messageToEncrypt = pad(new Buffer(raw, 'hex'));
      const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
      let encryptdata  = cipher.update(messageToEncrypt, 'hex', 'hex');
      encryptdata += cipher.final('hex');
      return new Buffer(iv.toString('hex') + encryptedKey + encryptdata, 'hex').toString('base64');
    } catch (err) {
      throw new Error('Encryption failed');
    }
  }
}

class Decryption {

  constructor(recipientKey, senderKey) {
    this.senderKey = senderKey;
    this.recipientKey = recipientKey;
  }

  decrypt(message) {
    try {
      const raw = new Buffer(message, 'base64').toString('binary');
      const iv = new Buffer(raw.substr(0, 16), 'binary');
      const key = this.getKey(raw);
      const decryptedData = this.getDecryptedMessage(iv, key, raw);
      const signature = this.getSignature(decryptedData);
      const decryptedMessage = this.getMessage(decryptedData);

      if (this.verify(signature, decryptedMessage)) {
        return {
          message: decryptedMessage.toString(),
          signature: signature.toString('hex')
        };
      }
      throw new Error('Invalid message signature');
    } catch (err) {
      throw new Error('Decryption failed');
    }
  }

  getKey(raw) {
    try {
      const senderKeyBytes = this.senderKey.getModulus().length;
      const encryptedKey = new Buffer(raw.substring(16, 16 + senderKeyBytes), 'binary');
      return this.recipientKey.decrypt(encryptedKey, 'binary', 'binary');
    } catch (err) {
      throw new Error('Incorrect message length.');
    }
  }

  getDecryptedMessage(iv, key, raw) {
    const recipientKeyBytes = this.senderKey.getModulus().length;
    const encryptdata = new Buffer(raw.substr(16 + recipientKeyBytes), 'binary');
    const unpad = (s) => s.substr(0, s.length - s.substr(s.length - 1).charCodeAt(0));
    const cipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decoded = cipher.update(encryptdata, 'binary', 'binary');
    decoded += cipher.final('binary');
    return unpad(decoded);
  }

  getSignature(decryptedData) {
    const senderKeyBytes = this.senderKey.getModulus().length;
    return new Buffer(decryptedData.substr(0, senderKeyBytes), 'binary');
  }

  getMessage(decryptedData) {
    const senderKeyBytes = this.senderKey.getModulus().length;
    return new Buffer(decryptedData.substr(senderKeyBytes), 'binary');
  }

  verify(signature, message) {
    return this.senderKey.hashAndVerify('sha512', message, signature, 'base64');
  }
}

module.exports = {
  Encryption: Encryption,
  Decryption: Decryption
};
