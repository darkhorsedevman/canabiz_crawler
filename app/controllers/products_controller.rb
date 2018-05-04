class ProductsController < ApplicationController
    before_action :site_visitor_state, only: [:show, :index]
    before_action :set_product, only: [:edit, :update, :destroy, :show]
    before_action :site_visitor_ip, only: [:index, :refine_index]
    before_action :require_admin, only: [:admin, :edit, :update, :delete]

    def index
        
        if params[:format].present?
            
            @searched_category = @product_categories.find_by(name: params[:format])
            
            if !@searched_category.present?
                if params[:format] == 'Hybrid-Indica'
                    @searched_is_dom = 'Indica'
                elsif params[:format] == 'Hybrid-Sativa'
                    @searched_is_dom = 'Sativa'
                else
                    @searched_sub_category = params[:format] 
                end
            end
        end
        
        @products = Product.featured.left_join(:dispensary_source_products).group(:id).
                    order('COUNT(dispensary_source_products.id) DESC').
                    includes(:vendors, :category, :average_prices)

        if @searched_category.present?
            
            @products = @products.where(category_id: @searched_category.id)
            @search_string = "#{@searched_category.name} in #{@site_visitor_state.name}"
        
        elsif @searched_sub_category.present? 
        
            @products = @products.where(sub_category: @searched_sub_category).where(is_dom: nil)
            @search_string = "#{@searched_sub_category} in #{@site_visitor_state.name}"
        
        elsif @searched_is_dom.present?    
        
            @products = @products.where(is_dom: @searched_is_dom)
            @search_string = "Hybrid-#{@searched_is_dom} in #{@site_visitor_state.name}"
        
        else
            @search_string = @site_visitor_state.name
        end

        @products = @products. #order("dsp_count DESC").
                        paginate(page: params[:page], per_page: 16)

    end
    
    def refine_index
        
        result = ProductFinder.new(params).build
        
        #parse returns
        @products, @search_string, @searched_name, @az_letter, 
            @searched_category, @searched_location, @searched_state = 
                result[0], result[1], result[2], result[3], result[4], result[5], result[6]
        
        @products = @products.paginate(page: params[:page], per_page: 16)
        
        render 'index' 
    end
    
    #-------------------------------------------
    def new
      @product = Product.new
    end
    def create
        @product = Product.new(product_params)
        if @product.save
            flash[:success] = 'Product was successfully created'
            redirect_to product_admin_path
        else 
            render 'new'
        end
    end
    
    #-------------------------------------------
    
    def show
        
        #only show featured product
            if @product.featured_product == false
                redirect_to root_path 
            end
        
        #similar products - include is_dom and sub_category as well
            if @product.is_dom.present?
                @similar_products = Product.featured.where.not(id: @product.id).
                            where(is_dom: @product.is_dom).order("Random()").limit(4)
    
            elsif @product.sub_category.present? 
                @similar_products = Product.featured.where.not(id: @product.id).
                            where(sub_category: @product.sub_category).
                            order("Random()").limit(4)
            
            elsif @product.category.present?
                @similar_products = @product.category.products.
                        featured.where.not(id: @product.id).order("Random()").limit(4)
            end
        
        #populate page maps
        @dispensary_sources = @product.dispensary_sources.where(state_id: @site_visitor_state.id).
                                includes(:dispensary, :dispensary_source_products => :dsp_prices).
                                order('last_menu_update DESC').order("name ASC")
                                
        #need a map of dispensary to dispensary source product
        @dispensary_to_product = Hash.new
        @table_headers = Hash.new #for product table
        
        @dispensary_sources.each do |dispSource|
            
            #get the th from dsp_prices
            dispSource.dispensary_source_products.each do |dsp|
                dsp.dsp_prices.each do |dsp_price|
                    if dsp_price.display_order != nil
                       @table_headers.store(dsp_price.display_order, dsp_price.unit)
                    end
                end
            end
            
            #dispensary products
            if !@dispensary_to_product.has_key?(dispSource)
                
                dsps = dispSource.dispensary_source_products.select { |dsp| dsp.product_id == @product.id}
                
                if dsps.size > 0
                    @dispensary_to_product.store(dispSource, dsps[0])
                end
            end
        end
        
        @table_headers = Hash[@table_headers.sort_by {|k,v| k.to_i }]
    end

    #-------------------------------------------
    
    def edit
        @requires_admin = true
    end   
    def update
        if @product.update(product_params)
            flash[:success] = 'Product was successfully updated'
            redirect_to product_admin_path
        else 
            render 'edit'
        end
    end 
    
    #-------------------------------------------
   
    def destroy
        @product.destroy
        flash[:success] = 'Product was successfully deleted'
        redirect_to product_admin_path
    end
   
    def destroy_multiple
        Product.destroy(params[:products])
        flash[:success] = 'Products were successfully deleted'
        redirect_to product_admin_path        
    end
    
    #-------------------------------------------

  
    private
    
        def require_admin
            if !logged_in? || (logged_in? and !current_user.admin?)
                #flash[:danger] = 'Only administrators can visit that page'
                redirect_to root_path
            end
        end
        
        def set_product
          @product = Product.friendly.find(params[:id])
        end
        
        def product_params
          params.require(:product).permit(:name, :product_type, :image, :remote_image_url, 
                                            :ancillary, :featured_product, :alternate_names,
                                            :sub_category, :cbd, :cbn, :min_thc, :med_thc, :max_thc, :is_dom,
                                            :year, :month, :category_id, :description, dispensary_source_ids: [], vendor_ids: [])
        end  
end