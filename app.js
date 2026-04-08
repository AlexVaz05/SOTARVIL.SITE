document.addEventListener('DOMContentLoaded', () => {
    
    // 1. LÓGICA DO AGE GATE (Verificação Legal de Maioridade)
    const ageGate = document.getElementById('age-gate');
    if (ageGate) {
        // Verifica se o visitante já confirmou em sessoes anteriores
        const isVerified = localStorage.getItem('sotarvil_age_verified');
        
        if (!isVerified) {
            // Se nao verificou, mostra o modal e bloqueia o scroll do website
            ageGate.classList.add('active');
            document.body.style.overflow = 'hidden';
            
            document.getElementById('btn-over-18').addEventListener('click', () => {
                localStorage.setItem('sotarvil_age_verified', 'true');
                ageGate.classList.remove('active');
                setTimeout(() => { ageGate.style.display = 'none'; }, 600);
                document.body.style.overflow = '';
            });
            
            document.getElementById('btn-under-18').addEventListener('click', () => {
                // Ao declarar menoridade, redireciona o utilizador legalmente para uma página segura
                window.location.href = 'https://www.google.pt';
            });
        } else {
            ageGate.style.display = 'none';
        }
    }

    // 2. OBSERVADOR DE INTERSECÇÃO (Animações Fluídas de Scroll 'Fade-Up')
    const observerOptions = {
        threshold: 0.15, // Aciona quando 15% do bloco está visível no ecrã
        rootMargin: '0px 0px -50px 0px'
    };

    const scrollObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                // Opcional: parar de observar após animar uma vez para performance B2B
                scrollObserver.unobserve(entry.target);
            }
        });
    }, observerOptions);

    const fadeElements = document.querySelectorAll('.fade-up');
    fadeElements.forEach(el => scrollObserver.observe(el));

    // 3. LÓGICA DE FILTROS DO CATÁLOGO ON-LINE (Acordéons)
    const filterHeaders = document.querySelectorAll('.filter-item.has-sub > span');
    filterHeaders.forEach(header => {
        header.addEventListener('click', () => {
            const parentLi = header.parentElement;
            
            // Comportamento Exclusivo: fecha outro acordeon se abrir um (opcional mas premium)
            document.querySelectorAll('.filter-item.has-sub').forEach(item => {
                if(item !== parentLi) item.classList.remove('active');
            });
            
            parentLi.classList.toggle('active');
        });
    });

    // 4. HEADER DINÂMICO (Scroll & Mouse Tracking)
    const floatingNav = document.querySelector('.floating-nav');
    if(floatingNav) {
        // Rastreamento do Mouse para Efeito Visual
        floatingNav.addEventListener('mousemove', (e) => {
            const rect = floatingNav.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            floatingNav.style.setProperty('--mouse-x', `${x}px`);
            floatingNav.style.setProperty('--mouse-y', `${y}px`);
        });

        // Lógica de Scroll Progressivo
        window.addEventListener('scroll', () => {
            if (window.scrollY > 50) {
                floatingNav.classList.add('scrolled');
            } else {
                floatingNav.classList.remove('scrolled');
            }
        });
    }

    // 5. LÓGICA DE PESQUISA GLOBAL (Overlay)
    const searchOpen = document.getElementById('search-open');
    const searchClose = document.getElementById('search-close');
    const searchOverlay = document.getElementById('search-overlay');
    const globalSearchInput = document.getElementById('global-search-input');

    if (searchOpen && searchOverlay && searchClose) {
        searchOpen.addEventListener('click', () => {
            searchOverlay.classList.add('active');
            document.body.style.overflow = 'hidden';
            setTimeout(() => globalSearchInput.focus(), 300);
        });

        searchClose.addEventListener('click', () => {
            searchOverlay.classList.remove('active');
            if (!document.getElementById('mobile-menu').classList.contains('active')) {
                document.body.style.overflow = 'auto';
            }
        });

        // Fechar com a tecla ESC
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && searchOverlay.classList.contains('active')) {
                searchOverlay.classList.remove('active');
                document.body.style.overflow = 'auto';
            }
        });
    }

    // 6. LÓGICA DO MENU MOBILE (Unificada)
    const menuOpen = document.getElementById('menu-open');
    const menuClose = document.getElementById('menu-close');
    const mobileMenu = document.getElementById('mobile-menu');
    const mobileLinks = document.querySelectorAll('.mobile-nav-links a');

    if (menuOpen && mobileMenu && menuClose) {
        menuOpen.addEventListener('click', () => {
            mobileMenu.classList.add('active');
            document.body.style.overflow = 'hidden';
        });

        const closeMobileMenu = () => {
            mobileMenu.classList.remove('active');
            if (!searchOverlay.classList.contains('active')) {
                document.body.style.overflow = 'auto';
            }
        };

        menuClose.addEventListener('click', closeMobileMenu);
        mobileLinks.forEach(link => link.addEventListener('click', closeMobileMenu));
    }

});
