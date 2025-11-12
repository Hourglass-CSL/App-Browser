import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

export const application = Application.start()
window.Stimulus = application

// Esto carga automáticamente todos los archivos *_controller.js del directorio
eagerLoadControllersFrom("controllers", application)

 