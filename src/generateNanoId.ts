// generateNanoId.ts
import { readFile, writeFile } from 'fs/promises';
import { customAlphabet } from 'nanoid';

const nanoid = customAlphabet('1234567890abcdef', 10);

interface FileIdMapping {
    [key: string]: string;
}

const dbFilePath = './fileid.db.json';

async function readDbFile(): Promise<FileIdMapping> {
    try {
        const data = await readFile(dbFilePath, { encoding: 'utf8' });
        return JSON.parse(data);
    } catch (error) {
        console.error('Error reading the DB file:', error);
        return {};
    }
}

async function writeDbFile(data: FileIdMapping): Promise<void> {
    await writeFile(dbFilePath, JSON.stringify(data, null, 2), { encoding: 'utf8' });
}

async function getId(filename: string): Promise<string> {
    const fileMapping = await readDbFile();
    if (fileMapping[filename]) {
        return fileMapping[filename];
    }

    const newNanoId = nanoid();
    fileMapping[filename] = newNanoId;
    await writeDbFile(fileMapping);
    return newNanoId;
}

export default getId;
