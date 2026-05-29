// Checkout page — critical flow that must be covered by specs
export function CheckoutPage() {
  return (
    <div>
      <h1>Checkout</h1>
      <form>
        <section>
          <h2>Shipping Address</h2>
          <input name="name" placeholder="Full name" required />
          <input name="address" placeholder="Address" required />
          <input name="city" placeholder="City" required />
          <input name="zip" placeholder="ZIP code" required />
        </section>
        <section>
          <h2>Payment</h2>
          <input name="card" placeholder="Card number" required />
          <input name="expiry" placeholder="MM/YY" required />
          <input name="cvc" placeholder="CVC" required />
        </section>
        <div className="order-summary">
          <h2>Order Summary</h2>
          <div>Total: $65.97</div>
        </div>
        <button type="submit">Place Order</button>
      </form>
    </div>
  );
}
