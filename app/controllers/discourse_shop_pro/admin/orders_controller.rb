class DiscourseShopPro::Admin::OrdersController < ::Admin::AdminController
  def index
    orders = DiscourseShopPro::Order.order(created_at: :desc).limit(200)
    render_json_dump orders.as_json(include: :shipments)
  end
  def ship
    o = DiscourseShopPro::Order.find(params[:id])
    carrier = params.require(:carrier); tracking = params.require(:tracking_no)
    s = o.shipments.where(carrier: carrier, tracking_no: tracking).first_or_initialize
    s.status ||= 'created'; s.traces ||= []; s.save!
    if SiteSetting.shop_test_mode
      s.update!(status: 'onway', traces: (s.traces + [{ time: Time.now, context: '【测试】已揽收' }]))
    end
    render_json_dump s
  end
end
