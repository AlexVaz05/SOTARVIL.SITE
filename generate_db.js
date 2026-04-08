const fs = require('fs');
const path = require('path');

const basePath = `C:\\Users\\vazfa\\.gemini\\antigravity\\scratch\\sotarvil`;

function getFiles(dir, category, brandFallback) {
    const fullPath = path.join(basePath, dir);
    if (!fs.existsSync(fullPath)) return [];
    
    let results = [];
    const list = fs.readdirSync(fullPath, { withFileTypes: true });
    
    for (const dirent of list) {
        if (dirent.isDirectory()) {
            results = results.concat(getFiles(path.join(dir, dirent.name), category, dirent.name));
        } else {
            const ext = path.extname(dirent.name).toLowerCase();
            if (['.png', '.jpg', '.jpeg', '.webp'].includes(ext)) {
                let niceName = dirent.name.replace(ext, '').replace(/[-_]/g, ' ').trim();
                niceName = niceName.charAt(0).toUpperCase() + niceName.slice(1);
                
                // Fix specific names
                if (niceName.toLowerCase().includes('alcool00')) niceName = 'Super Bock 0.0%';
                if (niceName.toLowerCase() === 'guaraná') niceName = 'Guaraná Brasil';
                if (niceName.toLowerCase() === 'mingorra white wine vinegar') niceName = 'Vinagre de Vinho Branco Mingorra';
                if (niceName.toLowerCase() === 'mingorra extra virgin olive oil') niceName = 'Azeite Virgem Extra Mingorra';

                results.push({
                    name: niceName,
                    img: path.join(dir, dirent.name).replace(/\\/g, '/'),
                    brand: brandFallback || 'Sotarvil'
                });
            }
        }
    }
    return results;
}

const db = {
    'cervejas': { title: 'Cervejas', files: getFiles('cervejas', 'cervejas', 'Cerveja') },
    'aguas': { title: 'Águas', files: getFiles('Produtos catálogo(imagens)/Águas', 'aguas', 'Água') },
    'refrigerantes': { title: 'Refrigerantes', files: getFiles('Produtos catálogo(imagens)/Refrigerantes', 'refrigerantes', 'Refrigerante') },
    'nectares': { title: 'Néctares', files: [] }, // Will filter from Refrigerantes if needed, or leave together
    'cafes': { title: 'Cafés', files: getFiles('Produtos catálogo(imagens)/Cafés', 'cafes', 'Café') },
    'bebidas-brancas': { title: 'Bebidas Brancas', files: getFiles('Produtos catálogo(imagens)/Bebidas Brancas', 'bebidas-brancas', 'Bebida Branca') },
    'vinhos': { title: 'Vinhos', files: getFiles('Produtos catálogo(imagens)/vinhos e espumantes/Vinhos', 'vinhos', 'Vinho') },
    'espumantes': { title: 'Espumantes', files: getFiles('Produtos catálogo(imagens)/vinhos e espumantes/Espumante', 'espumantes', 'Espumante') },
    'champanhes': { title: 'Champanhes', files: getFiles('Produtos catálogo(imagens)/vinhos e espumantes/Champanhe', 'champanhes', 'Champanhe') },
    'alimentares': { title: 'Produtos Alimentares', files: [
        { name: 'Vinagre de Vinho Branco Mingorra', img: 'Produtos catálogo(imagens)/mingorra-white-wine-vinegar.jpg', brand: 'Mingorra' },
        { name: 'Azeite Virgem Extra Mingorra', img: 'Produtos catálogo(imagens)/mingorra-extra-virgin-olive-oil.jpg', brand: 'Mingorra' }
    ] },
    'laticinios': { title: 'Laticínios', files: getFiles('Produtos catálogo(imagens)/Laticinios', 'laticinios', 'Lacticínio') },
    'detergentes': { title: 'Detergentes', files: [] }
};

fs.writeFileSync('C:\\Users\\vazfa\\.gemini\\antigravity\\scratch\\sotarvil\\db_dump.json', JSON.stringify(db, null, 2));
console.log('DB Dumped');
