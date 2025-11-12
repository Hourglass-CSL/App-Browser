// app/javascript/flash_autoclose.js
function armAutoClose(el) {
  if (el.dataset.bound) return;
  el.dataset.bound = "1";
  // asegúrate de tener duración de transición en la clase (ver nota abajo)
  setTimeout(() => {
    el.classList.add("opacity-0");
    setTimeout(() => el.remove(), 500); // debe coincidir con tu duración
  }, 4000);
}

function bindExisting() {
  document.querySelectorAll(".auto-close-flash:not([data-bound])")
    .forEach(armAutoClose);
}

document.addEventListener("turbo:load", bindExisting);
document.addEventListener("turbo:render", bindExisting);
document.addEventListener("turbo:frame-load", bindExisting);

// Observa el contenedor donde insertas los flashes por turbo_stream
document.addEventListener("turbo:load", () => {
  const container = document.getElementById("flash-container");
  if (!container) return;

  const obs = new MutationObserver((mutations) => {
    mutations.forEach(({ addedNodes }) => {
      addedNodes.forEach((n) => {
        if (n.nodeType === 1) {
          // si el nodo agregado es el toast
          if (n.classList?.contains("auto-close-flash")) armAutoClose(n);
          // o si vino envuelto, busca dentro
          n.querySelectorAll?.(".auto-close-flash:not([data-bound])")
            .forEach(armAutoClose);
        }
      });
    });
  });

  obs.observe(container, { childList: true, subtree: true });
});
