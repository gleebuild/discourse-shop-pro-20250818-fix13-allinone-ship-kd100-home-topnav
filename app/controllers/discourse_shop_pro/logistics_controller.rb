class DiscourseShopPro::LogisticsController < ::ApplicationController
  skip_before_action :verify_authenticity_token
  def kd100_notify
    json = JSON.parse(request.raw_post) rescue {}
    last = json["lastResult"] || {}
    number = last["nu"] || json["nu"]
    data = last["data"] || []
    if number
      ship = DiscourseShopPro::Shipment.where(tracking_no: number).order(created_at: :desc).first
      ship&.update!(status: (last["state"] || json["status"]).to_s, traces: data)
    end
    render json: { result: true, returnCode: "200", message: "OK" }
  end
end
