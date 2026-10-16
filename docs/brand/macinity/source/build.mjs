import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
fs.mkdirSync(path.join(root, 'assets'), { recursive: true });
fs.mkdirSync(path.join(root, 'Macinity.iconset'), { recursive: true });
const master = JSON.parse(fs.readFileSync(path.join(root, 'source/mark.json')));
const d = master.paths.map(p => p.map(c => c.join(' ')).join(' ')).join(' ');
const svg = (body, label, box = '0 0 256 256') => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${box}" role="img" aria-label="${label}">${body}</svg>\n`;
for (const [name, color] of Object.entries({ cobalt: '#4169F5', black: '#151A23', white: '#FFFFFF' })) {
  fs.writeFileSync(path.join(root, `assets/mark-${name}.svg`), svg(`<path fill="${color}" d="${d}"/>`, `Macinity ${name} mark`));
}
fs.writeFileSync(path.join(root, 'assets/menu-template.svg'), svg(`<path fill="black" d="${d}"/>`, 'Macinity menu template'));
fs.writeFileSync(path.join(root, 'assets/app-icon.svg'), svg(`<defs><linearGradient id="tile" x2="0" y2="1"><stop stop-color="#303B4B"/><stop offset="1" stop-color="#10151D"/></linearGradient><linearGradient id="mark" x2="0.25" y2="1"><stop stop-color="#78B9FF"/><stop offset="0.38" stop-color="#4169F5"/><stop offset="1" stop-color="#2754E5"/></linearGradient></defs><rect x="24" y="24" width="464" height="464" rx="104" fill="url(#tile)"/><rect x="25" y="25" width="462" height="462" rx="103" fill="none" stroke="#607084" stroke-opacity=".5" stroke-width="2"/><g transform="translate(102.4 102.4) scale(1.2)"><path fill="url(#mark)" stroke="#A5CCFF" stroke-opacity=".55" stroke-width="1" d="${d}"/></g>`, 'Macinity app icon', '0 0 512 512'));
execFileSync('/usr/bin/xcrun', ['swift', path.join(root, 'source/render.swift'), root], { stdio: 'inherit' });
execFileSync('/usr/bin/iconutil', ['-c', 'icns', path.join(root, 'Macinity.iconset'), '-o', path.join(root, 'Macinity.icns')], { stdio: 'inherit' });
console.log('Built SVG, PNG, menu templates, and Macinity.icns from source/mark.json.');
