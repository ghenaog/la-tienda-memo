class PurchasesController < ApplicationController
  before_action :authenticate_user!, only: :create
  before_action :its_admin?, only: [ :update, :dashboard, :destroy ]

  def create
    product = Product.find(params[:product_id])

    purchase = Purchase.new
    purchase.product = product
    purchase.user = current_user
    purchase.status = :pending
    purchase.price = product.price

    if product.available? && purchase.save
      balance = Purchase.balance(current_user)
      PurchaseNotifierMailer.notify_account_balance(current_user, balance).deliver_now if balance > 10_000
      product.update_stock
      flash[:notice] = 'Tu compra ha sido realizada con éxito'
    else
      flash[:alert] = 'No ha sido posible agregar este producto a tus compras, intenta de nuevo'
    end
    redirect_to root_path(category_id: product.category_id)
  end

  def update
    purchase = Purchase.find(params[:id])
    if purchase.update(status: :paid)
      flash[:notice] = 'Tu compra ha sido pagada con éxito'
    else
      flash[:alert] = 'No ha sido posible pagar esta compra, intenta de nuevo'
    end
    redirect_to profile_path(id: params[:user_id])
  end

  def dashboard
    @users = User.all
  end

  def destroy
    @purchase = Purchase.find(params[:id])
    @purchase.destroy
    flash[:notice] = 'La compra fue elminada con éxito'
    redirect_to profile_path(id: params[:user_id])
  end

  private
    def its_admin?
      unless current_user.admin?
        redirect_to root_path, alert: "Acceso denegado, no posee permisos como administrador"
      end
    end
end
