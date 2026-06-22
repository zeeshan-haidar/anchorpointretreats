# app/controllers/admin/testimonials_controller.rb
# CRUD for guest testimonials

module Admin
  class TestimonialsController < BaseController
  skip_authorization_check
    # GET /admin/testimonials
    def index
      @testimonials = Testimonial.order(sort_order: :asc)
    end

    # GET /admin/testimonials/new
    def new
      @testimonial = Testimonial.new
    end

    # POST /admin/testimonials
    def create
      @testimonial = Testimonial.new(testimonial_params)
      max_sort = Testimonial.maximum(:sort_order) || 0
      @testimonial.sort_order = max_sort + 1

      if @testimonial.save
        redirect_to admin_testimonials_path, notice: "Testimonial added successfully."
      else
        flash.now[:alert] = "Failed to add testimonial."
        render :new, status: :unprocessable_content
      end
    end

    # GET /admin/testimonials/:id/edit
    def edit
      @testimonial = Testimonial.find(params[:id])
    end

    # PATCH /admin/testimonials/:id
    def update
      @testimonial = Testimonial.find(params[:id])

      if @testimonial.update(testimonial_params)
        redirect_to admin_testimonials_path, notice: "Testimonial updated."
      else
        flash.now[:alert] = "Failed to update testimonial."
        render :edit, status: :unprocessable_content
      end
    end

    # DELETE /admin/testimonials/:id
    def destroy
      @testimonial = Testimonial.find(params[:id])
      @testimonial.image.purge if @testimonial.image.attached?
      @testimonial.destroy!
      redirect_to admin_testimonials_path, notice: "Testimonial removed."
    end

    private

    def testimonial_params
      params.require(:testimonial).permit(:author_name, :author_title, :content,
                                           :rating, :retreat_type, :featured, :sort_order, :image)
    end
  end
end
