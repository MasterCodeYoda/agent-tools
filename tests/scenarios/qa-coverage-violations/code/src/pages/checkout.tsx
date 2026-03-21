// Checkout page — critical flow with NO NL spec
// VIOLATION QCV-01: Payment flow exists but no spec covers it
export function CheckoutPage() {
  return (
    <div>
      <h1>Checkout</h1>
      <div className="cart-summary">
        <h2>Order Summary</h2>
        {/* Cart items */}
      </div>
      <form>
        <input type="text" name="card" placeholder="Card number" />
        <input type="text" name="expiry" placeholder="MM/YY" />
        <input type="text" name="cvc" placeholder="CVC" />
        <button type="submit">Pay Now</button>
      </form>
    </div>
  );
}
