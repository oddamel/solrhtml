import * as cheerio from 'cheerio';
import { readFileSync, writeFileSync } from 'fs';

interface Paragraph {
    title: string;
    text: string;
}

interface Chapter {
    title: string;
    text: string;
    paragraphs: Paragraph[];
}

interface Section {
    title: string;
    chapters: Chapter[];
}

interface LawDocument {
    title: string;
    sections: Section[];
}

const baseFileName = process.argv[2];
const inputFileName = `${baseFileName}.html`;
const outputFileName = `${baseFileName}_x.json`;

const html = readFileSync(inputFileName, 'utf8');
const $ = cheerio.load(html);

const lawTitle = $('h1').first().text().trim();
const sections: Section[] = [];

$('section').each((_, section) => {
    const h2 = $(section).find('h2').first();
    if (!h2.length) return;

    const sectionTitle = h2.text().trim();
    const chapters: Chapter[] = [];

    $(section).find('h3').each((_, h3) => {
        const chapterTitle = $(h3).text().trim();
        const chapterTextNodes = $(h3).nextUntil('h3, h2', 'p, article:not(.legalArticle)');
        const chapterText = chapterTextNodes.map((i, el) => $(el).text().trim()).get().join(' ');

        const paragraphs: Paragraph[] = [];

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

const document: LawDocument = { title: lawTitle, sections };

const jsonChunks: string[] = [];
const baseJson = { add: { doc: {} }, commit: {} };

sections.forEach((section, idx) => {
    baseJson.add.doc = section;
    const jsonOutput = JSON.stringify(baseJson);

    if (jsonOutput.length > 32000) {
        // Split into smaller parts or handle differently
        // Example: Split by chapters if still too large
    } else {
        jsonChunks.push(jsonOutput);
    }
});

// Write each chunk to file
jsonChunks.forEach((chunk, idx) => {
    writeFileSync(`${outputFileName}-${idx + 1}.json`, chunk, 'utf8');
});

console.log(`Documents parsed and saved as multiple parts of ${outputFileName}.`);
