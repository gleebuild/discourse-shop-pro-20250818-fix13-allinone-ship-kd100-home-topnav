class DiscourseShopPro::Public::ProductsController < ::ApplicationController
  skip_before_action :ensure_logged_in, raise: false
  skip_before_action :redirect_to_login_if_required, raise: false
  skip_before_action :check_xhr, raise: false
  skip_before_action :preload_json, raise: false
  skip_before_action :verify_authenticity_token, raise: false

  def index
    limit = (params[:limit] || 100).to_i.clamp(1, 200)
    scope = DiscourseShopPro::Product.where(on_sale: true).order(created_at: :desc).limit(limit) rescue []
    @products = scope
    respond_to do |format|
      format.html { render layout: false }
      format.json do
        render json: scope.map { |p|
          specs = Array(p.specs)
          price = specs.first.is_a?(Hash) ? specs.first["price_cents"].to_i : 0
          { id: p.id, title: p.title, images: p.images || [], price_cents: price }
        }
      end
    end
  end

  def show
    @product = DiscourseShopPro::Product.find(params[:id])
    render layout: false
  end
end
