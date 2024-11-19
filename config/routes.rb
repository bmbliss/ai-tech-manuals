Rails.application.routes.draw do
  devise_for :users

  resources :manuals do
    resources :sections do
      collection do
        get :search
        post :summarize
        post :generate_content
        get :find_similar
        post :suggest_edits
      end
    end
  end

  root 'home#index'
end
