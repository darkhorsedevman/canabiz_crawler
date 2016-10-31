class ArticlesController < ApplicationController
    before_action :set_article, only: [:edit, :update, :destroy, :show]
    #before_action :require_admin, except: [:index, :show]

    #--------ADMIN PAGE-------------------------
    def admin
        @articles = Article.order(sort_column + " " + sort_direction).paginate(page: params[:page], per_page: 100)
    
        #for csv downloader
        respond_to do |format|
            format.html
            format.csv {render text: @articles.to_csv }
        end
    end
    
    #method is used for csv file upload
    def import
        Article.import(params[:file])
        flash[:success] = 'Articles were successfully imported'
        redirect_to article_admin_path 
    end
    
    def search
        @q = "%#{params[:query]}%"
        @articles = Article.where("title LIKE ? or abstract LIKE ?", @q, @q).order(sort_column + " " + 
                                    sort_direction).paginate(page: params[:page], per_page: 50)
        render 'admin'
    end
    #--------ADMIN PAGE-------------------------
    
    def index
        @top_articles = Article.where('image IS NOT NULL').limit(4)
        @categories = Category.order("RANDOM()").limit(4) #randomize the categories that are returned
    end

    #-----------------------------------
    def new
      @article = Article.new
    end
    def create
      @article = Article.new(article_params)
      if @article.save
         flash[:success] = 'Article was successfully created'
         redirect_to article_admin_path
      else 
         render 'new'
      end
    end 
    #-----------------------------------
    
    def show
        @categories = Category.order("RANDOM()").where(:active =>  true).limit(6)
        @other_articles = Article.order("RANDOM()").limit(7)
        
        #add view to article for sorting
        @article.increment(:num_views, by = 1)
        @article.save
        
        #add userView record
    end
    
    #-----------------------------------
    def edit
    end   
    def update
        if @article.update(article_params)
            flash[:success] = 'Article was successfully updated'
            redirect_to article_admin_path
        else 
            render 'edit'
        end
    end 
    #-----------------------------------
   
    def destroy
        @article.destroy
        flash[:success] = 'Article was successfully deleted'
        redirect_to article_admin_path
    end 
   
    def destroy_multiple
      Article.destroy(params[:articles])
      flash[:success] = 'Articles were successfully deleted'
      redirect_to article_admin_path        
    end   
    
    private 
        def require_admin
            if !logged_in? || (logged_in? and !current_user.admin?)
                flash[:danger] = 'Only administrators can visit that page'
                redirect_to root_path
            end
        end
        
        def set_article
            @article = Article.find(params[:id])
        end
        def article_params
            params.require(:article).permit(:title, :abstract, :body, :date, :image, :source_id, state_ids: [], category_ids: [])
        end
      
        def sort_column
            params[:sort] || "date"
        end
        def sort_direction
            params[:direction] || 'desc'
        end
          
end