(() => {
    const toggle = document.getElementById('mobile-menu-toggle');
    const drawer = document.getElementById('mobile-menu');
    if (!toggle || !drawer || typeof drawer.showModal !== 'function') return;
    const mobile = window.matchMedia('(max-width: 768px)');
    document.documentElement.classList.add('mobile-nav-ready');
    let scrollY = 0;
    let previousStyle = '';
    const close = () => { if (drawer.open) drawer.close(); };
    toggle.addEventListener('click', () => {
        if (drawer.open) return close();
        if (!mobile.matches) return;
        scrollY = window.scrollY;
        previousStyle = document.body.style.cssText;
        document.body.style.position = 'fixed';
        document.body.style.top = `-${scrollY}px`;
        document.body.style.width = '100%';
        drawer.showModal();
        toggle.setAttribute('aria-expanded', 'true');
    });
    drawer.addEventListener('close', () => {
        document.body.style.cssText = previousStyle;
        window.scrollTo({ top: scrollY, behavior: 'instant' });
        toggle.setAttribute('aria-expanded', 'false');
        if (mobile.matches) toggle.focus();
    });
    drawer.querySelector('.mobile-menu-close').addEventListener('click', close);
    drawer.addEventListener('cancel', event => { event.preventDefault(); close(); });
    drawer.addEventListener('click', event => {
        const rect = drawer.getBoundingClientRect();
        if (event.target === drawer && (event.clientX < rect.left || event.clientX > rect.right ||
            event.clientY < rect.top || event.clientY > rect.bottom)) close();
        if (event.target.closest('a')) close();
    });
    document.getElementById('mobile-theme-toggle')?.addEventListener('click', () => {
        document.getElementById('theme-toggle')?.click();
    });
    mobile.addEventListener('change', () => { if (!mobile.matches) close(); });
})();
