const fs = require('fs');
const path = require('path');

const base = path.join(__dirname, 'produtos');
const webBase = 'produtos';
const validExts = new Set(['.png', '.jpg', '.jpeg', '.webp', '.gif']);

// Mapping from top-level folder names to category keys used in the URLs
const categoryMap = {
    'Águas': 'aguas',
    'Bebidas Brancas': 'bebidas-brancas',
    'Bebidas Quentes e Cafés': 'cafes',
    'cervejas': 'cervejas',
    'Champanhes': 'champanhes',
    'Detergentes': 'detergentes',
    'Energéticos': 'energeticos',
    'Espumantes': 'espumantes',
    'La Casera': 'la-casera',
    'Pressão': 'pressao',
    'Produtos Alimentares': 'alimentares',
    'Refrigerantes': 'refrigerantes',
    'Sidras': 'sidras',
    'Vinhos': 'vinhos'
};

let descMap = { categories: {}, brands: {}, products: {} };
if (fs.existsSync(path.join(__dirname, 'descriptions.json'))) {
    descMap = JSON.parse(fs.readFileSync(path.join(__dirname, 'descriptions.json'), 'utf8'));
}

function getDesc(name, brand, catKey) {
    if (name) {
        // Tenta encontrar por nome de produto (case-insensitive)
        for (const k of Object.keys(descMap.products)) {
            if (name.toLowerCase().includes(k.toLowerCase())) return descMap.products[k];
        }
    }
    if (brand) {
        // Tenta encontrar por marca
        for (const k of Object.keys(descMap.brands)) {
            if (brand.toLowerCase().includes(k.toLowerCase())) return descMap.brands[k];
        }
    }
    // Tenta encontrar por categoria
    if (descMap.categories[catKey]) return descMap.categories[catKey];
    
    return 'Produto premium distribuído pela Sotarvil.';
}

const db = {};

// Initialize categories with titles
const titles = {
    'cervejas': 'Cervejas',
    'pressao': 'Pressão',
    'aguas': 'Águas',
    'vinhos': 'Vinhos',
    'bebidas-brancas': 'Bebidas Brancas',
    'champanhes': 'Champanhes',
    'espumantes': 'Espumantes',
    'refrigerantes': 'Refrigerantes',
    'nectares': 'Néctares e Sumos',
    'cafes': 'Cafés e Bebidas Quentes',
    'laticinios': 'Laticínios',
    'azeites': 'Azeites, Óleos e Vinagres',
    'alimentares': 'Produtos Alimentares',
    'detergentes': 'Detergentes',
    'energeticos': 'Energéticos',
    'la-casera': 'La Casera',
    'sidras': 'Sidras'
};

for (const key in titles) {
    db[key] = { title: titles[key], files: [] };
}

function encodeImgPath(fullPath) {
    const rel = path.relative(base, fullPath).replace(/\\/g, '/');
    const parts = rel.split('/');
    return webBase + '/' + parts.map(p => encodeURIComponent(p)).join('/');
}

function getName(filePath) {
    const name = path.basename(filePath, path.extname(filePath));
    // Remove common prefixes if any, and capitalize
    return name.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

function walk(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    
    // Check if this directory should be treated as a single product with variants
    // A directory is a product if it's inside a brand folder or deep in the hierarchy
    // For now, let's say if it's 2 levels deep from 'produtos/category', it might be a product
    const relFromBase = path.relative(base, dir);
    const parts = relFromBase.split(path.sep);
    
    // Example: cervejas/engarrafadas/Super Bock Original
    // parts: ['cervejas', 'engarrafadas', 'Super Bock Original']
    if (parts.length >= 3) {
        processProductFolder(dir, parts);
        return;
    }

    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            walk(fullPath);
        } else {
            const ext = path.extname(entry.name).toLowerCase();
            if (validExts.has(ext)) {
                processFile(fullPath);
            }
        }
    }
}

function processProductFolder(dir, parts) {
    const topFolder = parts[0];
    let categoryKey = categoryMap[topFolder] || 'outros';
    const productName = getName(dir);
    const brand = parts[parts.length - 2];
    const hierarchy = parts.slice(1, -1).join(' > ');
    
    // Determine type (same logic as processFile)
    let type = '';
    if (topFolder === 'cervejas') type = 'engarrafada';
    if (topFolder === 'Águas') {
        if (dir.includes('Lisas')) type = 'lisa';
        else if (dir.includes('Sem Sabor')) type = 'gas-sem-sabor';
        else if (dir.includes('Com Sabor')) type = 'gas-com-sabor';
    }

    const variantFiles = fs.readdirSync(dir).filter(f => validExts.has(path.extname(f).toLowerCase()));
    if (variantFiles.length === 0) return;

    // Pick main image (prefer one starting with 1_ or just the first)
    const mainImgFile = variantFiles.find(f => f.startsWith('1_')) || variantFiles[0];
    
    const product = {
        name: productName,
        brand: brand,
        type: type,
        hierarchy: hierarchy,
        desc: getDesc(productName, brand, categoryKey),
        img: encodeImgPath(path.join(dir, mainImgFile)),
        isGroup: true,
        variants: variantFiles.map(f => ({
            name: getName(f).replace(productName, '').trim(), // e.g., "33cl"
            img: encodeImgPath(path.join(dir, f))
        }))
    };

    if (!db[categoryKey]) {
        db[categoryKey] = { title: categoryKey, files: [] };
    }
    db[categoryKey].files.push(product);

    if (categoryKey === 'pressao') {
        if (!db['cervejas']) { db['cervejas'] = { title: titles['cervejas'], files: [] }; }
        db['cervejas'].files.push(product);
    }
}

function processFile(fullPath) {
    const rel = path.relative(base, fullPath);
    const parts = rel.split(path.sep);
    if (parts.length < 1) return;

    const topFolder = parts[0];
    let categoryKey = categoryMap[topFolder] || 'outros';
    let brand = topFolder;
    let type = '';

    // Handle nested structure for brand/type
    if (parts.length > 1) {
        brand = parts[parts.length - 2];
    }

    // Special cases
    // 1. Águas differentiation
    if (topFolder === 'Águas') {
        if (rel.includes('Lisas')) type = 'lisa';
        else if (rel.includes('Sem Sabor')) type = 'gas-sem-sabor';
        else if (rel.includes('Com Sabor')) type = 'gas-com-sabor';
    }

    // 2. Cervejas differentiation
    if (topFolder === 'Pressão') {
        type = 'pressao';
        brand = 'Pressão';
    } else if (topFolder === 'cervejas') {
        type = 'engarrafada';
    }

    // 3. Néctares e Sumos logic
    if (topFolder === 'Refrigerantes') {
        if (rel.includes('Compal') || rel.includes('Super Bock Group')) {
            categoryKey = 'nectares';
        }
    }

    // 4. Laticínios
    if (topFolder === 'Bebidas Quentes e Cafés' && rel.includes('Laticínios')) {
        categoryKey = 'laticinios';
    }

    // 5. Azeites
    if (topFolder === 'Produtos Alimentares' && rel.includes('Azeite, óleo, Vinagre')) {
        categoryKey = 'azeites';
    }

    const name = getName(fullPath);
    const hierarchy = parts.length > 1 ? parts.slice(1, -1).join(' > ') : '';
    
    // Add to category
    if (!db[categoryKey]) {
        db[categoryKey] = { title: categoryKey, files: [] };
    }
    
    db[categoryKey].files.push({
        img: encodeImgPath(fullPath),
        name: name,
        brand: brand,
        type: type,
        hierarchy: hierarchy,
        desc: getDesc(name, brand, categoryKey)
    });

    if (categoryKey === 'pressao') {
        if (!db['cervejas']) { db['cervejas'] = { title: titles['cervejas'], files: [] }; }
        db['cervejas'].files.push({
            img: encodeImgPath(fullPath),
            name: name,
            brand: brand,
            type: type,
            hierarchy: hierarchy,
            desc: getDesc(name, brand, 'cervejas')
        });
    }
}

if (fs.existsSync(base)) {
    walk(base);
}

// Write to JS file for direct inclusion in HTML
const content = `window.productsDB = ${JSON.stringify(db, null, 2)};`;
fs.writeFileSync(path.join(__dirname, 'productsDB.js'), content, 'utf8');

console.log('Successfully generated productsDB.js');
for (const key in db) {
    if (db[key].files.length > 0) {
        console.log(` - ${key}: ${db[key].files.length} items`);
    }
}

