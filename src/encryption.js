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
    if (typeof message !== 'string') throw new Error('Message must be string type.');
    const raw = message.toString();
    const iv = this.getIv(raw);
    const key = this.getKey(raw);
    const decryptedMessage = this.getDecryptedMessage(iv, key, raw);
    const signature = this.getSignature(decryptedMessage);
    message = this.getMessage(decryptedMessage);

    if (this.verify(signature, message)) return {message: message, signature: new Buffer(signature).toString('hex')};

    throw new Error('Invalid message signature');
  }

  getIv(raw) {
    return raw.substr(0, 16);
  }

  getKey(raw) {
    try {
      const recipientKeyBytes = this.recipientKey.getModulus().length;
      const encryptedKey = raw.substring(16, 16 + recipientKeyBytes);
      return this.recipientKey.publicDecrypt(encryptedKey, 'base64', 'base64');
    } catch (err) {
      throw new Error('Incorrect message length.');
    }
  }

  getDecryptedMessage(iv, key, raw) {
    const recipientKeyBytes = this.recipientKey.getModulus().length;
    const encryptedMessage = raw.substr(16 + recipientKeyBytes);
    const unpad = (s) => s.substr(0, s.length - s.substr(s.length - 1).charCodeAt(0));
    const encryptdata = new Buffer(encryptedMessage, 'base64').toString('binary');
    const cipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decoded = cipher.update(encryptdata);
    decoded += cipher.final();
    return unpad(decoded);
  }

  getSignature(decryptedMessage) {
    const senderKeyBytes = this.recipientKey.getModulus().length;
    return decryptedMessage.substr(0, senderKeyBytes);
  }

  getMessage(decryptedMessage) {
    const senderKeyBytes = this.recipientKey.getModulus().length;
    return decryptedMessage.substr(senderKeyBytes);
  }

  verify(signature, message) {
    message = new Buffer(message).toString('base64');
    return this.senderKey.hashAndVerify('sha256', message, signature, 'base64');
  }
}

module.exports = {
  Encryption: Encryption,
  Decryption: Decryption
};
