# frozen_string_literal: true

module DiscourseShopPro
  module Admin
    class ProductsController < ::Admin::AdminController
      requires_plugin DiscourseShopPro::PLUGIN_NAME

      def index
        @products = DiscourseShopPro::Product.order(created_at: :desc)
        respond_to do |f|
          f.html { render }
          f.json { render_json_dump(products: serialize_data(@products, DiscourseShopPro::ProductSerializer)) }
        end
      end

      def create
        product = DiscourseShopPro::Product.new(product_params)
        if params[:image].present?
          upload = upload_from_param(params[:image])
          product.image_upload = upload if upload
        elsif params[:image_upload_id].present?
          product.image_upload = Upload.find_by(id: params[:image_upload_id])
        end

        if product.save
          respond_to do |f|
            f.html { redirect_to '/shop/admin/products', notice: 'Created' }
            f.json { render_json_dump(product: serialize_data(product, DiscourseShopPro::ProductSerializer)) }
          end
        else
          failed = { errors: product.errors.full_messages }
          respond_to do |f|
            f.html { render :index, status: 422, locals: { error: failed } }
            f.json { render_json_error failed, status: 422 }
          end
        end
      end

      def update
        product = DiscourseShopPro::Product.find_by(id: params[:id])
        raise Discourse::NotFound unless product

        product.assign_attributes(product_params)
        if params[:image].present?
          upload = upload_from_param(params[:image])
          product.image_upload = upload if upload
        elsif params[:image_upload_id].present?
          product.image_upload = Upload.find_by(id: params[:image_upload_id])
        end

        if product.save
          render_json_dump(product: serialize_data(product, DiscourseShopPro::ProductSerializer))
        else
          render_json_error product.errors.full_messages, status: 422
        end
      end

      def destroy
        product = DiscourseShopPro::Product.find_by(id: params[:id])
        raise Discourse::NotFound unless product

        product.destroy
        render json: success_json
      end

      private

      def product_params
        params.permit(:name, :description, :price_cents, :stock)
      end

      def upload_from_param(file_param)
        # file_param is an ActionDispatch::Http::UploadedFile
        return if file_param.blank?
        filename = file_param.original_filename
        creator = UploadCreator.new(file_param, filename, type: "card", for_private_message: false)
        creator.create_for(current_user.id)
      end
    end
  end
end
