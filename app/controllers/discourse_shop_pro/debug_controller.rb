# frozen_string_literal: true

module ::DiscourseShopPro
  class DebugController < ::Admin::AdminController
    def status
      body = {
        plugin_loaded: true,
        after_initialize_started: ::DiscourseShopPro::DEBUG[:after_initialize_started],
        after_initialize_finished: ::DiscourseShopPro::DEBUG[:after_initialize_finished],
        engine_loaded: ::DiscourseShopPro::DEBUG[:engine_loaded],
        boot_errors: ::DiscourseShopPro::DEBUG[:boot_errors]
      }
      render json: body
    end

    def routes
      paths = Rails.application.routes.routes.map { |r| (r.path.spec.to_s rescue nil) }
               .compact.select { |p| p.start_with?('/shop') }.sort
      render json: { routes: paths }
    end

    def match
      path = params[:path].to_s
      if path.blank?
        render json: { error: 'missing query param: path' }
      else
        begin
          hit = Rails.application.routes.recognize_path(path, method: :get) rescue Rails.application.routes.recognize_path(path)
          render json: { path: path, recognized: true, to: hit }
        rescue => e
          render json: { path: path, recognized: false, error: "#{e.class}: #{e.message}" }
        end
      end
    end
  end
end
