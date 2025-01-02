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
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const cheerio = __importStar(require("cheerio"));
const fs_1 = require("fs");
const baseFileName = process.argv[2];
const inputFileName = `${baseFileName}.html`;
const outputFileName = `${baseFileName}_x.json`;
const html = (0, fs_1.readFileSync)(inputFileName, 'utf8');
const $ = cheerio.load(html);
const lawTitle = $('h1').first().text().trim();
const sections = [];
$('section').each((_, section) => {
    const h2 = $(section).find('h2').first();
    if (!h2.length)
        return;
    const sectionTitle = h2.text().trim();
    const chapters = [];
    $(section).find('h3').each((_, h3) => {
        const chapterTitle = $(h3).text().trim();
        const chapterTextNodes = $(h3).nextUntil('h3, h2', 'p, article:not(.legalArticle)');
        const chapterText = chapterTextNodes.map((i, el) => $(el).text().trim()).get().join(' ');
        const paragraphs = [];
        $(h3).nextUntil('h3, h2', 'article.legalArticle').each((_, article) => {
            const paragraphTitle = $(article).find('h4').first().text().trim();
            const paragraphText = $(article).children().not('h4').map((i, el) => $(el).text().trim()).get().join(' ');
            paragraphs.push({
                title: paragraphTitle,
                text: paragraphText
            });
        });
        chapters.push({
            title: chapterTitle,
            text: chapterText,
            paragraphs
        });
    });
    sections.push({
        title: sectionTitle,
        chapters
    });
});
const document = { title: lawTitle, sections };
const jsonChunks = [];
const baseJson = { add: { doc: {} }, commit: {} };
sections.forEach((section, idx) => {
    baseJson.add.doc = section;
    const jsonOutput = JSON.stringify(baseJson);
    if (jsonOutput.length > 32000) {
        // Split into smaller parts or handle differently
        // Example: Split by chapters if still too large
    }
    else {
        jsonChunks.push(jsonOutput);
    }
});
// Write each chunk to file
jsonChunks.forEach((chunk, idx) => {
    (0, fs_1.writeFileSync)(`${outputFileName}-${idx + 1}.json`, chunk, 'utf8');
});
console.log(`Documents parsed and saved as multiple parts of ${outputFileName}.`);
