# frozen_string_literal: true
module DiscourseShopPro
  class Engine < ::Rails::Engine
    engine_name DiscourseShopPro::PLUGIN_NAME
    isolate_namespace DiscourseShopPro
  end
end


Discourse::Application.routes.append do
      post "/shop/admin/seed-nav" => "discourse_shop_pro/admin/admin#seed_nav"

  mount ::DiscourseShopPro::Engine, at: '/shop'
end

DiscourseShopPro::Engine.routes.draw do
  root to: 'public/products#index'
  get '/public/products', to: 'public/products#index'
  get '/public/products/:id', to: 'public/products#show'

  namespace :admin do
    get '/bootstrap' => 'admin#bootstrap'
    resources :orders, only: [:index] do
      post :ship, on: :member
    end
  end

  post '/logistics/kd100/notify', to: 'logistics#kd100_notify'
end


# Boot-time seeding of sidebar links (idempotent)
if SiteSetting.respond_to?(:shop_seed_nav_on_boot) && SiteSetting.shop_seed_nav_on_boot
  begin
    ::DiscourseShopPro::NavSeeder.ensure!
  rescue => e
    Rails.logger.warn("[Shop/NavSeeder] boot seed error: #{e.class} #{e.message}")
  end
end
