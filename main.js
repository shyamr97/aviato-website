/* ============================================================
   AVIATO — main.js
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {

  /* ---- CUSTOM CURSOR ------------------------------------ */
  const cursor = document.getElementById('cursor');
  const cursorDot = document.getElementById('cursorDot');
  if (cursor && cursorDot) {
    let mouseX = 0, mouseY = 0;
    let curX = 0, curY = 0;
    document.addEventListener('mousemove', e => {
      mouseX = e.clientX; mouseY = e.clientY;
      cursorDot.style.left = mouseX + 'px';
      cursorDot.style.top  = mouseY + 'px';
    });
    function animateCursor() {
      curX += (mouseX - curX) * 0.12;
      curY += (mouseY - curY) * 0.12;
      cursor.style.left = curX + 'px';
      cursor.style.top  = curY + 'px';
      requestAnimationFrame(animateCursor);
    }
    animateCursor();
  }

  /* ---- NAV SCROLL --------------------------------------- */
  const nav = document.getElementById('nav');
  window.addEventListener('scroll', () => {
    nav.classList.toggle('scrolled', window.scrollY > 40);
  }, { passive: true });

  /* ---- HAMBURGER ---------------------------------------- */
  const hamburger = document.getElementById('hamburger');
  const mobileMenu = document.getElementById('mobileMenu');
  if (hamburger && mobileMenu) {
    hamburger.addEventListener('click', () => {
      mobileMenu.classList.toggle('open');
      const spans = hamburger.querySelectorAll('span');
      const isOpen = mobileMenu.classList.contains('open');
      spans[0].style.transform = isOpen ? 'translateY(6.5px) rotate(45deg)' : '';
      spans[1].style.opacity   = isOpen ? '0' : '1';
      spans[2].style.transform = isOpen ? 'translateY(-6.5px) rotate(-45deg)' : '';
    });
    mobileMenu.querySelectorAll('a').forEach(a => {
      a.addEventListener('click', () => {
        mobileMenu.classList.remove('open');
        hamburger.querySelectorAll('span').forEach(s => { s.style.transform = ''; s.style.opacity = ''; });
      });
    });
  }

  /* ---- INTERSECTION OBSERVER — reveal ------------------- */
  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry, i) => {
      if (entry.isIntersecting) {
        const el = entry.target;
        const delay = el.dataset.delay || (Array.from(el.parentElement?.children || []).indexOf(el) * 80);
        setTimeout(() => el.classList.add('visible'), Math.min(Number(delay), 500));
        revealObserver.unobserve(el);
      }
    });
  }, { threshold: 0.12 });

  document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

  /* ---- STAT COUNTER ------------------------------------- */
  const statObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      entry.target.querySelectorAll('.stat-num').forEach(el => {
        const target = +el.dataset.target;
        const duration = 1600;
        const start = performance.now();
        function tick(now) {
          const progress = Math.min((now - start) / duration, 1);
          const ease = 1 - Math.pow(1 - progress, 3);
          el.textContent = Math.round(ease * target);
          if (progress < 1) requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);
      });
      statObserver.unobserve(entry.target);
    });
  }, { threshold: 0.3 });

  const statsRow = document.querySelector('.stats-row');
  if (statsRow) statObserver.observe(statsRow);

  /* ---- TIMELINE PROGRESS -------------------------------- */
  const timelineSection = document.querySelector('.process-timeline');
  const timelineProgress = document.getElementById('timelineProgress');
  if (timelineSection && timelineProgress) {
    const tlObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          setTimeout(() => { timelineProgress.style.width = '100%'; }, 400);
          // Activate step nodes sequentially
          document.querySelectorAll('.process-step').forEach((step, i) => {
            setTimeout(() => step.classList.add('visible'), 400 + i * 200);
          });
          tlObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.2 });
    tlObserver.observe(timelineSection);
  }

  /* ---- CONTACT UNDERLINE -------------------------------- */
  const contactSection = document.querySelector('.contact-hero');
  if (contactSection) {
    const cuObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          setTimeout(() => {
            const u = document.querySelector('.contact-underline');
            if (u) u.classList.add('drawn');
          }, 600);
          cuObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.3 });
    cuObserver.observe(contactSection);
  }

  /* ---- PORTFOLIO FILTER --------------------------------- */
  const filterBtns = document.querySelectorAll('.filter-btn');
  const portfolioCards = document.querySelectorAll('.portfolio-card');

  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const filter = btn.dataset.filter;
      portfolioCards.forEach(card => {
        const cats = card.dataset.cat || '';
        if (filter === 'all' || cats.includes(filter)) {
          card.classList.remove('hidden');
        } else {
          card.classList.add('hidden');
        }
      });
    });
  });

  /* ---- TAG SELECT --------------------------------------- */
  document.querySelectorAll('.tag-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      btn.classList.toggle('selected');
    });
  });

  /* ---- FAQ ACCORDION ------------------------------------ */
  document.querySelectorAll('.faq-q').forEach(btn => {
    btn.addEventListener('click', () => {
      const item = btn.parentElement;
      const isOpen = item.classList.contains('open');
      document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('open'));
      if (!isOpen) item.classList.add('open');
    });
  });

  /* ---- CONTACT FORM ------------------------------------- */
  const form = document.getElementById('contactForm');
  const submitBtn = document.getElementById('submitBtn');
  const formSuccess = document.getElementById('formSuccess');

  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name  = document.getElementById('fname')?.value.trim();
      const email = document.getElementById('femail')?.value.trim();
      if (!name || !email) {
        [document.getElementById('fname'), document.getElementById('femail')].forEach(el => {
          if (el && !el.value.trim()) {
            el.style.borderColor = '#e53e3e';
            el.addEventListener('input', () => el.style.borderColor = '', { once: true });
          }
        });
        return;
      }
      // Loading state
      const textEl    = submitBtn.querySelector('.btn-submit-text');
      const loadingEl = submitBtn.querySelector('.btn-submit-loading');
      textEl.style.display    = 'none';
      loadingEl.style.display = 'flex';
      submitBtn.disabled = true;

      // Simulate send (replace with real fetch in production)
      await new Promise(r => setTimeout(r, 1800));

      form.style.display    = 'none';
      formSuccess.style.display = 'block';
    });
  }

  /* ---- SMOOTH SCROLL for anchor links ------------------- */
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', e => {
      const target = document.querySelector(a.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

});
