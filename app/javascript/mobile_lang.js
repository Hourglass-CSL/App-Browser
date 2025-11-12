// app/javascript/mobile_lang.js

document.addEventListener("turbo:load", () => {
  const isMobile = window.innerWidth <= 768;
  const popup = document.getElementById("mobile-lang-popup");
  if (!popup) return;

  const DISMISS_KEY = "langPopupDismissed"; // usa localStorage si quieres persistir entre tabs
  const dismissed = sessionStorage.getItem(DISMISS_KEY) === "1";

  function openPopup() {
    popup.classList.remove("hidden");
  }

  function closeAndRemember() {
    popup.classList.add("hidden");
    sessionStorage.setItem(DISMISS_KEY, "1");
  }

  // Mostrar solo si móvil y no ha sido descartado en esta sesión
  if (isMobile && !dismissed) {
    setTimeout(openPopup, 1000);
  }

  // Cerrar tocando fuera del contenido
  popup.addEventListener("click", (e) => {
    if (e.target === popup) closeAndRemember();
  });

  // Marcar como visto al elegir idioma (antes de que Turbo navegue)
  popup.querySelectorAll("a").forEach((a) => {
    a.addEventListener("click", () => {
      closeAndRemember();
      // Turbo hará la navegación normalmente
    });
  });
});
