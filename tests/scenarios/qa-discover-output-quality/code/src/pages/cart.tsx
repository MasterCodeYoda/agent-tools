// Shopping cart page
export function CartPage() {
  return (
    <div>
      <h1>Shopping Cart</h1>
      <div className="cart-items">
        {/* Cart items with quantity controls and remove buttons */}
      </div>
      <div className="cart-summary">
        <div>Subtotal: $59.98</div>
        <div>Shipping: $5.99</div>
        <div>Total: $65.97</div>
      </div>
      <a href="/checkout" className="checkout-button">Proceed to Checkout</a>
      <a href="/products">Continue Shopping</a>
    </div>
  );
}
