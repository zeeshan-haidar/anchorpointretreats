$(document).ready(function(){
    initNavLink();
    initSidebar();
    initSidebarDropdown();
    initTabSchedule();
    initTestimonialSlider();
    initFlatpickrCalendar();
    initAnimationScroll();
    initCounter();
});

function initNavLink() {
    const currentUrl = window.location.href;
    $(".navbar-nav .nav-link").each(function() {
        if (this.href === currentUrl) {
            $(this).addClass("active");
        }
    });
    $(".navbar-nav .dropdown-menu .dropdown-item").each(function() {
        if (this.href === currentUrl) {
            $(this).addClass("active");
            $(this).closest(".dropdown").find(".nav-link.dropdown-toggle").addClass("active");
        }
    });
}

function initSidebar() {
    const $menu = $(".nav-btn");
    const $close = $(".close-btn-sidebar");
    const $overlay = $(".sidebar-overlay");
    const $sidebar = $(".sidebar");

    $menu.on("click", function() {
        $overlay.addClass("active");
        setTimeout(() => $sidebar.addClass("active"), 200);
    });

    $close.on("click", closeSidebar);
    $overlay.on("click", closeSidebar);

    function closeSidebar() {
        $sidebar.removeClass("active");
        setTimeout(() => $overlay.removeClass("active"), 200);
    }
}

function initSidebarDropdown() {
    const $sidebar = $(".sidebar");

    $sidebar.on("click", ".sidebar-dropdown-btn", function() {
        const $dropdownMenu = $(this).parent().next(".sidebar-dropdown-menu");
        const isOpen = $dropdownMenu.hasClass("active");

        $(".sidebar-dropdown-menu").not($dropdownMenu).removeClass("active");

        $dropdownMenu.toggleClass("active", !isOpen);
    });
}

function initFlatpickrCalendar() {
    var $date = $("#date");

    $date.flatpickr({
        dateFormat: "d M Y"
    });
}

function initTabSchedule() {
    const $tabButtons = $('.schedule-tab-btn');
    const $desktopPanels = $('.schedule-tab-panel');
    const $mobilePanels = $('.mobile-schedule-tab-panel');

    function isMobile() {
        return window.matchMedia('(max-width: 767.98px)').matches;
    }

    function resetTabs() {
        $tabButtons.removeClass('active');
        $desktopPanels.removeClass('active');
        $mobilePanels.removeClass('active');
    }

    function activateTab(index) {
        resetTabs();
        $tabButtons.eq(index).addClass('active');
        
        if (isMobile()) {
        $mobilePanels.eq(index).addClass('active');
        } else {
        $desktopPanels.eq(index).addClass('active');
        }
    }

    $(document).on('click', '.schedule-tab-btn', function(e) {
        e.preventDefault();
        const index = $('.schedule-tab-btn').index(this);
        activateTab(index);
    });

    activateTab(0);

    $(window).on('resize', function() {
        const currentIndex = $tabButtons.filter('.active').index();
        activateTab(currentIndex >= 0 ? currentIndex : 0);
    });
}

function initTestimonialSlider() {
    const $testimonialBoxes = $('.testimonial-box');
    const $btnPrev = $('.btn-prev');
    const $btnNext = $('.btn-next');
    const $testimonialContainer = $('.testimonial-box-container');
    
    let currentIndex = 0;
    const totalSlides = $testimonialBoxes.length;
    
    function showSlide(index) {
        if (index >= totalSlides) {
            currentIndex = 0;
        } else if (index < 0) {
            currentIndex = totalSlides - 1;
        } else {
            currentIndex = index;
        }
        
        $testimonialBoxes.each(function() {
            $(this).fadeOut(300);
        });
        
        setTimeout(() => {
            $testimonialBoxes.eq(currentIndex).fadeIn(300);
        }, 150);
    }
    
    $btnPrev.on('click', function() {
        showSlide(currentIndex - 1);
    });
    
    $btnNext.on('click', function() {
        showSlide(currentIndex + 1);
    });
    
    showSlide(0);
}


function initAnimationScroll() {
    const elements = document.querySelectorAll('[data-animation]');

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (!entry.isIntersecting) return;

            const el = entry.target;
            const animation = el.dataset.animation;

            const styles = getComputedStyle(el);

            const duration = el.dataset.duration 
                || styles.getPropertyValue('--anim-duration').trim() 
                || '1s';

            const delay = el.dataset.delay 
                || styles.getPropertyValue('--anim-delay').trim() 
                || '0s';

            el.style.animationName = animation;
            el.style.animationDuration = duration;
            el.style.animationDelay = delay;
            el.style.animationPlayState = 'running';
            el.classList.add('animated');

            observer.unobserve(el);
        });
    }, {
        threshold: 0.1
    });

    elements.forEach(el => {
        el.style.animationPlayState = 'paused';
        el.style.opacity = '0';
        observer.observe(el);
    });
}


function initCounter() {
    const $counters = $('.counter');
    
    const observer = new window.IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const $el = $(entry.target);
                
                const targetCount = parseInt($el.data('count'), 10) || 0;
                
                let currentCount = 0;
                
                // Animation duration in milliseconds
                const duration = 2000;
                const increment = targetCount / (duration / 16);
                
                const counter = setInterval(() => {
                    currentCount += increment;
                    
                    if (currentCount >= targetCount) {
                        currentCount = targetCount;
                        clearInterval(counter);
                    }
                    
                    $el.text(Math.floor(currentCount));
                }, 16);
                
                observer.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.1
    });
    
    $counters.each(function () {
        observer.observe(this);
    });
}