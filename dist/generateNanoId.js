"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
// generateNanoId.ts
const promises_1 = require("fs/promises");
const nanoid_1 = require("nanoid");
const nanoid = (0, nanoid_1.customAlphabet)('1234567890abcdef', 10);
const dbFilePath = './fileid.db.json';
function readDbFile() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const data = yield (0, promises_1.readFile)(dbFilePath, { encoding: 'utf8' });
            return JSON.parse(data);
        }
        catch (error) {
            console.error('Error reading the DB file:', error);
            return {};
        }
    });
}
function writeDbFile(data) {
    return __awaiter(this, void 0, void 0, function* () {
        yield (0, promises_1.writeFile)(dbFilePath, JSON.stringify(data, null, 2), { encoding: 'utf8' });
    });
}
function getId(filename) {
    return __awaiter(this, void 0, void 0, function* () {
        const fileMapping = yield readDbFile();
        if (fileMapping[filename]) {
            return fileMapping[filename];
        }
        const newNanoId = nanoid();
        fileMapping[filename] = newNanoId;
        yield writeDbFile(fileMapping);
        return newNanoId;
    });
}
exports.default = getId;
