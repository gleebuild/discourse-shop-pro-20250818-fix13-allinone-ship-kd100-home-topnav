# frozen_string_literal: true
# name: discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav
# about: Shop (Products/Orders/WeChatPay/TopicWidget) + Kuaidi100 + Home strip + idempotent migration + robust routes + TOP NAV
# version: 1.11.0
# authors: GleeBuild + ChatGPT
# required_version: 3.0.0

enabled_site_setting :shop_enabled
register_asset 'stylesheets/common/discourse-shop-pro.scss'

after_initialize do
  module ::DiscourseShopPro
    PLUGIN_NAME = "discourse-shop-pro-20250818-fix13-allinone-ship-kd100-home-topnav"
  end
  require_relative 'lib/discourse_shop_pro/engine'

  # top-level fallback routes (same as fix12)
  Discourse::Application.routes.append do
    get '/shop/public/products' => 'discourse_shop_pro/public/products#index'
    get '/shop/public/products/:id' => 'discourse_shop_pro/public/products#show'
    get '/shop/admin/orders' => 'discourse_shop_pro/admin/orders#index'
    post '/shop/admin/orders/:id/ship' => 'discourse_shop_pro/admin/orders#ship'
    post '/shop/logistics/kd100/notify' => 'discourse_shop_pro/logistics#kd100_notify'
  end
end
