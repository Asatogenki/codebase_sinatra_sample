require "sinatra"
require "sinatra/reloader"
require "sinatra/cookies"
require "pg"

enable "sessions"

client = PG::connect(
  :host => ENV.fetch("DB_HOST", "localhost"),
  :user => ENV.fetch("DB_USER","keihiga"),
  :password => ENV.fetch("DB_PASSWORD",""),
  :dbname => ENV.fetch("DB_NAME","board"))

  get '/posts' do
    if session[:user].nil?
      return redirect '/login'
    end
    @posts = client.exec_params("SELECT * from posts").to_a
    return erb :posts
  end


  post '/posts' do
    name = params[:name]
    content = params[:content]
    image_path = ""
    # 以下のように変更
    if !params[:img].nil? # データがあれば処理を続行する
      tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
      save_to = "./public/images/#{params[:img][:filename]}" # ファイルを保存したい場所
      FileUtils.mv(tempfile, save_to)
      image_path = params[:img][:filename]
    end
    client.exec_params(
      "INSERT INTO posts (name, content, image_path) VALUES ($1, $2, $3)",
      [name, content, image_path]
      )
    redirect '/posts'
  end

  get '/signup' do
    return erb :signup
  end

  post '/signup' do
    name = params[:name]
    email = params[:email]
    password = params[:password]
    client.exec_params(
      "INSERT INTO users (name, email, password) VALUES ($1, $2, $3)",
      [name, email, password]
    )
    user = client.exec_params(
      "SELECT * from users WHERE email = $1 AND password = $2 LIMIT 1",
      [email, password]
    ).to_a.first

    session[:user] = user
    return redirect '/posts'
  end

  get '/login' do
    return erb :login
  end

  post '/login' do
    email = params[:email]
    password = params[:password]
    user = client.exec_params(
      "SELECT * FROM users WHERE email = $1 AND password = $2 LIMIT 1",
      [email, password]
    ).to_a.first
    if user.nil?
      return erb :login
    else
      session[:user] = user
      return redirect '/posts'
    end
  end

  delete '/logout' do
    session[:user] = nil
    return redirect '/login'
  end
  get "/boards/new" do
    return erb :new_board
  end
  post '/boards' do
    name = params[:name]
    client.exec_params(
      "INSERT INTO boards (name) VALUES ($1)",
      [name]
    )
    ​​  new_board = client.exec_params(
      "SELECT * FROM boards WHERE name = $1",[name]).to_a.first
      binding.irb
      # return redirect "/boards/#{new_board['id']}"​
  end
post '/boards/:id/posts' do
  board_id = params[:id]
  name = session[:user]["name"]
  content = params[:content]
  image_path = ""

  # 以下のように変更
  if !params[:img].nil? # データがあれば処理を続行する
    tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
    save_to = "./public/images/#{params[:img][:filename]}" # ファイルを保存したい場所
    FileUtils.mv(tempfile, save_to)
    image_path = params[:img][:filename]
  end
  client.exec_params(
    "INSERT INTO posts (name, content, image_path, board_id) VALUES ($1, $2, $3, $4)",
    [name, content, image_path, board_id]
  )
  return redirect "/boards/#{board_id}"
end
get '/boards/:id' do
  if session[:user].nil?
    return redirect '/login'
  end
  @board_id = params[:id]
  @posts = client.exec_params(
    "SELECT * from posts WHERE board_id = $1",
    [@board_id]
  ).to_a
  return erb :board
end
