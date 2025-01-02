const fs = require('fs');
const cheerio = require('cheerio');

// Funksjon for å trekke ut tekst utenfor HTML-tagger og telle tegn
function countCharactersOutsideTags(htmlContent) {
    const $ = cheerio.load(htmlContent); // Last HTML med cheerio
    const text = $('body').text(); // Få all tekstinnhold fra <body>
    return text.length; // Tell antall tegn (inkludert mellomrom)
}

function main() {
    const filePath = process.argv[2]; // Filsti fra kommandolinjeargument
    if (!filePath) {
        console.error('Bruk: node script.js <filsti>');
        process.exit(1);
    }

    fs.readFile(filePath, 'utf-8', (err, data) => {
        if (err) {
            console.error('Feil ved lesing av fil:', err);
            return;
        }

        const charCount = countCharactersOutsideTags(data);
        console.log(`Antall tegn utenfor HTML-tagger: ${charCount}`);
    });
}

main();
