import * as fs from 'fs';
export function readFile(userPath: string) {
    // Path Traversal
    return fs.readFileSync('/var/data/' + userPath);
}\n