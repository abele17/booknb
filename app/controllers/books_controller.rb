class BooksController < ApplicationController
  before_action :set_book, only: %i[show edit update destroy]
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @books = Book.where(status: "available")
    @books = @books.where.not(user_id: current_user.id) if user_signed_in?
    if user_signed_in?
      @users = User.near(current_user.address, 15)
    else
      @users = User.all
    end

    if params[:query].present?
      sql_subquery = <<~SQL
        books.title @@ :query
        OR books.author @@ :query
      SQL
      @books = @books.where(sql_subquery, query: params[:query])
      @users = User.where(id: @books.pluck(:user_id))
    end

    @markers = @users.geocoded.map do |user|
      {
        lat: user.latitude,
        lng: user.longitude,
        info_window_html: render_to_string(partial: "info_window", locals: {user: user}),
        marker_html: render_to_string(partial: "marker")
      }
    end
  end

  def show
    @booking = Booking.new
    @book = Book.find(params[:id])
    @user = @book.user
    if @user.geocoded?
    @markers =  [
      {
        lat: @user.latitude,
        lng: @user.longitude,
        info_window_html: render_to_string(partial: "info_window", locals: {user: @user}),
        marker_html: render_to_string(partial: "marker")
      }
    ]
  end
end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    @book.user = current_user
    if @book.save
      redirect_to book_path(@book), notice: "Book was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @book.update(book_params)
      redirect_to book_path(@book)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to dashboard_path
  end

  private

  def book_params
    params.require(:book).permit(:user_id, :title, :author, :summary, :year, :isbn_number, :book_picture, :editor, :status, :photo)
  end

  def set_book
    @book = Book.find(params[:id])
  end
end
