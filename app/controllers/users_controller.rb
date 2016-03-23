class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /oauth_redirect
  def oauth_redirect
    if params.key?('code')
      response = Net::HTTP.post_form(
          URI('https://api.weibo.com/oauth2/access_token'),
          client_id:      APP_ID,
          client_secret:  APP_SECRET,
          grant_type:     'authorization_code',
          redirect_uri:   "http://#{APP_HOST}/oauth_redirect",
          code:           params['code'])
      json = JSON.parse(response.body)
      @token = json['access_token']
      render :emotion
    end
  end

  def user_timeline
    uri ='https://api.weibo.com/2/statuses/user_timeline.json?'+
        "source=#{APP_ID}&access_token=#{params['access_token']}"
    response = Net::HTTP.get_response(URI(uri))
    json = JSON.parse(response.body)
    happy, unhappy, count = 0.0, 0.0, 0
    if json.key?('statuses')
      statuses = json['statuses']
      statuses.each do |s|
        text = s['text']
        current_words = ((text.scan /\[[^\[\]]+\]/).map { |x| x[1...-1] })
        h, u = get_em(current_words)
        happy += h * current_words.size
        unhappy += u * current_words.size
        s['count'] = current_words.size
        s['happy'] = h
        s['unhappy'] = u
        count += s['count']
      end
      render json: { posts: statuses, happy: happy / count, unhappy: unhappy / count }
    else
      render json: { posts: [], happy: 0, unhappy: 0 }
    end
  end

  private
    def get_em(words)
      return [0.5, 0.5] unless words && words.size > 0
      uri = URI('http://api.bosondata.net/sentiment/analysis')
      res = Net::HTTP.start(uri.host, uri.port) do |http|
        req = Net::HTTP::Post.new(uri)
        req['Content-Type'] = 'application/json'
        req['X-Token'] = 'j7qM_fTv.5457.u0OqgFcklbUv'
        # The body needs to be a JSON string, use whatever you know to parse Hash to JSON
        req.body = words.to_json
        http.request(req)
      end
      result = JSON.parse(res.body)
      ret = result.reduce([0, 0]) do |sum, x|
        [sum.first + x.first, sum.last + x.last]
      end
      [ret.first / result.count, ret.last / result.count]
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.fetch(:user, {})
    end
end
