Rails.application.routes.draw do
  devise_for :users,
             path: "",
             path_names: { sign_in: "login", sign_out: "logout" } 


  scope "(:locale)", locale: /en|es/ do
    root "display#index"
    namespace :admin do
      resources :users
    end
    resources :dashboard
    resources :staffs, path: "staff"
   resources :restaurants do
  member do
    delete :purge_menu_file
    delete :purge_menu_file_es
  end
end
      resources :bars do
  member do
    delete :purge_menu_file
    delete :purge_menu_file_es
  end
end

resource :spa, only: [:show, :update] do
  delete :purge_menu_file
  delete :purge_menu_file_es
end

    resources :activities
    resources :specials
    resource :module_title, only: [:edit, :update]
    resource :settings, only: [:show, :edit, :update] do
    delete :remove_qr_code, on: :collection
    end
    get "stock_images", to: "stock_images#stock_images"   
    get "menus/:model/:id/:which", to: "menus#show", as: :menu_fetch
    get "stock_images/fetch", to: "stock_images#fetch", as: :stock_image_fetch
   
  end
end