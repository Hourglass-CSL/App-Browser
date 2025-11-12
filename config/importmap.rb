pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "controllers", to: "controllers/index.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "stock_gallery"
pin "flash" 
pin "mobile_lang" 

 