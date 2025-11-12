import "@hotwired/turbo-rails"
import "controllers"
import "stock_gallery"  
import "flash"  
import "mobile_lang"
 
window.__APP_OK__ = true
document.addEventListener("turbo:load", () => {
  console.log("✅ application.js cargado (turbo:load)")
})
 



function isMobile() {
    return window.matchMedia("(pointer: coarse), (max-width: 640px)").matches;
  }

  if (!isMobile()) {
    setTimeout(function() {
      document.getElementById('lang-overlay').style.display = "flex";
      setTimeout(function() {
        let currentLocale = window.location.pathname.split('/')[1];
        let nextLocale = (currentLocale === 'es') ? 'en' : 'es';
        let pathRest = window.location.pathname.replace(/^\/(en|es)/, '');
        window.location.href = `/${nextLocale}${pathRest}${window.location.search}`;
      }, 800); // muestra el overlay 0.8s antes de recargar
    }, 87000);
  }