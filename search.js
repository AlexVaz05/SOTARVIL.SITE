/**
 * Sotarvil Global Search Logic - v4.1 (Optimized Ranking & Word Matching)
 * Handles searching across all products in productsDB.js
 */

document.addEventListener('DOMContentLoaded', () => {
    console.log("Sotarvil Search Engine v4.1 Initialized");
    const productsDB = window.productsDB;
    if (!productsDB) {
        console.error("Products database not found!");
        return;
    }

    const allProducts = [];

    function flatten(item, catKey, catTitle) {
        if (Array.isArray(item)) {
            item.forEach(i => flatten(i, catKey, catTitle));
        } else if (item && typeof item === 'object') {
            if (item.name && (item.img || item.isGroup)) {
                const hasVariants = item.isGroup && item.variants && item.variants.length > 0;
                
                if (!hasVariants) {
                    allProducts.push({
                        ...item,
                        categoryKey: catKey,
                        categoryTitle: catTitle,
                        hierarchy: item.hierarchy || ''
                    });
                } else {
                    item.variants.forEach(variant => {
                        const variantSuffix = variant.name || variant.size || '';
                        allProducts.push({
                            ...variant,
                            name: `${item.name} ${variantSuffix}`.trim(),
                            categoryKey: catKey,
                            categoryTitle: catTitle,
                            desc: item.desc || '',
                            brand: item.brand || item.hierarchy || '',
                            hierarchy: item.hierarchy || ''
                        });
                    });
                }
            }
            
            Object.keys(item).forEach(key => {
                if (key !== 'variants') {
                    const val = item[key];
                    if (Array.isArray(val) || (val && typeof val === 'object')) {
                        flatten(val, catKey, catTitle);
                    }
                }
            });
        }
    }

    Object.keys(productsDB).forEach(catKey => {
        const cat = productsDB[catKey];
        flatten(cat, catKey, cat.title);
    });

    console.log(`Indexed ${allProducts.length} items for search.`);

    const searchInput = document.getElementById('global-search-input');
    const resultsDropdown = document.getElementById('global-search-results');
    
    // Also support the original catalog page search if present
    const catalogSearchInput = document.querySelector('.search-container .search-input');
    const catalogResultsDropdown = document.querySelector('.search-container .search-results-dropdown');

    if (!searchInput && !catalogSearchInput) return;

    const inputs = [searchInput, catalogSearchInput].filter(Boolean);


    function cleanString(str) {
        if (!str) return "";
        return str.toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "");
            // Note: We don't remove leading numbers here anymore to allow searching for sizes like '1L'
    }

    inputs.forEach(input => {
        input.addEventListener('input', (e) => {
            const rawInput = e.target.value.trim();
            const cleanQuery = cleanString(rawInput);
            
            // Determine which results container to use
            const currentResults = (input === searchInput) ? resultsDropdown : catalogResultsDropdown;
            
            if (cleanQuery.length < 2) {
                if (currentResults) currentResults.classList.remove('active');
                return;
            }

            const queryWords = cleanQuery.split(/\s+/).filter(w => w.length > 0);

            const matches = allProducts.map(prod => {
                // ... (rest of the matching logic remains the same)
                const cleanName = cleanString(prod.name);
                const cleanBrand = cleanString(prod.brand);
                const cleanPath = cleanString(decodeURIComponent(prod.img || ''));
                const cleanCatTitle = cleanString(prod.categoryTitle);
                
                const combined = [cleanName, cleanBrand, cleanPath, cleanCatTitle].join(' ');

                let score = 0;
                const allWordsMatch = queryWords.every(word => combined.includes(word));
                
                if (allWordsMatch) {
                    score = 1;
                    const wordsInName = queryWords.filter(word => cleanName.includes(word)).length;
                    score += (wordsInName * 20);
                    if (cleanName.includes(cleanQuery)) score += 100;
                    if (cleanName.startsWith(cleanQuery)) score += 200;
                    if (queryWords.some(w => cleanBrand.includes(w))) score += 10;
                }
                
                return { prod, score };
            })
            .filter(m => m.score > 0)
            .sort((a, b) => b.score - a.score)
            .map(m => m.prod)
            .slice(0, 10);

            console.log(`Search query: "${cleanQuery}" | Results: ${matches.length}`);
            renderResults(matches, currentResults);
        });
    });

    function renderResults(matches, targetDropdown) {
        if (!targetDropdown) return;
        
        if (matches.length === 0) {
            targetDropdown.innerHTML = '<div class="search-empty">Nenhum produto encontrado.</div>';
        } else {
            targetDropdown.innerHTML = matches.map(prod => {
                const displayName = prod.name.replace(/^\d+[\s\-_.\b]+(?![cl|l|g|kg|ml])/, '');
                const displayBrand = (prod.brand || '').replace(/^\d+[\s\-_.\b]+(?![cl|l|g|kg|ml])/, '');
                
                return `
                    <div class="search-result-item" data-cat="${prod.categoryKey}" data-name="${prod.name}">
                        <img src="${prod.img}" class="search-result-img" alt="${displayName}" onerror="this.src='data:image/svg+xml;utf8,<svg xmlns=\\'http://www.w3.org/2000/svg\\' width=\\'50\\' height=\\'50\\'><rect fill=\\'%23f0f0f0\\' width=\\'50\\' height=\\'50\\'/></svg>'">
                        <div class="search-result-info">
                            <div class="search-result-name">${displayName}</div>
                            <div class="search-result-meta">${displayBrand} | ${prod.categoryTitle}</div>
                        </div>
                    </div>
                `;
            }).join('');
        }
        targetDropdown.classList.add('active');
    }

    // Handle clicks for both dropdowns
    const dropdowns = [resultsDropdown, catalogResultsDropdown].filter(Boolean);
    dropdowns.forEach(dropdown => {
        dropdown.addEventListener('click', (e) => {
            const item = e.target.closest('.search-result-item');
            if (item) {
                const cat = item.dataset.cat;
                const name = item.dataset.name;
                window.location.href = `categoria.html?cat=${cat}&highlight=${encodeURIComponent(name)}`;
            }
        });
    });

    document.addEventListener('click', (e) => {
        dropdowns.forEach(dropdown => {
            if (!e.target.closest('.search-container') && !e.target.closest('.search-overlay-input-wrapper')) {
                dropdown.classList.remove('active');
            }
        });
    });

});
