import * as cheerio from 'cheerio';
import { readFileSync, writeFileSync } from 'fs';

interface Paragraph {
    id: string;
    paragraph_title: string;
    paragraph_text: string;
    _type: string;
}

interface Chapter {
    id: string;
    chapter_title: string;
    chapter_text: string;
    _childDocuments_: Paragraph[];
    _type: string;
}

interface Section {
    id: string;
    section_title: string;
    section_text: string;
    _childDocuments_: Chapter[];
    _type: string;
}

interface LawDocument {
    title: string;
    id: string;
    _childDocuments_?: Section[] | Chapter[] | Paragraph[];
    _type: string;
}

const baseFileName = process.argv[2];
const lawFormatType = process.argv[3];
const inputFileName = `${baseFileName}.html`;
const outputFileName = `${baseFileName}.json`;

const html = readFileSync(inputFileName, 'utf8');
const $ = cheerio.load(html);

const lawTitle = $('h1').first().text().trim();
const lawId = $('dd.dokid').text().trim(); // Fetching the law ID from the HTML

const document: LawDocument = {
    title: lawTitle,
    id: lawId,
    _type: "law"
};

if (lawFormatType === 's') {
    document._childDocuments_ = $('section').map((sectionIndex, sectionElement) => {
        const section = $(sectionElement);
        const sectionId = section.attr('id') || `section-${sectionIndex}`;
        const sectionTitle = section.find('h2').first().text().trim();
        const sectionText = section.find('p').first().text().trim();
        const chapters = section.find('h3').map((chapterIndex, h3) => {
            const chapter = $(h3);
            const chapterId = chapter.attr('id') || `chapter-${chapterIndex}`;
            const chapterTitle = chapter.text().trim();
            const chapterText = chapter.nextUntil('h3, h2', 'p').text().trim();
            const paragraphs = chapter.nextUntil('h3, h2', 'article.legalArticle').map((paragraphIndex, article) => {
                const articleElement = $(article);
                const paragraphId = articleElement.attr('id') || `paragraph-${paragraphIndex}`;
                const paragraphTitle = articleElement.find('h4').first().text().trim();
                const paragraphText = articleElement.children().not('h4').map((i, el) => $(el).text().trim()).get().join(' ');
                return {
                    id: paragraphId,
                    paragraph_title: paragraphTitle,
                    paragraph_text: paragraphText,
                    _type: "paragraph"
                };
            }).get();
            return {
                id: chapterId,
                chapter_title: chapterTitle,
                chapter_text: chapterText,
                _childDocuments_: paragraphs,
                _type: "chapter"
            };
        }).get();
        return {
            id: sectionId,
            section_title: sectionTitle,
            section_text: sectionText,
            _childDocuments_: chapters,
            _type: "section"
        };
    }).get();
} else if (lawFormatType === 'c') {
    document._childDocuments_ = $('h2').map((chapterIndex, h2) => {
        const chapter = $(h2);
        const chapterId = chapter.attr('id') || `chapter-${chapterIndex}`;
        const chapterTitle = chapter.text().trim();
        const chapterText = chapter.nextUntil('h2', 'p').text().trim();
        const paragraphs = chapter.nextUntil('h2', 'article.legalArticle').map((paragraphIndex, article) => {
            const articleElement = $(article);
            const paragraphId = articleElement.attr('id') || `paragraph-${paragraphIndex}`;
            return {
                id: paragraphId,
                paragraph_title: articleElement.find('h3').first().text().trim(),
                paragraph_text: articleElement.children().not('h3').map((i, el) => $(el).text().trim()).get().join(' '),
                _type: "paragraph"
            };
        }).get();
        return {
            id: chapterId,
            chapter_title: chapterTitle,
            chapter_text: chapterText,
            _childDocuments_: paragraphs,
            _type: "chapter"
        };
    }).get();
} else if (lawFormatType === 'p') {
    document._childDocuments_ = $('h2, h3').map((paragraphIndex, header) => {
        const headerElement = $(header);
        const paragraphId = headerElement.attr('id') || `paragraph-${paragraphIndex}`;
        const paragraphTitle = headerElement.text().trim();
        const paragraphText = headerElement.nextUntil('h2, h3').map((i, el) => $(el).text().trim()).get().join(' ');
        return {
            id: paragraphId,
            paragraph_title: paragraphTitle,
            paragraph_text: paragraphText,
            _type: "paragraph"
        };
    }).get();
}

// Prepare the document for Solr ingestion by adding the root document metadata
const solrInput = {
    add: {
        doc: document,
        boost: 1.0,
        commitWithin: 1000,
        overwrite: true
    }
};

// Write the structured document to a JSON file
writeFileSync(outputFileName, JSON.stringify(solrInput, null, 2), 'utf8');
console.log(`Document parsed and structured for Solr, saved as ${outputFileName}.`);
