# frozen_string_literal: true
# name: discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav
# about: Shop plugin (ready build) with fixed namespaces, explicit requires, admin-only debug endpoints
# version: 1.11.0-ready
# authors: GleeBuild + ChatGPT
# required_version: 3.0.0

enabled_site_setting :shop_enabled
register_asset 'stylesheets/common/discourse-shop-pro.scss'

module ::DiscourseShopPro
  DEBUG = { boot_errors: [], after_initialize_started: false, after_initialize_finished: false, engine_loaded: false }
end

after_initialize do
  ::DiscourseShopPro::DEBUG[:after_initialize_started] = true

  module ::DiscourseShopPro
    PLUGIN_NAME = "discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav"
  end

  module ::DiscourseShopPro; module Public; end; end unless defined?(::DiscourseShopPro::Public)
  module ::DiscourseShopPro; module Admin;  end; end unless defined?(::DiscourseShopPro::Admin)

  begin
    require_relative 'lib/discourse_shop_pro/engine'
    ::DiscourseShopPro::DEBUG[:engine_loaded] = true
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require engine.rb: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  begin
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/public/products_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/admin/orders_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/logistics_controller.rb', __FILE__)
    require_dependency File.expand_path('../app/controllers/discourse_shop_pro/debug_controller.rb', __FILE__)
  rescue => e
    ::DiscourseShopPro::DEBUG[:boot_errors] << "require controllers/models: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
  end

  ::DiscourseShopPro::DEBUG[:after_initialize_finished] = true
end

Discourse::Application.routes.append do
  get '/shop/ping' => proc { [200, { 'Content-Type' => 'text/plain' }, ['pong']] }

  get '/shop/debug/status' => 'discourse_shop_pro/debug#status'
  get '/shop/debug/routes' => 'discourse_shop_pro/debug#routes'
  get '/shop/debug/match'  => 'discourse_shop_pro/debug#match'

  get  '/shop/public/products'       => 'discourse_shop_pro/public/products#index'
  get  '/shop/public/products/:id'   => 'discourse_shop_pro/public/products#show'
  get  '/shop/admin/orders'          => 'discourse_shop_pro/admin/orders#index'
  post '/shop/admin/orders/:id/ship' => 'discourse_shop_pro/admin/orders#ship'
  post '/shop/logistics/kd100/notify'=> 'discourse_shop_pro/logistics#kd100_notify'
end
