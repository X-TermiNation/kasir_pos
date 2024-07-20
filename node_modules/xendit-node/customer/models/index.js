"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
/* tslint:disable */
/* eslint-disable */
__exportStar(require("./AccountBank"), exports);
__exportStar(require("./AccountCard"), exports);
__exportStar(require("./AccountEwallet"), exports);
__exportStar(require("./AccountOTC"), exports);
__exportStar(require("./AccountPayLater"), exports);
__exportStar(require("./AccountQRCode"), exports);
__exportStar(require("./Address"), exports);
__exportStar(require("./AddressRequest"), exports);
__exportStar(require("./AddressStatus"), exports);
__exportStar(require("./BusinessDetail"), exports);
__exportStar(require("./CreateCustomer400Response"), exports);
__exportStar(require("./CreateCustomer400ResponseAllOf"), exports);
__exportStar(require("./Customer"), exports);
__exportStar(require("./CustomerRequest"), exports);
__exportStar(require("./EmploymentDetail"), exports);
__exportStar(require("./EndCustomerStatus"), exports);
__exportStar(require("./GetCustomerByReferenceID200Response"), exports);
__exportStar(require("./GetCustomerByReferenceID400Response"), exports);
__exportStar(require("./GetCustomerByReferenceID400ResponseAllOf"), exports);
__exportStar(require("./IdentityAccountRequest"), exports);
__exportStar(require("./IdentityAccountRequestProperties"), exports);
__exportStar(require("./IdentityAccountResponse"), exports);
__exportStar(require("./IdentityAccountResponseProperties"), exports);
__exportStar(require("./IdentityAccountType"), exports);
__exportStar(require("./IndividualDetail"), exports);
__exportStar(require("./KYCDocumentRequest"), exports);
__exportStar(require("./KYCDocumentResponse"), exports);
__exportStar(require("./KYCDocumentSubType"), exports);
__exportStar(require("./KYCDocumentType"), exports);
__exportStar(require("./ModelError"), exports);
__exportStar(require("./PatchCustomer"), exports);
__exportStar(require("./ResponseDataNotFound"), exports);
__exportStar(require("./UpdateCustomer400Response"), exports);
__exportStar(require("./UpdateCustomer400ResponseAllOf"), exports);
