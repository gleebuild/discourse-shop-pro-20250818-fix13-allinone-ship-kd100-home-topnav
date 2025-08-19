# frozen_string_literal: true
module ::DiscourseShopPro
  class DebugController < ::ApplicationController
    requires_plugin ::DiscourseShopPro::PLUGIN_NAME
    before_action :ensure_admin

    def status
      render json: {
        plugin_loaded: true,
        after_initialize_started: ::DiscourseShopPro::DEBUG[:after_initialize_started],
        after_initialize_finished: ::DiscourseShopPro::DEBUG[:after_initialize_finished],
        engine_loaded: ::DiscourseShopPro::DEBUG[:engine_loaded],
        boot_errors: ::DiscourseShopPro::DEBUG[:boot_errors]
      }
    end

    def routes
      routes = []
      Rails.application.routes.routes.map do |r|
        verb = r.verb&.source&.gsub(/[$^]/, '')
        path = r.path.spec.to_s
        app = r.defaults[:controller]
        routes << "#{verb} #{path} -> #{app}##{r.defaults[:action]}"
      end
      render plain: routes.select { |s| s.include?('/shop/') }.join("\n")
    end

    def match
      path = params[:path].to_s
      begin
        rset = Rails.application.routes.set
        found = rset.recognize_path(path)
        render json: { path: path, recognized: true, route: found }
      rescue => e
        render json: { path: path, recognized: false, error: "#{e.class}: #{e.message}" }
      end
    end
  end
end
