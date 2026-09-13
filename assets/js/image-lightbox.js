(() => {
    const dialog = document.getElementById('image-lightbox');
    if (!dialog || typeof dialog.showModal !== 'function') return;
    const enlarged = dialog.querySelector('img');
    let previousStyle = '', scrollY = 0, opener;
    const close = () => { if (dialog.open) dialog.close(); };
    document.querySelectorAll('.post-single .post-content img.article-image').forEach(image => {
        image.dataset.lightbox = '';
        // Preserve existing linked-image markup while supporting keyboard access.
        const trigger = image.closest('a') || image;
        if (trigger === image) {
            image.tabIndex = 0;
            image.setAttribute('role', 'button');
        }
        trigger.setAttribute('aria-haspopup', 'dialog');
        trigger.setAttribute('aria-controls', 'image-lightbox');
        const open = event => {
            event.preventDefault();
            if (dialog.open) return;
            opener = trigger;
            enlarged.src = image.src;
            enlarged.alt = image.alt;
            scrollY = window.scrollY;
            previousStyle = document.body.style.cssText;
            document.body.style.position = 'fixed';
            document.body.style.top = `-${scrollY}px`;
            document.body.style.width = '100%';
            dialog.showModal();
        };
        trigger.addEventListener('click', open);
        trigger.addEventListener('keydown', event => {
            if (event.key === 'Enter' || event.key === ' ') open(event);
        });
    });
    dialog.querySelector('button').addEventListener('click', close);
    dialog.addEventListener('click', event => { if (event.target === dialog) close(); });
    dialog.addEventListener('cancel', event => { event.preventDefault(); close(); });
    dialog.addEventListener('close', () => {
        document.body.style.cssText = previousStyle;
        window.scrollTo({top: scrollY, behavior: 'instant'});
        opener?.focus({preventScroll: true});
        enlarged.removeAttribute('src');
    });
})();
