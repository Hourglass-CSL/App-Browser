// stock_gallery.js
// Delegación global (compatible con Turbo/Turbo Streams)
// Selección simple o múltiple según el field (SIN toggle).
// Multi fijo SOLO para: menu_file y menu_file_es.

(function () {
  if (window.__stockGalleryDelegated) return;
  window.__stockGalleryDelegated = true;

  // ---------- Config ----------
  const MULTI_FIELDS = new Set(["menu_file", "menu_file_es"]); // <- solo estos son múltiples

  function isMultiField(field) {
    return MULTI_FIELDS.has(field);
  }

  // Devuelve el nombre del parámetro array para múltiples según el field.
  // menu_file     -> stock_image_keys_menu_file
  // menu_file_es  -> stock_image_keys_menu_file_es
  function multiParamNameForField(field) {
    if (field === "menu_file_es") return "stock_image_keys_menu_file_es";
    return "stock_image_keys_menu_file";
  }

  // Crea/recupera un contenedor para inputs hidden (arrays) de multi-selección
  function ensureMultiBag(field, targetParam) {
    const bagId = `stock-image-keys-${field}`; // ej: stock-image-keys-menu_file
    let bag = document.getElementById(bagId);
    if (!bag) {
      bag = document.createElement("div");
      bag.id = bagId;
      bag.dataset.paramName = targetParam; // p.ej. "stock_image_keys_menu_file"
      const host = document.getElementById(`selected-${field}-filename`);
      (host || document.body).insertAdjacentElement("afterend", bag);
    } else {
      bag.dataset.paramName = targetParam;
    }
    return bag;
  }

  // Botón "Quitar" reutilizable
  function buildRemoveButton(field, key) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className =
      "remove-selected-image inline-flex items-center justify-center w-6 h-6 rounded-full bg-transparent hover:text-red-300 ml-1 text-warning cursor-pointer";
    btn.dataset.field = field;
    btn.dataset.imageKey = key;
    btn.innerHTML =
      `<svg class="w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 24 24">
         <path fill-rule="evenodd" d="M2 12C2 6.477 6.477 2 12 2s10 4.477 10 10-4.477 10-10 10S2 17.523 2 12Zm5.757-1a1 1 0 1 0 0 2h8.486a1 1 0 1 0 0-2H7.757Z" clip-rule="evenodd"/>
       </svg>`;
    return btn;
  }

  // --------- UX helpers: cerrar y contador ----------
  function closeGallery(field) {
    const gallery = document.getElementById(`stock-gallery-${field}`);
    if (gallery) gallery.classList.add("hidden");
  }

  function selectedCount(field) {
    const bag = document.getElementById(`stock-image-keys-${field}`);
    return bag ? bag.querySelectorAll('input[type="hidden"]').length : 0;
  }

  function updateFinishButtonState(field) {
    const btn = document.querySelector(`#stock-gallery-${field} .finish-stock-gallery`);
    if (!btn) return;
    const count = selectedCount(field);
    btn.disabled = count === 0;
    btn.setAttribute("aria-disabled", String(count === 0));
    const badge = btn.querySelector("[data-count]");
    if (badge) badge.textContent = count;
  }

  // Eliminar una selección (multi o simple)
  function removeSelectedItem(field, key, itemEl) {
    const multi = isMultiField(field);
    if (multi) {
      // 1) Elimina el hidden correspondiente (primer match)
      const bag = document.getElementById(`stock-image-keys-${field}`);
      if (bag) {
        const inputs = bag.querySelectorAll('input[type="hidden"]');
        for (const inp of inputs) {
          if (inp.value === key) {
            inp.remove();
            break;
          }
        }
      }
      // 2) Elimina el preview (itemEl)
      if (itemEl) itemEl.remove();
      // 3) Actualiza contador
      updateFinishButtonState(field);
    } else {
      // Simple: limpia hidden y preview
      const hidden = document.getElementById(`stock-image-key-${field}`);
      if (hidden) hidden.value = "";
      const labelDiv = document.getElementById(`selected-${field}-filename`);
      if (labelDiv) labelDiv.innerHTML = "";
    }
  }

  // Previsualización de imagen con url presignada fresca
  function loadPreviewInto(labelDiv, field, key, url) {
    const filename = key.split("/").pop();
    const isMulti = labelDiv.dataset.mode === "multi";

    const addFallbackLink = (theUrl, container) => {
      const a = document.createElement("a");
      a.href = theUrl;
      a.target = "_blank";
      a.rel = "noopener";
      a.className = "text-blue-500 underline";
      a.textContent = "(abrir)";
      const wrap = document.createElement("span");
      wrap.append(" ", a);
      container.appendChild(wrap);
    };

    const img = new Image();
    img.alt = "Preview";
    img.className = "inline-block h-16 mt-2 border rounded shadow";

    let retried = false;
    let item; // contenedor del preview (para multi)

    img.onerror = async () => {
      if (retried) {
        addFallbackLink(url, isMulti ? item : labelDiv);
        return;
      }
      retried = true;
      try {
        const r2 = await fetch(`/stock_images/fetch?key=${encodeURIComponent(key)}`, {
          headers: { "Accept": "application/json" },
        });
        if (!r2.ok) throw new Error(`HTTP ${r2.status}`);
        const { url: fresh } = await r2.json();
        img.src = fresh;
      } catch (_e) {
        addFallbackLink(url, isMulti ? item : labelDiv);
      }
    };

    if (!isMulti) {
      // Simple: reemplaza el contenido y agrega botón Quitar
      labelDiv.innerHTML = `<span>Seleccionado: <span class="font-semibold">${filename}</span></span><br>`;
      labelDiv.appendChild(img);
      const removeBtn = buildRemoveButton(field, key);
      removeBtn.dataset.itemSelector = "";
      labelDiv.appendChild(removeBtn);
    } else {
      // Multi: agrega un item con filename + miniatura + botón Quitar
      item = document.createElement("div");
      item.className = "mt-1 text-xs text-gray-700 flex items-center flex-wrap gap-2";
      item.dataset.key = key;

      const nameSpan = document.createElement("span");
      nameSpan.className = "inline-block px-2 py-0.5 bg-gray-200 rounded";
      nameSpan.textContent = filename;

      const removeBtn = buildRemoveButton(field, key);
      removeBtn.dataset.itemSelector = "";

      item.appendChild(nameSpan);
      item.appendChild(img);
      item.appendChild(removeBtn);
      labelDiv.appendChild(item);
    }

    img.onload = () => {};
    img.src = url;
  }

  // ---------- Abrir galería ----------
  function openStockGallery(field, folder) {
    if (!field) return;
    const folders = (folder || "hourglass_app/").toString();

    fetch(`/stock_images?field=${encodeURIComponent(field)}&folder=${encodeURIComponent(folders)}`)
      .then((res) => res.text())
      .then((html) => {
        const container = document.getElementById(`stock-gallery-${field}`);
        if (!container) return;

        container.innerHTML = html;
        container.dataset.multi = isMultiField(field) ? "true" : "false";
        container.classList.remove("hidden");

        // Header con botón "X" (evita duplicar)
        if (!container.querySelector(".gallery-header-bar")) {
          const header = document.createElement("div");
          header.className = "gallery-header-bar sticky top-0 inset-x-0 bg-white/90 backdrop-blur border-b border-gray-200 p-2 flex justify-end";
          header.innerHTML = `
            <button type="button" class="close-stock-gallery p-2 rounded hover:bg-gray-100" data-field="${field}" aria-label="Cerrar">✕</button>
          `;
          container.prepend(header);
        }

        // Footer con Cancelar / Terminar (solo multi)
        if (isMultiField(field)) {
          if (!container.querySelector(".gallery-footer-bar")) {
            const footer = document.createElement("div");
            footer.className = "gallery-footer-bar sticky bottom-0 inset-x-0 bg-white/90 backdrop-blur border-t border-gray-200 p-3 flex items-center justify-between";
            footer.innerHTML = `
              <div class="text-sm text-gray-600">
                
              </div>
              <div class="flex items-center gap-2">
                <button type="button"
                        class="cursor-pointer close-stock-gallery px-3 py-2 rounded-lg border border-gray-300 text-gray-700 hover:bg-gray-50"
                        data-field="${field}">
                  Cancelar
                </button>
                <button type="button"
                        class="cursor-pointer finish-stock-gallery px-3 py-2 rounded-lg bg-indigo-600 text-white hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
                        data-field="${field}" aria-disabled="true" disabled>
                  Guardar Selección
                  <span class="ml-2 inline-flex items-center justify-center w-6 h-6 text-xs rounded-full bg-white/20 border border-white/30" data-count>0</span>
                </button>
              </div>
            `;
            container.appendChild(footer);
          }
          updateFinishButtonState(field);
        }

        // Accesibilidad: permitir ESC y foco inmediato
        container.setAttribute("tabindex", "-1");
        try { container.focus({ preventScroll: true }); } catch (_e) {}

        // Marca modo del preview
        const labelDiv = document.getElementById(`selected-${field}-filename`);
        if (labelDiv) {
          labelDiv.dataset.mode = isMultiField(field) ? "multi" : "single";
        }
      })
      .catch(console.error);
  }

  // ---------- Selección simple (1 archivo) ----------
  function selectStockImage(field, key) {
    if (!field || !key) return;

    // 1) Guarda el key en el hidden simple (que ya tienes en el form)
    const input = document.getElementById(`stock-image-key-${field}`);
    if (input) input.value = key;

    // 2) Cierra la galería
    const gallery = document.getElementById(`stock-gallery-${field}`);
    if (gallery) gallery.classList.add("hidden");

    // 3) Preview con URL presignada fresca
    const filename = key.split("/").pop();
    const labelDiv = document.getElementById(`selected-${field}-filename`);
    if (!labelDiv) return;

    labelDiv.dataset.mode = "single";
    labelDiv.innerHTML = `<span>Seleccionado: <span class="font-semibold">${filename}</span></span>`;

    fetch(`/stock_images/fetch?key=${encodeURIComponent(key)}`, {
      headers: { "Accept": "application/json" },
    })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`))))
      .then(({ url }) => loadPreviewInto(labelDiv, field, key, url))
      .catch((err) => {
        console.error("[stock_gallery] fetch url error:", err);
        // fallback: solo filename + botón quitar
        labelDiv.innerHTML = `<span>Seleccionado: <span class="font-semibold">${filename}</span></span>`;
        const removeBtn = buildRemoveButton(field, key);
        labelDiv.appendChild(removeBtn);
      });
  }

  // ---------- Selección múltiple (varios archivos acumulados) ----------
  function selectStockImageMulti(field, key) {
    if (!field || !key) return;

    const paramName = multiParamNameForField(field); // ej: stock_image_keys_menu_file
    const bag = ensureMultiBag(field, paramName);

    // Evitar duplicados exactos
    const exists = Array.from(bag.querySelectorAll('input[type="hidden"]')).some(
      (inp) => inp.value === key
    );
    if (exists) return;

    // Agrega un hidden por cada selección
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = `${paramName}[]`; // Rails lo recibe como array
    input.value = key;
    bag.appendChild(input);

    // Preview acumulado
    const labelDiv = document.getElementById(`selected-${field}-filename`);
    if (labelDiv) {
      labelDiv.dataset.mode = "multi";
      fetch(`/stock_images/fetch?key=${encodeURIComponent(key)}`, {
        headers: { "Accept": "application/json" },
      })
        .then((r) => (r.ok ? r.json() : Promise.reject(new Error(`HTTP ${r.status}`))))
        .then(({ url }) => loadPreviewInto(labelDiv, field, key, url))
        .catch((err) => {
          console.error("[stock_gallery] fetch url error:", err);
          // fallback: filename + botón quitar
          const item = document.createElement("div");
          item.className = "mt-1 text-xs text-gray-700 flex items-center gap-2";
          item.dataset.key = key;

          const nameSpan = document.createElement("span");
          nameSpan.className = "inline-block px-2 py-0.5 bg-gray-200 rounded";
          nameSpan.textContent = key.split("/").pop();

          const removeBtn = buildRemoveButton(field, key);
          item.appendChild(nameSpan);
          item.appendChild(removeBtn);
          labelDiv.appendChild(item);
        });
    }

    // Actualiza contador del botón Terminar
    updateFinishButtonState(field);
    // En multi NO cerramos la galería para seguir eligiendo más
  }

  // ---------- Delegación global ----------
  document.addEventListener("click", (e) => {
    // 1) Abrir galería
    const openBtn = e.target.closest(".show-stock-gallery");
    if (openBtn) {
      const field = openBtn.dataset.field; // "menu_file" | "menu_file_es" | "logo"...
      const folder = openBtn.dataset.folder; // CSV con rutas si aplica
      openStockGallery(field, folder);
      return;
    }

    // 2) Seleccionar imagen dentro de la galería
    const pick = e.target.closest(".select-stock-image");
    if (pick) {
      const field = pick.dataset.field;
      const key = pick.dataset.imageKey;
      if (isMultiField(field)) {
        selectStockImageMulti(field, key);
      } else {
        selectStockImage(field, key);
      }
      return;
    }

    // 3) Cerrar galería (botón "Cancelar" o "X")
    const closeBtn = e.target.closest(".close-stock-gallery");
    if (closeBtn) {
      const field = closeBtn.dataset.field;
      const gallery = document.getElementById(`stock-gallery-${field}`);
      if (gallery) gallery.classList.add("hidden");
      return;
    }

    // 4) Terminar (solo multi)
    const finishBtn = e.target.closest(".finish-stock-gallery");
    if (finishBtn) {
      const field = finishBtn.dataset.field;
      closeGallery(field);
      return;
    }

    // 5) Quitar (multi o simple)
    const removeBtn = e.target.closest(".remove-selected-image");
    if (removeBtn) {
      const field = removeBtn.dataset.field;
      const key = removeBtn.dataset.imageKey;
      const itemEl = removeBtn.closest("[data-key]") || removeBtn.parentElement;
      removeSelectedItem(field, key, itemEl);
      return;
    }
  });

  // ESC para cerrar cualquier galería visible
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      document.querySelectorAll("[id^='stock-gallery-']:not(.hidden')")
        .forEach((el) => el.classList.add("hidden"));
    }
  });

  // (Se eliminó el listener del toggle; ya no se usa)
})();
