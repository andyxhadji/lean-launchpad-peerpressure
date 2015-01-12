class ProfileController < ApplicationController
	layout "signup", :only => [ :step_two, :step_three]
skip_before_filter  :verify_authenticity_token

	# api auth key
	def getAuthenticationToken
		potential_user = User.where(:email => params[:user_email]).first
		if params[:user_password] != nil && !potential_user.nil?
                  if potential_user.valid_password?(params[:user_password])
			@user = potential_user
	          end
                end
		respond_to do |format|
			format.json
		end
	end

	# api sign up
	def api_signup
		user = User.new
		user.email = params[:email]
		user.password = params[:password]
		user.name = params[:name]
		user.gender = params[:gender] if !params[:gender].nil?
		user.oauth_token = params[:oauth_token] if !params[:oauth_token].nil?
		user.oauth_expires_at = params[:oauth_expires_at] if !params[:oauth_expires_at].nil?
		
		if !params[:avatar].nil?
                  url = params[:avatar]
		  agent = Mechanize.new
		  page = agent.get(url)
		  redirect_url = page.uri.to_s
		end
		user.avatar = redirect_url
		user.save
		@user = user
		respond_to do |format|
			format.json { render "getAuthenticationToken" }
		end
	end
	# sign up process
	def step_one
		if current_user.signup_process != 0
			return redirect_to root_url
		end
		@user = current_user
		@products = Product.all.limit(14)
	end

        def setLocation
          user = current_user
          user.latitude = params[:latitude].to_s
          user.longitude = params[:longitude].to_s
          user.save
          respond_to do |format|
            format.json
          end
        end

	def step_one_complete

		@user = current_user
		params[:user][:signup_process] = 1
		p params
		@user.update(user_params)
		redirect_to signup_step_two_path
	end

	def step_two
		if current_user.signup_process != 1
			return redirect_to root_url
		end
		#get list of stores for following
		@store_list = User.where(:user_type => 2).limit(100)
		@products_for_each_store = []
		@store_profiles = []
		@store_list.each do |store|
			products = Product.where(:retailer_id => store.retailer_id).limit(6)
			if products.count >= 6
				@products_for_each_store << products
				@store_profiles << store
			end
		end
	end

	def step_two_complete
		current_user.signup_process = 2
		current_user.save
		redirect_to signup_step_three_path
	end

	def step_three
		if current_user.signup_process != 2
			return redirect_to root_url
		end
		@user_list = User.where("retailer_id IS NULL").limit(100)
		@products_for_each_user = []
		@user_profiles = []
		@user_list.each do |user|
			products = getProductsForUser(user.id)
			if products.count >= 6
				@products_for_each_user << products
				@user_profiles << user
			end
		end

	end

	def getProductsForUser(id)
		product_ids = Activity.where(:fromUser => id)
		.where(:activity_type => ["save", "add"])
		.order("created_at desc").limit(6).pluck(:product_id)

		products = Product.find(product_ids)
		p products
		return products
	end

	def step_three_complete
		current_user.signup_process = 3
		current_user.save
		redirect_to root_url
	end

	def index
	end
	
	def show
	 
           
	  if params[:id] != "0"
	  	@user_id = params[:id]
	  else
  		@user_id = current_user.id
   	  end
	  @user_info = User.find(@user_id)

	  @shared_products = userSharedProducts(@user_id)

	  @following = Activity.where(:fromUser => @user_id, :activity_type => "follow").count
	  @followers = Activity.where(:toUser => @user_id, :activity_type =>"follow").count

	  @vigor = Activity.where(:toUser => @user_id, :activity_type => "seen").count
	  @vigor_array = Array.new(@vigor)

	  # much simplified with correct model relations (activity table is a join table)
	  @lists = @user_info.lists.order("created_at desc").limit(5).uniq
	  @products_for_each_list = []
	  @lists.each do |list|
	  	@products_for_each_list << list.products.order("created_at desc").limit(6).uniq
	  end

	  # 1 or 0 , depending on if user is a followed
	  if user_signed_in?
	 	 @followed = isUserFollowed(@user_id)
	  end
	  if !@user_info.retailer_id.nil?
	  	@categories = Category.where(:parent => 1)

	  	@categories.each do |category|
	  	  if params[category.name.gsub(/\s+/, "").to_sym].to_i == 1
	  	  	@store_products = category.products.where(:retailer_id => @user_info.retailer_id)
	  	  	.where("image_s3_url IS NOT NULL").order("vigme_inserted desc").limit(50)
	  	  end
	  	end
	  	if @store_products.nil?
		  	@shared_products = Product.where(:retailer_id => @user_info.retailer_id)
		  	.where("image_s3_url IS NOT NULL")
	      .order("vigme_inserted desc").limit(50)
	 	end
	  	#return render 'store'
	  end


	end

	def update
		@user = current_user
		if @user.update(user_params)
			flash[:notice] = "Profile successfully updated"
		else
		end
		session[:user_image] = @user.avatar.url
		redirect_to profile_settings_path
	end

	def settings 
		@user = User.find(current_user.id)
		@user = current_user
	end

	def isUserFollowed(user_id)
		activity = Activity.where(:fromUser => current_user.id, :activity_type => "follow")
		.where(:toUser => user_id).first
		if activity.nil?
			return 0
		else
			return 1
		end
	end

	def follow
		if userAlreadyFollowed == 0
			activity = Activity.new
			activity.fromUser = current_user.id
			activity.toUser = params[:user_to_follow]
			activity.activity_type = "follow"
			activity.save
		end

		@user_info = User.find(params[:user_to_follow])
		@followers = Activity.where(:toUser => params[:user_to_follow], :activity_type =>"follow").count
		if params[:style]
			@style = "_" + params[:style]
		else
			@style=""
		end
		respond_to do |format|
 	      format.html
          format.js
          format.json
        end
	end

	def userAlreadyFollowed
		activity = Activity.where(:toUser => params[:user_to_follow], :activity_type => "follow", :fromUser => current_user.id).first
		if activity.nil?
			return 0
		else
			return 1
		end
	end

	def unfollow
		activity = Activity.where(:fromUser => current_user.id, :toUser => params[:user_to_unfollow])
		.where(:activity_type => "follow").first
		if !activity.nil?
			activity.destroy
		end

		@user_info = User.find(params[:user_to_unfollow])
		@followers = Activity.where(:toUser => params[:user_to_unfollow], :activity_type =>"follow").count
		if params[:style]
			@style = "_" + params[:style]
		else
			@style=""
		end
		respond_to do |format|
 	      format.html
          format.js
          format.json { render "follow" }
        end
	end

	def followers
		follower_ids = Activity.where(:toUser => params[:id])
		.where(:activity_type => "follow").select(:fromUser).uniq.pluck(:fromUser)
		@followers = User.where(:id => follower_ids).all
		@title = "Followers"
		@user = User.find(params[:id])
		@alreadyFollowedArray = arrayAlreadyFollowed(@followers)
	end

	def following
		follower_ids = Activity.where(:fromUser => params[:id])
		.where(:activity_type => "follow").select(:toUser).uniq.pluck(:toUser)
		@followers = User.where(:id => follower_ids).all
		@title = "Following"
		@alreadyFollowedArray = arrayAlreadyFollowed(@followers)
		@user = User.find(params[:id])

		render "followers"
	end

	def arrayAlreadyFollowed(followers)
		array = []
		followers.each do |follower|
			if user_signed_in?
				activity = current_user.activities.where(:toUser => follower.id)
				.where(:activity_type => "follow").first
			end
			if activity.nil?
				array << 0
			else
				array << 1
			end
		end
		return array
	end

	def profileProductsByCategory

	end

	def sharedProducts
		@user = User.find(params[:id])
		@user_id = params[:id]

		if @user.retailer_id.nil?
			product_ids = Activity.where(:activity_type => ["save","add"], :fromUser => params[:id]).limit(100).pluck(:product_id)
			@products = Product.where(:id => product_ids)
		else
			@products = Product.where(:retailer_id => @user.retailer_id).limit(100)
		end

	end

	def showList
		page = params[:page] if !params[:page].nil?
		@list = List.find(params[:id])
		if !page.nil?
			@products = @list.products.page(page).per(25)
		else
			@products = @list.products
		end
		@user_id = @list.user_id
		@user = User.find(@list.user_id)
	end
	# all user saved or added
	def userSharedProducts(user_id)
                user = User.find(user_id)
		p user
                if user.user_type == 3
                  celeb = Celebrity.where(user_id: user_id).first
                  product_ids = CelebrityProduct.where(celebrity_id: celeb.id).order("created_at desc").limit(100).pluck(:product_id)
		  p product_ids
	 	else
		  product_ids = Activity.where(:activity_type => ["save","add"], :fromUser => user_id).order("created_at desc").limit(100).pluck(:product_id)
		end
               @products = Product.where(:id => product_ids).order("ftp_transfer_datetime desc")
               return @products
	end

	def userSavedProducts(user_id)
		product_ids = Activity.where(:activity_type => "save", :fromUser => user_id).limit(100).pluck(:product_id)
		@products = Product.where(:id => product_ids)
		return @products
	end

	def userAddedProducts(user_id)
		product_ids = Activity.where(:activity_type => "add", :fromUser => user_id).limit(100).pluck(:product_id)
		@products = Product.where(:id => product_ids)
		return @products
	end

	private

	  def user_params
	    params.require(:user).permit(:signup_process, :preference, :name, :avatar, :gender, :email, :password, :picture)
	  end

end
