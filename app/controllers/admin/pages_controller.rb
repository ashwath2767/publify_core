# coding: utf-8
require 'base64'

class Admin::PagesController < Admin::BaseController
  before_action :set_macro, only: [:new, :edit]
  before_action :set_page, only: [:show, :edit, :update, :destroy]

  layout :get_layout

  def index
    @search = params[:search] ? params[:search] : {}
    @pages = Page.search_with(@search).page(params[:page]).per(this_blog.admin_display_elements)
  end

  def new
    @page = Page.new
    @page.text_filter ||= default_textfilter
    @page.published = true
    @page.user_id = current_user.id
  end

  def edit
    @page.text_filter ||= default_textfilter
  end

  def create
    @page = Page.new(page_params)
    @page.published_at = Time.now
    @page.blog = this_blog
    @page.user_id = current_user.id

    if @page.save
      redirect_to admin_pages_url, notice: I18n.t('admin.pages.new.success')
    else
      render :new
    end
  end

  def update
    @page.text_filter ||= default_textfilter
    if @page.update(page_params)
      redirect_to admin_pages_url, notice: I18n.t('admin.pages.edit.success')
    else
      render :edit
    end
  end

  def destroy
    destroy_a(Page)
  end

  private

  def default_textfilter
    current_user.text_filter || blog.text_filter
  end

  def set_macro
    @macros = TextFilterPlugin.macro_filters
  end

  def get_layout
    case action_name
    when 'new', 'edit', 'create'
      'editor'
    when 'show'
      nil
    else
      'administration'
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_page
    @page = Page.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def page_params
    params.require(:page).permit(:title, :body, :name, :published, :text_filter)
  end
end
