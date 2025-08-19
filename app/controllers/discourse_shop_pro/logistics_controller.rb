# frozen_string_literal: true

module ::DiscourseShopPro
  class LogisticsController < ::ApplicationController
    skip_before_action :check_xhr, :redirect_to_login_if_required, :ensure_logged_in, raise: false
    protect_from_forgery with: :null_session

    # 快递 100 异步回调占位
    def kd100_notify
      render plain: "ok"
    end
  end
end
